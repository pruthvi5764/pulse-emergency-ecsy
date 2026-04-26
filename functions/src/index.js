const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { fetchNearbyHospitals } = require("./helpers/places");
const { rankHospitals, getFirstAidSteps } = require("./helpers/gemini");
const { generateEmergencyPacket } = require("./helpers/packet");
const { makeVoiceCall, sendWhatsApp } = require("./helpers/voice");
const { generateRoute } = require("./helpers/routes");
const sgMail = require("@sendgrid/mail");

admin.initializeApp();

// Task T-80: Global configuration to minimize cold starts
setGlobalOptions({ 
  maxInstances: 10,
  memory: "512MiB",
  timeoutSeconds: 30,
});

// Secrets (Task T-51/52)
const MAPS_API_KEY = defineSecret("MAPS_API_KEY");
const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
const TWILIO_SID = defineSecret("TWILIO_SID");
const TWILIO_AUTH = defineSecret("TWILIO_AUTH");
const SENDGRID_KEY = defineSecret("SENDGRID_KEY");
const EMERGENCY_FROM_NUMBER = defineSecret("EMERGENCY_FROM_NUMBER");

/**
 * Task T-40: initiateEmergency callable function.
 */
exports.initiateEmergency = onCall({ 
  secrets: [MAPS_API_KEY, GEMINI_API_KEY] 
}, async (request) => {
  const { uid, lat, lng, emergencyType } = request.data;
  if (!uid || !lat || !lng) throw new HttpsError("invalid-argument", "Missing data.");

  try {
    const db = admin.firestore();
    const profileDoc = await db.collection("users").doc(uid).collection("medical_profile").doc("main").get();
    const medicalProfile = profileDoc.exists ? profileDoc.data() : {};

    const rankedHospitals = await rankHospitals(hospitals, medicalProfile, emergencyType || "medical", GEMINI_API_KEY.value());

    // 6. Generate Route (Phase 10 - T-58)
    let routeData = null;
    if (rankedHospitals.length > 0) {
        routeData = await generateRoute(
            { latitude: lat, longitude: lng },
            { latitude: rankedHospitals[0].lat, longitude: rankedHospitals[0].lng },
            MAPS_API_KEY.value()
        );
    }

    const emergencyRef = await db.collection("emergencies").add({
      uid, lat, lng,
      emergencyType: emergencyType || "medical",
      status: "active",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      rankedHospitals: rankedHospitals,
      route: routeData,
      dispatched: false,
    });

    return {
      emergencyId: emergencyRef.id,
      topHospital: rankedHospitals[0] || null,
      status: "initialized",
    };
  } catch (error) {
    console.error("Initiation Failed:", error);
    throw new HttpsError("internal", "System failure.");
  }
});

/**
 * Task T-50: dispatchEmergency callable function.
 */
exports.dispatchEmergency = onCall({ 
  secrets: [TWILIO_SID, TWILIO_AUTH, SENDGRID_KEY, EMERGENCY_FROM_NUMBER] 
}, async (request) => {
  const { emergencyId } = request.data;
  const db = admin.firestore();

  try {
    const emergencyDoc = await db.collection("emergencies").doc(emergencyId).get();
    if (!emergencyDoc.exists) throw new HttpsError("not-found", "Missing record.");
    
    const emergency = emergencyDoc.data();
    const profileDoc = await db.collection("users").doc(emergency.uid).collection("medical_profile").doc("main").get();
    const medicalProfile = profileDoc.exists ? profileDoc.data() : {};

    const packet = generateEmergencyPacket(medicalProfile, { 
        id: emergencyId, 
        ...emergency,
        dashboardUrl: `https://lifelinenexus.web.app/dispatch/${emergencyId}` // T-60
    });

    // Send Emails
    if (medicalProfile.emergencyContacts?.length > 0) {
      sgMail.setApiKey(SENDGRID_KEY.value());
      const msg = {
        to: medicalProfile.emergencyContacts.map(c => c.email).filter(e => e),
        from: "dispatch@lifelinenexus.com",
        subject: "🚨 CRITICAL: Emergency SOS",
        text: packet,
      };
      if (msg.to.length > 0) await sgMail.sendMultiple(msg);
    }

    // Trigger Twilio Alerts
    const hospitalPhone = "+1234567890";
    try {
        await sendWhatsApp(hospitalPhone, packet, {
            accountSid: TWILIO_SID.value(),
            authToken: TWILIO_AUTH.value(),
            fromNumber: EMERGENCY_FROM_NUMBER.value(),
        });
        await makeVoiceCall(hospitalPhone, `Automated alert. Trauma incoming. ${packet}`, {
            accountSid: TWILIO_SID.value(),
            authToken: TWILIO_AUTH.value(),
            fromNumber: EMERGENCY_FROM_NUMBER.value(),
        });
    } catch (e) {
        console.error("Twilio Fallback...");
    }

    await emergencyDoc.ref.update({ dispatched: true, status: "coordinated" });
    return { success: true };
  } catch (error) {
    console.error("Dispatch Error:", error);
    throw new HttpsError("internal", "Dispatch failure.");
  }
});

