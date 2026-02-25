# Flutter Mongol History App

A beautiful Flutter application for learning about Mongol Empire history with Firebase integration.

## Features

- 🎨 Modern, clean UI with custom components
- 🔥 Firebase integration for data storage
- 📱 Responsive design
- 🎯 Quick action buttons
- 📚 Featured historical content
- 💡 AI-powered historical insights
- 🎨 Beautiful carousel header

## Project Structure

```
lib/
├── main.dart                 # Main app entry point
├── firebase_options.dart     # Firebase configuration
├── components/
│   ├── HeaderCarousel.dart   # Auto-scrolling header carousel
│   ├── QuickActions.dart     # Quick action buttons
│   ├── FeaturedContent.dart  # Featured stories list
│   └── BottomNav.dart        # Bottom navigation bar
└── services/
    └── ai_service.dart       # Historical insights service
```

## Setup Instructions

### 1. Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Firebase account (optional, for full functionality)

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup (Optional)

If you want to use Firebase features:

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Configure Firebase for your project:
   ```bash
   flutterfire configure
   ```

3. This will automatically update `firebase_options.dart` with your Firebase project settings.

**Note:** The app will work without Firebase configuration, but Firebase-dependent features will be simulated with local data.

### 4. Run the App

```bash
flutter run
```

Or select a device in your IDE and press Run.

## Dependencies

- **firebase_core**: Firebase SDK core functionality
- **cloud_firestore**: Cloud Firestore database
- **provider**: State management
- **google_fonts**: Custom fonts (Inter)
- **lucide_flutter**: Beautiful icon set

## Customization

### Change App Theme
Edit the `ThemeData` in `lib/main.dart`:

```dart
theme: ThemeData(
  textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
  scaffoldBackgroundColor: Colors.white,
  // Add your custom theme properties
),
```

### Add More Historical Insights
Edit the insights array in `lib/services/ai_service.dart`:

```dart
final insights = [
  "Your historical fact here",
  // Add more insights
];
```

### Modify Carousel Slides
Edit the `_slides` list in `lib/components/HeaderCarousel.dart`

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Troubleshooting

### Firebase Issues
- Make sure you've run `flutterfire configure`
- Check that your `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) files are in the correct directories
- The app will work in demo mode without Firebase

### Dependency Issues
```bash
flutter clean
flutter pub get
```

### Build Issues
```bash
flutter doctor
```

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is open source and available under the MIT License.
