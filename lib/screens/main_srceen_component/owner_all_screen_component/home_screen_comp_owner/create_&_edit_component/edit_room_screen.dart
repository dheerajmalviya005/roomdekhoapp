// lib/screens/edit_room_screen_flutter.dart
import "dart:io";

import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:material_design_icons_flutter/material_design_icons_flutter.dart";

/* ============================================================
   ✅ CONFIG
   ============================================================ */

const String BASE_URL = "https://room.24x7techelp.com";

class API {
  static const String BASE_URL = "https://room.24x7techelp.com";

  // 🏠 ROOM ENDPOINTS
  static const String CREATE_ROOM = "/rooms/"; // also used for GET list rooms
  static const String OWNER_ROOMS = "/rooms/owner";

  static String getRoomByIdUrl(String id) => "/rooms/$id";
  static String getUpdateRoomUrl(String id) => "/rooms/$id";

  static String getRoomImagesUrl(String roomId) => "/rooms/$roomId/images";
  static String getRoomImageByIdUrl(String roomId, String imageNo) =>
      "/rooms/$roomId/images/$imageNo";
  static String getDeleteRoomImageUrl(String roomId, String imageNo) =>
      "/rooms/$roomId/images/$imageNo";

  static String getRoomVideoUrl(String roomId) => "/rooms/$roomId/video";
  static String getDeleteRoomVideoUrl(String roomId) => "/rooms/$roomId/video";
}

/* ============================================================
   ✅ DIO CLIENT (simple, direct paste)
   - agar aapke app me already dio instance hai, isko remove karke
     apna instance use kar lena.
   ============================================================ */

final Dio _dio = Dio(
  BaseOptions(
    baseUrl: API.BASE_URL,
    connectTimeout: const Duration(seconds: 25),
    receiveTimeout: const Duration(seconds: 25),
    sendTimeout: const Duration(seconds: 40),
  ),
);

/* ============================================================
   ✅ UTILS
   ============================================================ */

