import 'package:flutter/foundation.dart';

/// Central place for backend URLs, endpoints and network settings.
///
/// Base URL resolution order:
///   1. `--dart-define=API_BASE_URL=...`  (CI / staging / custom override)
///   2. Release build  -> [_productionUrl]
///   3. Debug/profile  -> URL based on the device platform
class ApiConstants {
  ApiConstants._();

  // ---- URLs ----------------------------------------------------------------

  /// Your deployed backend (used in release builds).
  static const String _productionUrl = 'http://localhost:3000/api';

  /// Dev server port on your computer.
  static const int _devPort = 3000;

  /// Android emulator reaches your computer through 10.0.2.2.
  static const String _androidEmulatorUrl = 'http://10.0.2.2:$_devPort/api';

  /// iOS simulator, web, and desktop share the host machine's localhost.
  static const String _localhostUrl = 'http://localhost:$_devPort/api';

  /// Optional override: flutter run --dart-define=API_BASE_URL=http://192.168.1.50:3000
  static const String _envOverride = String.fromEnvironment('API_BASE_URL');

  /// The base URL to use right now, chosen by build mode and device platform.
  static String get baseUrl {
    if (_envOverride.isNotEmpty) return _envOverride;
    if (kReleaseMode) return _productionUrl;
    return _devUrlForPlatform;
  }

  static String get _devUrlForPlatform {
    if (kIsWeb) return _localhostUrl;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidEmulatorUrl;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return _localhostUrl;
    }
  }

  // ---- Endpoints -----------------------------------------------------------
  static const String posts = '/posts';

  // ---- Timeouts ------------------------------------------------------------
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
