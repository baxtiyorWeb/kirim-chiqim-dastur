import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  final HttpClient _httpClient;
  String baseUrl;
  void Function()? onUnauthorized;

  ApiClient(this._storage, {String? baseUrl, this.onUnauthorized})
      : baseUrl = baseUrl ?? ApiConstants.defaultBaseUrl,
        _httpClient = HttpClient() {
    _httpClient.connectionTimeout = const Duration(seconds: 12);
  }

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
      port: base.port,
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
    // List of candidate base URLs to attempt
    final candidates = <String>[baseUrl];
    if (kDebugMode && !baseUrl.startsWith('https://')) {
      if (!candidates.contains('http://127.0.0.1:8080')) {
        candidates.add('http://127.0.0.1:8080');
      }
      if (!candidates.contains('http://localhost:8080')) {
        candidates.add('http://localhost:8080');
      }
    }

    for (int i = 0; i < candidates.length; i++) {
      final currentBase = candidates[i];
      try {
        final uri = _buildUri(currentBase, endpoint, queryParams);
        final request = await _httpClient.openUrl(method, uri).timeout(const Duration(seconds: 25));

        // 1. MUST set all headers BEFORE writing any body data
        _buildHeaders().forEach((k, v) => request.headers.set(k, v));

        // 2. Write body if present
        if (body != null) {
          final bodyBytes = utf8.encode(jsonEncode(body));
          request.contentLength = bodyBytes.length;
          request.add(bodyBytes);
        }

        final response = await request.close().timeout(const Duration(seconds: 25));
        final result = await _processResponse(response);
        // If successful and on fallback, update baseUrl
        if (currentBase != baseUrl) {
          baseUrl = currentBase;
        }
        return result;
      } on SocketException {
        continue; // Try next candidate
      } on TimeoutException {
        if (i < candidates.length - 1) {
          continue; // Try next candidate
        }
        throw ApiException('Server javob berish vaqti tugadi.');
      }
    }

    throw ApiException(
      'Server bilan aloqa o\'rnatib bo\'lmadi. Backend ishlayotganligini tekshiring.',
    );
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

  Future<dynamic> _processResponse(HttpClientResponse response) async {
    final responseBody = await response.transform(utf8.decoder).join();
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
      onUnauthorized?.call();
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
