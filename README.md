# MediSmart AI 🩺

### AI-Powered Medicine Assistant with Persistent Agentic Memory

MediSmart AI is an AI-powered medicine assistant that helps users analyze medicines and prescriptions, discover medicine information, and receive intelligent recommendations.

Built for the **CockroachDB × AWS Hackathon: Build with Agentic Memory**, MediSmart combines **CockroachDB persistent memory** with **Amazon Web Services** to create an application that can remember previous medicine-related interactions and use that information in future requests.

---

## 🚀 The Problem

Patients often need to repeatedly search for the same medicines, prescriptions, and medicine-related information.

Traditional medicine applications usually treat every search as a completely new request.

This creates several problems:

* Repeated processing of the same medicine
* No persistent context between searches
* Limited personalization
* Repeated AI/API processing
* Search history separated from the AI workflow

MediSmart AI addresses this by introducing **persistent memory into the medicine-assistance workflow**.

---

# 💡 The Solution

MediSmart gives the AI backend a persistent memory layer powered by **CockroachDB**.

When a user searches for a medicine:

1. The request reaches the backend.
2. MediSmart checks CockroachDB for previously stored information.
3. If a relevant result exists, it is recalled from memory.
4. If no relevant memory exists, the ML model or Amazon Bedrock processes the request.
5. The result is stored in CockroachDB.
6. Future searches can reuse that information.

```text
                 User
                  │
                  ▼
          ┌───────────────┐
          │ Flutter App   │
          └───────┬───────┘
                  │
                  ▼
          ┌───────────────┐
          │ Flask Backend │
          │   AWS EC2     │
          └───────┬───────┘
                  │
                  ▼
        ┌───────────────────┐
        │ CockroachDB Memory│
        └─────────┬─────────┘
                  │
          ┌───────┴────────┐
          │                │
       Found            Not Found
          │                │
          ▼                ▼
    Recall Result     ML Model /
                      Bedrock
                          │
                          ▼
                  Store in Memory
                          │
                          ▼
                     Response
```

---

# 🧠 Agentic Memory

Persistent memory is the central concept of MediSmart AI.

Instead of treating every medicine request independently, the system maintains information about previous interactions.

For example:

### First search

```text
User:
Panadol

Backend:
No previous memory found.

ML Model:
Paracetamol

CockroachDB:
Store Panadol → Paracetamol
```

### Second search

```text
User:
Panadol

Backend:
Previous result found in CockroachDB.

Response:
Paracetamol

Memory:
Recalled from previous search
```

The Flutter application displays a **Memory** indicator when the result is retrieved from persistent memory.

This makes the memory behavior visible rather than keeping it hidden inside the backend.

---

# 🤖 AI Processing

MediSmart uses a combination of:

### Local Machine Learning

A trained machine-learning model handles medicine prediction where applicable.

### Amazon Bedrock

When the local model does not provide a suitable result, Amazon Bedrock can assist with AI-based medicine identification.

The application displays a **Bedrock** indicator when Bedrock is used.

This creates a simple decision flow:

```text
Medicine Request
       │
       ▼
CockroachDB Memory
       │
       ├── Found ─────────► Return Memory
       │
       └── Not Found
              │
              ▼
         ML Prediction
              │
              ├── Result ──► Store Memory
              │
              └── Need AI
                    │
                    ▼
               Amazon Bedrock
                    │
                    ▼
               Store Memory
```

---

# 🐘 CockroachDB Integration

CockroachDB is used as the application's **persistent memory layer**.

The system stores medicine-related information and user search history so that future requests can benefit from previous interactions.

CockroachDB is also used for medicine search/index information and statistics.

### Memory Data

The backend can maintain information such as:

* User ID
* Medicine searched
* Predicted salt
* Confidence information
* Search history
* Search frequency
* Previously generated results

### Why CockroachDB?

