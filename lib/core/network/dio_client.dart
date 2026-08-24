import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/api.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;
  final _storage = const FlutterSecureStorage();

  DioClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: Api.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      followRedirects: true,
      maxRedirects: 3,
      validateStatus: (s) => s != null && s < 500,
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      dio.post(path, data: data);

  // Sends application/x-www-form-urlencoded — required for /pay/* confirm endpoints
  Future<Response> postForm(String path, Map<String, String> fields) =>
      dio.post(path,
        data: fields,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          followRedirects: true,
        ),
      );
}
