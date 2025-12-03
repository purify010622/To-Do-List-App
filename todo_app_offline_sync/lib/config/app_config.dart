/// Application configuration
/// 
/// This file contains environment-specific configuration for the app.
/// Update the production URL after deploying the backend.
class AppConfig {
  /// Environment type
  static const Environment environment = Environment.production;

  /// API base URL based on environment
  static String get apiBaseUrl {
    switch (environment) {
      case Environment.development:
        return 'http://192.168.1.x:3000/api'; // Replace x with your computer's IP
      case Environment.production:
        return 'https://codsoft-dad2.onrender.com'; // TODO: Update with your deployed URL
    }
  }

  /// Whether to enable debug logging
  static bool get enableDebugLogging {
    return environment == Environment.development;
  }

  /// API timeout duration
  static const Duration apiTimeout = Duration(seconds: 30);

  /// Sync retry attempts
  static const int syncRetryAttempts = 3;

  /// Sync retry delay
  static const Duration syncRetryDelay = Duration(seconds: 5);
}

/// Environment types
enum Environment {
  development,
  production,
}