String INR_FMT(dynamic n) {
  if (n == null) return "";
  final s = n.toString();
  if (s.trim().isEmpty) return "";
  final raw = s.replaceAll(RegExp(r"\D"), "");
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

int fromINR(dynamic s) {
  final raw = (s ?? "0").toString().replaceAll(",", "").trim();
  return int.tryParse(raw.isEmpty ? "0" : raw) ?? 0;
}

String toISO(DateTime d) {
  final y = d.year.toString().padLeft(4, "0");
  final m = d.month.toString().padLeft(2, "0");
  final day = d.day.toString().padLeft(2, "0");
  return "$y-$m-$day";
}

bool isVideoUri(String uri, {String? type, bool flag = false}) {
  if (flag) return true;
  if ((type ?? "").toLowerCase().startsWith("video")) return true;
  return RegExp(r"\.(mp4|mov|mkv|avi)$", caseSensitive: false).hasMatch(uri);
}

String absolutize(String? url) {
  if (url == null) return "";
  final trimmed = url.trim();
  if (trimmed.isEmpty) return "";

  if (trimmed.startsWith("http://") ||
      trimmed.startsWith("https://") ||
      trimmed.startsWith("file://") ||
      trimmed.startsWith("asset://") ||
      trimmed.startsWith("data:")) {
    return trimmed;
  }

  final cleanBase = BASE_URL.endsWith("/")
      ? BASE_URL.substring(0, BASE_URL.length - 1)
      : BASE_URL;
  final path = trimmed.startsWith("/") ? trimmed : "/$trimmed";
  return "$cleanBase$path";
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic v) {
  if (v is List) return v;
  return const [];
}

/* ============================================================
   ✅ CONSTANTS
   ============================================================ */

const List<String> FURNISHED = [
  "UNFURNISHED",
  "SEMI_FURNISHED",
  "FULLY_FURNISHED",
];

const List<String> LIV_PREFS = ["INDEPENDENT", "OWNER_LIVING"];

const List<String> TENANT_PREFS = [
  "FAMILY",
  "BACHELORS",
  "STUDENTS",
  "WORKING_PROFESSIONALS",
];

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

/* ============================================================
   ✅ THEME TOKENS
   ============================================================ */

class Tokens {
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
  final Color chipBg;
  final Color chipText;

  Tokens({
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
    required this.chipBg,
    required this.chipText,
  });

  factory Tokens.light() => Tokens(
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
    chipBg: const Color(0xFFF1F5F9),
    chipText: const Color(0xFF0F172A),
  );
}

/* ============================================================
   ✅ SCREEN
   - SAMPLE_DATA removed ✅
   - Edit prefill via GET /rooms/{room_id} ✅
   - PATCH update /rooms/{room_id} ✅
   - Upload image POST /rooms/{room_id}/images ✅
   - Replace image PATCH /rooms/{room_id}/images/{image_no} ✅
   - Delete image DELETE /rooms/{room_id}/images/{image_no} ✅
   - Delete video DELETE /rooms/{room_id}/video ✅
   - Fullscreen gallery (swipe) ✅
   ============================================================ */

class EditRoomScreenFlutter extends StatefulWidget {
  /// route.params: { roomId, accessToken, prefill(optional map) }
  final String? roomId;
  final String? accessToken;
  final Map<String, dynamic>? prefill;

  const EditRoomScreenFlutter({
    super.key,
    this.roomId,
    this.accessToken,
    this.prefill,
  });

  @override
  State<EditRoomScreenFlutter> createState() => _EditRoomScreenFlutterState();
}

class _EditRoomScreenFlutterState extends State<EditRoomScreenFlutter> {
  final Tokens T = Tokens.light();
  final ImagePicker _picker = ImagePicker();

  String? roomId;
  String? accessToken;

  bool _loading = false;
  String? _loadErr;

  // form shape
  Map<String, dynamic> form = {
    "title": "",
    "description": "",
    "rent": "0",
    "deposit": "0",
    "availability_from": toISO(DateTime.now()),
    "bedrooms": "",
    "sqft_area": "0",
    "furnished_type": "UNFURNISHED",
    "floor": "0",
    "living_preference": "INDEPENDENT",
    "tenant_preferences": <String>["FAMILY"],
    "images": <dynamic>[], // combined media list (images + videos)
    "amenities": <String>[],
    "rules": <String>[],
    "location_address": "",
    "location_lat": 0,
    "location_long": 0,
    "area": "",
  };

  String amenityInput = "";
  String ruleInput = "";

  @override
  void initState() {
    super.initState();
    roomId = widget.roomId;
    accessToken = widget.accessToken;

    // optional prefill map (fast)
    if (widget.prefill != null) {
      _applyPrefill(widget.prefill!);
    }

    // ✅ always fetch latest
    _fetchRoom();
  }

  bool get canSubmit {
    final titleOk = (form["title"] ?? "").toString().trim().isNotEmpty;
    final areaOk = (form["area"] ?? "").toString().trim().isNotEmpty;
    final addressOk = (form["location_address"] ?? "")
        .toString()
        .trim()
        .isNotEmpty;
    final dateOk = (form["availability_from"] ?? "")
        .toString()
        .trim()
        .isNotEmpty;
    final bedroomsOk = (form["bedrooms"] ?? "").toString().trim().isNotEmpty;
    final sqft = int.tryParse((form["sqft_area"] ?? "0").toString()) ?? 0;
    final mediaCount = (form["images"] as List).length;

    return titleOk &&
        areaOk &&
        addressOk &&
        dateOk &&
        bedroomsOk &&
        sqft >= 0 &&
        mediaCount >= 5;
  }

  void update(Map<String, dynamic> patch) {
    setState(() => form = {...form, ...patch});
  }

  void toggleTenant(String tag) {
    final current = List<String>.from(form["tenant_preferences"] ?? []);
    final set = current.toSet();
    if (set.contains(tag)) {
      set.remove(tag);
    } else {
      set.add(tag);
    }
    update({"tenant_preferences": set.toList()});
  }

  void addAmenity() {
    final v = amenityInput.trim();
    if (v.isEmpty) return;
    final arr = List<String>.from(form["amenities"] ?? []);
    arr.add(v);
    setState(() {
      form["amenities"] = arr;
      amenityInput = "";
    });
  }

  void addRule() {
    final v = ruleInput.trim();
    if (v.isEmpty) return;
    final arr = List<String>.from(form["rules"] ?? []);
    arr.add(v);
    setState(() {
      form["rules"] = arr;
      ruleInput = "";
    });
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final init =
        DateTime.tryParse((form["availability_from"] ?? "").toString()) ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );

    if (picked != null) update({"availability_from": toISO(picked)});
  }

  /* -------------------- FETCH ROOM -------------------- */

  Future<void> _fetchRoom() async {
    if (roomId == null || roomId!.trim().isEmpty) {
      setState(() => _loadErr = "Room ID missing");
      return;
    }

    try {
      setState(() {
        _loading = true;
        _loadErr = null;
      });

      final raw = await getRoomByIdApi(
        roomId: roomId!,
        accessToken: accessToken,
      );
      _applyPrefill(raw);
    } catch (e) {
      setState(() => _loadErr = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyPrefill(Map<String, dynamic> raw) {
    final rawImages = _asList(raw["images"]);
    final rawVideos = _asList(raw["videos"]);

    // map images
    final mappedImages = rawImages
        .map((u) {
          if (u == null) return null;

          if (u is Map) {
            final m = _asMap(u);
            final url = (m["url"] ?? m["uri"] ?? "").toString();
            final uri = absolutize(url);
            if (uri.isEmpty) return null;

            // ✅ IMPORTANT: image_no (server key)
            final imageNo =
                (m["image_no"] ??
                        m["imageNo"] ??
                        m["image_id"] ??
                        m["id"] ??
                        m["media_id"])
                    ?.toString();

            return {
              "uri": uri,
              "type": (m["type"] ?? "image/jpeg"),
              "isVideo": false,
              "image_no": imageNo, // used for delete/replace
            };
          }

          if (u is String) {
            final uri = absolutize(u);
            if (uri.isEmpty) return null;
            return {"uri": uri, "type": "image/jpeg", "isVideo": false};
          }

          return null;
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    // map videos
    final mappedVideos = rawVideos
        .map((v) {
          if (v == null) return null;

          if (v is Map) {
            final m = _asMap(v);
            final url = (m["url"] ?? m["uri"] ?? "").toString();
            final uri = absolutize(url);
            if (uri.isEmpty) return null;

            return {
              "uri": uri,
              "type": (m["type"] ?? "video/mp4"),
              "isVideo": true,
            };
          }

          if (v is String) {
            final uri = absolutize(v);
            if (uri.isEmpty) return null;
            return {"uri": uri, "type": "video/mp4", "isVideo": true};
          }

          return null;
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    final combinedMedia = [...mappedImages, ...mappedVideos];

    // bedrooms normalize
    final rawBedrooms = raw["bedrooms"] ?? raw["bedrooms_label"] ?? "";
    String normalizedBedrooms = "";
    if (rawBedrooms != null) {
      final upper = rawBedrooms.toString().toUpperCase().trim();
      if (BEDROOM_OPTIONS.contains(upper)) {
        normalizedBedrooms = upper;
      } else if (RegExp(r"^\d+$").hasMatch(upper)) {
        final guess = "${upper}BHK";
        normalizedBedrooms = BEDROOM_OPTIONS.contains(guess) ? guess : "";
      }
    }

    setState(() {
      form = {
        ...form,
        ...Map<String, dynamic>.from(raw),
        "rent": INR_FMT(raw["rent"]),
        "deposit": INR_FMT(raw["deposit"]),
        "bedrooms": normalizedBedrooms,
        "images": combinedMedia,
        "sqft_area": (raw["sqft_area"] ?? "0").toString(),
        "floor": (raw["floor"] ?? "0").toString(),
        "availability_from": (raw["availability_from"] ?? "").toString(),
        "furnished_type": (raw["furnished_type"] ?? "UNFURNISHED").toString(),
        "living_preference": (raw["living_preference"] ?? "INDEPENDENT")
            .toString(),
        "tenant_preferences": (raw["tenant_preferences"] is List)
            ? List<String>.from(raw["tenant_preferences"])
            : List<String>.from(form["tenant_preferences"] ?? []),
        "amenities": (raw["amenities"] is List)
            ? List<String>.from(raw["amenities"])
            : List<String>.from(form["amenities"] ?? []),
        "rules": (raw["rules"] is List)
            ? List<String>.from(raw["rules"])
            : List<String>.from(form["rules"] ?? []),
      };
    });
  }

  /* -------------------- MEDIA ACTIONS -------------------- */

  Future<void> addMedia() async {
    final result = await _picker.pickMultiImage(imageQuality: 85);
    if (result.isEmpty) return;

    if (roomId == null || roomId!.trim().isEmpty) {
      _alert("Room missing", "Room ID not found, can't upload images.");
      return;
    }

    try {
      setState(() => _loading = true);

      final uploaded = <Map<String, dynamic>>[];

      for (final x in result) {
        final localPath = x.path;

        final img = await uploadRoomImageApi(
          roomId: roomId!,
          accessToken: accessToken,
          filePath: localPath,
        );

        final url = (img["url"] ?? img["uri"] ?? "").toString();
        final imageNo =
            (img["image_no"] ??
                    img["imageNo"] ??
                    img["image_id"] ??
                    img["id"] ??
                    img["media_id"])
                ?.toString();

        final uri = absolutize(url);

        if (uri.isNotEmpty) {
          uploaded.add({
            "uri": uri,
            "type": (img["type"] ?? "image/jpeg"),
            "isVideo": false,
            "image_no": imageNo,
          });
        }
      }

      if (uploaded.isEmpty) {
        _alert("Upload failed", "No images could be uploaded.");
        return;
      }

      final merged = [...(form["images"] as List), ...uploaded];
      if (merged.length > 60) merged.removeRange(60, merged.length);
      update({"images": merged});
    } catch (e) {
      _alert("Upload failed", e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _replaceImageAt(int idx) async {
    final list = List<Map<String, dynamic>>.from(
      (form["images"] as List).map((e) => Map<String, dynamic>.from(e)),
    );
    if (idx < 0 || idx >= list.length) return;

    final m = list[idx];
    final uri = absolutize((m["uri"] ?? m["url"] ?? "").toString());
    final isVid = isVideoUri(
      uri,
      type: (m["type"] ?? "").toString(),
      flag: m["isVideo"] == true,
    );

    if (isVid) {
      _alert("Not supported", "Video replacement is not supported yet.");
      return;
    }

    final imageNo = (m["image_no"] ?? "").toString().trim();
    if (imageNo.isEmpty) {
      _alert(
        "Missing image_no",
        "This image does not have an image_no, so it cannot be replaced",
      );
      return;
    }

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    if (roomId == null || roomId!.trim().isEmpty) {
      _alert("Room missing", "Room ID nahi mila.");
      return;
    }

    try {
      setState(() => _loading = true);

      final res = await replaceRoomImageApiPatch(
        roomId: roomId!,
        imageNo: imageNo,
        accessToken: accessToken,
        filePath: picked.path,
      );

      final newUrl = (res["url"] ?? res["uri"] ?? "").toString();
      final newUri = absolutize(newUrl);

      if (newUri.isEmpty) {
        _alert("Replace failed", "Server did not return a new URL.");
        return;
      }

      list[idx] = {
        ...m,
        "uri": newUri,
        "type": (res["type"] ?? m["type"] ?? "image/jpeg"),
        "isVideo": false,
        // image_no same
      };

      update({"images": list});
    } catch (e) {
      _alert("Replace failed", e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> removeMedia(int idx) async {
    final list = List<Map<String, dynamic>>.from(
      (form["images"] as List).map((e) => Map<String, dynamic>.from(e)),
    );
    if (idx < 0 || idx >= list.length) return;

    final m = list[idx];
    final rawUri = (m["uri"] ?? m["url"] ?? "").toString();
    final uri = absolutize(rawUri);
    final isVid = isVideoUri(
      uri,
      type: (m["type"] ?? "").toString(),
      flag: (m["isVideo"] == true),
    );

    // optimistic UI
    list.removeAt(idx);
    update({"images": list});

    if (roomId == null || roomId!.trim().isEmpty) return;

    try {
      setState(() => _loading = true);

      if (isVid) {
        await deleteRoomVideoApi(roomId: roomId!, accessToken: accessToken);
      } else {
        final imageNo = (m["image_no"] ?? "").toString().trim();
        if (imageNo.isEmpty) return;

        await deleteRoomImageApi(
          roomId: roomId!,
          imageNo: imageNo,
          accessToken: accessToken,
        );
      }
    } catch (e) {
      _alert("Delete Failed", "Failed to delete media on the server.\n$e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openGallery(String tappedUri) {
    final media = List<Map<String, dynamic>>.from(
      (form["images"] as List).map((e) => Map<String, dynamic>.from(e)),
    );

    final imagesOnly = media.where((m) {
      final u = absolutize((m["uri"] ?? "").toString());
      final isVid = isVideoUri(
        u,
        type: (m["type"] ?? "").toString(),
        flag: m["isVideo"] == true,
      );
      return !isVid;
    }).toList();

    final start = imagesOnly.indexWhere((m) {
      final u = absolutize((m["uri"] ?? "").toString());
      return u == tappedUri;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenGallery(
          T: T,
          items: imagesOnly,
          initialIndex: start < 0 ? 0 : start,
        ),
      ),
    );
  }

  /* -------------------- SAVE (PATCH /rooms/{room_id}) -------------------- */

  Future<void> onSave() async {
    if (!canSubmit) {
      _alert(
        "Missing info",
        "Please fill required fields and keep at least 5 images/videos.",
      );
      return;
    }

    if (roomId == null || roomId!.trim().isEmpty) {
      _alert("Error", "Room ID missing. Cannot update room.");
      return;
    }

    final bedroomsStr = (form["bedrooms"] ?? "").toString().trim();

    final payload = {
      "title": (form["title"] ?? "").toString().trim(),
      "description": (form["description"] ?? "").toString().trim(),
      "rent": fromINR(form["rent"]),
      "deposit": fromINR(form["deposit"]),
      "availability_from": (form["availability_from"] ?? "").toString(),
      "bedrooms": bedroomsStr,
      "sqft_area": int.tryParse((form["sqft_area"] ?? "0").toString()) ?? 0,
      "furnished_type": (form["furnished_type"] ?? "UNFURNISHED").toString(),
      "floor": int.tryParse((form["floor"] ?? "0").toString()) ?? 0,
      "living_preference": (form["living_preference"] ?? "INDEPENDENT")
          .toString(),
      "tenant_preferences": List<String>.from(form["tenant_preferences"] ?? []),
      "amenities": List<String>.from(form["amenities"] ?? []),
      "rules": List<String>.from(form["rules"] ?? []),
      "location_address": (form["location_address"] ?? "").toString().trim(),
      "location_lat": (form["location_lat"] is num) ? form["location_lat"] : 0,
      "location_long": (form["location_long"] is num)
          ? form["location_long"]
          : 0,
      "area": (form["area"] ?? "").toString().trim(),

      // optional: backend expects images list of URLs?
      // NOTE: image replace/delete/upload already handled via APIs.
      "images": (form["images"] as List)
          .map((m) {
            final mm = Map<String, dynamic>.from(m);
            final rawUri = (mm["uri"] ?? mm["url"] ?? "").toString();
            if (rawUri.isEmpty) return null;

            // skip local
            if (rawUri.startsWith("file://") || rawUri.startsWith("/")) {
              return null;
            }

            final u = absolutize(rawUri);
            if (!u.startsWith("http://") && !u.startsWith("https://")) {
              return null;
            }

            // only images (not video)
            final isVid = isVideoUri(
              u,
              type: (mm["type"] ?? "").toString(),
              flag: mm["isVideo"] == true,
            );
            if (isVid) return null;

            return u;
          })
          .whereType<String>()
          .toList(),
    };

    try {
      setState(() => _loading = true);

      await updateRoomApiPatch(
        roomId: roomId!,
        payload: payload,
        accessToken: accessToken,
      );

      if (!mounted) return;
      _alert(
        "Saved",
        "Room updated successfully.",
        onOk: () => Navigator.of(context).maybePop(),
      );
    } catch (e) {
      _alert("Update Failed", e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* -------------------- UI HELPERS -------------------- */

  void _alert(String title, String msg, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onOk?.call();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _mediaActionSheet(int idx) async {
    final media = List<Map<String, dynamic>>.from(
      (form["images"] as List).map((e) => Map<String, dynamic>.from(e)),
    );
    if (idx < 0 || idx >= media.length) return;

    final m = media[idx];
    final uri = absolutize((m["uri"] ?? m["url"] ?? "").toString());
    final isVid = isVideoUri(
      uri,
      type: (m["type"] ?? "").toString(),
      flag: m["isVideo"] == true,
    );

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(MdiIcons.eyeOutline, color: T.onBackground),
                  title: const Text("View Fullscreen"),
                  onTap: () {
                    Navigator.pop(context);
                    if (!isVid) _openGallery(uri);
                  },
                ),
                if (!isVid)
                  ListTile(
                    leading: Icon(
                      MdiIcons.imageEditOutline,
                      color: T.onBackground,
                    ),
                    title: const Text("Replace Image"),

                    onTap: () async {
                      Navigator.pop(context);
                      await _replaceImageAt(idx);
                    },
                  ),
                ListTile(
                  leading: Icon(MdiIcons.deleteOutline, color: T.error),
                  title: Text(
                    isVid ? "Delete Video" : "Delete Image",
                    style: TextStyle(color: T.error),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await removeMedia(idx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = List<Map<String, dynamic>>.from(
      (form["images"] as List).map((e) => Map<String, dynamic>.from(e)),
    );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: T.background,
          body: SafeArea(
            child: Column(
              children: [
                _HeaderBar(
                  T: T,
                  title: "Edit Room",
                  rightText: "Save",
                  rightDisabled: !canSubmit || _loading,
                  onBack: () => Navigator.of(context).maybePop(),
                  onRight: onSave,
                ),

                if (_loadErr != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: T.surface,
                    child: Row(
                      children: [
                        Icon(
                          MdiIcons.alertCircleOutline,
                          color: T.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loadErr!,
                            style: TextStyle(
                              color: T.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _fetchRoom,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      children: [
                        Section(
                          T: T,
                          title: "Basic Info",
                          child: Column(
                            children: [
                              Field(
                                T: T,
                                label: "Title*",
                                value: (form["title"] ?? "").toString(),
                                onChanged: (v) => update({"title": v}),
                                hint: "e.g. City View Residency",
                              ),
                              Field(
                                T: T,
                                label: "Description",
                                value: (form["description"] ?? "").toString(),
                                onChanged: (v) => update({"description": v}),
                                hint: "Short description",
                                multiline: true,
                              ),
                            ],
                          ),
                        ),

                        Section(
                          T: T,
                          title: "Pricing",
                          child: Row(
                            children: [
                              Expanded(
                                child: Field(
                                  T: T,
                                  label: "Rent / month*",
                                  value: INR_FMT(form["rent"]),
                                  onChanged: (v) => update({"rent": v}),
                                  hint: "₹",
                                  keyboard: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Field(
                                  T: T,
                                  label: "Deposit",
                                  value: INR_FMT(form["deposit"]),
                                  onChanged: (v) => update({"deposit": v}),
                                  hint: "₹",
                                  keyboard: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Section(
                          T: T,
                          title: "Availability & Specs",
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _DateBox(
                                      T: T,
                                      label: "Available from*",
                                      value: (form["availability_from"] ?? "")
                                          .toString(),
                                      onTap: pickDate,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownSelect(
                                      T: T,
                                      label: "Bedrooms*",
                                      value: (form["bedrooms"] ?? "")
                                          .toString(),
                                      options: BEDROOM_OPTIONS,
                                      onSelect: (v) => update({"bedrooms": v}),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Field(
                                      T: T,
                                      label: "Sqft Area",
                                      value: (form["sqft_area"] ?? "0")
                                          .toString(),
                                      onChanged: (v) => update({
                                        "sqft_area": v.replaceAll(
                                          RegExp(r"\D"),
                                          "",
                                        ),
                                      }),
                                      hint: "0",
                                      keyboard: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Field(
                                      T: T,
                                      label: "Floor",
                                      value: (form["floor"] ?? "0").toString(),
                                      onChanged: (v) => update({
                                        "floor": v.replaceAll(
                                          RegExp(r"\D"),
                                          "",
                                        ),
                                      }),
                                      hint: "0",
                                      keyboard: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownSelect(
                                      T: T,
                                      label: "Furnished Type",
                                      value:
                                          (form["furnished_type"] ??
                                                  "UNFURNISHED")
                                              .toString(),
                                      options: FURNISHED,
                                      onSelect: (v) =>
                                          update({"furnished_type": v}),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownSelect(
                                      T: T,
                                      label: "Living Preference",
                                      value:
                                          (form["living_preference"] ??
                                                  "INDEPENDENT")
                                              .toString(),
                                      options: LIV_PREFS,
                                      onSelect: (v) =>
                                          update({"living_preference": v}),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _Label(T: T, text: "Tenant Preferences"),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  alignment: WrapAlignment.start,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: TENANT_PREFS.map((tp) {
                                    final active =
                                        (form["tenant_preferences"] as List)
                                            .contains(tp);
                                    return InkWell(
                                      onTap: () => toggleTenant(tp),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: active ? T.primary : T.chipBg,
                                          border: Border.all(
                                            color: active
                                                ? T.primary
                                                : T.border,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          tp.replaceAll("_", " "),
                                          style: TextStyle(
                                            color: active
                                                ? T.onPrimary
                                                : T.chipText,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Section(
                          T: T,
                          title: "Location",
                          child: Column(
                            children: [
                              Field(
                                T: T,
                                label: "Area*",
                                value: (form["area"] ?? "").toString(),
                                onChanged: (v) => update({"area": v}),
                                hint: "e.g. Vijay Nagar",
                              ),
                              Field(
                                T: T,
                                label: "Full Address*",
                                value: (form["location_address"] ?? "")
                                    .toString(),
                                onChanged: (v) =>
                                    update({"location_address": v}),
                                hint: "House / Street / Landmark",
                              ),
                            ],
                          ),
                        ),

                        Section(
                          T: T,
                          title: "Amenities & Rules",
                          child: Column(
                            children: [
                              ChipInput(
                                T: T,
                                label: "Add Amenity",
                                value: amenityInput,
                                items: List<String>.from(
                                  form["amenities"] ?? [],
                                ),
                                onChanged: (v) =>
                                    setState(() => amenityInput = v),
                                onAdd: addAmenity,
                                onRemove: (i) {
                                  final items = List<String>.from(
                                    form["amenities"] ?? [],
                                  );
                                  items.removeAt(i);
                                  update({"amenities": items});
                                },
                              ),
                              ChipInput(
                                T: T,
                                label: "Add Rule",
                                value: ruleInput,
                                items: List<String>.from(form["rules"] ?? []),
                                onChanged: (v) => setState(() => ruleInput = v),
                                onAdd: addRule,
                                onRemove: (i) {
                                  final items = List<String>.from(
                                    form["rules"] ?? [],
                                  );
                                  items.removeAt(i);
                                  update({"rules": items});
                                },
                              ),
                            ],
                          ),
                        ),

                        Section(
                          T: T,
                          title: "Media (min 5) — ${media.length} selected",
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  alignment: WrapAlignment.start,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ...List.generate(media.length, (idx) {
                                      final m = media[idx];
                                      final raw = (m["uri"] ?? m["url"] ?? "")
                                          .toString();
                                      final uri = absolutize(raw);
                                      final isVid = isVideoUri(
                                        uri,
                                        type: (m["type"] ?? "").toString(),
                                        flag: m["isVideo"] == true,
                                      );

                                      return _MediaTile(
                                        T: T,
                                        uri: uri,
                                        isVideo: isVid,
                                        onTap: () {
                                          if (!isVid) _openGallery(uri);
                                        },
                                        onLongPress: () =>
                                            _mediaActionSheet(idx),
                                        onRemove: () => removeMedia(idx),
                                      );
                                    }),
                                    _AddTile(T: T, onTap: addMedia),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                media.length < 5
                                    ? "Please keep at least 5 images/videos."
                                    : "Looks good.",
                                style: TextStyle(
                                  color: media.length < 5 ? T.error : T.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Tip: Image pe long-press => Replace/Delete",
                                style: TextStyle(
                                  color: T.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ✅ loader overlay
        if (_loading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.12),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 20,
                      color: Colors.black12,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                    SizedBox(width: 10),
                    Text("Please wait..."),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/* ============================================================
   ✅ FULLSCREEN GALLERY (Swipe one-by-one)
   ============================================================ */

class FullscreenGallery extends StatefulWidget {
  const FullscreenGallery({
    super.key,
    required this.T,
    required this.items,
    required this.initialIndex,
  });

  final Tokens T;
  final List<Map<String, dynamic>> items; // images only
  final int initialIndex;

  @override
  State<FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<FullscreenGallery> {
  late final PageController _pc;
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
    _pc = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text("${_idx + 1} / $total"),
      ),
      body: PageView.builder(
        controller: _pc,
        itemCount: total,
        onPageChanged: (i) => setState(() => _idx = i),
        itemBuilder: (_, i) {
          final m = widget.items[i];
          final uri = absolutize((m["uri"] ?? "").toString());

          return Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: uri.startsWith("http")
                  ? Image.network(uri, fit: BoxFit.contain)
                  : Image.file(
                      File(uri.replaceFirst("file://", "")),
                      fit: BoxFit.contain,
                    ),
            ),
          );
        },
      ),
    );
  }
}

/* ============================================================
   ✅ WIDGETS
   ============================================================ */

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.T,
    required this.title,
    required this.rightText,
    required this.rightDisabled,
    required this.onBack,
    required this.onRight,
  });

  final Tokens T;
  final String title;
  final String rightText;
  final bool rightDisabled;
  final VoidCallback onBack;
  final VoidCallback onRight;

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
              width: 36,
              height: 36,
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
            height: 36,
            child: ElevatedButton(
              onPressed: rightDisabled ? null : onRight,
              style: ElevatedButton.styleFrom(
                backgroundColor: rightDisabled ? T.disabled : T.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                rightText,
                style: TextStyle(
                  color: rightDisabled ? T.onBackground : T.onPrimary,
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
    required this.T,
    required this.title,
    required this.child,
  });

  final Tokens T;
  final String title;
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

class _Label extends StatelessWidget {
  const _Label({required this.T, required this.text});
  final Tokens T;
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
  });

  final Tokens T;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final bool multiline;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: value)
      ..selection = TextSelection.collapsed(offset: value.length);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(T: T, text: label),
          const SizedBox(height: 6),
          Container(
            height: multiline ? 90 : 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: T.surface,
              border: Border.all(color: T.border),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: multiline ? Alignment.topLeft : Alignment.centerLeft,
            child: TextField(
              controller: ctrl,
              keyboardType: keyboard,
              maxLines: multiline ? null : 1,
              expands: multiline,
              style: TextStyle(color: T.onBackground, fontSize: 13),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: T.muted),
                border: InputBorder.none,
              ),
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
  });

  final Tokens T;
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: value)
      ..selection = TextSelection.collapsed(offset: value.length);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(T: T, text: label),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: T.surface,
                    border: Border.all(color: T.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: ctrl,
                    style: TextStyle(color: T.onBackground, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Type & add",
                      hintStyle: TextStyle(color: T.muted),
                      border: InputBorder.none,
                    ),
                    onChanged: onChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
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
  });

  final Tokens T;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelect;

  String pretty(String s) => s.replaceAll("_", " ");

  @override
  Widget build(BuildContext context) {
    final safeValue = options.contains(value)
        ? value
        : (options.isNotEmpty ? options.first : "");

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(T: T, text: label),
          const SizedBox(height: 6),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: T.surface,
              border: Border.all(color: T.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: safeValue,
                isExpanded: true,
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
                    child: Text(pretty(opt)),
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

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.T,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final Tokens T;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(T: T, text: label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 44,
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
                Text(
                  value,
                  style: TextStyle(
                    color: T.onBackground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.T,
    required this.uri,
    required this.isVideo,
    required this.onRemove,
    this.onTap,
    this.onLongPress,
  });

  final Tokens T;
  final String uri;
  final bool isVideo;
  final VoidCallback onRemove;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    Widget thumb;
    if (isVideo) {
      thumb = Container(
        color: Colors.black.withOpacity(0.70),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(MdiIcons.playCircleOutline, size: 26, color: Colors.white),
            const SizedBox(height: 2),
            const Text(
              "Video",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else {
      if (uri.startsWith("http")) {
        thumb = Image.network(uri, fit: BoxFit.cover);
      } else if (uri.startsWith("file://")) {
        thumb = Image.file(
          File(uri.replaceFirst("file://", "")),
          fit: BoxFit.cover,
        );
      } else if (uri.startsWith("/")) {
        thumb = Image.file(File(uri), fit: BoxFit.cover);
      } else {
        thumb = Container(color: T.surface);
      }
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 90,
        height: 70,
        decoration: BoxDecoration(
          color: T.surface,
          border: Border.all(color: T.border),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: thumb),
            if (isVideo)
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            Positioned(
              right: 4,
              top: 4,
              child: InkWell(
                onTap: onRemove,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.60),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.T, required this.onTap});
  final Tokens T;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 90,
        height: 70,
        decoration: BoxDecoration(
          color: T.surface,
          border: Border.all(color: T.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(MdiIcons.plus, color: T.onBackground, size: 22),
            const SizedBox(height: 4),
            Text(
              "Add",
              style: TextStyle(color: T.muted, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   ✅ REAL APIs (DIO)
   ============================================================ */

Options _authOptions(String? token) {
  final headers = <String, dynamic>{"Accept": "application/json"};
  if (token != null && token.trim().isNotEmpty) {
    headers["Authorization"] = "Bearer $token";
  }
  return Options(headers: headers);
}

/// ✅ GET /rooms/{room_id}
Future<Map<String, dynamic>> getRoomByIdApi({
  required String roomId,
  required String? accessToken,
}) async {
  final res = await _dio.get(
    API.getRoomByIdUrl(roomId),
    options: _authOptions(accessToken),
  );

  final data = res.data;
  if (data is Map<String, dynamic>) return data;

  if (data is Map) return Map<String, dynamic>.from(data);

  // sometimes API wraps in {data: {...}}
  if (data is String) {
    throw "Unexpected response: $data";
  }
  return <String, dynamic>{};
}

/// ✅ PATCH /rooms/{room_id}
Future<void> updateRoomApiPatch({
  required String roomId,
  required Map<String, dynamic> payload,
  required String? accessToken,
}) async {
  await _dio.patch(
    API.getUpdateRoomUrl(roomId),
    data: payload,
    options: _authOptions(accessToken),
  );
}

/// ✅ POST /rooms/{room_id}/images   (upload)
Future<Map<String, dynamic>> uploadRoomImageApi({
  required String roomId,
  required String? accessToken,
  required String filePath,
}) async {
  final file = await MultipartFile.fromFile(
    filePath,
    filename: filePath.split(Platform.pathSeparator).last,
  );

  final formData = FormData.fromMap({
    "file": file, // ✅ backend expects different key? change here if needed
  });

  final res = await _dio.post(
    API.getRoomImagesUrl(roomId),
    data: formData,
    options: _authOptions(accessToken),
  );

  // accept {url, image_no} or {data:{...}}
  final m = _asMap(res.data);
  if (m.containsKey("data")) return _asMap(m["data"]);
  return m;
}

/// ✅ PATCH /rooms/{room_id}/images/{image_no}  (replace/update)
Future<Map<String, dynamic>> replaceRoomImageApiPatch({
  required String roomId,
  required String imageNo,
  required String? accessToken,
  required String filePath,
}) async {
  final file = await MultipartFile.fromFile(
    filePath,
    filename: filePath.split(Platform.pathSeparator).last,
  );

  final formData = FormData.fromMap({
    "file": file, // ✅ backend expects different key? change here if needed
  });

  final res = await _dio.patch(
    API.getRoomImageByIdUrl(roomId, imageNo),
    data: formData,
    options: _authOptions(accessToken),
  );

  final m = _asMap(res.data);
  if (m.containsKey("data")) return _asMap(m["data"]);
  return m;
}

/// ✅ DELETE /rooms/{room_id}/images/{image_no}
Future<void> deleteRoomImageApi({
  required String roomId,
  required String imageNo,
  required String? accessToken,
}) async {
  await _dio.delete(
    API.getDeleteRoomImageUrl(roomId, imageNo),
    options: _authOptions(accessToken),
  );
}

/// ✅ DELETE /rooms/{room_id}/video
Future<void> deleteRoomVideoApi({
  required String roomId,
  required String? accessToken,
}) async {
  await _dio.delete(
    API.getDeleteRoomVideoUrl(roomId),
    options: _authOptions(accessToken),
  );
}
