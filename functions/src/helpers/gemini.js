const { GoogleGenerativeAI } = require("@google-generative-ai/node");

/**
 * Task T-39: Rank hospitals based on Medical Profile using Gemini.
 * @param {Array} hospitals - List of nearby hospitals
 * @param {Object} medicalProfile - User's medical data
 * @param {string} emergencyType - Type of emergency (medical/bystander)
 * @param {string} apiKey - Gemini API Key
 * @returns {Promise<Array>} Ranked hospital list
 */
async function rankHospitals(hospitals, medicalProfile, emergencyType, apiKey) {
  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

  const prompt = `
    You are a professional emergency medical dispatcher.
    Given a patient's medical profile and a list of nearby hospitals, rank the hospitals from 1 to 5 (or max available) based on suitability for this specific case.
    
    PATIENT PROFILE:
    - Blood Type: ${medicalProfile.bloodType || "Unknown"}
    - Allergies: ${medicalProfile.allergies?.join(", ") || "None"}
    - Chronic Illnesses: ${medicalProfile.chronicIllnesses?.join(", ") || "None"}
    - Current Medications: ${medicalProfile.medications?.join(", ") || "None"}
    - Special Conditions: ${medicalProfile.specialConditions?.join(", ") || "None"}
    - Emergency Type: ${emergencyType}

    NEARBY HOSPITALS:
    ${JSON.stringify(hospitals)}

    RESPONSE FORMAT:
    Return ONLY a JSON array of objects. Each object must contain:
    - placeId: (string)
    - name: (string)
    - aiRank: (number, 1 is best)
    - reasoning: (string, brief explanation of why this hospital was ranked this way for THIS patient)

    Do not include any other text or markdown formatting.
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    let text = response.text().trim();
    
    // Clean up potential markdown formatting if Gemini includes it
    if (text.startsWith("```json")) {
        text = text.substring(7, text.length - 3).trim();
    } else if (text.startsWith("```")) {
        text = text.substring(3, text.length - 3).trim();
    }

    const rankedList = JSON.parse(text);
    return rankedList;
  } catch (error) {
    console.error("Gemini ranking error:", error);
    // Return original list if AI fails, with default rank
    return hospitals.slice(0, 5).map((h, index) => ({
      ...h,
      aiRank: index + 1,
      reasoning: "Default ranking due to AI timeout/error."
    }));
  }
}

/**
 * Task T-63: Get bite-sized first aid instructions based on emergency description.
 * @param {string} emergencyDescription - Description of the emergency
 * @param {string} apiKey - Gemini API Key
 * @returns {Promise<Array>} List of first aid steps strings
 */
async function getFirstAidSteps(emergencyDescription, apiKey) {
  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

  const prompt = `
    You are an emergency medical AI assisting a bystander.
    Given this emergency: "${emergencyDescription}"
    
    Provide a JSON array of strings containing immediate, life-saving first aid steps.
    Rules:
    - Return ONLY a raw JSON array of strings.
    - Each string MUST be a single, short action.
    - Maximum 8 words per step.
    - Focus on immediate stabilization until paramedics arrive.
    - Use clear, urgent language (e.g., "Check for breathing", "Apply firm pressure").
    - Do not include markdown formatting or extra text.
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    let text = response.text().trim();
    
    // Clean up potential markdown formatting
    if (text.startsWith("```json")) {
        text = text.substring(7, text.length - 3).trim();
    } else if (text.startsWith("```")) {
        text = text.substring(3, text.length - 3).trim();
    }

    const stepsArray = JSON.parse(text);
    return stepsArray;
  } catch (error) {
    console.error("Gemini first aid error:", error);
    return ["Stay calm.", "Ensure the scene is safe.", "Wait for professional help."];
  }
}

module.exports = { rankHospitals, getFirstAidSteps };
