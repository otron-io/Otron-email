from firebase_functions import https_fn, options
from firebase_admin import initialize_app, auth
from firebase_functions.https_fn import Request, Response
import json
import google.auth.transport.requests
from google.oauth2 import id_token
from googleapiclient.discovery import build
from google.auth.exceptions import GoogleAuthError

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

    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return Response(json.dumps({'error': 'Unauthorized'}), status=401)

    id_token_str = auth_header.split('Bearer ')[1]

    try:
        # Verify the ID token
        decoded_token = auth.verify_id_token(id_token_str)
        user_id = decoded_token['uid']
        print(f"Decoded token: {decoded_token}")

        # Use the ID token to fetch emails from Gmail
        request_adapter = google.auth.transport.requests.Request()
        id_info = id_token.verify_oauth2_token(id_token_str, request_adapter)
        print(f"ID info: {id_info}")

        credentials = google.oauth2.credentials.Credentials(id_token_str)
        service = build('gmail', 'v1', credentials=credentials)
        print("Gmail service built successfully")

        results = service.users().messages().list(userId='me', maxResults=10).execute()
        print(f"Gmail API response: {results}")

        messages = results.get('messages', [])
        print(f"Messages: {messages}")

        emails = []
        for message in messages:
            msg = service.users().messages().get(userId='me', id=message['id']).execute()
            snippet = msg.get('snippet', 'No snippet')
            emails.append({'snippet': snippet})

        response = Response(json.dumps(emails), status=200)
        return response

    except GoogleAuthError as e:
        print(f"Google Auth Error: {e}")
        return Response(json.dumps({'error': f'Google Auth Error: {str(e)}'}), status=500)
    except Exception as e:
        print(f"Error verifying ID token or fetching emails: {e}")
        return Response(json.dumps({'error': f'Failed to fetch emails: {str(e)}'}), status=500)

@https_fn.on_request(
    cors=options.CorsOptions(
        cors_origins="*",  # Allow all origins
        cors_methods=["GET", "POST", "OPTIONS"]  # Allow GET, POST, and OPTIONS methods
    )
)
def classify(request: Request) -> Response:
    if request.method == 'OPTIONS':
        # Handle preflight request
        response = Response(json.dumps({'message': 'CORS preflight'}), status=200)
        response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
        return response

    if request.method == 'POST':
        try:
            data = request.get_json()
            message = data.get('message', 'No message provided')
            result = f"Classified message: {message}"
            return Response(json.dumps({'result': result}), status=200)
        except Exception as e:
            print(f"Error in classify endpoint: {e}")
            return Response(json.dumps({'error': f'Failed to classify: {str(e)}'}), status=500)
    else:
        return Response(json.dumps({'error': 'Method not allowed'}), status=405)
