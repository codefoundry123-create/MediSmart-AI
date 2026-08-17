# MediSmart AI Backend
## Repo: medismart-ai | Runs on: AWS EC2

---

## What This Repo Does

Python Flask AI server. Runs on AWS EC2 and handles:
- Medicine salt prediction (ML model + Amazon Bedrock)
- Persistent agent memory (CockroachDB — remembers every search)
- Distributed search index (CockroachDB medicine_vectors table)
- Prescription image storage (Amazon S3)
- User search history API

## CockroachDB Tools Used

| Tool | Table | What it does |
|---|---|---|
| Distributed Vector Indexing | `medicine_vectors` | Tracks every medicine searched globally, search count, confidence scores |
| Cloud Managed MCP Server | Both tables | Connected via CockroachDB Cloud connection string |

## AWS Services Used

| Service | Purpose |
|---|---|
| EC2 | Runs this Flask server 24/7 |
| Bedrock (Claude 3 Haiku) | AI medicine identification with user history context |
| S3 | Stores prescription images |
| Amplify | Hosts admin panel (separate repo) |

---

## STEP 1 — Prerequisites on Your Windows PC

### Install Python
1. Go to https://python.org/downloads
2. Download Python 3.11
3. During install CHECK "Add Python to PATH"
4. Verify:
```
python --version
```
Expected: `Python 3.11.x`

### Install AWS CLI
1. Go to https://aws.amazon.com/cli/
2. Download and run Windows installer
3. Verify:
```
aws --version
```
Expected: `aws-cli/2.x.x`

---

## STEP 2 — AWS Account and IAM Setup

### Create IAM User
1. Go to https://console.aws.amazon.com
2. Search IAM → Users → Create user
3. Username: `medismart-admin`
4. Attach these policies:
   - `AmazonEC2FullAccess`
   - `AmazonS3FullAccess`
   - `AmazonBedrockFullAccess`
5. Create access key → Choose CLI → Copy both keys

### Configure AWS CLI
```
aws configure
```
Enter:
```
AWS Access Key ID: YOUR_ACCESS_KEY
AWS Secret Access Key: YOUR_SECRET_KEY
Default region name: us-east-1
Default output format: json
```
Verify:
```
aws sts get-caller-identity
```
Expected: JSON with your account ID

---

## STEP 3 — Create Amazon S3 Bucket

```
aws s3 mb s3://medismart-prescriptions --region us-east-1
```
Verify:
```
aws s3 ls
```
Expected: `medismart-prescriptions` in list

Set public read policy:
```
aws s3api put-bucket-policy --bucket medismart-prescriptions --policy "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"PublicRead\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::medismart-prescriptions/*\"}]}"
```

---

## STEP 4 — Enable Amazon Bedrock

1. AWS Console → Search Bedrock → Click Amazon Bedrock
2. Left menu → Model access → Manage model access
3. Find Anthropic → Check "Claude 3 Haiku"
4. Click "Request model access"
5. Wait 2-5 minutes → Refresh → Status: "Access granted"

Verify:
```
aws bedrock list-foundation-models --region us-east-1 --query "modelSummaries[?contains(modelId,'claude-3-haiku')]"
```
Expected: Shows Claude 3 Haiku details

---

## STEP 5 — CockroachDB Cloud Setup

### Create Account
1. Go to https://cockroachlabs.cloud
2. Sign Up → Verify email

### Create Free Cluster
1. Click "Create Cluster"
2. Choose Serverless (free)
3. Cloud provider: AWS
4. Region: us-east-1
5. Cluster name: `medismart-cluster`
6. Click "Create cluster" → Wait 2-3 minutes

### Create Database User
1. Popup appears → Username: `medismart`
2. Click "Generate & save password"
3. COPY password — save it now, you cannot see it again

### Get Connection String
1. Select "Connection string" → Select "Python"
2. Copy the string — looks like:
```
postgresql://medismart:PASSWORD@free-tier.cockroachlabs.cloud:26257/defaultdb?sslmode=verify-full
```
Save this — needed in STEP 8

### Verify in SQL Shell (Optional)
1. CockroachDB Console → Connect → Open SQL Shell
2. Run:
```sql
SELECT version();
```
Expected: Shows CockroachDB version

---

## STEP 6 — Create EC2 Instance

### Launch EC2
1. AWS Console → EC2 → Launch instance
2. Settings:
   - Name: `medismart-server`
   - AMI: Ubuntu Server 22.04 LTS
   - Instance type: `t2.medium`
   - Key pair: Create new → Name: `medismart-key` → RSA → .pem
   - SAVE the .pem file that downloads
3. Network settings → Edit → Add rules:
   - SSH, Port 22, Source: My IP
   - Custom TCP, Port 5000, Source: Anywhere 0.0.0.0/0
4. Storage: 20 GB
5. Launch instance

### Get EC2 Public IP
1. EC2 → Instances → Click `medismart-server`
2. Copy "Public IPv4 address" e.g. `54.123.45.67`
3. Save this IP — needed in medismart-app setup

### Attach IAM Role to EC2
1. EC2 → Instances → Select instance
2. Actions → Security → Modify IAM role
3. Click "Create new IAM role":
   - Select AWS service → EC2 → Next
   - Attach: `AmazonBedrockFullAccess` + `AmazonS3FullAccess`
   - Role name: `medismart-ec2-role`
   - Create role
4. Back in EC2 → Select `medismart-ec2-role` → Update IAM role

