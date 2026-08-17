import os
import re
import pickle
import pandas as pd
import matplotlib.pyplot as plt

from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    ConfusionMatrixDisplay,
)

# Create model folder if not exists
os.makedirs("model", exist_ok=True)

# Load dataset
data = pd.read_csv("data/medicine_dataset.csv")



# Clean text function
def clean_text(text):
    text = str(text).lower()
    text = re.sub(r"\(.*?\)", "", text)
    text = re.sub(r"[^a-zA-Z0-9\s]", " ", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()

# Check required columns
required_columns = ["name", "short_composition1", "short_composition2"]
for col in required_columns:
    if col not in data.columns:
        raise ValueError(f"Missing column: {col}")

# Remove empty rows
data = data.dropna(subset=["name", "short_composition1"])

# Clean columns
data["name_clean"] = data["name"].apply(clean_text)
data["composition1_clean"] = data["short_composition1"].apply(clean_text)
data["composition2_clean"] = data["short_composition2"].fillna("").apply(clean_text)

# 🔥 Use ONLY medicine name for training (VERY IMPORTANT)
data["input_text"] = data["name_clean"]

# Target label: main salt/composition
data["target_salt"] = data["composition1_clean"]

# Remove empty target
data = data[data["target_salt"] != ""]

# Keep only salts with enough examples
salt_counts = data["target_salt"].value_counts()
valid_salts = salt_counts[salt_counts >= 5].index
data = data[data["target_salt"].isin(valid_salts)]

print("Total rows used:", len(data))
print("Total salt classes:", data["target_salt"].nunique())

X = data["input_text"]
y = data["target_salt"]

# Train-test split
X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.2,
    random_state=42,
    stratify=y
)

# TF-IDF Vectorizer
vectorizer = TfidfVectorizer(
    max_features=10000,
    ngram_range=(1, 2),
    stop_words="english"
)

X_train_vec = vectorizer.fit_transform(X_train)
X_test_vec = vectorizer.transform(X_test)

# ML Model
model = LogisticRegression(
    max_iter=1000,
    solver="lbfgs"
)

print("Training model...")
model.fit(X_train_vec, y_train)

# Predictions
y_pred = model.predict(X_test_vec)

# Accuracy
accuracy = accuracy_score(y_test, y_pred)
print("\nModel Accuracy:", round(accuracy * 100, 2), "%")

# Classification report
report = classification_report(y_test, y_pred, zero_division=0)
print("\nClassification Report:\n")
print(report)

# Save report
with open("model/classification_report.txt", "w", encoding="utf-8") as f:
    f.write(f"Model Accuracy: {round(accuracy * 100, 2)}%\n\n")
    f.write(report)

# Confusion matrix for top 20 most common salts only
top_labels = data["target_salt"].value_counts().head(20).index.tolist()

cm = confusion_matrix(y_test, y_pred, labels=top_labels)

plt.figure(figsize=(14, 10))
disp = ConfusionMatrixDisplay(
    confusion_matrix=cm,
    display_labels=top_labels
)
disp.plot(
    xticks_rotation=90,
    cmap="Blues",
    values_format="d"
)

plt.title("Confusion Matrix - Top 20 Medicine Salts")
plt.tight_layout()
plt.savefig("model/confusion_matrix.png", dpi=300)
plt.close()

# Save model and vectorizer
pickle.dump(model, open("model/model.pkl", "wb"))
pickle.dump(vectorizer, open("model/vectorizer.pkl", "wb"))

# Save cleaned dataset for API recommendation
data.to_csv("model/cleaned_medicine_dataset.csv", index=False)

print("\nModel saved successfully!")
print("Saved files:")
print("- model/model.pkl")
print("- model/vectorizer.pkl")
print("- model/classification_report.txt")
print("- model/confusion_matrix.png")
print("- model/cleaned_medicine_dataset.csv")