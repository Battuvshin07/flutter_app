import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { mn, en }

class LanguageProvider with ChangeNotifier {
  AppLanguage _language = AppLanguage.mn;
  static const String _languageKey = 'app_language';

  AppLanguage get language => _language;
  bool get isMongolian => _language == AppLanguage.mn;
  bool get isEnglish => _language == AppLanguage.en;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(_languageKey) ?? 'mn';
    _language = langCode == 'en' ? AppLanguage.en : AppLanguage.mn;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, lang == AppLanguage.en ? 'en' : 'mn');
  }

  Future<void> toggleLanguage() async {
    await setLanguage(
        _language == AppLanguage.mn ? AppLanguage.en : AppLanguage.mn);
  }

  /// Get translated string by key
  String tr(String key) {
    return _translations[key]?[_language] ?? key;
  }
}

/// Translation map: key -> {mn: Mongolian, en: English}
const Map<String, Map<AppLanguage, String>> _translations = {
  // Bottom Navigation
  'nav_home': {AppLanguage.mn: 'Нүүр', AppLanguage.en: 'Home'},
  'nav_people': {AppLanguage.mn: 'Хүмүүс', AppLanguage.en: 'People'},
  'nav_learn': {AppLanguage.mn: 'Судлах', AppLanguage.en: 'Learn'},
  'nav_map': {AppLanguage.mn: 'Зураг', AppLanguage.en: 'Map'},
  'nav_profile': {AppLanguage.mn: 'Профайл', AppLanguage.en: 'Profile'},

  // Profile Screen
  'profile': {AppLanguage.mn: 'Профайл', AppLanguage.en: 'Profile'},
  'edit_profile': {
    AppLanguage.mn: 'Профайл засах',
    AppLanguage.en: 'Edit Profile'
  },
  'settings': {AppLanguage.mn: 'Тохиргоо', AppLanguage.en: 'Settings'},
  'language': {AppLanguage.mn: 'Хэл', AppLanguage.en: 'Language'},
  'change_password': {
    AppLanguage.mn: 'Нууц үг солих',
    AppLanguage.en: 'Change Password'
  },
  'support': {AppLanguage.mn: 'Дэмжлэг', AppLanguage.en: 'Support'},
  'help': {AppLanguage.mn: 'Тусламж', AppLanguage.en: 'Help'},
  'terms_of_service': {
    AppLanguage.mn: 'Үйлчилгээний нөхцөл',
    AppLanguage.en: 'Terms of Service'
  },
  'privacy_policy': {
    AppLanguage.mn: 'Нууцлалын бодлого',
    AppLanguage.en: 'Privacy Policy'
  },
  'about_app': {
    AppLanguage.mn: 'Аппликейшний тухай',
    AppLanguage.en: 'About App'
  },
  'version': {AppLanguage.mn: 'Хувилбар', AppLanguage.en: 'Version'},
  'logout': {AppLanguage.mn: 'Гарах', AppLanguage.en: 'Logout'},
  'admin_dashboard': {
    AppLanguage.mn: 'Админ самбар',
    AppLanguage.en: 'Admin Dashboard'
  },
  'admin_access': {AppLanguage.mn: 'Админ эрх', AppLanguage.en: 'Admin Access'},

  // Home Screen
  'start_exploring': {
    AppLanguage.mn: 'Судлаж эхлэх',
    AppLanguage.en: 'Start Exploring'
  },
  'daily_fact': {
    AppLanguage.mn: 'Өнөөдрийн баримт',
    AppLanguage.en: 'Daily Fact'
  },
  'featured': {AppLanguage.mn: 'Онцлох', AppLanguage.en: 'Featured'},
  'see_all': {AppLanguage.mn: 'Бүгдийг харах', AppLanguage.en: 'See All'},

  // Common
  'loading': {AppLanguage.mn: 'Ачаалж байна...', AppLanguage.en: 'Loading...'},
  'error': {AppLanguage.mn: 'Алдаа', AppLanguage.en: 'Error'},
  'retry': {AppLanguage.mn: 'Дахин оролдох', AppLanguage.en: 'Retry'},
  'cancel': {AppLanguage.mn: 'Цуцлах', AppLanguage.en: 'Cancel'},
  'save': {AppLanguage.mn: 'Хадгалах', AppLanguage.en: 'Save'},
  'delete': {AppLanguage.mn: 'Устгах', AppLanguage.en: 'Delete'},
  'confirm': {AppLanguage.mn: 'Баталгаажуулах', AppLanguage.en: 'Confirm'},
  'search': {AppLanguage.mn: 'Хайх', AppLanguage.en: 'Search'},
  'back': {AppLanguage.mn: 'Буцах', AppLanguage.en: 'Back'},

  // Journey/Learning
  'journey': {AppLanguage.mn: 'Аялал', AppLanguage.en: 'Journey'},
  'continue_journey': {
    AppLanguage.mn: 'Үргэлжлүүлэх',
    AppLanguage.en: 'Continue'
  },
  'start_journey': {AppLanguage.mn: 'Эхлэх', AppLanguage.en: 'Start'},
  'completed': {AppLanguage.mn: 'Дууссан', AppLanguage.en: 'Completed'},
  'in_progress': {
    AppLanguage.mn: 'Явагдаж байна',
    AppLanguage.en: 'In Progress'
  },
  'locked': {AppLanguage.mn: 'Түгжээтэй', AppLanguage.en: 'Locked'},

  // Quiz
  'quiz': {AppLanguage.mn: 'Тест', AppLanguage.en: 'Quiz'},
  'correct': {AppLanguage.mn: 'Зөв', AppLanguage.en: 'Correct'},
  'incorrect': {AppLanguage.mn: 'Буруу', AppLanguage.en: 'Incorrect'},
  'score': {AppLanguage.mn: 'Оноо', AppLanguage.en: 'Score'},
  'next': {AppLanguage.mn: 'Дараах', AppLanguage.en: 'Next'},
  'finish': {AppLanguage.mn: 'Дуусгах', AppLanguage.en: 'Finish'},

  // Map
  'map_title': {AppLanguage.mn: 'Газрын зураг', AppLanguage.en: 'Map'},

  // Culture
  'culture': {AppLanguage.mn: 'Соёл', AppLanguage.en: 'Culture'},
  'history': {AppLanguage.mn: 'Түүх', AppLanguage.en: 'History'},
  'traditions': {AppLanguage.mn: 'Уламжлал', AppLanguage.en: 'Traditions'},

  // Persons
  'persons_title': {
    AppLanguage.mn: 'Түүхэн хүмүүс',
    AppLanguage.en: 'Historical Figures'
  },
  'biography': {AppLanguage.mn: 'Намтар', AppLanguage.en: 'Biography'},
  'achievements': {AppLanguage.mn: 'Амжилтууд', AppLanguage.en: 'Achievements'},
  'timeline': {AppLanguage.mn: 'Он дараалал', AppLanguage.en: 'Timeline'},

  // Stats
  'total_xp': {AppLanguage.mn: 'Нийт XP', AppLanguage.en: 'Total XP'},
  'lessons_completed': {
    AppLanguage.mn: 'Дууссан хичээлүүд',
    AppLanguage.en: 'Lessons Completed'
  },
  'quizzes_passed': {
    AppLanguage.mn: 'Тэнцсэн тестүүд',
    AppLanguage.en: 'Quizzes Passed'
  },
  'streak_days': {
    AppLanguage.mn: 'Тасралтгүй өдрүүд',
    AppLanguage.en: 'Day Streak'
  },
};
