const axios = require("axios");

/**
 * Task T-57: Generate ambulance route using Google Maps Routes API.
 * @param {Object} origin - lat, lng
 * @param {Object} destination - lat, lng
 * @param {string} apiKey - API Key
 * @returns {Promise<Object>} Polyline and ETA
 */
async function generateRoute(origin, destination, apiKey) {
  try {
    const response = await axios.post(
      `https://routes.googleapis.com/directions/v2:computeRoutes`,
      {
        origin: { location: { latLng: origin } },
        destination: { location: { latLng: destination } },
        travelMode: "DRIVE",
        routingPreference: "TRAFFIC_AWARE_OPTIMAL",
      },
      {
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": apiKey,
          "X-Goog-FieldMask": "routes.duration,routes.staticDuration,routes.polyline.encodedPolyline",
        },
      }
    );

    const route = response.data.routes[0];
    return {
      polyline: route.polyline.encodedPolyline,
      duration: route.duration,
      staticDuration: route.staticDuration,
    };
  } catch (error) {
    console.error("Routes API Error:", error.response?.data || error.message);
    return null;
  }
}

module.exports = { generateRoute };
