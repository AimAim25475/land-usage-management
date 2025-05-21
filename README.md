## Land Resource Management
A cross-platform application for analyzing land usage from satellite imagery.
Users can select areas on a map and receive land use segmentation powered by a deep learning model trained on the Land Cover dataset.

## Features
Interactive Map: Select regions on satellite imagery.
Land Use Segmentation: Deep learning model classifies land into:
Background (Unlabelled)
Buildings
Trees and Greens
Water
Modern UI: Built with Flutter for Android, Windows, and Web.
On-device Inference: Uses TensorFlow Lite for fast, private predictions.
Firebase Integration: User authentication and data management.
Python Tools: For model development and batch inference.



## How to Run This Project

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.7.2 or higher)
- [Android Studio](https://developer.android.com/studio) (for Android emulator and SDK)
- [VS Code](https://code.visualstudio.com/) or Android Studio (with Flutter & Dart plugins)
- Enable **Developer Mode** on Windows (for symlink support)

### Setup Steps

1. **Clone the repository:**
   ```
   git clone https://github.com/your-username/your-repo.git
   cd your-repo
   ```

2. **Enable Developer Mode (Windows only):**
   - Run in terminal:  
     ```
     start ms-settings:developers
     ```
   - Turn on **Developer Mode** in the settings window.

3. **Install dependencies:**
   ```
   flutter pub get
   ```

4. **Set up Firebase:**
   - The project uses Firebase. Make sure your `lib/firebase_options.dart` is configured for your Firebase project.
   - If you use your own Firebase, generate a new `firebase_options.dart` using the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/).

5. **Run the app:**
   - For Android:
     ```
     flutter run
     ```
   - For Web:
     ```
     flutter run -d chrome
     ```
   - For Windows:
     ```
     flutter run -d windows
     ```

6. **Troubleshooting:**
   - If you see errors about missing SDKs or licenses, run:
     ```
     flutter doctor
     flutter doctor --android-licenses
     ```
   - Follow any prompts to resolve issues.

---

## License

MIT (or your chosen license)


