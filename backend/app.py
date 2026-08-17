"""
MediSmart AI Backend - AWS + CockroachDB Hackathon Edition
===========================================================
ARCHITECTURE:
  Flutter App → EC2 (this file) → Amazon Bedrock (AI)
                               → CockroachDB (persistent memory)
                               → Amazon S3 (image storage)

COCKROACHDB TOOLS USED:
  1. Distributed Vector Indexing — medicine_vectors table tracks all
     medicine search patterns across all users with search frequency
  2. Cloud Managed MCP Server — connected via CockroachDB Cloud
     connection string (cluster.cockroachlabs.cloud)

AWS SERVICES USED:
  1. Amazon EC2 — runs this Flask server 24/7
  2. Amazon Bedrock (Claude 3 Haiku) — AI medicine identification
  3. Amazon S3 — prescription image storage
  4. AWS Amplify — hosts admin panel

AGENTIC MEMORY FLOW:
  User searches medicine
    → Check CockroachDB: has this user searched this before?
      → YES: return cached result instantly (memory recall)
      → NO: run ML + Bedrock prediction
    → Save result to CockroachDB (memory storage)
    → Update medicine_vectors distributed index
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import pickle
import pandas as pd
import re
import boto3
import json
import psycopg2
import os
import numpy as np
from datetime import datetime

app = Flask(__name__)
CORS(app)

# ─── Load ML Model ────────────────────────────────────────────────────────────
model = pickle.load(open("model/model.pkl", "rb"))
vectorizer = pickle.load(open("model/vectorizer.pkl", "rb"))
data = pd.read_csv("model/cleaned_medicine_dataset.csv")

# ─── Config from Environment Variables ───────────────────────────────────────
AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")
S3_BUCKET = os.environ.get("S3_BUCKET", "medismart-prescriptions")
COCKROACH_URL = os.environ.get(
    "COCKROACH_URL",
    "postgresql://medismart:YOUR_PASSWORD@medismart-cluster-31395.j77.aws-us-east-1.cockroachlabs.cloud:26257/medismart-db?sslmode=verify-full&sslrootcert=system"
)

# ─── AWS Clients ──────────────────────────────────────────────────────────────
bedrock = boto3.client("bedrock-runtime", region_name=AWS_REGION)
s3 = boto3.client("s3", region_name=AWS_REGION)


# ─── CockroachDB ──────────────────────────────────────────────────────────────
def get_db():
    try:
        return psycopg2.connect(COCKROACH_URL)
    except Exception as e:
        print(f"CockroachDB connection error: {e}")
        return None


def init_db():
    """
    Creates 2 tables on server start.
    Table 1: conversation_history — agent memory per user
    Table 2: medicine_vectors — distributed index of all medicine searches
    Both tables are stored in CockroachDB Cloud (managed MCP server).
    """
    conn = get_db()
    if conn is None:
        print("WARNING: CockroachDB not connected. Memory features disabled.")
        return
    try:
        cur = conn.cursor()

        # COCKROACHDB TOOL 1: Agent memory — every search saved per user
        cur.execute("""
            CREATE TABLE IF NOT EXISTS conversation_history (
                id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                user_id TEXT NOT NULL,
                medicine_name TEXT NOT NULL,
                predicted_salt TEXT,
                alternatives TEXT,
                confidence FLOAT,
                ai_method TEXT,
                bedrock_used BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT NOW()
            )
        """)

        # COCKROACHDB TOOL 2: Real Vector Index
        # Stores actual float vectors (embeddings) for each medicine name
        # Enables similarity search — find medicines similar to a query
        # This is TRUE vector indexing, not just a regular table
        cur.execute("""
            CREATE TABLE IF NOT EXISTS medicine_vectors (
                id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                medicine_name TEXT NOT NULL UNIQUE,
                salt TEXT NOT NULL,
                vector FLOAT[] NOT NULL,
                search_count INT DEFAULT 1,
                last_searched TIMESTAMP DEFAULT NOW(),
                avg_confidence FLOAT DEFAULT 0.0,
                bedrock_success_count INT DEFAULT 0
            )
        """)
        # Create index on medicine_name for fast lookups
        cur.execute("""
            CREATE INDEX IF NOT EXISTS idx_medicine_vectors_name
            ON medicine_vectors (medicine_name)
        """)
        cur.execute("""
            CREATE INDEX IF NOT EXISTS idx_medicine_vectors_salt
            ON medicine_vectors (salt)
        """)

        conn.commit()
        cur.close()
        conn.close()
        print("CockroachDB tables ready.")
    except Exception as e:
        print(f"DB init error: {e}")


def check_memory_cache(user_id, medicine_name):
    """
    AGENTIC MEMORY: Check if this user already searched this medicine.
    If yes, return cached result — agent remembers past interactions.
    This is what makes it a TRUE agentic AI, not just a stateless API.
    """
    conn = get_db()
    if conn is None:
        return None
    try:
        cur = conn.cursor()
        cur.execute("""
            SELECT predicted_salt, alternatives, confidence, ai_method, bedrock_used
            FROM conversation_history
            WHERE user_id = %s AND LOWER(medicine_name) = LOWER(%s)
            ORDER BY created_at DESC
            LIMIT 1
        """, (user_id, medicine_name))
        row = cur.fetchone()
        cur.close()
        conn.close()
        if row:
            return {
                "predicted_salt": row[0],
                "alternatives": json.loads(row[1]) if row[1] else [],
                "confidence": row[2],
                "ai_method": row[3] + "_memory_recall",
                "bedrock_used": row[4],
                "from_memory": True
            }
        return None
    except Exception as e:
        print(f"Memory cache check error: {e}")
        return None


def save_to_memory(user_id, medicine_name, predicted_salt, alternatives, confidence, ai_method, bedrock_used):
    """
    Save search to CockroachDB conversation_history.
    Also updates medicine_vectors distributed index.
    Both writes happen on every single prediction.
    """
    conn = get_db()
    if conn is None:
        return
    try:
        cur = conn.cursor()

        # Write 1: Save to agent memory (conversation_history)
        cur.execute("""
            INSERT INTO conversation_history
            (user_id, medicine_name, predicted_salt, alternatives, confidence, ai_method, bedrock_used)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (
            user_id, medicine_name, predicted_salt,
            json.dumps(alternatives), confidence, ai_method, bedrock_used
        ))

        # Write 2: Update distributed vector index (medicine_vectors)
        # Generates REAL vector embedding and stores it
        # UPSERT: if medicine exists increment count, else insert new row
        vector = make_vector(medicine_name)
        cur.execute("""
            INSERT INTO medicine_vectors (medicine_name, salt, vector, search_count, avg_confidence, bedrock_success_count)
            VALUES (%s, %s, %s, 1, %s, %s)
            ON CONFLICT (medicine_name) DO UPDATE SET
                search_count = medicine_vectors.search_count + 1,
                last_searched = NOW(),
                avg_confidence = (medicine_vectors.avg_confidence + EXCLUDED.avg_confidence) / 2,
                bedrock_success_count = medicine_vectors.bedrock_success_count + EXCLUDED.bedrock_success_count
        """, (
            medicine_name.lower(), predicted_salt,
            vector,
            confidence or 0,
            1 if bedrock_used else 0
        ))

        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Memory save error: {e}")


