import "dart:async";
import "dart:io";
import "dart:convert";
import "package:flutter/material.dart";
import "package:material_design_icons_flutter/material_design_icons_flutter.dart";
import "package:file_picker/file_picker.dart";
import "package:permission_handler/permission_handler.dart";
import '../../../../../services/room_service.dart';

import 'package:dio/dio.dart';

String INR_FMT(String? s) {
  final raw = (s ?? "").replaceAll(RegExp(r"\D"), "");
  if (raw.isEmpty) return "";
  final chars = raw.split("");
  final out = <String>[];
  int count = 0;
  for (int i = chars.length - 1; i >= 0; i--) {
    out.add(chars[i]);
    count++;
    if (count % 3 == 0 && i != 0) out.add(",");
  }
  return out.reversed.join();
}

int fromINR(String? s) {
  final raw = (s ?? "").replaceAll(",", "").trim();
  return int.tryParse(raw.isEmpty ? "0" : raw) ?? 0;
}

String toISO(DateTime d) {
  final y = d.year.toString().padLeft(4, "0");
  final m = d.month.toString().padLeft(2, "0");
  final day = d.day.toString().padLeft(2, "0");
  return "$y-$m-$day";
}

/* ---------------- Constants ---------------- */

const List<String> FURNISHED = [
  "UNFURNISHED",
  "SEMI_FURNISHED",
  "FULLY_FURNISHED",
];
const List<String> LIV_PREFS = ["INDEPENDENT", "OWNER_LIVING"];
const List<String> TENANT_PREFS = ["FAMILY", "BOYS", "GIRLS", "EMPLOYED"];
const List<String> BEDROOM_OPTIONS = [
  "1BHK",
  "2BHK",
  "3BHK",
  "4BHK",
  "5BHK",
  "1RK",
  "2RK",
  "3RK",
  "4RK",
  "5RK",
];

bool isGooglePhotosUri(String? uri) {
  if (uri == null) return false;
  return uri.startsWith("content://com.google.android.apps.photos.content");
}

Future<bool> ensureMediaPermission() async {
  if (!Platform.isAndroid) return true;

  try {
    final p1 = await Permission.photos.request();
    final p2 = await Permission.videos.request();

    if (p1.isGranted && p2.isGranted) return true;

    final st = await Permission.storage.request();
    return st.isGranted;
  } catch (_) {
    final st = await Permission.storage.request();
    return st.isGranted;
  }
}

// Future<int?> _androidSdkInt() async {
//   return null;
// }

Map<String, dynamic> defaultForm() {
  return {
    "title": "",
    "description": "",
    "rent": "",
    "deposit": "",
    "availability_from": toISO(DateTime.now()),
    "bedrooms": "0",
    "sqft_area": "0",
    "furnished_type": "UNFURNISHED",
    "floor": "0",
    "living_preference": "INDEPENDENT",
    "tenant_preferences": <String>[],
    "images": <Map<String, String>>[],
    "videos": <Map<String, String>>[],
    "amenities": <String>[],
    "rules": <String>[],
    "location_address": "",
    "location_lat": "",
    "location_long": "",
    "area": "",
    "city": "Indore",
  };
}

String normalizeBedrooms(String val) {
  final s = val.toUpperCase().trim();
  if (RegExp(r"^\d+$").hasMatch(s)) return "${s}BHK";
  if (RegExp(r"^[1-5](BHK|RK)$").hasMatch(s)) return s;
  return "";
}

/* ---------------- Upload Item ---------------- */

class UploadItem {
  UploadItem({
    required this.id,
    required this.uri,
    required this.kind,
    this.progress = 0,
    this.status = "uploading",
    this.errorMsg,
  });

  final String id;
  final String uri;
  final String kind;
  int progress;
  String status;
  String? errorMsg;
}

/* ---------------- Alert Modal ---------------- */

class AlertPayload {
  AlertPayload({
    required this.visible,
    required this.title,
    required this.message,
    required this.variant,
    this.onConfirm,
  });

  bool visible;
  String title;
  String message;
  String variant; // error | warning | success
  VoidCallback? onConfirm;
}

