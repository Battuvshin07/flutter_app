# 🚀 Quick Reference - Flutter Commands

## Essential Commands (Copy & Paste)

```bash
# 1. Navigate to project
cd flutter_app

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run

# 4. (Optional) Configure Firebase
flutterfire configure
```

## File Overview

| File | Purpose |
|------|---------|
| `lib/main.dart` | Main app, home screen, top bar, insight card |
| `lib/components/HeaderCarousel.dart` | Auto-scrolling banner at top |
| `lib/components/QuickActions.dart` | Four action buttons (Learn, Explore, etc.) |
| `lib/components/FeaturedContent.dart` | Story cards list |
| `lib/components/BottomNav.dart` | Bottom navigation bar |
| `lib/services/ai_service.dart` | Historical insights data service |
| `lib/firebase_options.dart` | Firebase configuration |
| `pubspec.yaml` | Dependencies and project config |

## Key Features

✅ **Works immediately** - No Firebase required for testing  
✅ **Auto-scrolling carousel** - Beautiful header animation  
✅ **Historical insights** - Rotating facts about Mongol Empire  
✅ **Responsive design** - Adapts to different screen sizes  
✅ **Modern UI** - Clean, professional interface  

## What Each Component Does

### HeaderCarousel
- Auto-scrolls every 4 seconds
- 3 slides with gradients
- Shows page indicators

### QuickActions  
- 4 quick action cards
- Icons: Book, Map, Trophy, Users
- Tap handlers ready for navigation

### FeaturedContent
- 3 featured story cards
- Icons and descriptions
- Ready for detail pages

### BottomNav
- 4 navigation items
- Active state highlighting
- Icons: Home, Compass, Book, User

### HistoryInsightCard
- Orange themed card
- Loads random historical fact
- 2-second loading animation

## Dependencies Used

- `firebase_core` & `cloud_firestore` - Backend (optional)
- `provider` - State management
- `google_fonts` - Inter font family
- `lucide_flutter` - Icon library

## Next Steps

1. ✅ Run `flutter pub get`
2. ✅ Run `flutter run`
3. 📱 Test on your device/emulator
4. 🎨 Customize colors and content
5. 🔥 Add Firebase (optional)

---

**Need detailed instructions?** See `SETUP_GUIDE.md`  
**Full documentation?** See `README.md`
