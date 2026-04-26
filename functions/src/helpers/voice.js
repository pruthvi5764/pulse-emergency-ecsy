const twilio = require("twilio");

/**
 * Task T-53: Make an automated voice call with synthesized emergency details.
 * @param {string} to - Hospital phone number
 * @param {string} message - Text to synthesize
 * @param {Object} credentials - Twilio AccountSid and AuthToken
 */
async function makeVoiceCall(to, message, { accountSid, authToken, fromNumber }) {
  const client = twilio(accountSid, authToken);

  try {
    const call = await client.calls.create({
      twiml: `<Response><Say voice="alice">${message}</Say></Response>`,
      to: to,
      from: fromNumber,
    });
    console.log(`Voice Call initiated: ${call.sid}`);
    return call.sid;
  } catch (error) {
    console.error("Twilio Voice Error:", error);
    throw error;
  }
}

/**
 * Task T-50: Send WhatsApp message.
 */
async function sendWhatsApp(to, body, { accountSid, authToken, fromNumber }) {
  const client = twilio(accountSid, authToken);
  try {
    const message = await client.messages.create({
      from: `whatsapp:${fromNumber}`,
      to: `whatsapp:${to}`,
      body: body,
    });
    console.log(`WhatsApp sent: ${message.sid}`);
    return message.sid;
  } catch (error) {
    console.error("Twilio WhatsApp Error:", error);
    throw error;
  }
}

module.exports = { makeVoiceCall, sendWhatsApp };
