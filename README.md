
# Project Setup and Development Guide

## Backend Setup
This project uses Firebase Functions for the backend. Follow these steps to set it up locally:
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login to Firebase: `firebase login`
3. Initialize Firebase in your project directory: `firebase init`
4. Start the Firebase emulator: `firebase emulators:start`

Backend code is located in the `functions/main` directory. Make sure to deploy your functions after making changes:
```
firebase deploy --only functions
```

## Frontend Setup (Flutter)
To run the Flutter project, follow these steps:
1. Install Flutter: [Flutter Installation Guide](https://flutter.dev/docs/get-started/install)
2. Clone the repository and navigate to the project directory.
3. Run `flutter pub get` to install dependencies.
4. Run the project: `flutter run`

Key files in the `lib` folder:
- `lib/services/email_service.dart`: Handles email fetching using Google Sign-In and Gmail API.
<!-- Add other important files and their descriptions here -->

## Environment Variables
Ensure you have a `.env` file in the root directory with the following variables:
```
GOOGLE_CLIENT_ID=your_google_client_id
```

## Usage
After setting up, you can start developing and testing the project locally. Make sure to follow the instructions for both backend and frontend setups.
