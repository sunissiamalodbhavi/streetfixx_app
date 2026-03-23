class ApiConfig {
  // Toggle this to switch between development and production
  static const bool isProduction = false;

  // Development backend
  static const String devBaseUrl = "http://192.168.0.163:5000";

  // Production backend (Render deployment)
  static const String prodBaseUrl = "https://campuscare-api.onrender.com";

  // Dynamic Base URL based on environment
  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;

  // Reduced timeout setting for quicker failure discovery
  static const int timeoutSeconds = 10;
}