/* ---------------- Screen ---------------- */

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  String? _extractRoomId(dynamic data) {
    if (data == null) return null;

    // Map response (most common)
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);

      final direct =
          m["room_id"]?.toString() ??
          m["id"]?.toString() ??
          m["roomId"]?.toString();

      if (direct != null && direct.trim().isNotEmpty) return direct;

      final room = m["room"];
      if (room is Map) {
        final rm = Map<String, dynamic>.from(room);
        final v = rm["id"]?.toString() ?? rm["room_id"]?.toString();
        if (v != null && v.trim().isNotEmpty) return v;
      }

      final d = m["data"];
      if (d is Map) {
        final dm = Map<String, dynamic>.from(d);
        final v = dm["room_id"]?.toString() ?? dm["id"]?.toString();
        if (v != null && v.trim().isNotEmpty) return v;
      }

      final raw = m["raw"];
      if (raw is String) return _extractRoomId(raw);

      return null;
    }

    // String response (fallback)
    if (data is String) {
      final s = data.trim();
      if (s.isEmpty) return null;

      // try JSON parse
      try {
        final parsed = json.decode(s);
        return _extractRoomId(parsed);
      } catch (_) {}

      // regex: "room_id": "value"
      final jsonMatch = RegExp(r'"room_id"\s*:\s*"([^"]+)"').firstMatch(s);
      if (jsonMatch != null) return jsonMatch.group(1);

      // regex: room_id=value
      final simpleMatch = RegExp(r'room_id[=:]\s*([^\s,}]+)').firstMatch(s);
      if (simpleMatch != null) {
        return simpleMatch
            .group(1)
            ?.replaceAll('"', '')
            .replaceAll("'", '')
            .trim();
      }

      return null;
    }

    return null;
  }

  // ✅ WHITE theme (as you asked)
  late final _T = _Tokens.light();

  // ✅ unified field height
  static const double _FIELD_H = 46;

  Map<String, dynamic> form = defaultForm();

  String amenityInput = "";
  String ruleInput = "";

  bool showSuggestions = false;
  List<Map<String, dynamic>> suggestions = []; // [{description: "..."}]

  final List<UploadItem> uploads = [];

  static const int MAX_VIDEO_BYTES = 20 * 1024 * 1024;

  int step = 1; // 1 details, 2 media
  dynamic roomId;
  bool savingStep1 = false;

  AlertPayload alertModal = AlertPayload(
    visible: false,
    title: "",
    message: "",
    variant: "error",
  );

  void showAlert({
    required String title,
    required String message,
    String variant = "error",
    VoidCallback? onConfirm,
  }) {
    setState(() {
      alertModal = AlertPayload(
        visible: true,
        title: title,
        message: message,
        variant: variant,
        onConfirm: onConfirm,
      );
    });
  }

  void closeAlert() {
    final cb = alertModal.onConfirm;
    setState(() {
      alertModal.visible = false;
      alertModal.onConfirm = null;
    });
    if (cb != null) {
      try {
        cb();
      } catch (_) {}
    }
  }

  bool get canSubmit {
    final f = form;
    return (f["title"] as String).trim().isNotEmpty &&
        (f["area"] as String).trim().isNotEmpty &&
        (f["location_address"] as String).trim().isNotEmpty &&
        (f["availability_from"] as String).trim().isNotEmpty &&
        (f["bedrooms"] as String).trim().isNotEmpty &&
        (int.tryParse((f["sqft_area"] as String).trim()) ?? 0) >= 0;
  }

  void update(Map<String, dynamic> patch) {
    setState(() {
      form = {...form, ...patch};
    });
  }

  void toggleTenant(String tag) {
    final List<String> list = List<String>.from(
      form["tenant_preferences"] ?? [],
    );
    final set = list.toSet();
    if (set.contains(tag)) {
      set.remove(tag);
    } else {
      set.add(tag);
    }
    update({"tenant_preferences": set.toList()});
  }

  void addAmenity() {
    final val = amenityInput.trim();
    if (val.isEmpty) return;
    final items = List<String>.from(form["amenities"] ?? []);
    items.add(val);
    update({"amenities": items});
    setState(() => amenityInput = "");
  }

  void addRule() {
    final val = ruleInput.trim();
    if (val.isEmpty) return;
    final items = List<String>.from(form["rules"] ?? []);
    items.add(val);
    update({"rules": items});
    setState(() => ruleInput = "");
  }

  Timer? _debounceTimer;

  Future<void> onAreaChange(String text) async {
    update({"area": text});

    if (text.trim().length < 2) {
      if (mounted) {
        setState(() {
          suggestions = [];
          showSuggestions = false;
        });
      }
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      try {
        final q = text.trim();
        print('🔍 Fetching suggestions for: $q');

        final suggestionsData = await RoomService.getSuggestions(q);

        final List<Map<String, dynamic>> processed = [];

        for (final item in suggestionsData) {
          if (item is Map) {
            final m = Map<String, dynamic>.from(item);

            processed.add({
              "title": (m["title"] ?? "").toString(),
              "subtitle": (m["subtitle"] ?? "").toString(),
              "place_id": (m["place_id"] ?? "").toString(),
            });
          } else if (item is String) {
            processed.add({"title": item, "subtitle": "", "place_id": ""});
          }
        }

        if (!mounted) return;

        setState(() {
          suggestions = processed;
          showSuggestions = processed.isNotEmpty;
        });
      } catch (error) {
        print('❌ Error fetching suggestions: $error');
        if (!mounted) return;

        setState(() {
          suggestions = [];
          showSuggestions = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Map<String, dynamic> buildRoomPayloadInline(Map<String, dynamic> f) {
    final bedrooms = normalizeBedrooms((f["bedrooms"] ?? "").toString());
    if (bedrooms.isEmpty) {
      throw Exception("Bedrooms must be like 1RK/1BHK/2BHK…");
    }

    final rent = fromINR((f["rent"] ?? "").toString());
    final deposit = fromINR((f["deposit"] ?? "").toString());
    final sqftArea = int.tryParse((f["sqft_area"] ?? "0").toString()) ?? 0;
    final floor = int.tryParse((f["floor"] ?? "0").toString()) ?? 0;

    final livingPref = (f["living_preference"] ?? "INDEPENDENT").toString();
    final safeLiving = LIV_PREFS.contains(livingPref)
        ? livingPref
        : "INDEPENDENT";

    final tenantPrefs = List<String>.from(f["tenant_preferences"] ?? []);
    final safeTenant = tenantPrefs.isNotEmpty ? tenantPrefs : ["FAMILY"];

    // Build payload matching exactly what the API expects
    return {
      "title": (f["title"] ?? "").toString().trim(),
      "description": (f["description"] ?? "").toString().trim(),
      "rent": rent,
      "deposit": deposit,
      "availability_from": (f["availability_from"] ?? toISO(DateTime.now()))
          .toString(),
      "bedrooms": bedrooms,
      "sqft_area": sqftArea,
      "furnished_type": (f["furnished_type"] ?? "UNFURNISHED").toString(),
      "floor": floor,
      "living_preference": safeLiving,
      "tenant_preferences": safeTenant,
      "amenities": List<String>.from(f["amenities"] ?? []),
      "rules": List<String>.from(f["rules"] ?? []),
      "area": (f["area"] ?? "").toString().trim(),
    };
  }

  Future<void> handleStep1Submit() async {
    if (!canSubmit) {
      showAlert(
        title: "Missing info",
        message: "Please fill all required fields before continuing.",
        variant: "warning",
      );
      return;
    }

    setState(() => savingStep1 = true);

    try {
      final accessToken = await _getAccessToken();

      if (accessToken == null || accessToken.trim().isEmpty) {
        showAlert(
          title: "Session expired",
          message: "Please sign in again.",
          variant: "warning",
        );
        return;
      }

      final payload = buildRoomPayloadInline(form);

      // Log the payload being sent
      print('📤 Sending payload: $payload');

      // ✅ Call actual RoomService.createRoom API
      final dynamic responseData = await RoomService.createRoom(
        payload,
        accessToken,
      );
      // ✅ Debug: Print full response
      print('📦 Create Room Response: $responseData');

      // ✅ Extract room_id from response - check different possible keys
      String? newRoomId;

      // First, check if responseData is a Map
      if (responseData is Map<String, dynamic>) {
        newRoomId =
            responseData["room_id"]?.toString() ?? // Primary field
            responseData["id"]?.toString() ??
            responseData["roomId"]?.toString() ??
            (responseData["room"]?["id"]?.toString()) ??
            (responseData["data"]?["room_id"]?.toString());
      } else if (responseData is Map) {
        // If it's a Map but not specifically Map<String, dynamic>
        final Map<String, dynamic> map = Map<String, dynamic>.from(
          responseData,
        );
        newRoomId =
            map["room_id"]?.toString() ??
            map["id"]?.toString() ??
            map["roomId"]?.toString() ??
            (map["room"]?["id"]?.toString()) ??
            (map["data"]?["room_id"]?.toString());
      }

      if (newRoomId == null) {
        print('❌ No room_id found in response. Full response: $responseData');
        print('❌ Response type: ${responseData.runtimeType}');

        if (responseData is String) {
          print('📄 Response is String, trying to extract room_id...');

          try {
            final parsed = json.decode(responseData) as Map<String, dynamic>;
            newRoomId = parsed["room_id"]?.toString();
            print('✅ Parsed JSON successfully, room_id: $newRoomId');
          } catch (e) {
            print('❌ Failed to parse response string as JSON: $e');
            if (responseData.contains('room_id')) {
              print('📄 String contains "room_id", trying regex extraction...');
              final jsonMatch = RegExp(
                r'"room_id"\s*:\s*"([^"]+)"',
              ).firstMatch(responseData);
              if (jsonMatch != null) {
                newRoomId = jsonMatch.group(1);
                print('✅ Extracted room_id via regex: $newRoomId');
              } else {
                final simpleMatch = RegExp(
                  r'room_id[=:]\s*([^\s,}]+)',
                ).firstMatch(responseData);
                if (simpleMatch != null) {
                  newRoomId = simpleMatch.group(1);
                  newRoomId = newRoomId
                      ?.replaceAll('"', '')
                      .replaceAll("'", '')
                      .trim();
                  print('✅ Extracted room_id via simple pattern: $newRoomId');
                }
              }
            }
          }
        }

        if (newRoomId == null) {
          throw Exception(
            "Room created but no room_id returned from server. Response type: ${responseData.runtimeType}, Response: $responseData",
          );
        }
      }

      roomId = newRoomId;

      print('✅ Room created with ID: $roomId');

      showAlert(
        title: "Step 1 saved",
        message: "Now add photos & videos for this room.",
        variant: "success",
        onConfirm: () {
          setState(() => step = 2);
        },
      );
    } on DioException catch (e) {
      print('❌ Dio Error creating room: ${e.message}');
      print('❌ Response status: ${e.response?.statusCode}');
      print('❌ Response data: ${e.response?.data}');

      String errorMessage = e.message ?? "Unknown error";
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          final errorData = e.response!.data as Map;
          errorMessage =
              errorData["message"]?.toString() ??
              errorData["detail"]?.toString() ??
              errorData["error"]?.toString() ??
              e.message ??
              "Unknown error";
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data.toString();
        }
      }

      showAlert(
        title: "Room creation failed",
        message: errorMessage,
        variant: "error",
      );
    } catch (e) {
      print('❌ Error creating room: $e');
      print('❌ Error type: ${e.runtimeType}');
      showAlert(
        title: "Room creation failed",
        message: e.toString(),
        variant: "error",
      );
    } finally {
      setState(() => savingStep1 = false);
    }
  }

  Future<void> addMedia() async {
    if (roomId == null) {
      showAlert(
        title: "Room not saved",
        message:
            "Please complete Step 1 first so we can link media to this room.",
        variant: "warning",
      );
      return;
    }

    final ok = await ensureMediaPermission();
    if (!ok) {
      showAlert(
        title: "Permission needed",
        message: "Please allow Photos/Videos permission.",
        variant: "warning",
      );
      return;
    }

    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ["jpg", "jpeg", "png", "webp", "mp4", "mov", "mkv"],
        withData: false,
      );

      if (res == null) return;

      final picked = res.files.where((f) => (f.path ?? "").isNotEmpty).toList();

      final localFiles = picked
          .where((f) => !isGooglePhotosUri(f.path))
          .toList();
      final removedCount = picked.length - localFiles.length;

      if (localFiles.isEmpty) {
        showAlert(
          title: "Use phone gallery photos",
          message:
              "Ye media Google Photos cloud se aa raha hai. Kripya pehle phone me download/save karein, phir select karein.",
          variant: "warning",
        );
        return;
      }

      if (removedCount > 0) {
        showAlert(
          title: "Some media skipped",
          message:
              "Kuch photos/videos Google Photos cloud se the, unhe skip kar diya gaya. Sirf phone me saved media hi upload hoga.",
          variant: "warning",
        );
      }

      // Size check for videos
      for (final f in localFiles) {
        final path = f.path!;
        if (_isVideoPath(path)) {
          final size = await File(path).length();
          if (size > MAX_VIDEO_BYTES) {
            showAlert(
              title: "Video too large",
              message:
                  "Please select a smaller video (max 20 MB) or compress it before upload.",
              variant: "warning",
            );
            return;
          }
        }
      }

      // Prepare files list with kind
      final files = localFiles.map((f) {
        final path = f.path!;
        return {
          'kind': _isVideoPath(path) ? 'video' : 'image',
          'filePath': path,
        };
      }).toList();

      // Use the new multiple upload method
      await uploadMultipleFiles(files: files, roomId: roomId);
    } catch (e) {
      showAlert(
        title: "Media Picker Error",
        message: e.toString(),
        variant: "error",
      );
    }
  }

  Future<void> _uploadOne({
    required String id,
    required String kind,
    required String filePath,
    required dynamic roomId,
  }) async {
    void patch(int progress, {String? status, String? errorMsg}) {
      setState(() {
        final idx = uploads.indexWhere((u) => u.id == id);
        if (idx == -1) return;
        uploads[idx].progress = progress;
        if (status != null) uploads[idx].status = status;
        uploads[idx].errorMsg = errorMsg;
      });
    }

    try {
      final accessToken = await _getAccessToken();

      if (accessToken == null || accessToken.trim().isEmpty) {
        patch(0, status: "error", errorMsg: "Access token missing");
        showAlert(
          title: "Session expired",
          message: "Please sign in again.",
          variant: "error",
        );
        return;
      }

      // ✅ Use the new uploadFiles method
      final results = await RoomService.uploadFiles(
        files: [
          {'kind': kind, 'filePath': filePath},
        ],
        roomId: roomId.toString(),
        accessToken: accessToken,
        onProgress: (progress, index) => patch(progress.toInt()),
      );

      if (results.isEmpty) {
        patch(0, status: "error", errorMsg: "No result returned from server");
        showAlert(
          title: "Upload error",
          message: "Upload succeeded but server returned no data.",
          variant: "warning",
        );
        return;
      }

      final item = results.first;
      final finalUrl = item["url"]?.toString() ?? "";

      if (finalUrl.isEmpty) {
        patch(0, status: "error", errorMsg: "No URL returned from server");
        showAlert(
          title: "Upload error",
          message: "Upload succeeded but server returned no media URL.",
          variant: "warning",
        );
        return;
      }

      if (kind == "image") {
        final imgs = List<Map<String, String>>.from(form["images"] ?? []);
        imgs.add({"uri": finalUrl, "type": "image/jpeg"});
        update({"images": imgs});
      } else {
        final vids = List<Map<String, String>>.from(form["videos"] ?? []);
        vids.add({"uri": finalUrl, "type": "video/mp4"});
        update({"videos": vids});
      }

      patch(100, status: "done");
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() {
        uploads.removeWhere((u) => u.id == id);
      });
    } catch (e) {
      patch(0, status: "error", errorMsg: e.toString());
      showAlert(
        title: "Upload failed",
        message: e.toString().contains("Network")
            ? "Server ne upload ke beech me connection band kar diya. Video size ya server limit check karein."
            : e.toString(),
        variant: "error",
      );
    }
  }

  Future<void> uploadMultipleFiles({
    required List<Map<String, dynamic>> files, // List of {kind, filePath}
    required dynamic roomId,
  }) async {
    final accessToken = await _getAccessToken();

    if (accessToken == null || accessToken.trim().isEmpty) {
      showAlert(
        title: "Session expired",
        message: "Please sign in again.",
        variant: "error",
      );
      return;
    }

    try {
      // Separate lists for images and videos
      final List<Map<String, dynamic>> imageFiles = [];
      final List<Map<String, dynamic>> videoFiles = [];

      // Categorize files
      for (final file in files) {
        final kind = file['kind'] as String;
        final filePath = file['filePath'] as String;

        final id = "${DateTime.now().millisecondsSinceEpoch}_${_rand()}";

        setState(() {
          uploads.add(UploadItem(id: id, uri: filePath, kind: kind));
        });

        if (kind == 'image') {
          imageFiles.add({'id': id, 'kind': kind, 'filePath': filePath});
        } else {
          videoFiles.add({'id': id, 'kind': kind, 'filePath': filePath});
        }
      }

      print(
        '📊 Files breakdown: ${imageFiles.length} images, ${videoFiles.length} videos',
      );

      // Ek saath multiple uploads handle karne ke liye
      final List<Future<void>> uploadFutures = [];

      // Sirf images hain to video API na chale
      if (imageFiles.isNotEmpty && videoFiles.isEmpty) {
        print(
          '📤 Uploading only images (${imageFiles.length} files), skipping video API',
        );

        for (final item in imageFiles) {
          uploadFutures.add(
            _uploadOneParallel(
              id: item['id'] as String,
              kind: item['kind'] as String,
              filePath: item['filePath'] as String,
              roomId: roomId,
              accessToken: accessToken,
            ),
          );
        }
      }
      // Sirf videos hain to image API na chale
      else if (videoFiles.isNotEmpty && imageFiles.isEmpty) {
        print(
          '📤 Uploading only videos (${videoFiles.length} files), skipping image API',
        );

        for (final item in videoFiles) {
          uploadFutures.add(
            _uploadOneParallel(
              id: item['id'] as String,
              kind: item['kind'] as String,
              filePath: item['filePath'] as String,
              roomId: roomId,
              accessToken: accessToken,
            ),
          );
        }
      }
      // Dono hain to dono ki APIs chale - parallel upload
      else if (imageFiles.isNotEmpty && videoFiles.isNotEmpty) {
        print(
          '📤 Uploading both images and videos (${files.length} files total)',
        );

        // Pehle images upload karo (parallel)
        for (final item in imageFiles) {
          uploadFutures.add(
            _uploadOneParallel(
              id: item['id'] as String,
              kind: item['kind'] as String,
              filePath: item['filePath'] as String,
              roomId: roomId,
              accessToken: accessToken,
            ),
          );
        }

        // Phir videos upload karo (parallel)
        for (final item in videoFiles) {
          uploadFutures.add(
            _uploadOneParallel(
              id: item['id'] as String,
              kind: item['kind'] as String,
              filePath: item['filePath'] as String,
              roomId: roomId,
              accessToken: accessToken,
            ),
          );
        }
      }

      // Wait for all uploads to complete
      await Future.wait(uploadFutures, eagerError: false);

      print('✅ All uploads completed');
    } catch (e) {
      print('❌ Upload failed: $e');
      showAlert(
        title: "Upload failed",
        message: e.toString(),
        variant: "error",
      );
    }
  }

  // Parallel upload ke liye optimized method
  Future<void> _uploadOneParallel({
    required String id,
    required String kind,
    required String filePath,
    required dynamic roomId,
    required String accessToken,
  }) async {
    void patch(int progress, {String? status, String? errorMsg}) {
      if (!mounted) return;

      setState(() {
        final idx = uploads.indexWhere((u) => u.id == id);
        if (idx == -1) return;
        uploads[idx].progress = progress;
        if (status != null) uploads[idx].status = status;
        uploads[idx].errorMsg = errorMsg;
      });
    }

    try {
      // ✅ Use the new uploadFiles method
      final results = await RoomService.uploadFiles(
        files: [
          {'kind': kind, 'filePath': filePath},
        ],
        roomId: roomId.toString(),
        accessToken: accessToken,
        onProgress: (progress, index) {
          if (mounted) {
            patch(progress.toInt());
          }
        },
      );

      if (results.isEmpty) {
        patch(0, status: "error", errorMsg: "No result returned from server");
        if (mounted) {
          showAlert(
            title: "Upload error",
            message: "Upload succeeded but server returned no data.",
            variant: "warning",
          );
        }
        return;
      }

      final item = results.first;
      final finalUrl = item["url"]?.toString() ?? "";

      if (finalUrl.isEmpty) {
        patch(0, status: "error", errorMsg: "No URL returned from server");
        if (mounted) {
          showAlert(
            title: "Upload error",
            message: "Upload succeeded but server returned no media URL.",
            variant: "warning",
          );
        }
        return;
      }

      // Form mein add karo
      if (mounted) {
        if (kind == "image") {
          final imgs = List<Map<String, String>>.from(form["images"] ?? []);
          imgs.add({"uri": finalUrl, "type": "image/jpeg"});
          update({"images": imgs});
        } else {
          final vids = List<Map<String, String>>.from(form["videos"] ?? []);
          vids.add({"uri": finalUrl, "type": "video/mp4"});
          update({"videos": vids});
        }
      }

      patch(100, status: "done");

      // 400ms wait karo phir remove karo
      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        setState(() {
          uploads.removeWhere((u) => u.id == id);
        });
      }
    } catch (e) {
      patch(0, status: "error", errorMsg: e.toString());
      if (mounted) {
        showAlert(
          title: "Upload failed",
          message: e.toString().contains("Network")
              ? "Server ne upload ke beech me connection band kar diya. Video size ya server limit check karein."
              : e.toString(),
          variant: "error",
        );
      }
    }
  }

  void removeMedia(int idx) {
    final imgs = List<Map<String, String>>.from(form["images"] ?? []);
    if (idx < 0 || idx >= imgs.length) return;
    imgs.removeAt(idx);
    update({"images": imgs});
  }

  void removeVideo(int idx) {
    final vids = List<Map<String, String>>.from(form["videos"] ?? []);
    if (idx < 0 || idx >= vids.length) return;
    vids.removeAt(idx);
    update({"videos": vids});
  }

  Future<void> onSubmit() async {
    if (step != 2) return;
    if (roomId == null) {
      showAlert(
        title: "Room not saved",
        message: "Please go back and complete Step 1 again (room id missing).",
        variant: "warning",
      );
      return;
    }

    final totalMedia =
        (form["images"] as List).length + (form["videos"] as List).length;
    if (totalMedia < 5) {
      showAlert(
        title: "Add media",
        message: "Please upload at least 5 images or videos before publishing.",
        variant: "warning",
      );
      return;
    }

    showAlert(
      title: "Room published",
      message: "Your room has been created successfully.",
      variant: "success",
      onConfirm: () => Navigator.of(context).maybePop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerPublishDisabled = step != 2 || !canSubmit;
    final totalMedia =
        (form["images"] as List).length + (form["videos"] as List).length;

    return Scaffold(
      backgroundColor: _T.background, // ✅ white
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  T: _T,
                  title: step == 1 ? "Create Room" : "Add Media",
                  publishDisabled: headerPublishDisabled,
                  onBack: () => Navigator.of(context).maybePop(),
                  onPublish: onSubmit,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: step == 1
                        ? _buildStep1()
                        : _buildStep2(totalMedia: totalMedia),
                  ),
                ),
              ],
            ),
            AlertModal(
              visible: alertModal.visible,
              title: alertModal.title,
              message: alertModal.message,
              variant: alertModal.variant,
              T: _T,
              onClose: closeAlert,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        Section(
          title: "Basic Info",
          T: _T,
          child: Column(
            children: [
              Field(
                T: _T,
                label: "Title*",
                value: form["title"],
                onChanged: (v) => update({"title": v}),
                hint: "e.g. City View Residency",
                height: _FIELD_H,
              ),
              Field(
                T: _T,
                label: "Description",
                value: form["description"],
                onChanged: (v) => update({"description": v}),
                hint: "Short description",
                multiline: true,
                height: 96, // multiline needs more height
              ),
            ],
          ),
        ),
        Section(
          title: "Pricing",
          T: _T,
          child: Row(
            children: [
              Expanded(
                child: Field(
                  T: _T,
                  label: "Rent / month*",
                  value: INR_FMT(form["rent"]),
                  keyboard: TextInputType.number,
                  onChanged: (v) => update({"rent": v}),
                  hint: "₹",
                  height: _FIELD_H,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Field(
                  T: _T,
                  label: "Deposit",
                  value: INR_FMT(form["deposit"]),
                  keyboard: TextInputType.number,
                  onChanged: (v) => update({"deposit": v}),
                  hint: "₹",
                  height: _FIELD_H,
                ),
              ),
            ],
          ),
        ),
        Section(
          title: "Availability & Specs",
          T: _T,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      T: _T,
                      label: "Available from*",
                      value: form["availability_from"],
                      height: _FIELD_H,
                      onPick: () async {
                        final now = DateTime.now();
                        final init =
                            DateTime.tryParse(form["availability_from"]) ?? now;
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: init,
                          firstDate: DateTime(2000, 1, 1),
                          lastDate: DateTime(2100, 12, 31),
                        );
                        if (picked != null) {
                          update({"availability_from": toISO(picked)});
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownSelect(
                      T: _T,
                      label: "Bedrooms",
                      value: (form["bedrooms"] ?? "").toString(),
                      options: BEDROOM_OPTIONS,
                      onSelect: (v) => update({"bedrooms": v.toUpperCase()}),
                      height: _FIELD_H,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Field(
                      T: _T,
                      label: "Sqft Area",
                      value: form["sqft_area"],
                      keyboard: TextInputType.number,
                      onChanged: (v) => update({
                        "sqft_area": v.replaceAll(RegExp(r"\D"), ""),
                      }),
                      hint: "0",
                      height: _FIELD_H,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Field(
                      T: _T,
                      label: "Floor",
                      value: form["floor"],
                      keyboard: TextInputType.number,
                      onChanged: (v) =>
                          update({"floor": v.replaceAll(RegExp(r"\D"), "")}),
                      hint: "0",
                      height: _FIELD_H,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownSelect(
                      T: _T,
                      label: "Furnished Type",
                      value: form["furnished_type"],
                      options: FURNISHED,
                      onSelect: (v) => update({"furnished_type": v}),
                      height: _FIELD_H,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownSelect(
                      T: _T,
                      label: "Living Preference",
                      value: form["living_preference"],
                      options: LIV_PREFS,
                      onSelect: (v) => update({"living_preference": v}),
                      height: _FIELD_H,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Label(T: _T, text: "Tenant Preferences"),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TENANT_PREFS.map((tp) {
                  final active = (form["tenant_preferences"] as List).contains(
                    tp,
                  );
                  return InkWell(
                    onTap: () => toggleTenant(tp),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active ? _T.primary : _T.chipBg,
                        border: Border.all(
                          color: active ? _T.primary : _T.border,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tp.replaceAll("_", " "),
                        style: TextStyle(
                          color: active ? _T.onPrimary : _T.chipText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Section(
          title: "Location",
          T: _T,
          child: Column(
            children: [
              _AreaWithSuggestions(
                T: _T,
                value: form["area"],
                suggestions: suggestions,
                showSuggestions: showSuggestions,
                onChange: onAreaChange,
                onPickSuggestion: (desc) {
                  update({"area": desc});
                  setState(() => showSuggestions = false);
                },
                height: 46,
              ),

              Field(
                T: _T,
                label: "Full Address*",
                value: form["location_address"],
                onChanged: (v) => update({"location_address": v}),
                hint: "House / Street / Landmark",
                height: _FIELD_H,
              ),
            ],
          ),
        ),
        Section(
          title: "Amenities & Rules",
          T: _T,
          child: Column(
            children: [
              ChipInput(
                T: _T,
                label: "Add Amenity",
                value: amenityInput,
                items: List<String>.from(form["amenities"] ?? []),
                onChanged: (v) => setState(() => amenityInput = v),
                onAdd: addAmenity,
                onRemove: (i) {
                  final items = List<String>.from(form["amenities"] ?? []);
                  items.removeAt(i);
                  update({"amenities": items});
                },
                fieldHeight: _FIELD_H,
              ),
              ChipInput(
                T: _T,
                label: "Add Rule",
                value: ruleInput,
                items: List<String>.from(form["rules"] ?? []),
                onChanged: (v) => setState(() => ruleInput = v),
                onAdd: addRule,
                onRemove: (i) {
                  final items = List<String>.from(form["rules"] ?? []);
                  items.removeAt(i);
                  update({"rules": items});
                },
                fieldHeight: _FIELD_H,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: (!canSubmit || savingStep1) ? null : handleStep1Submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: (!canSubmit || savingStep1)
                    ? _T.disabled
                    : _T.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: savingStep1
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _T.onPrimary,
                      ),
                    )
                  : Text(
                      "Save & Continue",
                      style: TextStyle(
                        color: _T.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStep2({required int totalMedia}) {
    final images = List<Map<String, String>>.from(form["images"] ?? []);
    final videos = List<Map<String, String>>.from(form["videos"] ?? []);
    final isOk = totalMedia >= 5;

    return Section(
      title: "Media",
      T: _T,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Top meta row (count + requirement)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _T.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _T.primary.withOpacity(0.14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(MdiIcons.imageMultipleOutline, color: _T.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Photos & Videos",
                        style: TextStyle(
                          color: _T.onBackground,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Minimum 5 required to publish",
                        style: TextStyle(
                          color: _T.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isOk
                        ? _T.success.withOpacity(0.14)
                        : _T.warning.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOk
                          ? _T.success.withOpacity(0.35)
                          : _T.warning.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    "$totalMedia / 5",
                    style: TextStyle(
                      color: isOk ? _T.success : _T.warning,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ✅ Media grid container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _T.border),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                // Responsive tiles
                final width = c.maxWidth;
                final crossAxisCount = width >= 420 ? 4 : 3;
                final spacing = 10.0;
                final tileW =
                    (width - (spacing * (crossAxisCount - 1))) / crossAxisCount;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    // uploads
                    ...uploads.map(
                      (u) => SizedBox(
                        width: tileW,
                        height: tileW,
                        child: _UploadTilePro(T: _T, item: u),
                      ),
                    ),

                    // images
                    ...List.generate(images.length, (idx) {
                      final uri = (images[idx]["uri"] ?? "").toString();
                      if (uri.isEmpty) return const SizedBox.shrink();
                      return SizedBox(
                        width: tileW,
                        height: tileW,
                        child: _MediaTilePro(
                          T: _T,
                          uri: uri,
                          isVideo: false,
                          onRemove: () => removeMedia(idx),
                        ),
                      );
                    }),

                    // videos
                    ...List.generate(videos.length, (idx) {
                      final uri = (videos[idx]["uri"] ?? "").toString();
                      if (uri.isEmpty) return const SizedBox.shrink();
                      return SizedBox(
                        width: tileW,
                        height: tileW,
                        child: _MediaTilePro(
                          T: _T,
                          uri: uri,
                          isVideo: true,
                          onRemove: () => removeVideo(idx),
                        ),
                      );
                    }),

                    // add tile
                    SizedBox(
                      width: tileW,
                      height: tileW,
                      child: _AddTilePro(T: _T, onTap: addMedia),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // ✅ Helper / Error line (looks better)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: (isOk ? _T.success : _T.error).withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isOk ? _T.success : _T.error).withOpacity(0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isOk
                      ? MdiIcons.checkCircleOutline
                      : MdiIcons.alertCircleOutline,
                  size: 18,
                  color: isOk ? _T.success : _T.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOk
                        ? "Great! You can publish now, or add more media."
                        : "Please upload at least 5 images or videos.",
                    style: TextStyle(
                      color: isOk ? _T.success : _T.error,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _getAccessToken() async {
    return "YOUR_ACCESS_TOKEN";
  }
}

/* ---------------- Widgets ---------------- */

class _Header extends StatelessWidget {
  const _Header({
    required this.T,
    required this.title,
    required this.publishDisabled,
    required this.onBack,
    required this.onPublish,
  });

  final _Tokens T;
  final String title;
  final bool publishDisabled;
  final VoidCallback onBack;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: T.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: T.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(MdiIcons.arrowLeft, color: T.onPrimary, size: 20),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  color: T.onBackground,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: publishDisabled ? null : onPublish,
              style: ElevatedButton.styleFrom(
                backgroundColor: publishDisabled ? T.disabled : T.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                "Publish",
                style: TextStyle(
                  color: publishDisabled ? T.muted : T.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    required this.T,
    required this.child,
  });

  final String title;
  final _Tokens T;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: T.onBackground,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class Label extends StatelessWidget {
  const Label({super.key, required this.T, required this.text});

  final _Tokens T;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: T.muted, fontWeight: FontWeight.w700),
    );
  }
}

class Field extends StatelessWidget {
  const Field({
    super.key,
    required this.T,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.multiline = false,
    this.keyboard,
    this.height = 46,
  });

  final _Tokens T;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final bool multiline;
  final TextInputType? keyboard;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Label(T: T, text: label),
          const SizedBox(height: 6),
          Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: T.surface,
              border: Border.all(color: T.border),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: multiline ? Alignment.topLeft : Alignment.centerLeft,
            child: TextField(
              keyboardType: keyboard,
              maxLines: multiline ? null : 1,
              expands: multiline,
              style: TextStyle(color: T.onBackground, fontSize: 13),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: T.muted),
                border: InputBorder.none,
              ),
              controller: TextEditingController(text: value)
                ..selection = TextSelection.collapsed(offset: value.length),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class ChipInput extends StatelessWidget {
  const ChipInput({
    super.key,
    required this.T,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
    this.fieldHeight = 46,
  });

  final _Tokens T;
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final double fieldHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Label(T: T, text: label),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: fieldHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: T.surface,
                    border: Border.all(color: T.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    style: TextStyle(color: T.onBackground, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Type & add",
                      hintStyle: TextStyle(color: T.muted),
                      border: InputBorder.none,
                    ),
                    controller: TextEditingController(text: value)
                      ..selection = TextSelection.collapsed(
                        offset: value.length,
                      ),
                    onChanged: onChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: fieldHeight,
                child: ElevatedButton(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: T.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Add",
                    style: TextStyle(
                      color: T.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(items.length, (i) {
              final x = items[i];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: T.surface,
                  border: Border.all(color: T.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      x,
                      style: TextStyle(
                        color: T.onBackground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => onRemove(i),
                      child: Icon(MdiIcons.close, size: 14, color: T.muted),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class DropdownSelect extends StatelessWidget {
  const DropdownSelect({
    super.key,
    required this.T,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelect,
    this.height = 46,
  });

  final _Tokens T;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelect;
  final double height;

  @override
  Widget build(BuildContext context) {
    final safeValue = options.contains(value) ? value : options.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Label(T: T, text: label),
          const SizedBox(height: 6),
          Container(
            width: double.infinity, // ✅ full width
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: T.surface,
              border: Border.all(color: T.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: safeValue,
                isExpanded: true, // ✅ makes it match Field width
                icon: Icon(MdiIcons.chevronDown, color: T.muted, size: 18),
                dropdownColor: T.elevated,
                style: TextStyle(
                  color: T.onBackground,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                items: options.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt,
                    child: Text(
                      opt.replaceAll("_", " "),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) onSelect(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.T,
    required this.label,
    required this.value,
    required this.onPick,
    this.height = 46,
  });

  final _Tokens T;
  final String label;
  final String value;
  final VoidCallback onPick;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Label(T: T, text: label),
          const SizedBox(height: 6),
          InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: T.surface,
                border: Border.all(color: T.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(MdiIcons.calendar, color: T.muted, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: T.onBackground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaWithSuggestions extends StatefulWidget {
  const _AreaWithSuggestions({
    // super.key,
    required this.T,
    required this.value,
    required this.suggestions,
    required this.showSuggestions,
    required this.onChange,
    required this.onPickSuggestion,
    this.height = 46,
  });

  final _Tokens T;
  final String value;
  final List<Map<String, dynamic>> suggestions;
  final bool showSuggestions;
  final ValueChanged<String> onChange;
  final ValueChanged<String> onPickSuggestion;
  final double height;

  @override
  State<_AreaWithSuggestions> createState() => _AreaWithSuggestionsState();
}

class _AreaWithSuggestionsState extends State<_AreaWithSuggestions> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  late final TextEditingController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _AreaWithSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);

    // keep controller synced
    if (_ctl.text != widget.value) {
      _ctl.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }

    // show/hide overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.showSuggestions && widget.suggestions.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  void _showOverlay() {
    if (_entry != null) {
      _entry!.markNeedsBuild();
      return;
    }

    final overlay = Overlay.of(context);
    // if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (ctx) {
        final T = widget.T;

        return Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // tap outside to close
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _removeOverlay,
                    behavior: HitTestBehavior.translucent,
                    child: const SizedBox(),
                  ),
                ),

                CompositedTransformFollower(
                  link: _link,
                  showWhenUnlinked: false,
                  offset: Offset(
                    0,
                    16 + 6 + widget.height + 6,
                  ), // label+gap+field+gap
                  child: Material(
                    elevation: 10,
                    borderRadius: BorderRadius.circular(12),
                    color: T.elevated,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: Container(
                        width:
                            MediaQuery.of(context).size.width -
                            32, // same as Section padding (16+16)
                        decoration: BoxDecoration(
                          color: T.elevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: T.border),
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: widget.suggestions.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: T.border),
                          itemBuilder: (_, idx) {
                            final item = widget.suggestions[idx];

                            final title =
                                (item["title"] ?? item["description"] ?? "")
                                    .toString()
                                    .trim();
                            final subtitle = (item["subtitle"] ?? "")
                                .toString()
                                .trim();
                            final placeId = (item["place_id"] ?? "")
                                .toString()
                                .trim();

                            // fallback (agar galti se empty aa gaya)
                            final showTitle = title.isNotEmpty
                                ? title
                                : "Unknown";
                            final showSubtitle = subtitle.isNotEmpty
                                ? subtitle
                                : (placeId.isNotEmpty
                                      ? "Place ID: $placeId"
                                      : "");

                            return InkWell(
                              onTap: () {
                                // ✅ Area field me title set
                                widget.onPickSuggestion(showTitle);
                                _removeOverlay();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      showTitle,
                                      style: TextStyle(
                                        color: T.onBackground,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (showSubtitle.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        showSubtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: T.muted,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final T = widget.T;

    return CompositedTransformTarget(
      link: _link,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Label(T: T, text: "Area*"),
            const SizedBox(height: 6),
            Container(
              height: widget.height,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: T.surface,
                border: Border.all(color: T.border),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: _ctl,
                style: TextStyle(color: T.onBackground, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "e.g. Downtown",
                  hintStyle: TextStyle(color: T.muted),
                  border: InputBorder.none,
                ),
                onChanged: widget.onChange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaTilePro extends StatelessWidget {
  const _MediaTilePro({
    required this.T,
    required this.uri,
    required this.isVideo,
    required this.onRemove,
  });

  final _Tokens T;
  final String uri;
  final bool isVideo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: T.surface,
        border: Border.all(color: T.border),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: _thumb(uri)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.35),
                  ],
                ),
              ),
            ),
          ),

          if (isVideo)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.play_arrow, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "Video",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            right: 8,
            top: 8,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(String uri) {
    if (uri.startsWith("http")) {
      return Image.network(uri, fit: BoxFit.cover);
    }
    return Image.file(File(uri), fit: BoxFit.cover);
  }
}

class _AddTilePro extends StatelessWidget {
  const _AddTilePro({required this.T, required this.onTap});

  final _Tokens T;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: T.primary.withOpacity(0.45)),
          color: T.primary.withOpacity(0.10),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [T.primary, T.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.add, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                "Add Media",
                style: TextStyle(
                  color: T.onBackground,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Photos / Videos",
                style: TextStyle(
                  color: T.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadTilePro extends StatelessWidget {
  const _UploadTilePro({required this.T, required this.item});

  final _Tokens T;
  final UploadItem item;

  @override
  Widget build(BuildContext context) {
    final isErr = item.status == "error";
    final isDone = item.status == "done";

    return Container(
      decoration: BoxDecoration(
        color: T.surface,
        border: Border.all(color: isErr ? T.error.withOpacity(0.35) : T.border),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: Image.file(File(item.uri), fit: BoxFit.cover)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
          ),

          if (item.kind == "video")
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),

          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (!isDone && !isErr)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else if (isDone)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      )
                    else
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isErr
                            ? "Upload failed"
                            : isDone
                            ? "Uploaded"
                            : "Uploading… ${item.progress}%",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (item.progress.clamp(0, 100)) / 100.0,
                    minHeight: 5,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isErr ? T.error : (isDone ? T.success : Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- Alert Modal ---------------- */

class AlertModal extends StatelessWidget {
  const AlertModal({
    super.key,
    required this.visible,
    required this.title,
    required this.message,
    required this.onClose,
    required this.T,
    required this.variant,
  });

  final bool visible;
  final String title;
  final String message;
  final VoidCallback onClose;
  final _Tokens T;
  final String variant;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final iconName = variant == "success"
        ? MdiIcons.checkCircleOutline
        : variant == "warning"
        ? MdiIcons.alertCircleOutline
        : MdiIcons.alertOctagonOutline;

    final iconColor = variant == "success"
        ? T.success
        : variant == "warning"
        ? T.warning
        : T.error;

    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.45),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: T.elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: T.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconName, size: 40, color: iconColor),
                const SizedBox(height: 10),
                Text(
                  title.isEmpty ? "Something went wrong" : title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: T.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  message.isEmpty
                      ? "Something went wrong. Please check your connection and try again."
                      : message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: T.muted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: T.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "OK",
                      style: TextStyle(
                        color: T.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------- Tokens (WHITE background) ---------------- */

class _Tokens {
  _Tokens({
    required this.background,
    required this.surface,
    required this.elevated,
    required this.border,
    required this.primary,
    required this.accent,
    required this.disabled,
    required this.onPrimary,
    required this.onBackground,
    required this.muted,
    required this.error,
    required this.warning,
    required this.success,
    required this.chipBg,
    required this.chipText,
  });

  final Color background;
  final Color surface;
  final Color elevated;
  final Color border;
  final Color primary;
  final Color accent;
  final Color disabled;
  final Color onPrimary;
  final Color onBackground;
  final Color muted;
  final Color error;
  final Color warning;
  final Color success;
  final Color chipBg;
  final Color chipText;

  factory _Tokens.light() {
    return _Tokens(
      background: const Color(0xFFFFFFFF),
      surface: const Color(0xFFF6F7FB),
      elevated: const Color(0xFFFFFFFF),
      border: const Color(0xFFE5E7EB),
      primary: const Color(0xFF2563EB),
      accent: const Color(0xFF10B981),
      disabled: const Color(0xFFCBD5E1),
      onPrimary: Colors.white,
      onBackground: const Color(0xFF0F172A),
      muted: const Color(0xFF64748B),
      error: const Color(0xFFEF4444),
      warning: const Color(0xFFF59E0B),
      success: const Color(0xFF22C55E),
      chipBg: const Color(0xFFF1F5F9),
      chipText: const Color(0xFF0F172A),
    );
  }
}

/* ---------------- Helper ---------------- */

bool _isVideoPath(String path) {
  final p = path.toLowerCase();
  return p.endsWith(".mp4") || p.endsWith(".mov") || p.endsWith(".mkv");
}

String _rand() => DateTime.now().microsecondsSinceEpoch.toString();

/* ---------------- API PLACEHOLDERS ---------------- */

Future<Map<String, dynamic>> getSuggestions(String text) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return {
    "suggestions": [
      {"description": "$text - A"},
      {"description": "$text - B"},
    ],
  };
}

Future<Map<String, dynamic>> createRoom(
  Map<String, dynamic> payload,
  String accessToken,
) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return {"id": 12345};
}