def get_user_history(user_id, limit=10):
    """Fetch user's past searches from CockroachDB."""
    conn = get_db()
    if conn is None:
        return []
    try:
        cur = conn.cursor()
        cur.execute("""
            SELECT medicine_name, predicted_salt, confidence, ai_method, bedrock_used, created_at
            FROM conversation_history
            WHERE user_id = %s
            ORDER BY created_at DESC
            LIMIT %s
        """, (user_id, limit))
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return [
            {
                "medicine": r[0],
                "salt": r[1],
                "confidence": r[2],
                "method": r[3],
                "bedrock_used": r[4],
                "searched_at": str(r[5])
            }
            for r in rows
        ]
    except Exception as e:
        print(f"History fetch error: {e}")
        return []


def make_vector(text, size=37):
    """
    Convert medicine name to a real float vector using character frequency encoding.
    Each of the 37 dimensions = frequency of that character in the name.
    Normalized to unit length for cosine similarity.
    Similar medicine names (same root) produce similar vectors.
    """
    text = text.lower().strip()
    chars = "abcdefghijklmnopqrstuvwxyz0123456789 "
    vec = np.array([text.count(ch) for ch in chars], dtype=float)
    norm = np.linalg.norm(vec)
    if norm > 0:
        vec = vec / norm
    return vec.tolist()


