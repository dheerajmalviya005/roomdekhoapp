import "dart:async";
import "package:flutter/material.dart";
import "package:material_design_icons_flutter/material_design_icons_flutter.dart";
import "package:video_player/video_player.dart";
import 'package:go_router/go_router.dart';

import '../../../../services/room_service.dart';
import '../../../../services/auth_service.dart';

/* ---------------- Utils ---------------- */

String INR(num? n) {
  final v = (n ?? 0).toDouble();
  return "₹${v.toStringAsFixed(0)}";
}

int? daysFromToday(String? iso) {
  if (iso == null || iso.trim().isEmpty) return null;
  final d = DateTime.tryParse(iso);
  if (d == null) return null;

  final today = DateTime.now();
  final t0 = DateTime(today.year, today.month, today.day);
  final d0 = DateTime(d.year, d.month, d.day);
  return d0.difference(t0).inDays;
}

bool isUpcoming(String? iso) {
  final diff = daysFromToday(iso);
  return diff != null && diff > 0;
}

bool isAvailableNow(String? iso) {
  final diff = daysFromToday(iso);
  return diff != null && diff <= 0;
}

String toTitle(String? s) {
  final x = (s ?? "").replaceAll("_", " ").toLowerCase();
  return x
      .split(" ")
      .map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1)))
      .join(" ");
}

// ✅ FIX: query-string safe (".mp4?token=..." also works)
bool isVideoUri(String uri) {
  final u = uri.toLowerCase().split("?").first;
  return u.endsWith(".mp4") ||
      u.endsWith(".mov") ||
      u.endsWith(".mkv") ||
      u.endsWith(".avi");
}

/* ---------------- Models ---------------- */

class RoomItem {
  final String id;
  final String title;
  final String? description;
  final String? locationAddress;
  final String? area;
  final num rent;
  final num deposit;
  final int? bedrooms;
  final num? sqftArea;
  final String? furnishedType;
  final int? floor;
  final String? availabilityFrom; // ISO
  final bool published;
  final List<String> amenities;
  final List<String> rules;
  final List<String> tenantPreferences;

  /// media items are urls (image/video)
  final List<String> media;

  RoomItem({
    required this.id,
    required this.title,
    required this.rent,
    required this.deposit,
    required this.published,
    required this.media,
    this.description,
    this.locationAddress,
    this.area,
    this.bedrooms,
    this.sqftArea,
    this.furnishedType,
    this.floor,
    this.availabilityFrom,
    this.amenities = const [],
    this.rules = const [],
    this.tenantPreferences = const [],
  });

  RoomItem copyWith({bool? published}) => RoomItem(
    id: id,
    title: title,
    rent: rent,
    deposit: deposit,
    published: published ?? this.published,
    media: media,
    description: description,
    locationAddress: locationAddress,
    area: area,
    bedrooms: bedrooms,
    sqftArea: sqftArea,
    furnishedType: furnishedType,
    floor: floor,
    availabilityFrom: availabilityFrom,
    amenities: amenities,
    rules: rules,
    tenantPreferences: tenantPreferences,
  );

