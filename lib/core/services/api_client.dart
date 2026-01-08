import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// API Client for Pikkar Backend
/// Base HTTP client with interceptors and token management
class ApiClient {
  /// Backend API URL - choose based on platform.
  /// - Android Emulator: 10.0.2.2
  /// - iOS Simulator / Desktop: localhost
  /// - Physical device: change to your machine IP if server runs on your laptop
  static String get _baseUrl {
    // Runtime override:
    // flutter run --dart-define=PIKKAR_API_BASE_URL=http://192.168.1.10:5001/api/v1
    const override = String.fromEnvironment('PIKKAR_API_BASE_URL');
    if (override.isNotEmpty) return override;

    // Pikkar backend
    // - Web/iOS/Desktop uses localhost
    // - Android emulator uses 10.0.2.2
    if (kIsWeb) return 'http://localhost:5001/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:5001/api/v1';
    return 'http://localhost:5001/api/v1';
  }
  
  static const Duration _timeout = Duration(seconds: 15);
  
  /// Singleton instance
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();
  
  /// HTTP Client
  final http.Client _client = http.Client();
  
  /// Get stored auth token
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userToken');
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }
  
  /// Save auth token
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userToken', token);
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  static Future<void> saveRefreshToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('refreshToken', token);
    } catch (e) {
      print('Error saving refresh token: $e');
    }
  }
  
  /// Remove auth token
  static Future<void> removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userToken');
      await prefs.remove('refreshToken');
      await prefs.remove('userData');
    } catch (e) {
      print('Error removing token: $e');
    }
  }
  
  /// Save user data
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', jsonEncode(userData));
    } catch (e) {
      print('Error saving user data: $e');
    }
  }
  
  /// Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('userData');
      if (data != null) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
  
  /// Build headers with auth token
  Future<Map<String, String>> _buildHeaders({Map<String, String>? additionalHeaders}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    // Add auth token if available
    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    // Add additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    
    return headers;
  }
  
  /// Handle API response
  dynamic _handleResponse(http.Response response) {
    print('✅ API Response: ${response.statusCode} ${response.request?.url}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return jsonDecode(response.body);
    } else {
      // Handle error responses
      final errorData = response.body.isNotEmpty 
          ? jsonDecode(response.body) 
          : {'message': 'Unknown error'};
      
      // Handle 401 Unauthorized - logout user
      if (response.statusCode == 401) {
        removeToken();
      }
      
      throw ApiException(
        statusCode: response.statusCode,
        message: errorData['message'] ?? 'Request failed',
        data: errorData,
      );
    }
  }
  
  /// GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('$_baseUrl$endpoint');
      
      // Add query parameters
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map(
          (key, value) => MapEntry(key, value.toString()),
        ));
      }
      
      print('📡 API Request: GET $uri');
      
      final response = await _client
          .get(uri, headers: await _buildHeaders(additionalHeaders: headers))
          .timeout(_timeout);
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }
  
  /// POST request
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      
      print('📡 API Request: POST $uri');
      
      final response = await _client
          .post(
            uri,
            headers: await _buildHeaders(additionalHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }
  
  /// PUT request
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      
      print('📡 API Request: PUT $uri');
      
      final response = await _client
          .put(
            uri,
            headers: await _buildHeaders(additionalHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }
  
  /// DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      
      print('📡 API Request: DELETE $uri');
      
      final response = await _client
          .delete(uri, headers: await _buildHeaders(additionalHeaders: headers))
          .timeout(_timeout);
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }
  
  /// POST multipart request (for file uploads)
  Future<dynamic> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    List<http.MultipartFile>? files,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      
      print('📡 API Request: POST (multipart) $uri');
      
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers with token
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Add fields
      request.fields.addAll(fields);
      
      // Add files
      if (files != null) {
        request.files.addAll(files);
      }
      
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }
  
  /// Close the client
  void dispose() {
    _client.close();
  }
}

/// API Exception
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? data;
  
  ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });
  
  @override
  String toString() {
    return 'ApiException: $statusCode - $message';
  }
}