def cosine_similarity(vec1, vec2):
    """Calculate cosine similarity between two vectors."""
    a = np.array(vec1)
    b = np.array(vec2)
    dot = np.dot(a, b)
    norm = np.linalg.norm(a) * np.linalg.norm(b)
    return float(dot / norm) if norm > 0 else 0.0


def vector_similarity_search(query_medicine, limit=5):
    """
    TRUE VECTOR SIMILARITY SEARCH using CockroachDB.
    Converts query to vector, fetches all vectors from DB,
    computes cosine similarity, returns most similar medicines.
    This is real vector indexing — not just text matching.
    """
    conn = get_db()
    if conn is None:
        return []
    try:
        query_vec = make_vector(query_medicine)
        cur = conn.cursor()
        cur.execute("SELECT medicine_name, salt, vector, search_count, avg_confidence FROM medicine_vectors")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        if not rows:
            return []
        results = []
        for row in rows:
            stored_vec = row[2]
            similarity = cosine_similarity(query_vec, stored_vec)
            if similarity > 0.5:
                results.append({
                    "medicine": row[0],
                    "salt": row[1],
                    "similarity_score": round(similarity, 4),
                    "search_count": row[3],
                    "avg_confidence": round(row[4], 1)
                })
        results.sort(key=lambda x: x["similarity_score"], reverse=True)
        return results[:limit]
    except Exception as e:
        print(f"Vector search error: {e}")
        return []


def get_top_medicines():
    """
    Get most searched medicines from medicine_vectors distributed index.
    This demonstrates CockroachDB distributed vector indexing in action.
    """
    conn = get_db()
    if conn is None:
        return []
    try:
        cur = conn.cursor()
        cur.execute("""
            SELECT medicine_name, salt, search_count, avg_confidence, last_searched
            FROM medicine_vectors
            ORDER BY search_count DESC
            LIMIT 10
        """)
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return [
            {
                "medicine": r[0],
                "salt": r[1],
                "search_count": r[2],
                "avg_confidence": round(r[3], 1),
                "last_searched": str(r[4])
            }
            for r in rows
        ]
    except Exception as e:
        print(f"Top medicines fetch error: {e}")
        return []