  factory RoomItem.fromApiMap(Map<String, dynamic> data) {
    List<String> media = [];

    if (data['images'] is List) {
      for (final img in (data['images'] as List)) {
        String u = "";
        if (img is Map<String, dynamic>) {
          u = (img['url'] ?? '').toString();
        } else {
          u = img.toString();
        }
        if (u.trim().isNotEmpty) media.add(u.trim());
      }
    }

    if (data['videos'] is List) {
      for (final v in (data['videos'] as List)) {
        String u = "";
        if (v is Map<String, dynamic>) {
          u = (v['url'] ?? '').toString();
        } else {
          u = v.toString();
        }
        if (u.trim().isNotEmpty) media.add(u.trim());
      }
    }

    if (data['media'] is List) {
      for (final m in (data['media'] as List)) {
        String u = "";
        if (m is Map<String, dynamic>) {
          u = (m['url'] ?? m['path'] ?? '').toString();
        } else {
          u = m.toString();
        }
        if (u.trim().isNotEmpty) media.add(u.trim());
      }
    }

    media = media.toSet().toList();

    int? asInt(dynamic x) {
      if (x == null) return null;
      if (x is int) return x;
      final s = x.toString().trim();
      return int.tryParse(s);
    }

    double? asDouble(dynamic x) {
      if (x == null) return null;
      if (x is num) return x.toDouble();
      return double.tryParse(x.toString().trim());
    }

    bool published = false;
    final st = (data['status'] ?? data['published'] ?? '')
        .toString()
        .toUpperCase();
    if (data['published'] is bool) {
      published = data['published'] as bool;
    } else if (st == "ACTIVE" || st == "PUBLISHED" || st == "TRUE")
      published = true;

    return RoomItem(
      id: (data['id'] ?? data['room_id'] ?? '').toString(),
      title: (data['title'] ?? data['name'] ?? '').toString(),
      description: data['description']?.toString(),
      rent: (asDouble(data['rent']) ?? 0),
      deposit: (asDouble(data['deposit']) ?? 0),
      published: published,
      media: media,
      locationAddress: data['location_address']?.toString(),
      area: data['area']?.toString(),
      bedrooms: asInt(data['bedrooms'] ?? data['bedrooms_count']),
      sqftArea: asDouble(data['sqft_area']),
      furnishedType: data['furnished_type']?.toString(),
      floor: asInt(data['floor']),
      availabilityFrom: data['availability_from']?.toString(),
      amenities: (data['amenities'] is List)
          ? List<String>.from(data['amenities'])
          : const [],
      rules: (data['rules'] is List)
          ? List<String>.from(data['rules'])
          : const [],
      tenantPreferences: (data['tenant_preferences'] is List)
          ? List<String>.from(data['tenant_preferences'])
          : const [],
    );
  }
}

extension RoomItemToPrefill on RoomItem {
  Map<String, dynamic> toEditPrefill() {
    final imgs = <dynamic>[];
    final vids = <dynamic>[];

    // ✅ RoomItem me media field hona chahiye (List<String>)
    // agar aapke model me media ka naam different hai (images/mediaUrls) to bata dena
    for (final u in (media ?? <String>[])) {
      final uri = (u ?? "").toString().trim();
      if (uri.isEmpty) continue;

      final isVid = RegExp(
        r"\.(mp4|mov|mkv|avi)$",
        caseSensitive: false,
      ).hasMatch(uri);

      if (isVid) {
        vids.add({"url": uri, "type": "video/mp4"});
      } else {
        imgs.add({"url": uri, "type": "image/jpeg"});
      }
    }

    return {
      "id": id.toString(),
      "title": title ?? "",
      "description": description ?? "",
      "rent": rent ?? 0,
      "deposit": deposit ?? 0,
      "availability_from": availabilityFrom ?? "",
      "bedrooms": (bedrooms != null) ? "${bedrooms}BHK" : "",
      "sqft_area": sqftArea ?? 0,
      "furnished_type": furnishedType ?? "UNFURNISHED",
      "floor": floor ?? 0,
      "living_preference": "INDEPENDENT",
      "tenant_preferences": tenantPreferences ?? <String>[],
      "amenities": amenities ?? <String>[],
      "rules": rules ?? <String>[],
      "location_address": locationAddress ?? "",
      "area": area ?? "",
      "location_lat": 0,
      "location_long": 0,
      "images": imgs,
      "videos": vids,
    };
  }
}

/* ---------------- Chip config ---------------- */

class ChipCfg {
  final String id;
  final String label;
  final IconData icon;
  const ChipCfg(this.id, this.label, this.icon);
}

const CHIPS = <ChipCfg>[
  ChipCfg("all", "All", Icons.format_list_bulleted),
  ChipCfg("upcoming", "Upcoming", Icons.calendar_month),
  ChipCfg("unpublished", "Unpublished", Icons.visibility_off),
  ChipCfg("family", "Family-only", Icons.groups),
  ChipCfg("furnished", "Furnished", Icons.chair_alt),
];

class AppThemeT {
  // backgrounds
  final Color background;
  final Color elevated;
  final Color surface;
  final Color border;

  // text
  final Color onBackground;
  final Color muted;
  final Color chipBg;
  final Color chipText;
  final Color dotBackdrop;

  // brand
  final Color primary;
  final Color primaryVariant;
  final Color secondary;
  final Color accent;

