import 'package:dio/dio.dart';
import 'api_config.dart';
import 'interceptor/auth_interceptor.dart';
import 'interceptor/error_interceptor.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio dio;
  late final AuthInterceptor _authInterceptor;
  late final ErrorInterceptor _errorInterceptor;

  void init() {
    _authInterceptor = AuthInterceptor();
    _errorInterceptor = ErrorInterceptor();

    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      sendTimeout: ApiConfig.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      receiveDataWhenStatusError: true,
    ));

    dio.interceptors.addAll([
      _authInterceptor,
      _errorInterceptor,
    ]);
  }
}   