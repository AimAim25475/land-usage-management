Land Resource Management
A cross-platform Flutter application for managing land resources efficiently.
This app provides user authentication, profile management, and integrates with Firebase for backend services.
It features a modern UI and supports Android, Windows, and Web platforms.

Features
User registration and login (Firebase Auth)
Profile management
Google Maps integration
Image picking and processing
Land resource management tools
Clean, responsive UI
How to Run This Project
Prerequisites
Flutter SDK (version 3.7.2 or higher)
Android Studio (for Android emulator and SDK)
VS Code or Android Studio (with Flutter & Dart plugins)
Enable Developer Mode on Windows (for symlink support)
Setup Steps
Clone the repository:

Enable Developer Mode (Windows only):

Run in terminal:
Turn on Developer Mode in the settings window.
Install dependencies:

Set up Firebase:

The project uses Firebase. Make sure your lib/firebase_options.dart is configured for your Firebase project.
If you use your own Firebase, generate a new firebase_options.dart using the FlutterFire CLI.
Run the app:

For Android:
For Web:
For Windows:
Troubleshooting:

If you see errors about missing SDKs or licenses, run:
Follow any prompts to resolve issues.
