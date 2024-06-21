from firebase_functions import https_fn
from firebase_admin import initialize_app
from flask_cors import CORS
from flask import Flask, request, jsonify

initialize_app()

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})  # Allow all origins for testing

@app.route('/fetch_emails', methods=['POST'])
def fetch_emails():
    print("Request received")
    sample_emails = [
        {"snippet": "Email 1 snippet"},
        {"snippet": "Email 2 snippet"},
        {"snippet": "Email 3 snippet"}
    ]
    return jsonify(sample_emails), 200

if __name__ == "__main__":
    app.run(debug=True)