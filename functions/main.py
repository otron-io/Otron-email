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
import os
from typing import IO
from io import BytesIO
from elevenlabs import VoiceSettings
from elevenlabs.client import ElevenLabs

initialize_app()

ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY")
client = ElevenLabs(
    api_key=ELEVENLABS_API_KEY,
)

def text_to_speech_stream(text: str) -> IO[bytes]:
    # Perform the text-to-speech conversion
    response = client.text_to_speech.convert(
        voice_id="pNInz6obpgDQGcFmaJgB", # Adam pre-made voice
        optimize_streaming_latency="0",
        output_format="mp3_22050_32",
        text=text,
        model_id="eleven_multilingual_v2",
        voice_settings=VoiceSettings(
            stability=0.0,
            similarity_boost=1.0,
            style=0.0,
            use_speaker_boost=True,
        ),
    )

    # Create a BytesIO object to hold the audio data in memory
    audio_stream = BytesIO()

    # Write each chunk of audio data to the stream
    for chunk in response:
        if chunk:
            audio_stream.write(chunk)

    # Reset stream position to the beginning
    audio_stream.seek(0)

    # Return the stream for further use
    return audio_stream

@https_fn.on_request(
    cors=options.CorsOptions(
        cors_origins="*",  # Allow all origins
        cors_methods=["GET", "POST", "OPTIONS"]  # Allow GET, POST, and OPTIONS methods
    )
)
def TTS(request: Request) -> Response:
    if request.method == 'OPTIONS':
        # Handle preflight request
        response = Response(json.dumps({'message': 'CORS preflight'}), status=200)
        response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
        return response

    if request.method == 'POST':
        try:
            data = request.get_json()
            text = data.get('text', '')
            if not text:
                return Response(json.dumps({'error': 'Text is required'}), status=400)

            audio_stream = text_to_speech_stream(text)
            return Response(audio_stream.read(), status=200, mimetype='audio/mpeg')
        except Exception as e:
            return Response(json.dumps({'error': str(e)}), status=500)

    return Response("Method not allowed", status=405)

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
