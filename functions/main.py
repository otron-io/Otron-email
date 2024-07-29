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

4. **proxy_image**:
    - **Purpose**: Proxies images from external URLs to bypass CORS restrictions.
    - **CORS Configuration**: Allows all origins and supports GET and OPTIONS methods.
    - **Steps**:
        - Handles preflight OPTIONS requests for CORS.
        - For GET requests, fetches the image from the provided URL and returns the image content in the response.
    - **Error Handling**: Catches and returns errors related to image fetching and general exceptions.

5. **proxy_rss_feed**:
    - **Purpose**: Proxies RSS feeds from external URLs to bypass CORS restrictions.
    - **CORS Configuration**: Allows all origins and supports GET and OPTIONS methods.
    - **Steps**:
        - Handles preflight OPTIONS requests for CORS.
        - For GET requests, fetches the RSS feed from the provided URL and returns the RSS feed content in the response.
    - **Error Handling**: Catches and returns errors related to RSS feed fetching and general exceptions.
"""

# --IMPORTS--
from firebase_functions import https_fn, options
from firebase_admin import initialize_app, storage
from firebase_functions.https_fn import Request, Response
import json
import os
from typing import IO
from io import BytesIO
from elevenlabs import VoiceSettings
from elevenlabs.client import ElevenLabs
import requests
import xml.etree.ElementTree as ET
from datetime import datetime
import sys
import xml.dom.minidom as minidom
import traceback
import re

initialize_app()

ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY")
client = ElevenLabs(
    api_key=ELEVENLABS_API_KEY,
)

def text_to_speech_stream(text: str) -> IO[bytes]:
    # Perform the text-to-speech conversion
    response = client.text_to_speech.convert(
        voice_id="onwK4e9ZLuTAKqWW03F9", # Daniel
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
            def generate():
                while True:
                    chunk = audio_stream.read(1024)
                    if not chunk:
                        break
                    yield chunk

            return Response(generate(), status=200, mimetype='audio/mpeg', direct_passthrough=True)
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

@https_fn.on_request(
    cors=options.CorsOptions(
        cors_origins="*",
        cors_methods=["GET", "OPTIONS"]
    )
)
def proxy_image(request: Request) -> Response:
    if request.method == 'OPTIONS':
        # Handle preflight request
        response = Response(json.dumps({'message': 'CORS preflight'}), status=200)
        response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
        return response

    if request.method == 'GET':
        try:
            image_url = request.args.get('url')
            if not image_url:
                return Response(json.dumps({'error': 'Image URL is required'}), status=400)

            print(f"Attempting to fetch image from: {image_url}")  # Log the URL

            # Fetch the image
            image_response = requests.get(image_url, stream=True)
            if image_response.status_code != 200:
                error_message = f"Failed to fetch image. Status code: {image_response.status_code}"
                print(error_message)  # Log the error
                return Response(json.dumps({'error': error_message}), status=image_response.status_code)

            # Get the content type
            content_type = image_response.headers.get('Content-Type', 'image/jpeg')
            print(f"Content-Type: {content_type}")  # Log the content type

            # Create a response with the image content
            response = Response(image_response.content, status=200)
            response.headers['Content-Type'] = content_type
            print(f"Successfully proxied image. Size: {len(image_response.content)} bytes")  # Log success
            return response

        except Exception as e:
            error_message = f"Error proxying image: {str(e)}"
            print(error_message)  # Log the error
            return Response(json.dumps({'error': error_message}), status=500)

    return Response("Method not allowed", status=405)

@https_fn.on_request()
def proxy_rss_feed(request: Request) -> Response:
    # Set CORS headers for the preflight request
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)

    # Set CORS headers for the main request
    headers = {
        'Access-Control-Allow-Origin': '*'
    }

    if request.method == 'GET':
        try:
            rss_url = request.args.get('url')
            if not rss_url:
                return Response(json.dumps({'error': 'RSS feed URL is required'}), status=400)

            print(f"Attempting to fetch RSS feed from: {rss_url}")  # Log the URL

            # Fetch the RSS feed
            rss_response = requests.get(rss_url)
            if rss_response.status_code != 200:
                error_message = f"Failed to fetch RSS feed. Status code: {rss_response.status_code}"
                print(error_message)  # Log the error
                return Response(json.dumps({'error': error_message}), status=rss_response.status_code)

            # Create a response with the RSS feed content
            response = Response(rss_response.content, status=200)
            response.headers['Content-Type'] = 'application/xml'
            response.headers.update(headers)  # Add CORS headers
            print(f"Successfully proxied RSS feed. Size: {len(rss_response.content)} bytes")  # Log success
            return response

        except Exception as e:
            error_message = f"Error proxying RSS feed: {str(e)}"
            print(error_message)  # Log the error
            return Response(json.dumps({'error': error_message}), status=500, headers=headers)

    return Response("Method not allowed", status=405, headers=headers)

def fix_xml_namespaces(xml_content):
    # Add iTunes namespace if it's missing
    if 'xmlns:itunes' not in xml_content:
        xml_content = xml_content.replace('<rss ', '<rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" ')
    
    # Replace any 'ns0:' prefixes with 'itunes:'
    xml_content = re.sub(r'ns0:', 'itunes:', xml_content)
    
    return xml_content

@https_fn.on_request()
def update_rss_feed(request: Request) -> Response:
    # Set CORS headers for the preflight request
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)

    # Set CORS headers for the main request
    headers = {
        'Access-Control-Allow-Origin': '*'
    }

    if request.method == 'POST':
        try:
            data = request.get_json()
            feed_name = data.get('fileName')
            new_item = data.get('newItem')

            if not feed_name or not new_item:
                return Response(json.dumps({'error': 'Feed name and new item are required'}), status=400, headers=headers)

            # Get the current RSS feed XML
            bucket = storage.bucket()
            blob = bucket.blob(f'rss_feeds/{feed_name}')
            xml_content = blob.download_as_string().decode('utf-8')

            # Fix potential namespace issues
            xml_content = fix_xml_namespaces(xml_content)

            try:
                # Parse the XML
                dom = minidom.parseString(xml_content)
            except xml.parsers.expat.ExpatError as e:
                return Response(json.dumps({'error': f'XML parsing error: {str(e)}', 'xml_content': xml_content}), status=400, headers=headers)

            channel = dom.getElementsByTagName('channel')[0]

            # Create a new item element
            new_item_elem = dom.createElement('item')
            
            # Add sub-elements to the new item
            elements_to_add = [
                ('title', new_item['title']),
                ('itunes:author', new_item['author']),
                ('itunes:subtitle', new_item['subtitle']),
                ('itunes:summary', new_item.get('summary', new_item.get('description', ''))),
                ('description', new_item.get('description', new_item.get('summary', ''))),
                ('pubDate', new_item['pubDate']),
                ('itunes:duration', new_item['duration']),
            ]

            for tag, text in elements_to_add:
                elem = dom.createElement(tag)
                elem.appendChild(dom.createTextNode(text))
                new_item_elem.appendChild(elem)

            # Add enclosure
            enclosure = dom.createElement('enclosure')
            enclosure.setAttribute('url', new_item['audioUrl'])
            enclosure.setAttribute('type', 'audio/mpeg')
            enclosure.setAttribute('length', '0')
            new_item_elem.appendChild(enclosure)

            # Add guid
            guid = dom.createElement('guid')
            guid.appendChild(dom.createTextNode(new_item['audioUrl']))
            new_item_elem.appendChild(guid)

            # Add image if provided
            if 'imageUrl' in new_item and new_item['imageUrl']:
                image_elem = dom.createElement('itunes:image')
                image_elem.setAttribute('href', new_item['imageUrl'])
                new_item_elem.appendChild(image_elem)

            # Insert the new item at the beginning of the channel
            if channel.firstChild:
                channel.insertBefore(new_item_elem, channel.firstChild)
            else:
                channel.appendChild(new_item_elem)

            # Convert the updated XML to a string
            updated_xml = dom.toxml()

            # Upload the updated XML back to Firebase Storage
            blob.upload_from_string(updated_xml, content_type='application/xml')

            return Response(json.dumps({'message': 'RSS feed updated successfully'}), status=200, headers=headers)

        except Exception as e:
            error_message = f"Error updating RSS feed: {str(e)}"
            print(error_message)
            print("Traceback:")
            print(traceback.format_exc())
            return Response(json.dumps({'error': error_message, 'traceback': traceback.format_exc()}), status=500, headers=headers)

    return Response("Method not allowed", status=405, headers=headers)