---

## STEP 7 — Connect to EC2

```
cd Downloads
ssh -i medismart-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```
If permission error on Windows:
```
icacls medismart-key.pem /inheritance:r /grant:r "%username%:R"
ssh -i medismart-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```
Expected: `ubuntu@ip-xxx-xxx-xxx-xxx:~$`

---

## STEP 8 — Setup Server on EC2

### Install Software
Run inside EC2 SSH terminal:
```
sudo apt update
sudo apt install python3-pip git -y
```

### Upload This Repo to EC2
Open NEW Command Prompt on your PC (keep SSH open):
```
scp -i Downloads/medismart-key.pem -r "FULL_PATH_TO_THIS_REPO" ubuntu@YOUR_EC2_PUBLIC_IP:/home/ubuntu/medismart_ai
```
Verify in SSH terminal:
```
ls /home/ubuntu/medismart_ai
```
Expected: `app.py`, `requirements.txt`, `model/`

### Install Python Dependencies
In SSH terminal:
```
cd /home/ubuntu/medismart_ai
pip3 install -r requirements.txt
```
Expected: All packages install (3-5 minutes)

Verify:
```
python3 -c "import flask; import boto3; import psycopg2; print('All OK')"
```
Expected: `All OK`

### Set Environment Variables
Replace values with your actual ones:
```
echo 'export AWS_REGION="us-east-1"' >> ~/.bashrc
echo 'export S3_BUCKET="medismart-prescriptions"' >> ~/.bashrc
echo 'export COCKROACH_URL="YOUR_COCKROACHDB_CONNECTION_STRING"' >> ~/.bashrc
source ~/.bashrc
```
Verify:
```
echo $COCKROACH_URL
echo $S3_BUCKET
```
Expected: Shows your values (not empty)

---

## STEP 9 — Start Server

```
cd /home/ubuntu/medismart_ai
python3 app.py
```
Expected output:
```
Initializing CockroachDB tables...
CockroachDB tables ready.
Starting MediSmart AI Server on port 5000...
 * Running on http://0.0.0.0:5000
```

### Keep Running After SSH Disconnect
```
sudo apt install screen -y
screen -S medismart
cd /home/ubuntu/medismart_ai
python3 app.py
```
Press `Ctrl+A` then `D` to detach.

Reconnect later:
```
screen -r medismart
```

Auto-start on reboot:
```
crontab -e
```
Add this line:
```
@reboot cd /home/ubuntu/medismart_ai && python3 app.py >> /home/ubuntu/server.log 2>&1 &
```

---

## STEP 10 — Verify Everything Works

### Health check (also shows CockroachDB status)
```
curl http://YOUR_EC2_IP:5000/health
```
Expected:
```json
{"status": "healthy", "cockroachdb": "connected", "timestamp": "..."}
```

### Medicine prediction
```
curl -X POST http://YOUR_EC2_IP:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"medicine": "Panadol", "user_id": "test123"}'
```
Expected: `{"predicted_salt": "paracetamol", "from_memory": false, ...}`

### Memory recall (search same medicine again)
```
curl -X POST http://YOUR_EC2_IP:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"medicine": "Panadol", "user_id": "test123"}'
```
Expected: `{"from_memory": true, "memory_message": "Recalled from your search history", ...}`

### CockroachDB history
```
curl http://YOUR_EC2_IP:5000/history/test123
```
Expected: Shows the search from above

### Distributed vector index (medicine_vectors table)
```
curl http://YOUR_EC2_IP:5000/stats
```
Expected: Shows top searched medicines with search counts

### Bedrock test (use medicine not in dataset)
```
curl -X POST http://YOUR_EC2_IP:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"medicine": "Xanax", "user_id": "test123"}'
```
Expected: `{"bedrock_used": true, ...}`

### S3 upload test
```
curl -X POST http://YOUR_EC2_IP:5000/upload \
  -F "image=@any_image.jpg" \
  -F "user_id=test123"
```
Expected: Returns S3 URL

---

## API Endpoints Reference

| Endpoint | Method | What it does |
|---|---|---|
| `/` | GET | Server info + features list |
| `/health` | GET | Health check + CockroachDB status |
| `/predict` | POST | Predict medicine salt (with memory) |
| `/history/{user_id}` | GET | Get user search history from CockroachDB |
| `/stats` | GET | Top medicines from distributed vector index |
| `/upload` | POST | Upload image to S3 |

---

## Troubleshooting

**Port 5000 not accessible:**
```
# EC2 Console → Security Groups → Inbound Rules
# Add: Custom TCP, Port 5000, Source: 0.0.0.0/0
```

**CockroachDB connection fails:**
```
echo $COCKROACH_URL
# Verify URL is set and correct
# Check password has no special characters that break the URL
```

**Bedrock error:**
```
# Verify model access granted in Bedrock console
# Verify EC2 IAM role has AmazonBedrockFullAccess
```

**S3 upload fails:**
```
aws s3 ls
# Verify bucket exists and IAM role has AmazonS3FullAccess
```

**medicine_vectors table empty:**
```
# Make at least one /predict call first
# Then call /stats — it will show data
```

---

## Quick Reference
```
EC2 Public IP:     ___________________
EC2 Key file:      ___________________
S3 Bucket:         medismart-prescriptions
CockroachDB URL:   ___________________
AWS Region:        us-east-1
Bedrock Model:     anthropic.claude-3-haiku-20240307-v1:0
```
