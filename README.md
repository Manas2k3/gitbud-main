#  Gibud

**Gibud** is a Flutter-based mobile application crafted to deliver personalized insights and tracking centered around gut health. The app includes intelligent features such as **gut analysis** and **medical tracking**, aiming to help users better understand and improve their well-being.

The project leverages modern APIs and platforms like:

- **Firebase** – for authentication and real-time database
- **OneSignal** – for push notifications
- **Razorpay** – for handling payments
- **Gemini AI** – for AI-driven insights
- **ZegoCloud** – for video calling

---

## 🛠️ Getting Started

### ✅ Prerequisites

Ensure the following are installed on your system:

- **Flutter SDK** (latest stable version recommended)
- **Dart SDK** (comes with Flutter)
- **Android Studio** or **VS Code**
- **Git**

---

## 🔧 Project Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Manas2k3/gibud-main.git
cd gibud-main

2. Install Dependencies

flutter pub get

3. Set up Firebase

Ensure the following files are placed correctly:

    android/app/google-services.json

    ios/Runner/GoogleService-Info.plist

These files are essential for Firebase integration.
4. Add Keystore for Android Signing

Place your keystore file at:

android/app/upload-keystore.jks

Make sure your key.properties file is configured properly to reference this keystore for signed builds.
▶️ Run the App

You can launch the application using:

flutter run

Or use your preferred IDE’s built-in run button.
📦 Features

    ✅ Firebase Authentication & Firestore Database

    🚀 OneSignal Push Notification Integration

    💳 Razorpay Payment Gateway

    🤖 Google Gemini AI Integration

    📹 ZegoCloud for Video/Audio Calls

    🔑 Role-based User Experience with Dynamic Interface