  // statuses
  final Color success;
  final Color onSuccess;
  final Color info;
  final Color warning;
  final Color onWarning;

  // error
  final Color error;
  final Color onError;

  // buttons
  final Color onPrimary;

  const AppThemeT({
    required this.background,
    required this.elevated,
    required this.surface,
    required this.border,
    required this.onBackground,
    required this.muted,
    required this.chipBg,
    required this.chipText,
    required this.dotBackdrop,
    required this.primary,
    required this.primaryVariant,
    required this.secondary,
    required this.accent,
    required this.success,
    required this.onSuccess,
    required this.info,
    required this.warning,
    required this.onWarning,
    required this.error,
    required this.onError,
    required this.onPrimary,
  });

  static const light = AppThemeT(
    background: Color(0xFFF6F7FB),
    elevated: Colors.white,
    surface: Color(0xFFF8F9FA),
    border: Color(0xFFE5E7EB),
    onBackground: Color(0xFF111827),
    muted: Color(0xFF6B7280),
    chipBg: Color(0xFFF1F5F9),
    chipText: Color(0xFF334155),
    dotBackdrop: Color(0xAAFFFFFF),
    primary: Color(0xFF667EEA),
    primaryVariant: Color(0xFF764BA2),
    secondary: Color(0xFFF093FB),
    accent: Color(0xFF43E97B),
    success: Color(0xFF10B981),
    onSuccess: Colors.white,
    info: Color(0xFF3B82F6),
    warning: Color(0xFFF59E0B),
    onWarning: Color(0xFF111827),
    error: Color(0xFFEF4444),
    onError: Colors.white,
    onPrimary: Colors.white,
  );
}

/* ---------------- Confirm Modal ---------------- */

class ConfirmModal {
  static Future<void> show(
    BuildContext context, {
    String title = "Are you sure?",
    String subtitle = "",
    String confirmText = "Confirm",
    String cancelText = "Cancel",
    bool danger = false,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierLabel: "confirm_modal",
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, a1, a2) {
        return _ConfirmModalWidget(
          title: title,
          subtitle: subtitle,
          confirmText: confirmText,
          cancelText: cancelText,
          danger: danger,
          onConfirm: onConfirm,
          onCancel: onCancel,
        );
      },
      transitionBuilder: (context, anim, secAnim, child) {
        final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        final scale = Tween<double>(
          begin: 0.92,
          end: 1.0,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack));
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }
}

class _ConfirmModalWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String confirmText;
  final String cancelText;
  final bool danger;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const _ConfirmModalWidget({
    required this.title,
    required this.subtitle,
    required this.confirmText,
    required this.cancelText,
    required this.danger,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final T = AppThemeT.light;
    final iconColor = danger ? T.error : T.info;
    final iconBg = iconColor.withOpacity(0.10);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (onCancel == null) return;
                Navigator.of(context).pop();
                onCancel?.call();
              },
              child: const SizedBox(),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.88,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: T.elevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: T.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            danger
                                ? MdiIcons.trashCanOutline
                                : MdiIcons.informationOutline,
                            size: 20,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: T.onBackground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: T.muted,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _GhostBtn(
                          text: cancelText,
                          onTap: () {
                            Navigator.of(context).pop();
                            onCancel?.call();
                          },
                        ),
                        const SizedBox(width: 8),
                        _SolidBtn(
                          text: confirmText,
                          icon: danger
                              ? MdiIcons.deleteOutline
                              : MdiIcons.check,
                          bg: danger ? T.error : T.primary,
                          fg: danger ? T.onError : T.onPrimary,
                          onTap: () {
                            Navigator.of(context).pop();
                            onConfirm?.call();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _GhostBtn({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final T = AppThemeT.light;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: T.border, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: T.onBackground,
          ),
        ),
      ),
    );
  }
}

