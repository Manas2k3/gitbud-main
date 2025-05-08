# Gibud

**Gibud** is a Flutter-based mobile application designed to provide personalized health, wellness, or fitness experiences (customize this line if the app serves a more specific purpose like gut analysis, medical tracking, etc.).

The project integrates several key technologies and APIs including Firebase, OneSignal, Razorpay, Gemini AI, and ZegoCloud to deliver a rich, real-time and intelligent user experience.

---

## 🛠️ Getting Started

### Prerequisites

- Flutter SDK (latest stable version recommended)
- Dart SDK (bundled with Flutter)
- Android Studio or VS Code
- Git

---

### 🔧 Project Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Manas2k3/gibud-main.git
   cd gibud-main

    Install dependencies:

flutter pub get

Add your environment variables:

Create a .env file in the root directory and add your secrets:

FCM_SERVER_KEY=your_fcm_key_here
ONESIGNAL_INITIALISE_ID=your_onesignal_id
GEMINI_API_KEY=your_gemini_key
RZP_API_KEY=your_razorpay_key
ONESIGNAL_API_KEY=your_onesignal_api_key
ZEGOCLOUD_APP_ID=your_zegocloud_app_id
ZEGOCLOUD_APP_SIGN=your_zegocloud_app_sign

Set up Firebase:

Ensure that google-services.json (for Android) and GoogleService-Info.plist (for iOS) are placed in their correct locations inside the android/app and ios/Runner directories respectively.

Add upload-keystore.jks:

Place the upload-keystore.jks file in the following path:

    android/app/upload-keystore.jks

    Ensure that your key.properties file is correctly configured to reference this keystore.

▶️ Run the App

Use the following command to run the app:

flutter run

Or use your IDE's built-in run feature.
📦 Features

    Firebase Authentication and Firestore

    OneSignal Push Notifications

    Razorpay Payments Integration

    Google Gemini AI API integration

    ZegoCloud for Video Calling

    Role-based user flow and dynamic interfaces

📄 License

This project is licensed under the MIT License.
