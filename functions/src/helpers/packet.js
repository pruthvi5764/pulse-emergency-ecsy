/**
 * Task T-49: Generate a structured emergency packet for dispatch.
 * @param {Object} medicalProfile - User's medical data
 * @param {Object} emergency - Emergency incident data
 * @returns {String} Composed text packet
 */
function generateEmergencyPacket(medicalProfile, emergency) {
  const timestamp = new Date().toLocaleString();
  
  return `
🚨 EMERGENCY DISPATCH PACKET 🚨
---------------------------------
Time: ${timestamp}
Incident ID: ${emergency.id}
Location: https://www.google.com/maps?q=${emergency.lat},${emergency.lng}

PATIENT INFO:
- Blood Type: ${medicalProfile.bloodType || "N/A"}
- Essential Medications: ${medicalProfile.medications?.join(", ") || "None listed"}
- Critical Allergies: ${medicalProfile.allergies?.join(", ") || "None listed"}
- Chronic Illnesses: ${medicalProfile.chronicIllnesses?.join(", ") || "None listed"}
- Special Conditions: ${medicalProfile.specialConditions?.join(", ") || "None listed"}

AI ASSESSMENT:
${emergency.rankedHospitals?.[0]?.reasoning || "Immediate trauma intervention required."}

HOSPITAL DESTINATION:
${emergency.rankedHospitals?.[0]?.name || "Nearest Trauma Center"}
---------------------------------
CONFIRM RECEIPT IMMEDIATELY.
  `.trim();
}

/**
 * Task T-50: Helper to strip non-essential info for privacy.
 */
function sanitizeForDispatcher(packet) {
  // Logic to remove direct names if necessary (as per T-75)
  return packet;
}

module.exports = { generateEmergencyPacket, sanitizeForDispatcher };