class _SolidBtn extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _SolidBtn({
    required this.text,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- Screen ---------------- */

class RenterHomeFlutter extends StatefulWidget {
  const RenterHomeFlutter({super.key});

  @override
  State<RenterHomeFlutter> createState() => _RenterHomeFlutterState();
}

class _RenterHomeFlutterState extends State<RenterHomeFlutter>
    with TickerProviderStateMixin {
  final AppThemeT T = AppThemeT.light;

  final TextEditingController _query = TextEditingController();
  String _chip = "all";
  final String _sortKey = "recent";

  bool _loading = true;
  bool _deleting = false;
  bool _publishing = false;

  List<RoomItem> _data = [];
  String? _errorMessage;

  late final AnimationController _fabCtl;
  late final Animation<double> _fabScale;

  final ScrollController _chipScroll = ScrollController();
  final Map<String, GlobalKey> _chipKeys = {};

  @override
  void initState() {
    super.initState();
    for (final c in CHIPS) {
      _chipKeys[c.id] = GlobalKey();
    }

    _fabCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fabScale = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _fabCtl, curve: Curves.easeInOut));
    _fabCtl.repeat(reverse: true);

    _loadRooms();
  }

  @override
  void dispose() {
    _fabCtl.dispose();
    _query.dispose();
    _chipScroll.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final accessToken = AuthService.getCurrentToken();

      if (accessToken == null || accessToken.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _errorMessage = "Authentication required. Please login again.";
        });
        return;
      }

      final response = await RoomService.fetchOwnerRooms(
        accessToken: accessToken,
        includeDeleted: false,
        sort: _sortKey,
        offset: 0,
        limit: 20,
      );

      if (!mounted) return;

      final items = response['items'] as List<dynamic>? ?? [];

      final List<RoomItem> loadedRooms = items
          .map<RoomItem>((item) {
            if (item is Map<String, dynamic>) {
              return RoomItem.fromApiMap(item);
            }
            return RoomItem(
              id: '',
              title: 'Invalid Room',
              rent: 0,
              deposit: 0,
              published: false,
              media: [],
            );
          })
          .where((room) => room.id.isNotEmpty)
          .toList();

      setState(() {
        _data = loadedRooms;
        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading rooms: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage =
            "Unable to load rooms. Please try again.\nError: ${e.toString()}";
      });
    }
  }

  Future<void> _togglePublish(String id) async {
    try {
      final roomIndex = _data.indexWhere((x) => x.id == id);
      if (roomIndex == -1) return;

      final room = _data[roomIndex];
      final newPublishedStatus = !room.published;

      final accessToken = AuthService.getCurrentToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception("Authentication required");
      }

      setState(() {
        _publishing = true;
      });

      final payload = {'status': newPublishedStatus ? 'ACTIVE' : 'INACTIVE'};

      await RoomService.updateRoom(id, payload, accessToken);

      if (mounted) {
        setState(() {
          _data[roomIndex] = room.copyWith(published: newPublishedStatus);
          _publishing = false;
        });
      }
    } catch (e) {
      print('❌ Error toggling publish status: $e');

      if (mounted) {
        setState(() {
          _publishing = false;
          _errorMessage = "Failed to update room status";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: ${e.toString()}'),
            backgroundColor: T.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteRoom(String id, String title) async {
    await ConfirmModal.show(
      context,
      title: "Delete listing?",
      subtitle: "\"$title\" will be permanently removed.",
      confirmText: _deleting ? "Deleting..." : "Delete",
      cancelText: "Cancel",
      danger: true,
      barrierDismissible: !_deleting,
      onCancel: _deleting ? null : () {},
      onConfirm: _deleting
          ? null
          : () async {
              setState(() => _deleting = true);

              try {
                final accessToken = AuthService.getCurrentToken();
                if (accessToken == null || accessToken.isEmpty) {
                  throw Exception("Authentication required");
                }

                await RoomService.deleteRoom(id, accessToken);

                if (!mounted) return;

                setState(() {
                  _data.removeWhere((x) => x.id == id);
                  _deleting = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Room deleted successfully'),
                    backgroundColor: T.success,
                  ),
                );
              } catch (e) {
                print('❌ Error deleting room: $e');

                if (!mounted) return;

                setState(() {
                  _deleting = false;
                  _errorMessage = "Unable to delete room. Please try again.";
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Delete failed: ${e.toString()}'),
                    backgroundColor: T.error,
                  ),
                );
              }
            },
    );
  }

  List<RoomItem> get _filtered {
    var list = List<RoomItem>.from(_data);

    final q = _query.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((x) {
        final bag = [
          x.title,
          x.description ?? "",
          x.locationAddress ?? "",
          x.area ?? "",
          x.amenities.join(" "),
          x.rules.join(" "),
          x.tenantPreferences.join(" "),
          x.furnishedType ?? "",
        ].join(" ").toLowerCase();
        return bag.contains(q);
      }).toList();
    }

    if (_chip == "upcoming") {
      list = list.where((x) => isUpcoming(x.availabilityFrom)).toList();
    }
    if (_chip == "unpublished") {
      list = list.where((x) => !x.published).toList();
    }
    if (_chip == "family") {
      list = list.where((x) => x.tenantPreferences.contains("FAMILY")).toList();
    }
    if (_chip == "furnished") {
      list = list
          .where((x) => (x.furnishedType ?? "").contains("FURNISHED"))
          .toList();
    }

    if (_sortKey == "rentAsc") list.sort((a, b) => a.rent.compareTo(b.rent));
    if (_sortKey == "rentDesc") list.sort((a, b) => b.rent.compareTo(a.rent));
    if (_sortKey == "areaAsc") {
      list.sort((a, b) => (a.area ?? "").compareTo(b.area ?? ""));
    }
    if (_sortKey == "areaDesc") {
      list.sort((a, b) => (b.area ?? "").compareTo(a.area ?? ""));
    }

    return list;
  }

  void _scrollChipIntoView(String id) {
    final key = _chipKeys[id];
    final chipCtx = key?.currentContext;
    if (chipCtx == null) return;

    final box = chipCtx.findRenderObject() as RenderBox?;
    if (box == null) return;

    final chipPos = box.localToGlobal(Offset.zero);
    final chipW = box.size.width;

    final screenW = MediaQuery.of(context).size.width;
    final targetCenter = chipPos.dx + chipW / 2;
    final desired = _chipScroll.offset + (targetCenter - screenW / 2);

    if (!_chipScroll.hasClients) return;

    _chipScroll.animateTo(
      desired.clamp(
        _chipScroll.position.minScrollExtent,
        _chipScroll.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: T.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  T: T,
                  onBellTap: () {
                    // TODO: navigation to NotificationScreen
                  },
                  onRefresh: _loadRooms,
                  isLoading: _loading,
                ),

                // chips strip
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: T.border),
                    color: Colors.transparent,
                  ),
                  child: SingleChildScrollView(
                    controller: _chipScroll,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: CHIPS.map((c) {
                        final active = _chip == c.id;
                        return Padding(
                          key: _chipKeys[c.id],
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  setState(() => _chip = c.id);
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    _scrollChipIntoView(c.id);
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: active ? T.primary : T.border,
                                    ),
                                    color: active ? T.primary : T.chipBg,
                                    boxShadow: active
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.14,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        c.icon,
                                        size: 14,
                                        color: active
                                            ? T.onPrimary
                                            : T.chipText,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        c.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: active
                                              ? T.onPrimary
                                              : T.chipText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (active)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  height: 2,
                                  width: 38,
                                  decoration: BoxDecoration(
                                    color: T.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: _loading
                      ? _LoadingState(T: T)
                      : (_errorMessage != null)
                      ? _ErrorState(
                          T: T,
                          message: _errorMessage!,
                          onClose: () => setState(() => _errorMessage = null),
                          onRetry: () {
                            setState(() => _errorMessage = null);
                            _loadRooms();
                          },
                        )
                      : (filtered.isEmpty)
                      ? _EmptyState(
                          T: T,
                          onRefresh: () {
                            setState(() {
                              _chip = "all";
                              _query.text = "";
                            });
                            _loadRooms();
                          },
                        )
                      : RefreshIndicator(
                          onRefresh: _loadRooms,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final item = filtered[i];
                              return _RoomCard(
                                T: T,
                                item: item,
                                onEdit: () {
                                  final accessToken =
                                      AuthService.getCurrentToken();

                                  context.push(
                                    "/editRoom/${item.id}",
                                    extra: {
                                      "roomId": item.id,
                                      "accessToken": accessToken,
                                      "prefill": item
                                          .toEditPrefill(), // ✅ FULL DATA PASS
                                    },
                                  );
                                },

                                onTogglePublish: () => _togglePublish(item.id),
                                onDelete: () =>
                                    _deleteRoom(item.id, item.title),
                                isPublishing: _publishing,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),

            // FAB (pulse)
            Positioned(
              right: 20,
              bottom: 90,
              child: ScaleTransition(
                scale: _fabScale,
                child: _Fab(T: T, onTap: () => context.push("/createRoom")),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- Widgets ---------------- */

class _Header extends StatelessWidget {
  final AppThemeT T;
  final VoidCallback onBellTap;
  final VoidCallback onRefresh;
  final bool isLoading;

  const _Header({
    required this.T,
    required this.onBellTap,
    required this.onRefresh,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back 👋",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: T.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: T.primary.withOpacity(0.12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        MdiIcons.mapMarker,
                        size: 16,
                        color: T.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Your Properties",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: T.onBackground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Manage your listings",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: T.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Refresh button and Bell badge
          Row(
            children: [
              const SizedBox(width: 8),

              // Bell badge
              InkWell(
                onTap: onBellTap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: T.accent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(MdiIcons.bellOutline, color: T.onPrimary, size: 18),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: T.error,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "3",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: T.onError,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final AppThemeT T;
  const _LoadingState({required this.T});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(MdiIcons.homeSearchOutline, size: 32, color: T.muted),
          const SizedBox(height: 8),
          Text(
            "Loading rooms...",
            style: TextStyle(
              color: T.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppThemeT T;
  final VoidCallback onRefresh;
  const _EmptyState({required this.T, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(MdiIcons.homeCityOutline, size: 46, color: T.muted),
            const SizedBox(height: 10),
            Text(
              "No rooms found right now",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: T.onBackground,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Try clearing filters or refresh to see latest rooms near you.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: T.muted),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: onRefresh,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: T.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(MdiIcons.refresh, size: 18, color: T.onPrimary),

                    const SizedBox(width: 6),
                    Text(
                      "Refresh rooms",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: T.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final AppThemeT T;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const _ErrorState({
    required this.T,
    required this.message,
    required this.onRetry,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: T.elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: T.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(MdiIcons.homeAlertOutline, size: 40, color: T.error),
              const SizedBox(height: 10),
              Text(
                "Cannot load rooms",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: T.onBackground,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: T.muted),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: T.border),
                          color: Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Close",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: T.onBackground,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: onRetry,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: T.primary,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              MdiIcons.refresh,
                              size: 16,
                              color: T.onPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Retry",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: T.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  final AppThemeT T;
  final VoidCallback onTap;
  const _Fab({required this.T, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: T.primary.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            gradient: LinearGradient(
              colors: [T.primary, T.primaryVariant],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(MdiIcons.plus, size: 28, color: T.onPrimary),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final AppThemeT T;
  final RoomItem item;
  final VoidCallback onEdit;
  final VoidCallback onTogglePublish;
  final VoidCallback onDelete;
  final bool isPublishing;

  const _RoomCard({
    required this.T,
    required this.item,
    required this.onEdit,
    required this.onTogglePublish,
    required this.onDelete,
    required this.isPublishing,
  });

  @override
  Widget build(BuildContext context) {
    final diff = daysFromToday(item.availabilityFrom);
    final upcoming = isUpcoming(item.availabilityFrom);
    final availableNow = isAvailableNow(item.availabilityFrom);
    const double imgH = 175;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: T.elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: T.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              height: imgH,
              child: Stack(
                children: [
                  _MediaCarousel(T: T, media: item.media),

                  Positioned(
                    left: 10,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [T.primary, T.primaryVariant],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            INR(item.rent),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "/month",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (availableNow || upcoming)
                    Positioned(
                      left: 10,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: availableNow ? T.success : T.info,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.20),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              availableNow ? "Available" : "In ${diff ?? 0}d",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: availableNow ? T.onSuccess : T.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ✅ NEW clean info layout
            _RoomInfoSection(T: T, item: item),

            // ✅ keep your actions row (Edit / Publish / Delete) neat
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: T.border),
                          color: T.surface,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              MdiIcons.pencilOutline,
                              size: 16,
                              color: T.onBackground,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Edit",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: T.onBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: isPublishing ? null : onTogglePublish,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: item.published
                                ? [T.warning, const Color(0xFFD95845)]
                                : [T.primary, T.primaryVariant],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isPublishing)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: item.published
                                      ? T.onWarning
                                      : T.onPrimary,
                                ),
                              )
                            else
                              Icon(
                                item.published
                                    ? MdiIcons.eyeOffOutline
                                    : MdiIcons.checkCircleOutline,
                                size: 16,
                                color: item.published
                                    ? T.onWarning
                                    : T.onPrimary,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              isPublishing
                                  ? "Updating..."
                                  : (item.published ? "Unpublish" : "Publish"),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: item.published
                                    ? T.onWarning
                                    : T.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: T.error.withOpacity(0.25)),
                        color: T.error.withOpacity(0.10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        MdiIcons.trashCanOutline,
                        size: 18,
                        color: T.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomInfoSection extends StatelessWidget {
  final AppThemeT T;
  final RoomItem item;

  const _RoomInfoSection({required this.T, required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item.title.isNotEmpty ? item.title : "Untitled";
    final loc =
        "${(item.area != null && item.area!.isNotEmpty) ? "${item.area} • " : ""}${item.locationAddress ?? "—"}";

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
              color: T.onBackground,
            ),
          ),
          const SizedBox(height: 4),

          // Location row
          Row(
            children: [
              Icon(MdiIcons.mapMarker, size: 14, color: T.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  loc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: T.muted),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Deposit pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: T.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: T.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(MdiIcons.shieldCheck, size: 14, color: T.accent),
                const SizedBox(width: 6),
                Text(
                  "Security Deposit: ${INR(item.deposit)}",
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: T.onBackground,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ✅ Specs grid (2x2) - cleaner than 1 row of 4 tiny cards
          Row(
            children: [
              Expanded(
                child: _MiniSpecRow(
                  T: T,
                  icon: MdiIcons.bed,
                  title: "${item.bedrooms ?? 0}",
                  subtitle: "Beds",
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MiniSpecRow(
                  T: T,
                  icon: MdiIcons.rulerSquare,
                  title: (item.sqftArea ?? 0).toStringAsFixed(0),
                  subtitle: "Sq.ft",
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MiniSpecRow(
                  T: T,
                  icon: MdiIcons.sofa,
                  title: item.furnishedType != null
                      ? toTitle(item.furnishedType).split(" ").first
                      : "N/A",
                  subtitle: "Furnishing",
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MiniSpecRow(
                  T: T,
                  icon: MdiIcons.stairs,
                  title: "${item.floor ?? 0}",
                  subtitle: "Floor",
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Chips row
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...item.tenantPreferences.take(1).map((pref) {
                return _ChipPill(
                  T: T,
                  text: toTitle(pref),
                  bg: T.surface,
                  border: T.border,
                  fg: T.onBackground,
                  icon: MdiIcons.accountGroupOutline,
                );
              }),
              if (item.amenities.isNotEmpty)
                _ChipPill(
                  T: T,
                  text: "${item.amenities.length} Amenities",
                  bg: T.accent.withOpacity(0.12),
                  border: T.accent.withOpacity(0.30),
                  fg: T.accent,
                  icon: MdiIcons.star,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniSpecRow extends StatelessWidget {
  final AppThemeT T;
  final IconData icon;
  final String title;
  final String subtitle;

  const _MiniSpecRow({
    required this.T,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: T.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: T.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: T.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isNotEmpty ? title : "—",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: T.onBackground,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: T.muted,
                    height: 1.0,
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

class _ChipPill extends StatelessWidget {
  final AppThemeT T;
  final String text;
  final Color bg;
  final Color border;
  final Color fg;
  final IconData icon;

  const _ChipPill({
    required this.T,
    required this.text,
    required this.bg,
    required this.border,
    required this.fg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- Media Carousel (Image + Video) ---------------- */

class _MediaCarousel extends StatefulWidget {
  final AppThemeT T;
  final List<String> media;

  const _MediaCarousel({required this.T, required this.media});

  @override
  State<_MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<_MediaCarousel> {
  late final PageController _pc;
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController();
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final T = widget.T;
    final items = widget.media.where((x) => x.trim().isNotEmpty).toList();

    if (items.isEmpty) {
      return Container(
        color: T.surface,
        alignment: Alignment.center,
        child: Icon(MdiIcons.imageOffOutline, size: 22, color: T.muted),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pc,
          itemCount: items.length,
          onPageChanged: (i) => setState(() => _idx = i),
          itemBuilder: (_, i) {
            final uri = items[i];

            if (isVideoUri(uri)) {
              return _VideoCover(uri: uri, active: _idx == i, T: T);
            }

            // ✅ image proper cover (no cut issues)
            return SizedBox.expand(
              child: Image.network(
                uri,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => Container(
                  color: T.surface,
                  alignment: Alignment.center,
                  child: Icon(MdiIcons.imageBrokenVariant, color: T.muted),
                ),
                loadingBuilder: (c, w, p) {
                  if (p == null) return w;
                  return Container(
                    color: T.surface,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: T.primary,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),

        // count badge
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  MdiIcons.imageMultipleOutline,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  "${(_idx + 1).clamp(1, items.length)}/${items.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        // dots
        Positioned(
          bottom: 1,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: T.dotBackdrop,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(items.length, (i) {
                  final active = i == _idx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: active ? 18 : 12,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: active ? T.primary : T.chipBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoCover extends StatefulWidget {
  final String uri;
  final bool active;
  final AppThemeT T;

  const _VideoCover({required this.uri, required this.active, required this.T});

  @override
  State<_VideoCover> createState() => _VideoCoverState();
}

class _VideoCoverState extends State<_VideoCover> {
  VideoPlayerController? _vc;
  bool _muted = false;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final vc = VideoPlayerController.networkUrl(Uri.parse(widget.uri));
      _vc = vc;

      await vc.initialize();
      vc.setLooping(true);

      if (widget.active && mounted) {
        await vc.play();
        _autoHide();
      }

      if (mounted) setState(() {});
    } catch (e) {
      // ignore
    }
  }

  void _autoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showControls = false);
    });
  }

  @override
  void didUpdateWidget(covariant _VideoCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    final vc = _vc;
    if (vc == null) return;

    if (widget.active) {
      if (!vc.value.isPlaying) vc.play();
      _autoHide();
    } else {
      if (vc.value.isPlaying) vc.pause();
      setState(() => _showControls = true);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _vc?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final T = widget.T;
    final vc = _vc;

    if (vc == null || !vc.value.isInitialized) {
      return Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: CircularProgressIndicator(strokeWidth: 2, color: T.primary),
      );
    }

    final v = vc.value;
    final dur = v.duration;
    final pos = v.position;

    return GestureDetector(
      onTap: () {
        setState(() => _showControls = !_showControls);
        if (_showControls) _autoHide();
      },
      child: Stack(
        children: [
          // ✅ cover video properly
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: v.size.width,
                height: v.size.height,
                child: VideoPlayer(vc),
              ),
            ),
          ),

          // controls overlay
          if (_showControls)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // center play/pause
                    Align(
                      alignment: Alignment.center,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () {
                          if (vc.value.isPlaying) {
                            vc.pause();
                          } else {
                            vc.play();
                            _autoHide();
                          }
                          setState(() {});
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            vc.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // bottom bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: Row(
                        children: [
                          Text(
                            _fmt(pos),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // seek bar
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2.5,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 10,
                                ),
                              ),
                              child: Slider(
                                min: 0,
                                max: dur.inMilliseconds.toDouble().clamp(
                                  1,
                                  double.infinity,
                                ),
                                value: pos.inMilliseconds.toDouble().clamp(
                                  0,
                                  dur.inMilliseconds.toDouble(),
                                ),
                                onChanged: (val) {
                                  vc.seekTo(
                                    Duration(milliseconds: val.toInt()),
                                  );
                                  setState(() {});
                                },
                                onChangeEnd: (_) => _autoHide(),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),
                          Text(
                            _fmt(dur),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(width: 6),

                          // mute
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              _muted = !_muted;
                              vc.setVolume(_muted ? 0 : 1);
                              setState(() {});
                              _autoHide();
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.20),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                _muted ? Icons.volume_off : Icons.volume_up,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // small "Video" pill
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.50),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.play_circle_outline,
                    size: 16,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "Video",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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
