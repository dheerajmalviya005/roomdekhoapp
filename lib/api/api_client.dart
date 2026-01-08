import "package:dio/dio.dart";
import "package:shared_preferences/shared_preferences.dart";
import "base_url.dart";

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: BASE_URL.replaceAll(RegExp(r"/+$"), ""),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final url = options.path;

          // same logic: public endpoints no auth
          final isPublic = RegExp(
            r"/auth/(login|register|forgot|reset)",
            caseSensitive: false,
          ).hasMatch(url);

          try {
            if (!isPublic) {
              final token = await _getAuthToken();
              final tokenType = await _getTokenType();
              if (token.isNotEmpty) {
                options.headers["Authorization"] = "$tokenType $token";
              }
            } else {
              options.headers.remove("Authorization");
            }

            // debug logs like your axios
            final absUrl = _absoluteUrl(options.baseUrl, options.path);
            final auth = (options.headers["Authorization"] ?? "").toString();
            final short = auth.isNotEmpty
                ? "${auth.substring(0, auth.length >= 12 ? 12 : auth.length)}…${auth.substring(auth.length >= 6 ? auth.length - 6 : 0)}"
                : "(none)";
            // ignore: avoid_print
            print("➡️ $absUrl Auth? ${auth.isNotEmpty}");
            if (auth.isNotEmpty) {
              // ignore: avoid_print
              print("🔑 Auth header: $short (scheme:${auth.split(" ").first})");
            }
          } catch (e) {
            // ignore: avoid_print
            print("Error fetching token: $e");
          }

          return handler.next(options);
        },
        onResponse: (res, handler) => handler.next(res),
        onError: (err, handler) {
          if (err.response?.statusCode == 401) {
            // ignore: avoid_print
            print(
              "🔒 401 from ${err.requestOptions.path} → ${err.response?.data}",
            );
          }
          return handler.next(err);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;

  Dio get dio => _dio;

  static String _absoluteUrl(String base, String path) {
    final b = base.replaceAll(RegExp(r"/+$"), "");
    final p = path.replaceAll(RegExp(r"^/+"), "");
    if (path.startsWith("http://") || path.startsWith("https://")) return path;
    return "$b/$p";
  }

  static Future<String> _getTokenType() async {
    final sp = await SharedPreferences.getInstance();
    final raw = (sp.getString("token_type") ?? "Bearer").trim();
    if (raw.toLowerCase() == "bearer") return "Bearer";
    if (raw.toLowerCase() == "jwt") return "JWT";
    return raw;
  }

  static Future<String> _getAuthToken() async {
    final sp = await SharedPreferences.getInstance();
    String? t = sp.getString("access_token");
    t ??= sp.getString("token");

    t = (t ?? "").trim();
    if (t.startsWith("{")) {
      // token stored as JSON string (rare)
      try {
        // ignore: avoid_print
        print("Token looks like JSON string, handle yourself if needed.");
      } catch (_) {}
    }

    // remove quotes + Bearer prefix
    t = t.trim();

    if (t.length >= 2) {
      final first = t[0];
      final last = t[t.length - 1];
      if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
        t = t.substring(1, t.length - 1);
      }
    }

    t = t.replaceFirst(RegExp(r"^Bearer\s+", caseSensitive: false), "").trim();
    return t;
  }
}
