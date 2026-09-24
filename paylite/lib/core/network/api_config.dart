
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://paylite-322q.onrender.com',
  );
  static const Duration timeout = Duration(seconds: 15);
}