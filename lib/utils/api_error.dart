import "package:dio/dio.dart";

String apiErrorMessage(dynamic err) {
  try {
    if (err is DioException) {
      final res = err.response;
      final data = res?.data;

      if (data is Map) {
        if (data["detail"] != null) return data["detail"].toString();
        if (data["message"] != null) return data["message"].toString();
        if (data["errors"] != null) return data["errors"].toString();
      }

      if (data is String && data.trim().isNotEmpty) return data;

      final msg = err.message ?? "Request failed";
      if (msg.toLowerCase().contains("socket")) return "No internet connection";
      if (msg.toLowerCase().contains("timeout")) return "Request timeout";

      return "Request failed (${res?.statusCode ?? ""})";
    }

    final msg = err?.toString() ?? "Something went wrong";
    if (msg.contains("SocketException")) return "No internet connection";
    if (msg.contains("Timeout")) return "Request timeout";
    return msg;
  } catch (_) {
    return "Something went wrong";
  }
}
