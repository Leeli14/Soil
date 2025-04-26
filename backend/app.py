from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import pandas as pd
from utils.advice_generator import get_advice
import requests  # For making HTTP requests to GitHub

# Import Firebase Admin SDK
import firebase_admin
from firebase_admin import credentials
import os

# Initialize Firebase Admin SDK
cred = credentials.Certificate(os.getenv("FIREBASE_CREDENTIALS_PATH"))  # Replace with the actual path to your service account key
firebase_admin.initialize_app(cred)

app = Flask(__name__)
CORS(app)  # Allow all origins

@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    return response

# Load models and label encoders
models = {
    "tomato": joblib.load("ml_training/rf_tomato.pkl"),
    "potato": joblib.load("ml_training/rf_potato.pkl"),
    "onion": joblib.load("ml_training/rf_onion.pkl")
}

label_encoders = {
    "tomato": joblib.load("ml_training/le_tomato.pkl"),
    "potato": joblib.load("ml_training/le_potato.pkl"),
    "onion": joblib.load("ml_training/le_onion.pkl")
}

@app.route('/predict', methods=['POST'])
def predict():
    data = request.json
    crop = data.get("crop")
    features = data.get("features")

    # Validate crop and features
    if not crop or not features:
        return jsonify({"error": "Missing crop or features"}), 400

    required_keys = ["moisture", "temperature", "ph", "ec", "nitrogen", "phosphorus", "potassium"]
    for key in required_keys:
        if key not in features:
            return jsonify({"error": f"Missing feature: {key}"}), 400

    if crop not in models:
        return jsonify({"error": "Unsupported crop"}), 400

    # Proceed with prediction
    df = pd.DataFrame([features])
    prediction = models[crop].predict(df)[0]
    disease_name = label_encoders[crop].inverse_transform([prediction])[0].strip().title()

    # Debugging: Print the disease name
    print(f"Disease Name from LabelEncoder: {disease_name}")

    advice = get_advice(crop, features, disease_name)

    return jsonify({
        "predicted_disease": disease_name,
        "solution": advice["solution"],
        "irrigation": advice["irrigation"],
        "fertilization": advice["fertilization"]
    })

# GitHub Proxy Route
@app.route('/api/github', methods=['GET'])
def github_proxy():
    try:
        # Replace with the GitHub API endpoint you need
        github_api_url = "https://api.github.com/repos/Leeli14/Soil"
        
        # GitHub token from environment variables
        github_token = os.getenv("GITHUB_TOKEN")
        if not github_token:
            return jsonify({"error": "GitHub token not configured"}), 500

        # Forward the request to GitHub API
        headers = {"Authorization": f"Bearer {github_token}"}
        github_response = requests.get(github_api_url, headers=headers)

        # Return the GitHub API response to the frontend
        return jsonify(github_response.json()), github_response.status_code
    except requests.exceptions.RequestException as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