/**
 * Task T-59: getDispatcherDashboard (Public Tracking Link)
 */
exports.getDispatcherDashboard = onRequest(async (req, res) => {
  const emergencyId = req.path.split("/").pop();
  if (!emergencyId) return res.status(400).send("No ID provided.");

  const db = admin.firestore();
  const doc = await db.collection("emergencies").doc(emergencyId).get();
  if (!doc.exists) return res.status(404).send("Emergency not found.");

  const data = doc.data();
  const polyline = data.route?.polyline || "";

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
        <title>Lifeline Nexus Dispatch Dashboard</title>
        <meta name="viewport" content="initial-scale=1.0, user-scalable=no">
        <style>
            #map { height: 100%; }
            html, body { height: 100%; margin: 0; padding: 0; background: #121212; color: white; font-family: sans-serif; }
            .info { position: absolute; top: 10px; left: 10px; background: rgba(0,0,0,0.8); padding: 20px; border-radius: 12px; z-index: 5; border-left: 4px solid #F44336; }
        </style>
    </head>
    <body>
        <div class="info">
            <h2>🚨 ACTIVE RESCUE</h2>
            <p>Incident ID: ${emergencyId}</p>
            <p>Target Hospital: ${data.rankedHospitals?.[0]?.name || "Searching..."}</p>
        </div>
        <div id="map"></div>
        <script>
            function initMap() {
                const map = new google.maps.Map(document.getElementById("map"), {
                    zoom: 14,
                    center: { lat: ${data.lat}, lng: ${data.lng} },
                    styles: [{"elementType":"geometry","stylers":[{"color":"#212121"}]},{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},{"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},{"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},{"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},{"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#181818"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},{"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},{"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},{"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#4e4e4e"}]},{"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},{"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}]
                });

                const path = google.maps.geometry.encoding.decodePath("${polyline}");
                const routeLine = new google.maps.Polyline({ path, strokeColor: "#F44336", strokeWeight: 5, map });
                
                new google.maps.Marker({ position: { lat: ${data.lat}, lng: ${data.lng} }, map, label: "V" });
                new google.maps.Marker({ position: { lat: ${data.rankedHospitals?.[0]?.lat || 0}, lng: ${data.rankedHospitals?.[0]?.lng || 0} }, map, label: "H" });
            }
        </script>
        <script src="https://maps.googleapis.com/maps/api/js?key=${MAPS_API_KEY.value()}&callback=initMap" async defer></script>
    </body>
    </html>
  `;
  res.status(200).send(html);
});

/**
 * Task T-63: getFirstAidInstructions callable function.
 */
exports.getFirstAidInstructions = onCall({ 
  secrets: [GEMINI_API_KEY] 
}, async (request) => {
  const { emergencyDescription } = request.data;
  
  if (!emergencyDescription) {
    throw new HttpsError("invalid-argument", "Missing emergency description.");
  }

  try {
    const steps = await getFirstAidSteps(emergencyDescription, GEMINI_API_KEY.value());
    return { steps };
  } catch (error) {
    console.error("First Aid Instructions Error:", error);
    throw new HttpsError("internal", "Failed to get first aid instructions.");
  }
});
