import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient(this.baseUrl);

  final String baseUrl;
  final _storage = const FlutterSecureStorage();

  Dio _dio() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
    return dio;
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> data) async {
    final res = await _dio().post(path, data: data);
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> putJson(String path, Map<String, dynamic> data) async {
    final res = await _dio().put(path, data: data);
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final res = await _dio().get(path);
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> postMultipart(String path, Map<String, dynamic> fields, File? file) async {
    final form = FormData.fromMap({
      ...fields,
      if (file != null)
        'attachment': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
    });
    final res = await _dio().post(path, data: form);
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Response> downloadFile(String filename, String savePath) async {
    return _dio().download('/files/$filename', savePath);
  }
}
