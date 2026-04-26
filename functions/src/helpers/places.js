const { Client } = require("@googlemaps/google-maps-services-js");

const client = new Client({});

/**
 * Task T-38: Fetch nearby hospitals using Google Places API.
 * @param {number} lat - Latitude
 * @param {number} lng - Longitude
 * @param {string} apiKey - Google Maps API Key
 * @returns {Promise<Array>} List of hospital objects
 */
async function fetchNearbyHospitals(lat, lng, apiKey) {
  try {
    const response = await client.placesNearby({
      params: {
        location: { lat, lng },
        radius: 10000, // 10km radius
        type: "hospital",
        key: apiKey,
      },
      timeout: 5000,
    });

    return response.data.results.map((place) => ({
      placeId: place.place_id,
      name: place.name,
      address: place.vicinity,
      lat: place.geometry.location.lat,
      lng: place.geometry.location.lng,
      rating: place.rating || 0,
      userRatingsTotal: place.user_ratings_total || 0,
    }));
  } catch (error) {
    console.error("Error fetching hospitals:", error);
    return [];
  }
}

module.exports = { fetchNearbyHospitals };
