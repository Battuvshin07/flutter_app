# Quick Start Guide - Flutter Mongol History App

## ⚡ Fastest Way to Run This App

### Option 1: Run Without Firebase (Recommended for Quick Start)

1. **Ensure Flutter is installed**
   ```bash
   flutter --version
   ```
   If not installed, visit: https://flutter.dev/docs/get-started/install

2. **Navigate to project directory**
   ```bash
   cd flutter_app
   ```

3. **Get dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   flutter run
   ```
   
   Choose your target device when prompted (Android emulator, iOS simulator, Chrome, etc.)

**That's it!** The app will work in demo mode with simulated data.

---

## 📱 Testing on Different Platforms

### Android Emulator
```bash
# List available devices
flutter devices

# Run on Android
flutter run -d android
```

### iOS Simulator (macOS only)
```bash
# Run on iOS
flutter run -d ios
```

### Chrome (Web)
```bash
# Run on Chrome
flutter run -d chrome
```

### Physical Device
1. Enable Developer Mode on your device
2. Connect via USB
3. Run `flutter devices` to confirm it's detected
4. Run `flutter run`

---

## 🔥 Option 2: Set Up Firebase (For Full Features)

### Step 1: Create Firebase Project
1. Go to https://console.firebase.google.com/
2. Click "Add project"
3. Follow the setup wizard
4. Enable Firestore Database in your project

### Step 2: Install FlutterFire CLI
```bash
# Install FlutterFire CLI globally
dart pub global activate flutterfire_cli

# Add to PATH if needed
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

### Step 3: Configure Firebase
```bash
# From the flutter_app directory
flutterfire configure
```

Follow the prompts to:
- Select your Firebase project
- Choose platforms (iOS, Android, Web)
- This will auto-generate `firebase_options.dart` with your credentials

### Step 4: Run with Firebase
```bash
flutter pub get
flutter run
```

---

## 🛠️ Common Commands

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Run in release mode (faster)
flutter run --release

# Clean build files
flutter clean

# Check Flutter setup
flutter doctor

# Format code
flutter format .

# Analyze code
flutter analyze

# Build APK (Android)
flutter build apk

# Build iOS
flutter build ios

# Build for web
flutter build web
```

---

## 📂 Project File Structure

```
flutter_app/
│
├── lib/
│   ├── main.dart                    # App entry point & home screen
│   ├── firebase_options.dart        # Firebase config (auto-generated)
│   │
│   ├── components/
│   │   ├── BottomNav.dart          # Bottom navigation bar
│   │   ├── FeaturedContent.dart    # Featured stories cards
│   │   ├── HeaderCarousel.dart     # Auto-scrolling header
│   │   └── QuickActions.dart       # Quick action buttons
│   │
│   └── services/
│       └── ai_service.dart         # Historical insights service
│
├── pubspec.yaml                     # Dependencies
├── analysis_options.yaml            # Linting rules
└── README.md                        # Documentation
```

---

## 🎨 Customization Tips

### Change App Colors
In `lib/components/HeaderCarousel.dart`, modify the color values:
```dart
final List<Map<String, String>> _slides = [
  {
    'title': 'Your Title',
    'subtitle': 'Your Subtitle',
    'color': '0xFF2196F3',  // Change this hex color
  },
];
```

### Add More Quick Actions
In `lib/components/QuickActions.dart`, add more `_buildActionCard()` widgets

### Modify Historical Insights
In `lib/services/ai_service.dart`, edit the `insights` array

---

## ❓ Troubleshooting

### "Flutter command not found"
- Add Flutter to your PATH
- Restart terminal/IDE
- Run `flutter doctor` to verify installation

### Dependencies not installing
```bash
flutter clean
rm -rf pubspec.lock
flutter pub get
```

### Firebase errors
- The app works without Firebase in demo mode
- If you want Firebase, run `flutterfire configure`
- Make sure you're logged into Firebase CLI: `firebase login`

### Build errors on iOS
```bash
cd ios
pod install
cd ..
flutter run
```

### Hot reload not working
- Press 'R' in terminal to manually hot reload
- Press 'r' for hot restart

---

## 🚀 Next Steps

1. **Customize the app**: Change colors, text, and images
2. **Add Firebase data**: Create a Firestore collection for real historical data
3. **Add navigation**: Implement full screen navigation for each section
4. **Add authentication**: Use Firebase Auth for user accounts
5. **Deploy**: Build and publish to App Store / Play Store

---

## 📚 Helpful Resources

- **Flutter Documentation**: https://docs.flutter.dev/
- **Firebase for Flutter**: https://firebase.google.com/docs/flutter/setup
- **Lucide Icons**: https://lucide.dev/
- **Google Fonts**: https://fonts.google.com/

---

## 💡 Tips for Development

- Use **Hot Reload** (press 'r' in terminal) to see changes instantly
- Use **DevTools** for debugging: `flutter run` then press 'w' to open DevTools
- Check logs with `flutter logs`
- Use VS Code Flutter extension for better development experience

---

Need help? Check the README.md or Flutter documentation!
