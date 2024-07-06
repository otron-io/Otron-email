"""
This script defines three HTTP endpoints using Firebase Functions. Each endpoint has specific requirements and functionalities:

1. **fetch_emails**:
    - **Purpose**: Fetches the latest 10 emails from a user's Gmail account.
    - **CORS Configuration**: Allows all origins and supports GET, POST, and OPTIONS methods.
    - **Authorization**: Requires a Bearer token in the Authorization header.
    - **Steps**:
        - Handles preflight OPTIONS requests for CORS.
        - Extracts and verifies the ID token from the Authorization header.
        - Uses the verified token to authenticate with Gmail API.
        - Fetches the latest 10 emails and returns their snippets in the response.
    - **Error Handling**: Catches and returns errors related to Google authentication and general exceptions.

2. **classify**:
    - **Purpose**: Classifies a given message.
    - **CORS Configuration**: Allows all origins and supports GET, POST, and OPTIONS methods.
    - **Steps**:
        - Handles preflight OPTIONS requests for CORS.
        - For POST requests, extracts the message from the request body and returns a classified result.
    - **Error Handling**: Catches and returns errors related to message classification and general exceptions.

3. **generate_audio**:
    - **Purpose**: Generates audio from text using the ElevenLabs API.
    - **CORS Configuration**: Allows all origins and supports GET, POST, and OPTIONS methods.
    - **Steps**:
        - Handles preflight OPTIONS requests for CORS.
        - For POST requests, extracts necessary data (voice_id, text, model_id, etc.) from the request body.
        - Sends a request to the ElevenLabs API to generate audio and returns the audio content in the response.
    - **Error Handling**: Catches and returns errors related to audio generation and general exceptions.
"""

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
def hello_world(request: Request) -> Response:
    if request.method == 'OPTIONS':
        # Handle preflight request
        response = Response(json.dumps({'message': 'CORS preflight'}), status=200)
        response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
        return response

    return Response("Hello world", status=200)
