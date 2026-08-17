# MediSmart Flutter App

The Flutter mobile application for **MediSmart AI**.

MediSmart is an AI-powered medicine assistant that allows users to search medicines, analyze prescriptions, receive medicine information, and interact with an AI backend with persistent memory.

---

## Overview

The Flutter application provides the user-facing experience for MediSmart.

It handles:

* User authentication
* Medicine browsing and search
* Prescription scanning
* AI-powered medicine analysis
* Prescription image uploads
* Search history
* Persistent-memory indicators
* Amazon Bedrock indicators
* Medicine orders
* Prescription and order history

---

## Technology Stack

| Technology              | Purpose                             |
| ----------------------- | ----------------------------------- |
| Flutter                 | Mobile application                  |
| Dart                    | Application programming language    |
| Firebase Authentication | User authentication                 |
| Cloud Firestore         | Application data                    |
| Amazon EC2              | AI backend API                      |
| Amazon S3               | Prescription image storage          |
| CockroachDB             | Persistent AI search memory         |
| Amazon Bedrock          | AI-assisted medicine identification |

---

## Architecture

```text
                    ┌─────────────────────┐
                    │   Flutter Android   │
                    │       App           │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
       Firebase Auth      Firestore        Flask API
                                             │
                                             │
                          ┌──────────────────┼──────────────────┐
                          │                  │                  │
                          ▼                  ▼                  ▼
                     CockroachDB       Amazon Bedrock       Amazon S3
                     Persistent          AI reasoning       Prescription
                       Memory                                Storage
```

---

## AI and Memory Workflow

When a user analyzes a medicine or prescription:

```text
User
 │
 ▼
Flutter App
 │
 ▼
Flask Backend on EC2
 │
 ▼
Check CockroachDB Memory
 │
 ├── Previous result found
 │       │
 │       ▼
 │   Return remembered result
 │
 └── No previous result
         │
         ▼
   ML Model / Bedrock
         │
         ▼
   Store result in
   CockroachDB
         │
         ▼
      Response
         │
         ▼
    Flutter UI
```

The application visually communicates this behavior to the user through memory and AI indicators.

---

## Memory Indicator

When a medicine result is retrieved from CockroachDB, the application displays a:

**Memory badge**

This indicates that the backend recalled information from persistent application memory rather than generating the same result from scratch.

Example:

```text
Medicine: Panadol

Salt: Paracetamol

Memory
Result recalled from previous search
```

---

## Bedrock Indicator

When Amazon Bedrock is used to assist with medicine identification, the application displays a:

**Bedrock badge**

This helps demonstrate the integration between the mobile application, backend AI service, and Amazon Bedrock.

---

## Firebase Integration

Firebase is used for application-level functionality including:

### Firebase Authentication

Handles:

* User registration
* Login
* Authentication state

### Cloud Firestore

Stores application data such as:

* Medicines
* Orders
* Prescription information
* User-related application data

---

## Project Structure

```text
frontend/
│
├── android/
├── assets/
├── ios/
├── lib/
├── linux/
├── macos/
├── test/
├── web/
├── windows/
│
├── .gitignore
├── analysis_options.yaml
├── firebase.json
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

---

## Important Application Files

The main AI integration is located under:

```text
lib/features/ai/
```

The AI screen communicates with the backend for:

* Medicine analysis
* Prescription processing
* Search history
* Memory information
* Bedrock usage information
* Image upload

---

## Requirements

Before running the application, install:

* Flutter SDK
* Dart SDK
* Android Studio
* Android SDK
* A connected Android device or emulator

Verify Flutter:

```bash
flutter --version
```

Run:

```bash
flutter doctor
```

---

## Installation

Clone the repository and enter the frontend directory:

```bash
git clone <repository-url>
cd frontend
```

Install Flutter dependencies:

```bash
flutter pub get
```

---

## Backend Configuration

The application communicates with the MediSmart backend.

Configure the backend API URL according to your deployment environment.

For example:

```text
http://YOUR_EC2_PUBLIC_IP:5000
```

The application uses backend endpoints such as:

```text
/predict
/upload
/history/{user_id}
/health
```

For production deployments, use HTTPS rather than exposing an HTTP API directly.

---

## Run the Application

Connect an Android device or start an Android emulator.

Check connected devices:

```bash
flutter devices
```

Run the application:

```bash
flutter run
```

---

## Build APK

To create a release APK:

```bash
flutter build apk --release
```

The generated APK is located at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## Application Flow

```text
Login
  │
  ▼
Home
  │
  ├── Browse Medicines
  │
  ├── Search Medicines
  │
  ├── AI Prescription Scan
  │       │
  │       ├── Upload prescription
  │       ├── Analyze medicine
  │       ├── Retrieve memory
  │       └── Display AI result
  │
  ├── Orders
  │
  └── History
```

---

## Troubleshooting

### Backend is unreachable

Check:

```text
1. EC2 instance is running
2. Flask server is running
3. API URL is correct
4. EC2 security group allows the required application traffic
```

Test the backend:

```bash
curl http://YOUR_EC2_IP:5000/health
```

### Flutter dependencies fail

Run:

```bash
flutter clean
flutter pub get
```

### Android device is not detected

Run:

```bash
flutter devices
```

Then verify:

* USB debugging is enabled
* Device is authorized
* Android SDK is configured
* USB drivers are installed if required

---

## Hackathon Role

The Flutter application provides the user interface for demonstrating MediSmart's **agentic memory workflow**.

The user interacts with the application while the backend handles:

* Memory retrieval through CockroachDB
* AI processing
* Persistent storage of search information
* Amazon Bedrock integration
* Prescription image storage

This creates a complete flow from:

**Mobile User → AI Backend → Persistent Memory → AI Services → Mobile Response**

---

## License

See the root [`LICENSE`](../LICENSE) file.
