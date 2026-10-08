import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../services/local_storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ApiClient {
  final LocalStorageService _storage;
  final http.Client _httpClient;
  String baseUrl;
  void Function()? onUnauthorized;

  ApiClient(this._storage, {String? baseUrl, this.onUnauthorized, http.Client? httpClient})
      : baseUrl = baseUrl ?? ApiConstants.defaultBaseUrl,
        _httpClient = httpClient ?? http.Client();

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    final token = _storage.getAuthToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _buildUri(String targetBaseUrl, String endpoint, [Map<String, dynamic>? queryParams]) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final base = Uri.parse(targetBaseUrl);
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: cleanEndpoint,
      queryParameters: queryParams?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  /// Executes request with automatic fallback (e.g. LAN IP -> USB localhost)
  Future<dynamic> _executeWithFallback(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
  }) async {
    final candidates = <String>[baseUrl];
    if (kDebugMode && !baseUrl.startsWith('https://')) {
      if (!candidates.contains('http://127.0.0.1:8080')) {
        candidates.add('http://127.0.0.1:8080');
      }
      if (!candidates.contains('http://localhost:8080')) {
        candidates.add('http://localhost:8080');
      }
    }

    final headers = _buildHeaders();
    final bodyString = body != null ? jsonEncode(body) : null;

    for (int i = 0; i < candidates.length; i++) {
      final currentBase = candidates[i];
      try {
        final uri = _buildUri(currentBase, endpoint, queryParams);
        http.Response response;
        switch (method.toUpperCase()) {
          case 'GET':
            response = await _httpClient.get(uri, headers: headers).timeout(const Duration(seconds: 25));
            break;
          case 'POST':
            response = await _httpClient.post(uri, headers: headers, body: bodyString).timeout(const Duration(seconds: 25));
            break;
          case 'PUT':
            response = await _httpClient.put(uri, headers: headers, body: bodyString).timeout(const Duration(seconds: 25));
            break;
          case 'DELETE':
            response = await _httpClient.delete(uri, headers: headers).timeout(const Duration(seconds: 25));
            break;
          default:
            throw ApiException('Noma\'lum HTTP metod: $method');
        }

        final result = _processResponse(response);
        if (currentBase != baseUrl) {
          baseUrl = currentBase;
        }
        return result;
      } on TimeoutException {
        if (i < candidates.length - 1) {
          continue;
        }
        throw ApiException('Server javob berish vaqti tugadi.');
      } catch (e) {
        if (i < candidates.length - 1) {
          continue;
        }
        if (e is ApiException) rethrow;
        throw ApiException('Server bilan aloqa o\'rnatib bo\'lmadi. ($e)');
      }
    }

    throw ApiException('Server bilan aloqa o\'rnatib bo\'lmadi. Backend ishlayotganligini tekshiring.');
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    return _executeWithFallback('GET', endpoint, queryParams: queryParams);
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    return _executeWithFallback('POST', endpoint, body: body);
  }

  Future<dynamic> put(String endpoint, {dynamic body}) async {
    return _executeWithFallback('PUT', endpoint, body: body);
  }

  Future<dynamic> delete(String endpoint) async {
    return _executeWithFallback('DELETE', endpoint);
  }

  dynamic _processResponse(http.Response response) {
    final responseBody = response.body;
    dynamic decoded;
    if (responseBody.isNotEmpty) {
      try {
        decoded = jsonDecode(responseBody);
      } catch (_) {
        decoded = responseBody;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    // 401 Unauthorized Session Handling
    if (response.statusCode == 401) {
      if (onUnauthorized != null) {
        Future.microtask(() {
          onUnauthorized?.call();
        });
      }
      throw ApiException('Seans muddati tugadi. Iltimos, qayta kiring.', 401);
    }

    if (response.statusCode == 403) {
      throw ApiException('Sizda bu amalni bajarish uchun ruxsat yo\'q.', 403);
    }

    if (response.statusCode == 404) {
      throw ApiException('So\'ralgan ma\'lumot topilmadi.', 404);
    }

    if (response.statusCode == 409) {
      String msg = 'Ma\'lumot allaqachon mavjud yoki to\'qnashuv yuz berdi.';
      if (decoded is Map && decoded.containsKey('error')) {
        msg = decoded['error'].toString();
      }
      throw ApiException(msg, 409);
    }

    if (response.statusCode >= 500) {
      throw ApiException('Serverda vaqtinchalik muammo yuz berdi. Iltimos, keyinroq urinib ko\'ring.', response.statusCode);
    }

    String errorMsg = 'Xatolik yuz berdi (${response.statusCode})';
    if (decoded is Map && decoded.containsKey('error')) {
      errorMsg = decoded['error'].toString();
    }
    throw ApiException(errorMsg, response.statusCode);
  }
}
