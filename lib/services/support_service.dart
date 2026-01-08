import "dart:convert";
import "package:dio/dio.dart";
import "../api/api_client.dart";
import "../api/api_endpoints.dart";

class SupportService {
  static final Dio _dio = ApiClient.instance.dio;

  static Future<Map<String, dynamic>> getPublicSupport() async {
    try {
      final res = await _dio.get(API.SUPPORT_PUBLIC);
      final data = res.data;

      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);

      if (data is String) {
        final decoded = json.decode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }

      throw Exception("Invalid support response format");
    } on DioException catch (e) {
      final msg =
          e.response?.data?.toString() ?? e.message ?? "Support API error";
      throw Exception(msg);
    }
  }

  // ✅ ADD THIS: FAQ PUBLIC
  static Future<Map<String, dynamic>> getPublicFaq() async {
    try {
      final res = await _dio.get(API.FAQ_PUBLIC); // ✅ /faq/public
      final data = res.data;

      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);

      if (data is String) {
        final decoded = json.decode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }

      throw Exception("Invalid FAQ response format");
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message ?? "FAQ API error";
      throw Exception(msg);
    }
  }
}
