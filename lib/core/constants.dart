/// App-wide constants: subjects, levels, currencies, timezones, admin access.
/// All user-facing labels that need translation live in strings.dart; this
/// file holds stable identifiers and option lists.
library;

class C {
  static const appName = 'Lurniq';
  static const tagline = 'A smarter way to learn.';
  static const dataFileName = 'lurniq_data.json';
  static const sessionFileName = 'lurniq_session.json';

  /// Demo-mode admin passcode. Documented in README.md (repo-private), never
  /// shown inside the app UI. Change before any production deployment.
  static const adminPasscode = '482917';

  static const defaultCommission = 0.15;

  static const List<String> subjects = [
    'Mathematics',
    'Science',
    'English',
    'Languages',
    'History',
    'Computer Science',
    'Business',
    'Arts',
    'Other',
  ];

  static const List<String> educationLevels = [
    'Elementary',
    'Middle School',
    'High School',
    'Undergraduate',
    'Graduate',
    'Professional',
    'Hobby / Other',
  ];

  static const List<Map<String, String>> postTypes = [
    {'id': 'question', 'label': 'Question'},
    {'id': 'discussion', 'label': 'Discussion'},
    {'id': 'notes', 'label': 'Study notes'},
    {'id': 'resource', 'label': 'Resource'},
    {'id': 'studyGroup', 'label': 'Study group'},
    {'id': 'progress', 'label': 'Progress update'},
  ];

  static String postTypeLabel(String id) => postTypes
      .firstWhere((t) => t['id'] == id, orElse: () => {'label': id})['label']!;

  static const List<Map<String, String>> currencies = [
    {'code': 'USD', 'symbol': r'$', 'label': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'label': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'label': 'British Pound'},
    {'code': 'JPY', 'symbol': '¥', 'label': 'Japanese Yen'},
    {'code': 'PHP', 'symbol': '₱', 'label': 'Philippine Peso'},
    {'code': 'INR', 'symbol': '₹', 'label': 'Indian Rupee'},
    {'code': 'AUD', 'symbol': r'A$', 'label': 'Australian Dollar'},
    {'code': 'CAD', 'symbol': r'C$', 'label': 'Canadian Dollar'},
    {'code': 'SGD', 'symbol': r'S$', 'label': 'Singapore Dollar'},
    {'code': 'BRL', 'symbol': r'R$', 'label': 'Brazilian Real'},
    {'code': 'NGN', 'symbol': '₦', 'label': 'Nigerian Naira'},
    {'code': 'KES', 'symbol': 'KSh', 'label': 'Kenyan Shilling'},
  ];

  static String currencySymbol(String code) => currencies
      .firstWhere((c) => c['code'] == code,
          orElse: () => {'symbol': code})['symbol']!;

  /// Common UTC offsets with representative cities. The app also supports a
  /// "device" mode that follows the phone's own timezone.
  static const List<Map<String, Object>> timezones = [
    {'label': 'UTC−11:00 — Pago Pago', 'offset': -660},
    {'label': 'UTC−08:00 — Los Angeles, Vancouver', 'offset': -480},
    {'label': 'UTC−05:00 — New York, Toronto', 'offset': -300},
    {'label': 'UTC−03:00 — São Paulo, Buenos Aires', 'offset': -180},
    {'label': 'UTC+00:00 — London, Accra', 'offset': 0},
    {'label': 'UTC+01:00 — Paris, Lagos, Berlin', 'offset': 60},
    {'label': 'UTC+02:00 — Cairo, Johannesburg', 'offset': 120},
    {'label': 'UTC+03:00 — Nairobi, Moscow', 'offset': 180},
    {'label': 'UTC+04:00 — Dubai', 'offset': 240},
    {'label': 'UTC+05:30 — Mumbai, Delhi', 'offset': 330},
    {'label': 'UTC+07:00 — Jakarta, Bangkok', 'offset': 420},
    {'label': 'UTC+08:00 — Manila, Singapore, Perth', 'offset': 480},
    {'label': 'UTC+09:00 — Tokyo, Seoul', 'offset': 540},
    {'label': 'UTC+10:00 — Sydney', 'offset': 600},
    {'label': 'UTC+12:00 — Auckland', 'offset': 720},
  ];

  static const List<int> folderColors = [
    0xFF0F766E, // teal
    0xFFC2571D, // terracotta
    0xFFB45309, // amber dark
    0xFF4F46E5, // indigo
    0xFF0EA5E9, // sky
    0xFF16A34A, // green
    0xFFDB2777, // pink
    0xFF7C3AED, // violet
  ];

  /// Icon keys for subject folders; mapped to IconData in the UI layer.
  static const List<String> folderIcons = [
    'book',
    'flask',
    'language',
    'history',
    'code',
    'chart',
    'palette',
    'globe',
    'star',
    'folder',
  ];

  static const List<String> reportReasons = [
    'Spam or misleading',
    'Harassment or hate speech',
    'Inappropriate content',
    'Cheating / academic dishonesty request',
    'Privacy violation',
    'Other',
  ];

  static const List<String> taskPriorities = ['low', 'medium', 'high'];
  static const List<String> taskStatuses = ['todo', 'doing', 'done'];
}
