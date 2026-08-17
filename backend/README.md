# MediSmart AI Backend

The backend service for **MediSmart AI**, an AI-powered medicine assistant built for the **CockroachDB × AWS Hackathon: Build with Agentic Memory**.

The backend is implemented with **Python + Flask** and deployed on **Amazon EC2**. It connects the Flutter application with the machine-learning model, Amazon Bedrock, Amazon S3, and CockroachDB.

---

## Overview

The MediSmart backend provides APIs for:

* Medicine identification and salt prediction
* AI-assisted medicine analysis using Amazon Bedrock
* Persistent user search memory using CockroachDB
* Medicine search statistics
* Prescription image uploads to Amazon S3
* User search-history retrieval
* Memory-aware responses

The backend follows a memory-first approach:

```text
User Request
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
       CockroachDB memory
             │
             ▼
        Return result
```

This allows MediSmart to improve response efficiency while demonstrating persistent agentic memory.

---

## Technology Stack

| Technology                   | Purpose                                       |
| ----------------------------- | --------------------------------------------- |
| Python                       | Backend development                           |
| Flask                        | REST API                                      |
| Scikit-learn                 | Medicine prediction model                     |
| Amazon Bedrock               | AI-assisted medicine identification           |
| Amazon EC2                   | Backend deployment                            |
| Amazon S3                    | Prescription image storage                    |
| CockroachDB                  | Persistent application memory and search data |
| PostgreSQL-compatible driver | CockroachDB connectivity                      |

---

## CockroachDB Integration

CockroachDB is used as the **persistent memory layer** for MediSmart.

The backend stores information such as:

* User search history
* Previously identified medicines
* Predicted salts
* Confidence information
* Search counts
* Medicine-related vector/index data

When a user searches for a medicine that has already been processed, the backend can retrieve the previous result from CockroachDB instead of performing the complete prediction process again.

### Memory Flow

```text
Medicine Search
      │
      ▼
CockroachDB Memory Lookup
      │
      ├── Match found ──► Return remembered result
      │
      └── No match
             │
             ▼
       ML Model / Bedrock
             │
             ▼
       Save result to
       CockroachDB
             │
             ▼
          Response
```

This persistent memory is one of the core features of the hackathon implementation.

---

## AWS Services

### Amazon EC2

Hosts the Flask backend and exposes the REST API consumed by the Flutter application.

### Amazon Bedrock

Used for AI-assisted medicine identification when the local prediction model does not provide the required result.

### Amazon S3

Used to store prescription images uploaded through the application.

### AWS Amplify

Can be used to host related web/admin components where applicable.

---

## API Endpoints

| Endpoint             | Method | Description                                       |
| --------------------- | ------ | --------------------------------------------------- |
| `/`                  | GET    | Returns backend information                       |
| `/health`            | GET    | Health check and service status                   |
| `/predict`           | POST   | Predicts medicine salt and uses persistent memory |
| `/history/{user_id}` | GET    | Retrieves a user's search history                 |
| `/stats`             | GET    | Returns medicine search statistics                 |
| `/upload`            | POST   | Uploads prescription images to S3                  |

---

## Example Prediction Request

```http
POST /predict
Content-Type: application/json
```

Example request:

```json
{
  "medicine": "Panadol",
  "user_id": "test123"
}
```

A successful response can contain information such as:

```json
{
  "predicted_salt": "paracetamol",
  "from_memory": false
}
```

When the same medicine is searched again, the backend can retrieve the previous result from persistent memory:

```json
{
  "predicted_salt": "paracetamol",
  "from_memory": true
}
```

The `from_memory` field allows the frontend to visually communicate that the result was recalled from persistent memory.

---

## Project Structure

```text
backend/
│
├── data/
│   └── ...
│
├── model/
│   └── model.pkl
│
├── app.py
├── train.py
├── requirements.txt
└── README.md
```

### Important Files

**`app.py`**

Main Flask application containing the REST API and integrations.

**`train.py`**

Used to train or prepare the medicine prediction model.

**`model/model.pkl`**

Serialized machine-learning model used for medicine prediction.

**`requirements.txt`**

Python dependencies required by the backend.

---

## Local Development

### Requirements

* Python 3.10+
* pip
* Git
* AWS account for AWS services
* CockroachDB cluster

### Create Virtual Environment

Windows:

```bash
python -m venv venv
venv\Scripts\activate
```

Linux/macOS:

```bash
python3 -m venv venv
source venv/bin/activate
```

### Install Dependencies

```bash
pip install -r requirements.txt
```

### Configure Environment Variables

Configure the required environment variables before starting the server.

Example:

```text
AWS_REGION=us-east-1
S3_BUCKET=your-s3-bucket
COCKROACH_URL=your-cockroachdb-connection-string
```

Do not commit credentials or connection strings containing passwords to Git.

### Start the Server

```bash
python app.py
```

The API is then available locally at:

```text
http://127.0.0.1:5000
```

---

## AWS Deployment

The backend can be deployed to an Amazon EC2 instance.

High-level deployment flow:

```text
GitHub Repository
       │
       ▼
Amazon EC2
       │
       ├── Flask API
       │
       ├── ML Model
       │
       ├── Amazon Bedrock
       │
       ├── Amazon S3
       │
       └── CockroachDB
```

For deployment, use an EC2 IAM role with only the permissions required by the application.

Avoid storing long-lived AWS access keys directly on the EC2 server.

---

## Health Check

Once the server is running:

```bash
curl http://YOUR_EC2_IP:5000/health
```

Example response:

```json
{
  "status": "healthy",
  "cockroachdb": "connected"
}
```

---

## Security Notes

The following values must **never** be committed to GitHub:

* AWS Access Key ID
* AWS Secret Access Key
* CockroachDB passwords
* EC2 private key files
* Firebase private credentials
* API secrets

Use environment variables, IAM roles, and secret-management mechanisms instead.

A `.env` file should also be excluded from Git:

```gitignore
.env
*.pem
*.key
```

---

## Hackathon Relevance

The backend demonstrates the core **agentic memory** concept of MediSmart AI.

CockroachDB acts as persistent memory that allows the application to retain previous medicine-search information and use that information in future interactions.

Amazon Web Services provide the compute, AI, and storage infrastructure:

```text
CockroachDB
    │
    │ Persistent Memory
    ▼
Flask Backend ─────► Amazon Bedrock
    │
    ├───────────────► Amazon S3
    │
    └───────────────► Amazon EC2
```

---

## License

See the root [`LICENSE`](../LICENSE) file for licensing information.
