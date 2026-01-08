// lib/services/auth_service.dart - COMPLETE CODE
import "dart:convert";
import "package:dio/dio.dart";
import "package:shared_preferences/shared_preferences.dart";
import "../api/api_client.dart";
import "../api/api_endpoints.dart";

// JWT Decoder function
Map<String, dynamic>? decodeJWT(String token) {
  try {
    final parts = token.split(".");
    if (parts.length != 3) return null;

    final payload = parts[1];
    final normalized = base64.normalize(
      payload.replaceAll("-", "+").replaceAll("_", "/"),
    );
    final decoded = utf8.decode(base64.decode(normalized));
    return json.decode(decoded) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

class AuthService {
  static final Dio _dio = ApiClient.instance.dio;

  // Memory storage (temporary solution for SharedPreferences issue)
  static String? _memoryToken;
  static String? _memoryTokenType;
  static Map<String, dynamic>? _memoryPayload;

  // ✅ LOGIN METHOD - MAIN FUNCTION
  static Future<Map<String, dynamic>> loginUser(
    String email,
    String password,
  ) async {
    print('\n${'=' * 60}');
    print('🚀 LOGIN STARTED');
    print('=' * 60);
    print('📧 Email: $email');
    print('🔑 Password length: ${password.length}');
    print('🌐 Endpoint: ${API.LOGIN}');

    try {
      // ✅ Proper form-url-encoded body
      final body = {"username": email.trim(), "password": password};

      final response = await _dio.post(
        API.LOGIN,
        data: body,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {"accept": "application/json"},
          // ✅ 401/422 pe DioException throw mat karo
          validateStatus: (code) => code != null && code < 500,
        ),
      );

      print('\n📥 API RESPONSE:');
      print('✅ Status: ${response.statusCode}');
      print('✅ Data: ${response.data}');

      // ✅ If backend returned error but not thrown
      if ((response.statusCode ?? 0) >= 400) {
        String msg = "Login failed";
        final d = response.data;

        if (d is Map && d["detail"] != null) msg = d["detail"].toString();
        if (d is Map && d["message"] != null) msg = d["message"].toString();
        if (d is String && d.trim().isNotEmpty) msg = d;

        return {
          "success": false,
          "status": response.statusCode,
          "message": msg,
          "data": response.data,
        };
      }

      // ✅ Must be Map with access_token
      if (response.data == null || response.data is! Map) {
        return {
          "success": false,
          "status": response.statusCode,
          "message": "Invalid response format",
          "data": response.data,
        };
      }

      final map = Map<String, dynamic>.from(response.data as Map);

      if (map["access_token"] == null) {
        return {
          "success": false,
          "status": response.statusCode,
          "message": "No access_token in response",
          "data": map,
        };
      }

      final token = map["access_token"].toString();
      final tokenType = (map["token_type"] ?? "Bearer").toString().trim();

      print('\n${'=' * 60}');
      print('🎉 LOGIN SUCCESS! TOKEN RECEIVED');
      print('=' * 60);
      print('📦 $token');
      print('Type: $tokenType');
      print('=' * 60);

      _memoryToken = token;
      _memoryTokenType = tokenType;
      _memoryPayload = decodeJWT(token);

      // save prefs (best-effort)
      try {
        final sp = await SharedPreferences.getInstance();
        await sp.setString("token", token);
        await sp.setString("token_type", tokenType);
        if (_memoryPayload != null) {
          await sp.setString("user_payload", json.encode(_memoryPayload));
        }
        print('✅ Token saved to SharedPreferences');
      } catch (e) {
        print('⚠️ SharedPreferences error: $e');
      }

      return {
        "success": true,
        "token": token,
        "token_type": tokenType,
        "payload": _memoryPayload,
        "data": map,
      };
    } catch (e) {
      print('\n❌ LOGIN ERROR: $e');
      return {
        "success": false,
        "message": "Unexpected error",
        "error": e.toString(),
      };
    }
  }

  // ✅ REGISTER METHOD
  static Future<Map<String, dynamic>> registerUser(
    Map<String, dynamic> payload,
  ) async {
    try {
      print('\n${'=' * 60}');
      print('🚀 REGISTRATION STARTED');
      print('=' * 60);
      print('📦 Payload: $payload');
      print('🌐 Endpoint: ${API.REGISTER}');

      final res = await _dio.post(
        API.REGISTER,
        data: payload,
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      print('\n✅ REGISTRATION RESPONSE:');
      print('   Status: ${res.statusCode}');
      print('   Data: ${res.data}');

      final ok = (res.statusCode ?? 0) >= 200 && (res.statusCode ?? 0) < 300;

      return {
        "ok": ok,
        "success": ok,
        "status": res.statusCode,
        "data": res.data,
      };
    } on DioException catch (e) {
      print('\n❌ REGISTRATION DIO ERROR:');
      print('   Type: ${e.type}');
      print('   Status: ${e.response?.statusCode}');
      print('   Message: ${e.message}');
      print('   Response: ${e.response?.data}');

      final isTimeout =
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;

      return {
        "ok": false,
        "success": false,
        "status": e.response?.statusCode,
        "data": e.response?.data,
        "errorType": isTimeout ? "timeout" : "dio",
        "message": isTimeout
            ? "Server timeout. API not responding."
            : (e.response?.data?.toString() ?? e.message ?? "Request failed"),
      };
    } catch (e) {
      print('\n❌ REGISTRATION ERROR: $e');
      return {
        "ok": false,
        "success": false,
        "status": null,
        "data": null,
        "errorType": "unknown",
        "message": e.toString(),
      };
    }
  }

  // ✅ GET CURRENT TOKEN FROM MEMORY
  static String? getCurrentToken() {
    return _memoryToken;
  }

  // ✅ GET CURRENT TOKEN TYPE FROM MEMORY
  static String? getCurrentTokenType() {
    return _memoryTokenType;
  }

  // ✅ GET CURRENT PAYLOAD FROM MEMORY
  static Map<String, dynamic>? getCurrentPayload() {
    return _memoryPayload;
  }

  // ✅ PRINT CURRENT TOKEN (For debugging)
  static void printCurrentToken() {
    if (_memoryToken != null) {
      print('\n${'=' * 60}');
      print('🔐 CURRENT TOKEN IN MEMORY');
      print('=' * 60);
      print('📦 Token: $_memoryToken');
      print('📏 Length: ${_memoryToken!.length} characters');
      print('🔐 Type: $_memoryTokenType');

      if (_memoryPayload != null) {
        print('\n📋 Payload:');
        _memoryPayload!.forEach((key, value) {
          print('   $key: $value');
        });
      }
      print('=' * 60);
    } else {
      print('\n🔐 No token in memory');
    }
  }

  // ✅ MASK TOKEN FOR DISPLAY
  static String maskToken(String? t) {
    if (t == null || t.isEmpty) return "(empty)";
    if (t.length <= 20) return t;
    final head = t.substring(0, t.length >= 8 ? 8 : t.length);
    final tail = t.substring(t.length >= 6 ? t.length - 6 : 0);
    return "$head…$tail (len:${t.length})";
  }

  // ✅ LOGOUT USER
  static Future<void> logoutUser() async {
    print('\n${'=' * 60}');
    print('🚪 LOGOUT STARTED');
    print('=' * 60);

    // Clear memory storage
    final beforeToken = _memoryToken;
    _memoryToken = null;
    _memoryTokenType = null;
    _memoryPayload = null;

    print('🗑️ Memory cleared');
    print('   Before: ${maskToken(beforeToken)}');
    print('   After: ${_memoryToken == null ? "Cleared ✓" : "Still exists"}');

    try {
      // Try server logout
      await _dio.post(API.LOGOUT);
      print('✅ Server logout successful');
    } catch (e) {
      print('⚠️ Server logout skipped/failed: $e');
    }

    // Try to clear SharedPreferences
    try {
      final sp = await SharedPreferences.getInstance();
      final before = sp.getString("token");

      await sp.remove("token");
      await sp.remove("access_token");
      await sp.remove("token_type");
      await sp.remove("user_payload");

      final after = sp.getString("token");
      print('🗑️ SharedPreferences cleared');
      print('   Before: ${maskToken(before)}');
      print('   After: ${after == null ? "Cleared ✓" : "Still exists"}');
    } catch (e) {
      print('⚠️ SharedPreferences clear error: $e');
    }

    print('✅ Logout completed');
    print('=' * 60);
  }

  // ✅ DEBUG TOKEN (For checking stored token)
  static Future<void> debugToken() async {
    print('\n${'=' * 60}');
    print('🔍 DEBUG TOKEN INFO');
    print('=' * 60);

    // Memory token
    print('🧠 MEMORY STORAGE:');
    if (_memoryToken != null) {
      print('   Token: ${maskToken(_memoryToken)}');
      print('   Type: $_memoryTokenType');
      print('   Length: ${_memoryToken!.length}');
    } else {
      print('   No token in memory');
    }

    // SharedPreferences token
    try {
      final sp = await SharedPreferences.getInstance();
      final t = sp.getString("token");

      print('\n💾 SHARED PREFERENCES:');
      if (t == null) {
        print('   No token in SharedPreferences');
      } else {
        print('   Token: ${maskToken(t)}');
        print('   Length: ${t.length}');

        try {
          final payload = decodeJWT(t);
          if (payload != null) {
            final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            print('   JWT Payload:');
            payload.forEach((key, value) {
              print('     $key: $value');
            });

            if (payload.containsKey('exp')) {
              final exp = payload['exp'];
              final diff = exp - now;
              print(
                '   ⏰ Expires in: ${diff ~/ 3600}h ${(diff % 3600) ~/ 60}m',
              );
            }
          }
        } catch (e) {
          print('   ❌ JWT decode error: $e');
        }
      }
    } catch (e) {
      print('\n❌ SharedPreferences error: $e');
    }

    print('=' * 60);
  }

  // ✅ DECODE JWT TOKEN (Public method)
  static Map<String, dynamic>? decodeJWTToken(String token) {
    return decodeJWT(token);
  }

  // ✅ GET STORED USER PAYLOAD FROM SHAREDPREFERENCES
  static Future<Map<String, dynamic>?> getStoredUserPayload() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString("user_payload");
      if (raw == null || raw.trim().isEmpty) return null;
      return json.decode(raw) as Map<String, dynamic>;
    } catch (e) {
      print('⚠️ getStoredUserPayload error: $e');
      return null;
    }
  }

  // ✅ SIMPLE TEST METHOD
  static Future<void> testConnection() async {
    print('\n🔍 TESTING AUTH SERVICE CONNECTION');
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://room.24x7techelp.com/',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      print('✅ Server is reachable! Status: ${response.statusCode}');
    } catch (e) {
      print('❌ Server connection failed: $e');
    }
  }

  // ✅ Get user role from memory
  static String? getUserRole() {
    if (_memoryPayload != null && _memoryPayload!.containsKey('role')) {
      return _memoryPayload!['role'].toString().toUpperCase();
    }
    return null;
  }

  // ✅ Check if user is OWNER
  static bool isOwner() {
    final role = getUserRole();
    return role == 'OWNER';
  }

  // ✅ Check if user is TENANT
  static bool isTenant() {
    final role = getUserRole();
    return role == 'TENANT';
  }

  // ✅ Get navigation path based on role
  static String getNavigationPath() {
    final role = getUserRole();

    print('\n🔍 NAVIGATION CHECK:');
    print('   Role: $role');

    if (role == 'OWNER') {
      print('   ➡️ Navigating to: /RenterTabs');
      return '/RenterTabs';
    } else if (role == 'TENANT') {
      print('   ➡️ Navigating to: /bottomnav');
      return '/bottomnav';
    } else {
      print('   ⚠️ Unknown role, default to: /bottomnav');
      return '/bottomnav';
    }
  }

  // ✅ Get user ID from memory
  static String? getUserId() {
    if (_memoryPayload != null && _memoryPayload!.containsKey('sub')) {
      return _memoryPayload!['sub'].toString();
    }
    return null;
  }

  // ✅ Get user email from payload (if exists)
  static String? getUserEmail() {
    if (_memoryPayload != null && _memoryPayload!.containsKey('email')) {
      return _memoryPayload!['email'].toString();
    }
    return null;
  }

  // ✅ Get location ID from payload (if exists)
  static String? getLocationId() {
    if (_memoryPayload != null && _memoryPayload!.containsKey('location_id')) {
      return _memoryPayload!['location_id']?.toString();
    }
    return null;
  }

  // ✅ Check if token is expired
  static bool isTokenExpired() {
    if (_memoryPayload != null && _memoryPayload!.containsKey('exp')) {
      final exp = _memoryPayload!['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now >= exp;
    }
    return true; // Assume expired if no expiry info
  }

  // ✅ Get token expiry time
  static DateTime? getTokenExpiry() {
    if (_memoryPayload != null && _memoryPayload!.containsKey('exp')) {
      final exp = _memoryPayload!['exp'] as int;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    }
    return null;
  }

  // ✅ Get token remaining time in seconds
  static int? getTokenRemainingSeconds() {
    if (_memoryPayload != null && _memoryPayload!.containsKey('exp')) {
      final exp = _memoryPayload!['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final remaining = exp - now;
      return remaining > 0 ? remaining : 0;
    }
    return null;
  }

  // ✅ Print user info summary
  static void printUserInfo() {
    if (_memoryPayload != null) {
      print('\n${'=' * 60}');
      print('👤 USER INFO SUMMARY');
      print('=' * 60);
      print('   ID: ${getUserId() ?? "Unknown"}');
      print('   Role: ${getUserRole() ?? "Unknown"}');
      print('   Email: ${getUserEmail() ?? "Unknown"}');
      print('   Location ID: ${getLocationId() ?? "None"}');

      final expiry = getTokenExpiry();
      if (expiry != null) {
        print('   Token Expires: ${expiry.toLocal()}');
        final remaining = getTokenRemainingSeconds();
        if (remaining != null) {
          final hours = remaining ~/ 3600;
          final minutes = (remaining % 3600) ~/ 60;
          final seconds = remaining % 60;
          print('   Time Remaining: ${hours}h ${minutes}m ${seconds}s');
        }
      }
      print('=' * 60);
    } else {
      print('\n👤 No user info available');
    }
  }

  // ✅ Clear all auth data
  static void clearAuthData() {
    _memoryToken = null;
    _memoryTokenType = null;
    _memoryPayload = null;

    // Also try to clear SharedPreferences
    try {
      SharedPreferences.getInstance().then((sp) {
        sp.remove("token");
        sp.remove("access_token");
        sp.remove("token_type");
        sp.remove("user_payload");
      });
    } catch (e) {
      print('⚠️ Error clearing SharedPreferences: $e');
    }
  }

  // ✅ Check if user has specific role
  static bool hasRole(String role) {
    final userRole = getUserRole();
    return userRole == role.toUpperCase();
  }

  // ✅ Get all user roles (if multiple roles in future)
  static List<String> getUserRoles() {
    if (_memoryPayload != null && _memoryPayload!.containsKey('roles')) {
      final roles = _memoryPayload!['roles'];
      if (roles is List) {
        return roles.map((r) => r.toString().toUpperCase()).toList();
      }
    }

    // Fallback to single role
    final role = getUserRole();
    return role != null ? [role] : [];
  }

  // ✅ Check if user has any of the given roles
  static bool hasAnyRole(List<String> roles) {
    final userRole = getUserRole();
    if (userRole == null) return false;

    return roles.any((role) => userRole == role.toUpperCase());
  }

  // ✅ Validate token structure
  static bool isTokenValid(String? token) {
    if (token == null || token.isEmpty) return false;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      // Check if it can be decoded
      final payload = decodeJWT(token);
      return payload != null;
    } catch (e) {
      return false;
    }
  }
  // AuthService mein yeh method ko update karein:

  // ✅ RESTORE USER FROM STORAGE (UPDATED)
  static Future<bool> restoreUser() async {
    print('\n${'=' * 60}');
    print('🔄 ATTEMPTING TO RESTORE USER FROM STORAGE');
    print('=' * 60);

    try {
      // First try to get token from SharedPreferences
      final sp = await SharedPreferences.getInstance();
      final storedToken = sp.getString("token");
      final storedTokenType = sp.getString("token_type");
      final storedPayload = sp.getString("user_payload");

      print('📦 Storage Check:');
      print(
        '   Token exists: ${storedToken != null && storedToken.isNotEmpty}',
      );
      print('   Token type: $storedTokenType');
      print(
        '   Payload exists: ${storedPayload != null && storedPayload.isNotEmpty}',
      );

      if (storedToken != null && storedToken.isNotEmpty) {
        print('✅ TOKEN FOUND IN STORAGE');

        // Store in memory
        _memoryToken = storedToken;
        _memoryTokenType = storedTokenType ?? "Bearer";

        // Try to get payload
        if (storedPayload != null && storedPayload.isNotEmpty) {
          try {
            _memoryPayload = json.decode(storedPayload) as Map<String, dynamic>;
            print('✅ PAYLOAD RESTORED FROM STORAGE');
          } catch (e) {
            print('⚠️ Error decoding stored payload: $e');
            // Fallback to decode from token
            _memoryPayload = decodeJWT(storedToken);
            print('🔍 Decoded payload from token');
          }
        } else {
          // Decode payload from token
          _memoryPayload = decodeJWT(storedToken);
          print('🔍 Decoded payload from token');
        }

        // Verify the payload
        if (_memoryPayload != null && _memoryPayload!.isNotEmpty) {
          print('\n📋 RESTORED USER INFO:');
          print('   User ID: ${getUserId() ?? "Unknown"}');
          print('   Role: ${getUserRole() ?? "Unknown"}');
          print('   Token valid: ${isTokenValid(storedToken)}');

          // Check if token is expired
          if (isTokenExpired()) {
            print('⚠️ TOKEN IS EXPIRED - Clearing storage');
            await logoutUser();
            return false;
          }

          print('✅ USER RESTORED SUCCESSFULLY');
          return true;
        } else {
          print('❌ FAILED TO DECODE USER PAYLOAD');
          return false;
        }
      } else {
        print('🔐 NO TOKEN FOUND IN STORAGE');
        return false;
      }
    } catch (e) {
      print('❌ ERROR RESTORING USER: $e');
      return false;
    }
  }

  // ✅ CHECK AUTH STATUS (IMPROVED)
  static Future<bool> isAuthenticated() async {
    print('\n🔐 CHECKING AUTHENTICATION STATUS');

    // Check memory first
    if (_memoryToken != null && _memoryToken!.isNotEmpty) {
      print('✅ Token found in memory');
      print('   Role: ${getUserRole()}');
      print('   Token valid: ${isTokenValid(_memoryToken)}');

      // Check if token in memory is still valid
      if (!isTokenExpired()) {
        return true;
      } else {
        print('⚠️ Token in memory is expired');
        _memoryToken = null;
        _memoryTokenType = null;
        _memoryPayload = null;
      }
    }

    print('🔄 No valid token in memory, checking storage...');
    // Try to restore from storage
    return await restoreUser();
  }

  // ✅ CHECK AUTH STATUS (IMPROVED)
}