CockroachDB provides a distributed SQL database architecture suitable for applications that need reliable persistent data while supporting scalable access patterns.

For MediSmart, it provides the persistence required for the application's memory workflow.

---

# ☁️ AWS Integration

MediSmart uses multiple AWS services.

| AWS Service        | Role                                                      |
| ------------------ | --------------------------------------------------------- |
| **Amazon EC2**     | Hosts the Flask AI backend                                |
| **Amazon Bedrock** | AI-assisted medicine identification                       |
| **Amazon S3**      | Prescription image storage                                |
| **AWS Amplify**    | Hosting for related web/admin components where applicable |

### AWS Architecture

```text
                   AWS
                    │
       ┌────────────┼─────────────┐
       │            │             │
       ▼            ▼             ▼
     EC2         Bedrock          S3
       │            │             │
       │            │             │
       └────────────┼─────────────┘
                    │
                    ▼
               Flask API
```

---

# 📱 Flutter Application

The mobile application is built with Flutter.

Users can:

* Create an account
* Sign in
* Browse medicines
* Search medicines
* Analyze prescriptions
* Upload prescription images
* View medicine information
* View previous searches
* See when information was recalled from memory
* See when Amazon Bedrock was used
* Manage orders
* View prescription/order history

---

# 🔥 Firebase

Firebase is used for application-level functionality.

### Firebase Authentication

Handles:

* User registration
* Login
* Authentication state

### Cloud Firestore

Handles application data such as:

* Medicines
* Orders
* Prescription-related data
* User application data

CockroachDB is intentionally used for the **AI memory/search workflow**, while Firebase handles core application data.

---

# 🏗️ Project Architecture

```text
MediSmart-AI/
│
├── backend/
│   ├── data/
│   ├── model/
│   ├── app.py
│   ├── train.py
│   ├── requirements.txt
│   └── README.md
│
├── frontend/
│   ├── android/
│   ├── assets/
│   ├── ios/
│   ├── lib/
│   ├── linux/
│   ├── macos/
│   ├── test/
│   ├── web/
│   ├── windows/
│   ├── pubspec.yaml
│   └── README.md
│
├── .gitignore
├── LICENSE
└── README.md
```

---

# 🔄 End-to-End Workflow

```text
                  User
                   │
                   ▼
             Flutter App
                   │
                   │ Medicine /
                   │ Prescription
                   ▼
             Flask REST API
                   │
                   ▼
          CockroachDB Memory
                   │
          ┌────────┴────────┐
          │                 │
       Memory Found      No Memory
          │                 │
          ▼                 ▼
      Recall Data       ML Model
                            │
                            ▼
                     Amazon Bedrock
                            │
                            ▼
                    Store New Memory
                            │
                            ▼
                       API Response
                            │
                            ▼
                       Flutter UI
```

---

# 🔌 Backend API

The main backend endpoints include:

| Endpoint             | Method | Purpose                               |
| --------------------- | ------ | -------------------------------------- |
| `/`                  | GET    | Backend information                   |
| `/health`            | GET    | Service health check                  |
| `/predict`           | POST   | Medicine prediction and memory lookup |
| `/history/{user_id}` | GET    | User search history                   |
| `/stats`             | GET    | Medicine search statistics            |
| `/upload`            | POST   | Prescription image upload             |

---

# 🧪 Example Memory Interaction

### Request

```json
{
  "medicine": "Panadol",
  "user_id": "user123"
}
```

### First request

```json
{
  "predicted_salt": "paracetamol",
  "from_memory": false
}
```

The result is stored in CockroachDB.

### Subsequent request

```json
{
  "predicted_salt": "paracetamol",
  "from_memory": true
}
```

The application can then display:

```text
🧠 Memory
Recalled from previous search
```

---

# 🛠️ Technology Stack

## Frontend

* Flutter
* Dart
* Firebase Authentication
* Cloud Firestore

## Backend

* Python
* Flask
* Scikit-learn
* REST API