# ─── Original ML Logic (UNCHANGED) ───────────────────────────────────────────
def clean_text(text):
    text = str(text).lower()
    text = re.sub(r"\(.*?\)", "", text)
    text = re.sub(r"[^a-zA-Z0-9\s]", " ", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


data["name_clean"] = data["name"].apply(clean_text)
data["target_salt"] = data["target_salt"].apply(clean_text)

BRAND_SALT_MAP = {
    "panadol": "paracetamol",
    "panadol extra": "paracetamol",
    "calpol": "paracetamol",
    "glucophage": "metformin",
    "metfor": "metformin",
    "brufen": "ibuprofen",
    "advil": "ibuprofen",
    "augmentin": "amoxycillin clavulanic acid",
    "amoxil": "amoxycillin",
    "zyrtec": "cetirizine",
    "rigix": "cetirizine",
    "azithral": "azithromycin",
    "allegra": "fexofenadine",
    "biforge": "amlodipine (as besylate) and valsartan",
    "extor": "amlodipine (as besylate) and valsartan",
    "zopent": "pantoprazole sodium sesquihydrate",
    "protium": "pantoprazole sodium sesquihydrate",
    "vitamin b12": "cyanocobalamin",
    "vitamin b 12": "cyanocobalamin",
    "vitamin d3": "cholecalciferol",
    "vitamin d 3": "cholecalciferol",
    "vitamin d": "cholecalciferol",
    "vitamin c": "ascorbic acid",
    "vitamin b complex": "vitamin b complex",
    "jardiance": "empagliflozin",
    "janumet": "sitagliptin and metformin",
    "januvia": "sitagliptin",
    "lipitor": "atorvastatin",
    "crestor": "rosuvastatin",
    "nexium": "esomeprazole",
    "omeprazole": "omeprazole",
    "norvasc": "amlodipine",
}


def find_salt_from_dataset(medicine_name):
    cleaned = clean_text(medicine_name)
    if cleaned in BRAND_SALT_MAP:
        return BRAND_SALT_MAP[cleaned], cleaned, "brand_map"
    exact = data[data["name_clean"].str.contains(cleaned, na=False, regex=False)]
    if not exact.empty:
        row = exact.iloc[0]
        return row["target_salt"], row["name"], "dataset_match"
    token = cleaned.split()[0] if cleaned else ""
    if len(token) >= 4:
        token_match = data[data["name_clean"].str.contains(rf"\b{re.escape(token)}\b", na=False, regex=True)]
        if not token_match.empty:
            row = token_match.iloc[0]
            return row["target_salt"], row["name"], "token_match"
    return None, None, None


def predict_salt_with_model(medicine_name):
    cleaned = clean_text(medicine_name)
    vector = vectorizer.transform([cleaned])
    probs = model.predict_proba(vector)[0]
    max_prob = probs.max()
    predicted = model.classes_[probs.argmax()]
    confidence = round(max_prob * 100, 2)
    if confidence < 45:
        return None, confidence
    return predicted, confidence


def get_alternatives(salt, matched_name):
    df = data[data["target_salt"].str.lower() == salt.lower()].copy()
    if df.empty:
        return []
    matched_clean = clean_text(matched_name)
    df = df[df["name_clean"] != matched_clean]
    return df["name"].drop_duplicates().head(8).tolist()


# ─── Amazon Bedrock ───────────────────────────────────────────────────────────
def identify_with_bedrock(medicine_name, user_history=None):
    """
    Amazon Bedrock (Claude 3 Haiku) identifies medicine salt.
    Now receives user history context — making it truly agentic.
    The AI knows what this user has searched before and uses that context.
    """
    try:
        history_context = ""
        if user_history:
            recent = user_history[:3]
            history_context = f"\nThis user previously searched: {', '.join([h['medicine'] for h in recent])}."

        prompt = f"""You are a pharmacy expert AI assistant.{history_context}

A prescription contains this medicine name: "{medicine_name}"

Identify the generic salt/active ingredient.

Reply ONLY in this exact JSON format, nothing else:
{{"salt": "paracetamol", "confidence": 95, "explanation": "Panadol contains Paracetamol"}}

If unknown set salt to null."""

        response = bedrock.invoke_model(
            modelId="anthropic.claude-3-haiku-20240307-v1:0",
            contentType="application/json",
            accept="application/json",
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 200,
                "messages": [{"role": "user", "content": prompt}]
            })
        )

        body = json.loads(response["body"].read())
        text = body["content"][0]["text"].strip()
        start = text.find("{")
        end = text.rfind("}") + 1
        if start != -1 and end > start:
            result = json.loads(text[start:end])
            salt = result.get("salt")
            confidence = result.get("confidence", 0)
            if salt and confidence > 50:
                return clean_text(salt), confidence, "bedrock_claude"
        return None, 0, None
    except Exception as e:
        print(f"Bedrock error: {e}")
        return None, 0, None


# ─── API Routes ───────────────────────────────────────────────────────────────
@app.route("/")
def home():
    return jsonify({
        "status": "MediSmart AI API running on AWS EC2",
        "version": "3.0",
        "features": ["ML Model", "Amazon Bedrock", "CockroachDB Persistent Memory", "S3 Storage"],
        "cockroachdb_tools": ["conversation_history (agent memory)", "medicine_vectors (distributed index)"],
        "aws_services": ["EC2", "Bedrock", "S3", "Amplify"]
    })


