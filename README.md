# Lifeline Nexus 🚨

**Intelligent Emergency Response & Medical Dispatch System**

Lifeline Nexus is an AI-powered Flutter application designed to bridge the gap between emergency victims, bystanders, and first responders. By leveraging Google's Gemini 1.5 Flash algorithm, the Google Places API, and Twilio's dispatch ecosystem, Lifeline Nexus ensures that critical medical data reaches the *right* hospital before the ambulance even arrives.

## Features ✨

### 1. The Medical Vault
A secure, encrypted local and cloud repository for your critical medical profile (Blood Type, Allergies, Chronic Illnesses, Emergency Contacts).

### 2. Intelligent Victim Flow (SOS)
- **One-Tap / Voice Triggered:** Tap the pulsing SOS button or say "Emergency help me" to trigger the flow.
- **AI Hospital Matching:** The app fetches nearby hospitals via Google Places API and runs them through a Gemini 1.5 prompt along with your Medical Vault data to find the best specialized center (e.g., directing a cardiac patient to a stroke/cardiac center rather than a general clinic).
- **Automated Dispatch:** A Firebase Cloud Function automatically synthesizes your medical profile and AI assessment into an Emergency Packet, dispatching it to the chosen hospital via Twilio (WhatsApp & Automated Voice Call) and to your family via SendGrid (Email).
- **Live Rescue Routing:** Calculates the optimal ambulance route using the Routes API, generating a live web dashboard for police and traffic authorities to clear the path.

### 3. Bystander Mode
- Witness an emergency? Open Bystander Mode and use your voice to describe the situation.
- Gemini AI instantly returns bite-sized, life-saving first-aid steps in a high-contrast, distraction-free UI.
- Silently triggers an emergency dispatch in the background using the bystander's GPS.

### 4. Offline SMS Fallback
- No data? No problem. If the primary cloud functions fail due to lack of internet, the app falls back to a locally cached version of the Medical Vault to generate an intelligent SMS distress packet routed to 911.

## Architecture 🏗️

- **Frontend:** Flutter & Riverpod 3.x
- **Backend:** Node.js, Firebase Cloud Functions (Gen 2)
- **Database:** Cloud Firestore (Encryption at rest secured)
- **AI/ML:** Google Generative AI (Gemini 1.5 Flash)
- **APIs:** Google Maps SDK, Routes API, Places API
- **Comms:** Twilio (Voice & WhatsApp API), SendGrid (Email)

## Setup Instructions 🚀

### 1. Environment Variables
Create a `.env` file in the root directory:
```
MAPS_API_KEY=your_google_maps_api_key
GEMINI_API_KEY=your_gemini_api_key
```

### 2. Firebase Configuration
Ensure your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are placed in their respective directories. You must enable:
- Authentication (Google Sign-In)
- Firestore Database
- Cloud Storage
- App Check (Play Integrity & DeviceCheck)

### 3. Cloud Functions Secrets
Set up the following secrets in Google Cloud Secret Manager for the Firebase project:
- `MAPS_API_KEY`, `GEMINI_API_KEY`
- `TWILIO_SID`, `TWILIO_AUTH`, `EMERGENCY_FROM_NUMBER`
- `SENDGRID_KEY`

### 4. Run the App
```bash
flutter pub get
flutter run
```

---
*Built for the Google Solution Challenge 2026. Empowering communities with AI-driven emergency response.*
