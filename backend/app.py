from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import pandas as pd
from utils.advice_generator import get_advice

# Import Firebase Admin SDK
import firebase_admin
from firebase_admin import credentials
import os

# Initialize Firebase Admin SDK
cred = credentials.Certificate(os.getenv("FIREBASE_CREDENTIALS_PATH"))  # Replace with the actual path to your service account key
firebase_admin.initialize_app(cred)

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})  # Enable CORS for all routes and origins

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
    crop = data["crop"]
    features = data["features"]  # dict with keys: moisture, temp, pH, ec, N, P, K

    if crop not in models:
        return jsonify({"error": "Unsupported crop"}), 400

    df = pd.DataFrame([features])
    prediction = models[crop].predict(df)[0]  # Numerical prediction
    disease_name = label_encoders[crop].inverse_transform([prediction])[0].strip().title()  # Normalize disease name

    # Debugging: Print the disease name
    print(f"Disease Name from LabelEncoder: {disease_name}")

    advice = get_advice(crop, features, disease_name)

    return jsonify({
        "predicted_disease": disease_name,
        "solution": advice["solution"],
        "irrigation": advice["irrigation"],
        "fertilization": advice["fertilization"]
    })
        
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

    