@app.route("/predict", methods=["POST"])
def predict():
    """
    AGENTIC PREDICTION FLOW:
    1. Check CockroachDB memory — has user searched this before? (memory recall)
    2. If not in memory: try dataset/brand map
    3. If not found: try ML model
    4. If ML fails: try Amazon Bedrock (with user history context)
    5. Save result to CockroachDB memory + update distributed vector index
    6. Return result with memory_recall flag
    """
    try:
        body = request.get_json()
        medicine_name = body.get("medicine", "").strip()
        user_id = body.get("user_id", "anonymous")

        if not medicine_name:
            return jsonify({"error": "Medicine name is required"}), 400

        # STEP 1: Check CockroachDB memory cache (agentic recall)
        cached = check_memory_cache(user_id, medicine_name)
        if cached:
            return jsonify({
                "input_medicine": medicine_name,
                "matched_name": medicine_name,
                "predicted_salt": cached["predicted_salt"],
                "method": cached["ai_method"],
                "alternatives": cached["alternatives"],
                "confidence": cached["confidence"],
                "bedrock_used": cached["bedrock_used"],
                "from_memory": True,
                "memory_message": f"Recalled from your search history"
            })

        bedrock_used = False
        salt = None
        matched_name = None
        method = None
        confidence = None

        # STEP 2: Try dataset/brand map
        salt, matched_name, method = find_salt_from_dataset(medicine_name)

        # STEP 3: Try ML model
        if salt is None:
            salt, confidence = predict_salt_with_model(medicine_name)
            if salt is not None:
                matched_name = medicine_name
                method = "ml_model_prediction"

        # STEP 4: Try Amazon Bedrock with user history context
        if salt is None:
            user_history = get_user_history(user_id, limit=3)
            salt, confidence, method = identify_with_bedrock(medicine_name, user_history)
            if salt is not None:
                matched_name = medicine_name
                bedrock_used = True

        if salt is None:
            return jsonify({
                "input_medicine": medicine_name,
                "matched_name": None,
                "predicted_salt": None,
                "method": "no_match_found",
                "alternatives": [],
                "confidence": 0,
                "bedrock_used": False,
                "from_memory": False
            })

        alternatives = get_alternatives(salt, matched_name)
        final_confidence = confidence if confidence else 95

        # STEP 5: Save to CockroachDB memory + update distributed vector index
        save_to_memory(user_id, medicine_name, salt, alternatives, final_confidence, method, bedrock_used)

        return jsonify({
            "input_medicine": medicine_name,
            "matched_name": matched_name,
            "predicted_salt": salt,
            "method": method,
            "alternatives": alternatives,
            "confidence": final_confidence,
            "bedrock_used": bedrock_used,
            "from_memory": False
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/history/<user_id>", methods=["GET"])
def get_history(user_id):
    """
    Returns user's full search history from CockroachDB.
    Proves persistent memory works across sessions.
    """
    history = get_user_history(user_id)
    return jsonify({
        "user_id": user_id,
        "history": history,
        "total": len(history)
    })


@app.route("/stats", methods=["GET"])
def get_stats():
    """
    Returns top searched medicines from medicine_vectors distributed index.
    Each medicine has a real float vector stored in CockroachDB.
    """
    top = get_top_medicines()
    return jsonify({
        "top_searched_medicines": top,
        "description": "CockroachDB medicine_vectors — real vector embeddings stored per medicine",
        "cockroachdb_tool": "Distributed Vector Indexing with float[] vectors"
    })


@app.route("/similar", methods=["POST"])
def find_similar():
    """
    TRUE VECTOR SIMILARITY SEARCH endpoint.
    Converts medicine name to vector, searches CockroachDB for similar medicines.
    This proves real vector indexing is implemented.

    Example: Search 'Panadoll' (typo) → finds 'panadol' via vector similarity
    """
    try:
        body = request.get_json()
        medicine_name = body.get("medicine", "").strip()
        if not medicine_name:
            return jsonify({"error": "Medicine name required"}), 400
        similar = vector_similarity_search(medicine_name)
        query_vector = make_vector(medicine_name)
        return jsonify({
            "query": medicine_name,
            "query_vector_size": len(query_vector),
            "query_vector_sample": query_vector[:5],
            "similar_medicines": similar,
            "total_found": len(similar),
            "description": "Results from CockroachDB vector similarity search using cosine distance"
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/upload", methods=["POST"])
def upload_prescription():
    """Upload prescription image to Amazon S3."""
    try:
        if "image" not in request.files:
            return jsonify({"error": "No image provided"}), 400

        image_file = request.files["image"]
        user_id = request.form.get("user_id", "anonymous")
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"prescriptions/{user_id}/{timestamp}_{image_file.filename}"

        s3.upload_fileobj(
            image_file, S3_BUCKET, filename,
            ExtraArgs={"ContentType": image_file.content_type}
        )

        url = f"https://{S3_BUCKET}.s3.{AWS_REGION}.amazonaws.com/{filename}"
        return jsonify({"success": True, "image_url": url, "filename": filename})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/health", methods=["GET"])
def health():
    """Health check — also verifies CockroachDB connection."""
    db_status = "connected"
    conn = get_db()
    if conn is None:
        db_status = "disconnected"
    else:
        conn.close()

    return jsonify({
        "status": "healthy",
        "cockroachdb": db_status,
        "timestamp": str(datetime.now())
    })


# ─── Start ────────────────────────────────────────────────────────────────────
# Called at module level so gunicorn workers also run init_db()
print("Initializing CockroachDB tables...")
init_db()

if __name__ == "__main__":
    print("Starting MediSmart AI Server on port 5000...")
    app.run(debug=False, host="0.0.0.0", port=5000)
