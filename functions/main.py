from firebase_functions import https_fn, options
from firebase_admin import initialize_app
from firebase_functions.https_fn import Request, Response
import json

initialize_app()

@https_fn.on_request(
    cors=options.CorsOptions(
        cors_origins="*",  # Allow all origins
        cors_methods=["GET", "POST", "OPTIONS"]  # Allow GET, POST, and OPTIONS methods
    )
)
def fetch_emails(request: Request) -> Response:
    if request.method == 'OPTIONS':
        # Handle preflight request
        response = Response(json.dumps({'message': 'CORS preflight'}), status=200)
        response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
        return response

    print("Request received")
    print(f"Request headers: {request.headers}")
    print(f"Request body: {request.get_json()}")

    sample_emails = [
        {"snippet": "Email 1 snippet"},
        {"snippet": "Email 2 snippet"},
        {"snippet": "Email 3 snippet"}
    ]
    response = Response(json.dumps(sample_emails), status=200)
    return response

# Export the function
fetch_emails_fn = fetch_emails