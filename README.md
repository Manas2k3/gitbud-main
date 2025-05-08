Gibud

Gibud is a Flutter-based mobile application designed to provide personalized health, wellness, and fitness experiences. This app focuses on delivering tailored solutions for users, including features like gut analysis and medical tracking.

The project integrates several key technologies and APIs, including Firebase, OneSignal, Razorpay, Gemini AI, and ZegoCloud, to deliver a rich, real-time, and intelligent user experience.
🛠️ Getting Started
Prerequisites

    Flutter SDK: Latest stable version recommended
    Dart SDK: Bundled with Flutter
    IDE: Android Studio or VS Code
    Git: Version control system

🔧 Project Setup

    Clone the repository:

    bash

git clone https://github.com/Manas2k3/gibud-main.git

cd gibud-main

Install dependencies:

bash

flutter pub get

Set up Firebase:

    Ensure that google-services.json (for Android) and GoogleService-Info.plist (for iOS) are placed in their correct locations inside the android/app and ios/Runner directories, respectively.

Add upload-keystore.jks:

    Place the upload-keystore.jks file in the following path:

        android/app/upload-keystore.jks

        Ensure that your key.properties file is correctly configured to reference this keystore.

▶️ Run the App

    Use the following command to run the app:

    bash

    flutter run

    Alternatively, you can use your IDE's built-in run feature.

📦 Features

    Firebase Authentication and Firestore
    OneSignal Push Notifications
    Razorpay Payments Integration
    Google Gemini AI API Integration
    ZegoCloud for Video Calling
    Role-based User Flow and Dynamic Interfaces