## AI

* Amazon Bedrock
* Machine Learning model

## Database

* CockroachDB

## Cloud Infrastructure

* Amazon EC2
* Amazon S3
* AWS Amplify

---

# 📂 Repository Structure

The project is intentionally separated into frontend and backend components.

### `frontend/`

Contains the Flutter mobile application.

See [`frontend/README.md`](frontend/README.md) for setup and development instructions.

### `backend/`

Contains the Flask API, machine-learning model, AWS integrations, and CockroachDB memory implementation.

See [`backend/README.md`](backend/README.md) for backend documentation.

---

# 🚀 Getting Started

## Backend

```bash
cd backend

python -m venv venv
```

Windows:

```bash
venv\Scripts\activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Configure the required environment variables and start the server:

```bash
python app.py
```

---

## Frontend

```bash
cd frontend
flutter pub get
flutter run
```

The Flutter application must be configured with the URL of the deployed backend API.

For detailed instructions, see:

[`frontend/README.md`](frontend/README.md)

---

# 🔐 Security

Never commit sensitive credentials to the repository.

Do not commit:

```text
AWS Access Keys
AWS Secret Keys
CockroachDB passwords
Firebase private credentials
EC2 .pem files
API secrets
.env files containing credentials
```

Use environment variables, IAM roles, and appropriate secret-management mechanisms.

---

# 🎯 Hackathon Highlights

MediSmart AI was designed around the central theme of **persistent agentic memory**.

### CockroachDB

Used as persistent memory for medicine-related interactions and search history.

### Amazon Bedrock

Provides AI-assisted medicine identification when additional AI reasoning is required.

### Amazon EC2

Runs the backend API and connects the application's components.

### Amazon S3

Stores prescription images.

### Flutter

Provides the user-facing mobile experience.

---

# 🌟 What Makes MediSmart Different?

Traditional medicine search:

```text
Search → Process → Response
```

MediSmart:

```text
Search
  ↓
Remember
  ↓
Understand Context
  ↓
Reuse Previous Knowledge
  ↓
AI When Needed
  ↓
Remember New Information
```

The application demonstrates how persistent memory can turn a stateless AI interaction into a more context-aware experience.

---

# 🏆 Hackathon Demo Flow

For a live demonstration:

### 1. Open MediSmart

Sign in to the Flutter application.

### 2. Analyze a medicine

Search or scan a medicine such as:

```text
Panadol
```

### 3. Show the first response

The backend processes the medicine and stores the result in CockroachDB.

### 4. Search again

Search for the same medicine.

### 5. Demonstrate memory

The backend retrieves the previous result from CockroachDB.

The Flutter application displays the:

```text
Memory
```

indicator.

### 6. Demonstrate Bedrock

Use a medicine that requires the AI fallback workflow.

The application displays the:

```text
Bedrock
```

indicator.

### 7. Show the backend

Demonstrate the CockroachDB records and backend API during the technical portion of the presentation.

---

# 📊 Key Concept

```text
                    MediSmart AI
                         │
              ┌──────────┴──────────┐
              │                     │
        User Experience         AI Backend
              │                     │
           Flutter              Flask / EC2
              │                     │
              └──────────┬──────────┘
                         │
                  Persistent Memory
                         │
                    CockroachDB
                         │
              ┌──────────┴──────────┐
              │                     │
        Previous Knowledge      New Knowledge
              │                     │
              ▼                     ▼
           Recall              AI Processing
                                    │
                           Amazon Bedrock
                                    │
                                    ▼
                           Store in Memory
```

---

# 📜 License

This project is licensed under the terms specified in [`LICENSE`](LICENSE).

---

## Built For

**CockroachDB × AWS Hackathon — Build with Agentic Memory**

### MediSmart AI

An AI-powered medicine assistant designed to demonstrate how persistent memory can make AI-powered applications more context-aware, efficient, and useful.
