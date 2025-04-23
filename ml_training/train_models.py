import pandas as pd
import joblib
import os
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split


# Where to find data & where to save models
DATA_DIR = '/workspaces/Soil/ml_training'  # absolute path to the directory
if not os.path.exists(DATA_DIR):
    raise FileNotFoundError(f"Data directory {DATA_DIR} does not exist.")
OUTPUT_DIR = DATA_DIR  # models will be saved alongside this script

CROPS = ['tomato', 'potato', 'onion']

for crop in CROPS:
    csv_path = os.path.join(DATA_DIR, f"{crop}_data_correlated.csv")  # Updated to use data_correlated.csv
    print(f"\nLoading {csv_path}…")
    if not os.path.exists(csv_path):
        raise FileNotFoundError(f"CSV file {csv_path} does not exist.")
    df = pd.read_csv(csv_path)

    # Features & target
    X = df[['moisture', 'temperature', 'ph', 'ec', 'nitrogen', 'phosphorus', 'potassium']]
    y = df['disease']

    # Encode labels
    le = LabelEncoder()
    y_enc = le.fit_transform(y)

    # Split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y_enc, test_size=0.2, random_state=42, stratify=y_enc
    )

    # Train
    clf = RandomForestClassifier(n_estimators=100, random_state=42)
    clf.fit(X_train, y_train)

    # Evaluate
    acc = clf.score(X_test, y_test)
    print(f"  ▶ {crop.title()} accuracy: {acc:.2%}")

    # Save model + encoder
    model_path = os.path.join(OUTPUT_DIR, f"rf_{crop}.pkl")
    encoder_path = os.path.join(OUTPUT_DIR, f"le_{crop}.pkl")
    joblib.dump(clf, model_path)
    joblib.dump(le, encoder_path)
    print(f"  ▶ Saved model to {model_path}")
    print(f"  ▶ Saved encoder to {encoder_path}")