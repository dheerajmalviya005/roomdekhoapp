import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/* -------------------- Responsive scaling -------------------- */
class R {
  final double w;
  final double h;
  R(this.w, this.h);

  double s(double v) => (w / 375.0) * v;
  double vs(double v) => (h / 667.0) * v;
  double ms(double v, [double factor = 0.5]) => v + (s(v) - v) * factor;
}

/* -------------------- Premium Shadows -------------------- */
List<BoxShadow> softShadow() => [
  BoxShadow(
    color: Colors.black.withOpacity(0.10),
    blurRadius: 16,
    offset: const Offset(0, 8),
  ),
  BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 6,
    offset: const Offset(0, 3),
  ),
];

List<BoxShadow> strongShadow() => [
  BoxShadow(
    color: Colors.black.withOpacity(0.14),
    blurRadius: 22,
    offset: const Offset(0, 10),
  ),
  BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 10,
    offset: const Offset(0, 5),
  ),
];

/* -------------------- Theme Tokens (match RN fields) -------------------- */
class Toks {
  final Color background;
  final Color elevated;
  final Color surface;
  final Color border;
  final Color chipBg;

  final Color primary;
  final Color onPrimary;

  final Color onBackground;
  final Color muted;

  final Color info;
  final Color success;
  final Color warning;
  final Color error;
  final Color disabled;
  final Color accent;

  const Toks({
    required this.background,
    required this.elevated,
    required this.surface,
    required this.border,
    required this.chipBg,
    required this.primary,
    required this.onPrimary,
    required this.onBackground,
    required this.muted,
    required this.info,
    required this.success,
    required this.warning,
    required this.error,
    required this.disabled,
    required this.accent,
  });

  factory Toks.fromTheme(BuildContext context) {
    final th = Theme.of(context);
    final cs = th.colorScheme;

    return Toks(
      background: cs.surface,
      elevated: cs.surfaceContainerHighest,
      surface: cs.surfaceContainerHighest.withOpacity(0.70),
      border: cs.outlineVariant.withOpacity(0.65),
      chipBg: cs.onSurface.withOpacity(0.10),
      primary: cs.primary,
      onPrimary: cs.onPrimary,
      onBackground: cs.onSurface,
      muted: cs.onSurface.withOpacity(0.60),
      info: const Color(0xFF3B82F6),
      success: const Color(0xFF22C55E),
      warning: const Color(0xFFF59E0B),
      error: const Color(0xFFEF4444),
      disabled: cs.onSurface.withOpacity(0.18),
      accent: cs.primary,
    );
  }
}

/* -------------------- Helpers (RN-like) -------------------- */
ImageProvider? toImg(dynamic val, {String? fallback}) {
  if (val == null || (val is String && val.trim().isEmpty)) {
    return fallback != null ? CachedNetworkImageProvider(fallback) : null;
  }
  if (val is String) {
    if (val.startsWith('http')) return CachedNetworkImageProvider(val);
    return AssetImage(val);
  }
  return fallback != null ? CachedNetworkImageProvider(fallback) : null;
}

/* -------------------- Models -------------------- */
class ProfileDocs {
  String? aadhaarFront;
  String? aadhaarBack;
  String? pan;
  ProfileDocs({this.aadhaarFront, this.aadhaarBack, this.pan});

  ProfileDocs copyWith({
    String? aadhaarFront,
    String? aadhaarBack,
    String? pan,
  }) {
    return ProfileDocs(
      aadhaarFront: aadhaarFront ?? this.aadhaarFront,
      aadhaarBack: aadhaarBack ?? this.aadhaarBack,
      pan: pan ?? this.pan,
    );
  }
}

class TenantProfile {
  String name;
  String email;
  String? phone;
  String avatar; // url
  String cover; // url
  List<String> prefs;
  int budgetMin;
  int budgetMax;
  String? city;
  ProfileDocs docs;
  double verified; // 0..1

  TenantProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.cover,
    required this.prefs,
    required this.budgetMin,
    required this.budgetMax,
    required this.city,
    required this.docs,
    required this.verified,
  });

  TenantProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatar,
    String? cover,
    List<String>? prefs,
    int? budgetMin,
    int? budgetMax,
    String? city,
    ProfileDocs? docs,
    double? verified,
  }) {
    return TenantProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      cover: cover ?? this.cover,
      prefs: prefs ?? this.prefs,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      city: city ?? this.city,
      docs: docs ?? this.docs,
      verified: verified ?? this.verified,
    );
  }
}

class KPIItem {
  final IconData icon;
  final String label;
  final int value;
  final Color tint;
  const KPIItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });
}

class Achievement {
  final String id;
  final IconData icon;
  final String label;

  const Achievement({
    required this.id,
    required this.icon,
    required this.label,
  });
}

/* -------------------- Fake Services (replace with your API) -------------------- */
class TenantService {
  static Future<Map<String, dynamic>> getMyProfile(
    TenantProfile current,
  ) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return {"ok": true};
  }

  static Future<String> uploadAvatar(String path) async {
    await Future.delayed(const Duration(milliseconds: 450));
    return "https://images.unsplash.com/photo-1554151228-14d9def656e4?q=80&w=200&auto=format&fit=crop";
  }

  static Future<String> uploadUserDoc(String kind, String path) async {
    await Future.delayed(const Duration(milliseconds: 450));
    return "https://images.unsplash.com/photo-1518972559570-7cc1309f3229?q=80&w=1200&auto=format&fit=crop";
  }

  static Future<void> deleteUserDoc(String kind) async {
    await Future.delayed(const Duration(milliseconds: 350));
  }

  static double computeVerification(TenantProfile p) {
    double v = 0.25;
    if ((p.docs.aadhaarFront ?? "").isNotEmpty) v += 0.20;
    if ((p.docs.aadhaarBack ?? "").isNotEmpty) v += 0.20;
    if ((p.docs.pan ?? "").isNotEmpty) v += 0.25;
    if ((p.avatar).isNotEmpty) v += 0.10;
    return v.clamp(0.0, 1.0);
  }
}

/* -------------------- Screen -------------------- */
class TenantProfileScreen extends StatefulWidget {
  const TenantProfileScreen({super.key});

  @override
  State<TenantProfileScreen> createState() => _TenantProfileScreenState();
}

class _TenantProfileScreenState extends State<TenantProfileScreen>
    with TickerProviderStateMixin {
  static const _tabBarSpaceBase = 70.0;

  bool pickerOpen = false;
  bool showLogout = false;
  bool showDelete = false;
  bool authExpired = false;

  bool notify = true;
  bool darkAmoled = false;

  bool openAadhaar = false;
  bool openPan = false;

  String? previewUrl;
  String? previewKind;

  bool confirmDeleteOpen = false;
  String? confirmDeleteKind;

  final ImagePicker _picker = ImagePicker();

  late final ScrollController _scrollCtrl;
  double _scrollY = 0;

  late TenantProfile profile;

  @override
  void initState() {
    super.initState();

    profile = TenantProfile(
      name: "Riya Sharma",
      email: "riya.sharma@example.com",
      phone: "+44 7712 345678",
      avatar:
          "https://images.unsplash.com/photo-1554151228-14d9def656e4?q=80&w=200&auto=format&fit=crop",
      cover:
          "https://images.unsplash.com/photo-1524234107056-1c1f7a4c3b2d?q=80&w=1400&auto=format&fit=crop",
      prefs: ["Ensuite", "Gym", "Laundry"],
      budgetMin: 750,
      budgetMax: 1000,
      city: "London",
      docs: ProfileDocs(aadhaarFront: null, aadhaarBack: null, pan: null),
      verified: 0.6,
    );

    _scrollCtrl = ScrollController();
    _scrollCtrl.addListener(() {
      if (!mounted) return;
      setState(() => _scrollY = _scrollCtrl.offset);
    });

    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final mapped = await TenantService.getMyProfile(profile);
      if (!mounted) return;
      if (mapped["__unauthorized"] == true) setState(() => authExpired = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<KPIItem> _kpis(Toks T) => [
    KPIItem(
      icon: MdiIcons.heartOutline,
      label: "Wishlist",
      value: 18,
      tint: T.info,
    ),
    KPIItem(
      icon: MdiIcons.calendarCheck,
      label: "Visits",
      value: 4,
      tint: T.success,
    ),
    KPIItem(
      icon: MdiIcons.fileCheckOutline,
      label: "Bookings",
      value: 1,
      tint: T.primary,
    ),
  ];

  final List<Achievement> _ach = [
    Achievement(id: "a1", icon: MdiIcons.starOutline, label: "Early Bird"),
    Achievement(
      id: "a2",
      icon: MdiIcons.accountCheckOutline,
      label: "Verified",
    ),
    Achievement(id: "a3", icon: MdiIcons.clockOutline, label: "On-Time"),
    Achievement(
      id: "a4",
      icon: MdiIcons.shieldCheckOutline,
      label: "Secure Payer",
    ),
  ];

  double get _SCROLL_H => 220;

  double _coverH(R r) {
    final t = (_scrollY / r.vs(_SCROLL_H)).clamp(0.0, 1.0);
    return lerpDouble(r.vs(220), r.vs(120), t)!;
  }

  double _titleOpacity(R r) {
    final a = r.vs(60);
    final b = r.vs(120);
    final y = _scrollY;
    if (y <= 0) return 0;
    if (y < a) return (y / a) * 0.3;
    if (y < b) return 0.3 + ((y - a) / (b - a)) * (1 - 0.3);
    return 1;
  }

  Future<void> _pickImage({required String source, String? docKind}) async {
    try {
      final XFile? picked = source == "camera"
          ? await _picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 80,
              maxWidth: 1024,
              maxHeight: 1024,
            )
          : await _picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 80,
              maxWidth: 1024,
              maxHeight: 1024,
            );

      if (picked == null) return;

      if (docKind == null) {
        final url = await TenantService.uploadAvatar(picked.path);
        setState(() {
          profile = profile.copyWith(
            avatar: url,
            verified: TenantService.computeVerification(
              profile.copyWith(avatar: url),
            ),
          );
        });
      } else {
        final url = await TenantService.uploadUserDoc(docKind, picked.path);
        final nextDocs = ProfileDocs(
          aadhaarFront: docKind == "aadhaarFront"
              ? url
              : profile.docs.aadhaarFront,
          aadhaarBack: docKind == "aadhaarBack"
              ? url
              : profile.docs.aadhaarBack,
          pan: docKind == "pan" ? url : profile.docs.pan,
        );
        final next = profile.copyWith(docs: nextDocs);
        setState(() {
          profile = next.copyWith(
            verified: TenantService.computeVerification(next),
          );
        });
      }
    } catch (_) {}
  }

  void _openPreview(String kind) {
    final url = (kind == "aadhaarFront")
        ? profile.docs.aadhaarFront
        : (kind == "aadhaarBack")
        ? profile.docs.aadhaarBack
        : profile.docs.pan;

    if (url == null) return;
    setState(() {
      previewUrl = url;
      previewKind = kind;
    });
  }

  void _requestDeleteDoc(String kind) {
    setState(() {
      previewUrl = null;
      previewKind = null;
      confirmDeleteOpen = true;
      confirmDeleteKind = kind;
    });
  }

  Future<void> _doDeleteDoc() async {
    final kind = confirmDeleteKind;
    setState(() {
      confirmDeleteOpen = false;
      confirmDeleteKind = null;
    });
    if (kind == null) return;

    await TenantService.deleteUserDoc(kind);

    final nextDocs = ProfileDocs(
      aadhaarFront: kind == "aadhaarFront" ? null : profile.docs.aadhaarFront,
      aadhaarBack: kind == "aadhaarBack" ? null : profile.docs.aadhaarBack,
      pan: kind == "pan" ? null : profile.docs.pan,
    );
    final next = profile.copyWith(docs: nextDocs);
    setState(() {
      profile = next.copyWith(
        verified: TenantService.computeVerification(next),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final r = R(mq.size.width, mq.size.height);
    final T = Toks.fromTheme(context);

    final verificationPc = ((profile.verified) * 100).round();
    final tabBarSpace = r.vs(_tabBarSpaceBase);

    final coverH = _coverH(r);
    final titleOpacity = _titleOpacity(r);

    return WillPopScope(
      onWillPop: () async => !authExpired,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: SafeArea(
          child: Scaffold(
            backgroundColor: T.background,
            body: Stack(
              children: [
                // Cover (top) - (your cover is currently disabled, so we also removed extra spacing)

                // Scroll content
                SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: EdgeInsets.only(bottom: tabBarSpace + r.vs(16)),
                  child: Column(
                    children: [
                      // ✅ FIX 1: top extra space removed
                      SizedBox(height: r.vs(12)),

                      _Card(
                        r: r,
                        T: T,
                        child: Column(
                          children: [
                            // avatar block
                            Align(
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  // ✅ FIX 2: circular centered avatar
                                  SizedBox(
                                    width: r.s(96),
                                    height: r.s(96),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ), // ✅ square radius 5
                                            boxShadow: strongShadow(),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.35,
                                              ),
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ), // ✅ square radius 5
                                            child: _NetImg(
                                              src: profile.avatar,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: r.s(-2),
                                          bottom: r.s(-2),
                                          child: GestureDetector(
                                            onTap: () => setState(
                                              () => pickerOpen = true,
                                            ),
                                            child: Container(
                                              width: r.s(34),
                                              height: r.s(34),
                                              decoration: BoxDecoration(
                                                color: T.primary,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: const Color.fromARGB(
                                                    255,
                                                    255,
                                                    255,
                                                    255,
                                                  ).withOpacity(0.30),
                                                  width: 1,
                                                ),
                                                boxShadow: strongShadow(),
                                              ),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                MdiIcons.camera,
                                                size: r.ms(16),
                                                color: T.onPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: r.vs(12)),
                                  Text(
                                    profile.name,
                                    style: TextStyle(
                                      fontSize: r.ms(18),
                                      fontWeight: FontWeight.w900,
                                      color: T.onBackground,
                                    ),
                                  ),
                                  SizedBox(height: r.vs(4)),
                                  Text(
                                    profile.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: r.ms(12),
                                      color: T.muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                  // verify card
                                  Container(
                                    margin: EdgeInsets.only(top: r.vs(12)),
                                    width: double.infinity,
                                    padding: EdgeInsets.all(r.s(12)),
                                    decoration: BoxDecoration(
                                      color: T.surface,
                                      borderRadius: BorderRadius.circular(
                                        r.s(16),
                                      ),
                                      border: Border.all(
                                        color: T.border.withOpacity(0.55),
                                        width: 1,
                                      ),
                                      boxShadow: softShadow(),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: r.s(34),
                                              height: r.s(34),
                                              decoration: BoxDecoration(
                                                color: T.elevated,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      r.s(12),
                                                    ),
                                                boxShadow: softShadow(),
                                              ),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                MdiIcons.shieldCheckOutline,
                                                size: r.ms(18),
                                                color: T.info,
                                              ),
                                            ),
                                            SizedBox(width: r.s(10)),
                                            Expanded(
                                              child: Text(
                                                "Profile verification",
                                                style: TextStyle(
                                                  color: T.onBackground,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: r.ms(13),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              "$verificationPc%",
                                              style: TextStyle(
                                                color: T.info,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: r.vs(10)),
                                        Container(
                                          height: r.vs(10),
                                          decoration: BoxDecoration(
                                            color: T.chipBg,
                                            borderRadius: BorderRadius.circular(
                                              r.s(999),
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: FractionallySizedBox(
                                            widthFactor: (verificationPc / 100)
                                                .clamp(0.0, 1.0),
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      r.s(999),
                                                    ),
                                                gradient: LinearGradient(
                                                  colors: [T.info, T.primary],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: r.vs(8)),
                                        Text(
                                          "Complete documents to increase trust & faster approvals",
                                          style: TextStyle(
                                            color: T.muted,
                                            fontWeight: FontWeight.w700,
                                            fontSize: r.ms(11),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // KPI row
                            SizedBox(height: r.vs(12)),
                            Row(
                              children: _kpis(T).map((k) {
                                return Expanded(
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: r.s(4),
                                    ),
                                    padding: EdgeInsets.all(r.s(10)),
                                    decoration: BoxDecoration(
                                      color: T.surface,
                                      borderRadius: BorderRadius.circular(
                                        r.s(16),
                                      ),
                                      border: Border.all(
                                        color: T.border.withOpacity(0.55),
                                        width: 1,
                                      ),
                                      boxShadow: softShadow(),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: r.s(34),
                                          height: r.s(34),
                                          decoration: BoxDecoration(
                                            color: T.elevated,
                                            borderRadius: BorderRadius.circular(
                                              r.s(12),
                                            ),
                                            boxShadow: softShadow(),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            k.icon,
                                            size: r.ms(18),
                                            color: k.tint,
                                          ),
                                        ),
                                        SizedBox(height: r.vs(8)),
                                        Text(
                                          "${k.value}",
                                          style: TextStyle(
                                            fontSize: r.ms(16),
                                            fontWeight: FontWeight.w900,
                                            color: T.onBackground,
                                          ),
                                        ),
                                        SizedBox(height: r.vs(2)),
                                        Text(
                                          k.label,
                                          style: TextStyle(
                                            fontSize: r.ms(11),
                                            fontWeight: FontWeight.w700,
                                            color: T.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            // quick row
                            SizedBox(height: r.vs(10)),
                            Row(
                              children: [
                                Expanded(
                                  child: _GhostBtn(
                                    r: r,
                                    T: T,
                                    icon: MdiIcons.heartOutline,
                                    label: "Wishlist",
                                    onTap: () {},
                                  ),
                                ),
                                Expanded(
                                  child: _GhostBtn(
                                    r: r,
                                    T: T,
                                    icon: MdiIcons.calendarCheck,
                                    label: "Visits",
                                    onTap: () {},
                                  ),
                                ),
                                Expanded(
                                  child: _GhostBtn(
                                    r: r,
                                    T: T,
                                    icon: MdiIcons.fileCheckOutline,
                                    label: "Bookings",
                                    onTap: () {},
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      _Section(
                        r: r,
                        T: T,
                        title: "Contact",
                        child: Column(
                          children: [
                            _RowIconText(
                              r: r,
                              T: T,
                              icon: MdiIcons.emailOutline,
                              text: profile.email,
                            ),
                            _RowIconText(
                              r: r,
                              T: T,
                              icon: MdiIcons.phone,
                              text: profile.phone ?? "Add phone",
                              last: true,
                            ),
                          ],
                        ),
                      ),

                      _Section(
                        r: r,
                        T: T,
                        title: "Preferences",
                        child: Column(
                          children: [
                            _PrefRow(
                              r: r,
                              T: T,
                              icon: MdiIcons.cash,
                              label: "Budget",
                              value:
                                  "£${profile.budgetMin} – £${profile.budgetMax} / mo",
                            ),
                            _PrefRow(
                              r: r,
                              T: T,
                              icon: MdiIcons.mapMarker,
                              label: "City",
                              value: profile.city ?? "Add city",
                              last: true,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: r.s(12),
                                vertical: r.vs(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Amenities",
                                    style: TextStyle(
                                      color: T.muted,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: r.vs(10)),
                                  Wrap(
                                    spacing: r.s(8),
                                    runSpacing: r.vs(8),
                                    children: (profile.prefs.isNotEmpty)
                                        ? profile.prefs
                                              .map(
                                                (p) => Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: r.s(12),
                                                    vertical: r.vs(8),
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: T.surface,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          r.s(999),
                                                        ),
                                                    border: Border.all(
                                                      color: T.border
                                                          .withOpacity(0.55),
                                                      width: 1,
                                                    ),
                                                    boxShadow: softShadow(),
                                                  ),
                                                  child: Text(
                                                    p,
                                                    style: TextStyle(
                                                      color: T.onBackground,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: r.ms(12),
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList()
                                        : [
                                            Text(
                                              "Add amenities",
                                              style: TextStyle(
                                                color: T.muted,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      _Section(
                        r: r,
                        T: T,
                        title: "Achievements",
                        child: SizedBox(
                          height: r.vs(120),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(
                              horizontal: r.s(12),
                              vertical: r.vs(12),
                            ),
                            itemCount: _ach.length,
                            itemBuilder: (ctx, i) {
                              final a = _ach[i];
                              return Container(
                                width: r.s(108),
                                margin: EdgeInsets.only(right: r.s(12)),
                                padding: EdgeInsets.all(r.s(12)),
                                decoration: BoxDecoration(
                                  color: T.surface,
                                  borderRadius: BorderRadius.circular(r.s(16)),
                                  border: Border.all(
                                    color: T.border.withOpacity(0.55),
                                    width: 1,
                                  ),
                                  boxShadow: softShadow(),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: r.s(36),
                                      height: r.s(36),
                                      decoration: BoxDecoration(
                                        color: T.elevated,
                                        borderRadius: BorderRadius.circular(
                                          r.s(14),
                                        ),
                                        boxShadow: softShadow(),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        a.icon,
                                        size: r.ms(18),
                                        color: T.primary,
                                      ),
                                    ),
                                    SizedBox(height: r.vs(8)),
                                    Text(
                                      a.label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: T.onBackground,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      _Section(
                        r: r,
                        T: T,
                        title: "Documents",
                        child: Column(
                          children: [
                            _DocRow(
                              r: r,
                              T: T,
                              name: "Aadhaar",
                              status:
                                  (profile.docs.aadhaarFront != null ||
                                      profile.docs.aadhaarBack != null)
                                  ? "Verified"
                                  : "Pending",
                              last: false,
                              right: Row(
                                children: [
                                  _SmallBtn(
                                    r: r,
                                    T: T,
                                    icon: MdiIcons.cameraPlusOutline,
                                    label: openAadhaar
                                        ? "Hide"
                                        : ((profile.docs.aadhaarFront != null ||
                                                  profile.docs.aadhaarBack !=
                                                      null)
                                              ? "Replace"
                                              : "Upload"),
                                    onTap: () {
                                      setState(() {
                                        openAadhaar = !openAadhaar;
                                        openPan = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            if (openAadhaar)
                              _ThumbRow(
                                r: r,
                                T: T,
                                items: [
                                  _ThumbItem(
                                    label: "Front",
                                    url: profile.docs.aadhaarFront,
                                    kind: "aadhaarFront",
                                  ),
                                  _ThumbItem(
                                    label: "Back",
                                    url: profile.docs.aadhaarBack,
                                    kind: "aadhaarBack",
                                  ),
                                ],
                                onTap: _openPreview,
                                onAdd: (kind) => _pickImage(
                                  source: "gallery",
                                  docKind: kind,
                                ),
                                onDelete: _requestDeleteDoc,
                              ),
                            _DocRow(
                              r: r,
                              T: T,
                              name: "PAN",
                              status: (profile.docs.pan != null)
                                  ? "Verified"
                                  : "Pending",
                              last: true,
                              right: _SmallBtn(
                                r: r,
                                T: T,
                                icon: MdiIcons.cloudUploadOutline,
                                label: openPan
                                    ? "Hide"
                                    : ((profile.docs.pan != null)
                                          ? "Replace"
                                          : "Upload"),
                                onTap: () {
                                  setState(() {
                                    openPan = !openPan;
                                    openAadhaar = false;
                                  });
                                },
                              ),
                            ),
                            if (openPan)
                              _ThumbRow(
                                r: r,
                                T: T,
                                items: [
                                  _ThumbItem(
                                    label: "PAN",
                                    url: profile.docs.pan,
                                    kind: "pan",
                                  ),
                                ],
                                onTap: _openPreview,
                                onAdd: (kind) => _pickImage(
                                  source: "gallery",
                                  docKind: kind,
                                ),
                                onDelete: _requestDeleteDoc,
                              ),
                          ],
                        ),
                      ),

                      _Section(
                        r: r,
                        T: T,
                        title: "App & Account",
                        child: Column(
                          children: [
                            _ListItem(
                              r: r,
                              T: T,
                              icon: MdiIcons.accountEdit,
                              label: "Edit Profile",
                              onTap: () {},
                              last: false,
                            ),
                            _ListItem(
                              r: r,
                              T: T,
                              icon: MdiIcons.shieldLockOutline,
                              label: "Privacy & security",
                              onTap: () {},
                              last: false,
                            ),
                            _ListSwitch(
                              r: r,
                              T: T,
                              icon: MdiIcons.bellOutline,
                              label: "Notifications",
                              value: notify,
                              onChanged: (v) => setState(() => notify = v),
                            ),
                            _ListSwitch(
                              r: r,
                              T: T,
                              icon: MdiIcons.themeLightDark,
                              label: "AMOLED dark",
                              sub: "Extra-deep dark theme",
                              value: darkAmoled,
                              onChanged: (v) => setState(() => darkAmoled = v),
                              last: true,
                            ),
                          ],
                        ),
                      ),

                      _Card(
                        r: r,
                        T: T,
                        child: Column(
                          children: [
                            _DangerBtn(
                              r: r,
                              T: T,
                              icon: MdiIcons.logout,
                              label: "Logout",
                              onTap: () => setState(() => showLogout = true),
                            ),
                            SizedBox(height: r.vs(10)),
                            _DangerBtn(
                              r: r,
                              T: T,
                              icon: MdiIcons.deleteOutline,
                              label: "Delete account",
                              onTap: () => setState(() => showDelete = true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Photo source bottom sheet
                if (pickerOpen)
                  _PhotoSourceSheet(
                    T: T,
                    onClose: () => setState(() => pickerOpen = false),
                    onPickCamera: () async {
                      setState(() => pickerOpen = false);
                      await _pickImage(source: "camera");
                    },
                    onPickGallery: () async {
                      setState(() => pickerOpen = false);
                      await _pickImage(source: "gallery");
                    },
                  ),

                // Image preview modal
                if (previewUrl != null)
                  _ImagePreviewModal(
                    T: T,
                    url: previewUrl!,
                    onClose: () => setState(() {
                      previewUrl = null;
                      previewKind = null;
                    }),
                    onDelete: () {
                      if (previewKind != null) _requestDeleteDoc(previewKind!);
                    },
                  ),

                // Confirm delete doc
                _ConfirmModal(
                  T: T,
                  open: confirmDeleteOpen,
                  icon: MdiIcons.deleteOutline,
                  title: "Delete document?",
                  message: "This will remove the selected document.",
                  confirmLabel: "Delete",
                  tone: _ConfirmTone.danger,
                  onCancel: () => setState(() {
                    confirmDeleteOpen = false;
                    confirmDeleteKind = null;
                  }),
                  onConfirm: _doDeleteDoc,
                ),

                // Confirm logout
                _ConfirmModal(
                  T: T,
                  open: showLogout,
                  icon: MdiIcons.logout,
                  title: "Logout?",
                  message:
                      "You’ll need to sign in again to access your account.",
                  confirmLabel: "Logout",
                  tone: _ConfirmTone.warning,
                  onCancel: () => setState(() => showLogout = false),
                  onConfirm: () {
                    setState(() => showLogout = false);
                    // TODO: logout + navigate to login
                  },
                ),

                // Confirm delete account
                _ConfirmModal(
                  T: T,
                  open: showDelete,
                  icon: MdiIcons.deleteOutline,
                  title: "Delete account?",
                  message:
                      "This permanently removes your account and all data. This action cannot be undone.",
                  confirmLabel: "Delete",
                  tone: _ConfirmTone.danger,
                  onCancel: () => setState(() => showDelete = false),
                  onConfirm: () => setState(() => showDelete = false),
                ),

                // Auth expired modal (blocks back)
                if (authExpired)
                  _AuthExpiredModal(
                    T: T,
                    onOK: () {
                      setState(() => authExpired = false);
                      // TODO: logout + navigate to login
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* -------------------- UI Pieces -------------------- */
class _NetImg extends StatelessWidget {
  final String src;
  final BoxFit fit;
  const _NetImg({required this.src, required this.fit});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: src,
      fit: fit,
      placeholder: (_, __) => Container(color: const Color(0xFFFFFFFF)),
      errorWidget: (_, __, ___) => Container(color: const Color(0xFFFFFFFF)),
    );
  }
}

class _Card extends StatelessWidget {
  final R r;
  final Toks T;
  final Widget child;
  const _Card({required this.r, required this.T, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(r.s(16), r.vs(10), r.s(16), 0),
      padding: EdgeInsets.all(r.s(12)),
      decoration: BoxDecoration(
        color: T.elevated,
        borderRadius: BorderRadius.circular(r.s(18)),
        border: Border.all(color: T.border.withOpacity(0.55), width: 1),
        boxShadow: strongShadow(),
      ),
      child: child,
    );
  }
}

class _Section extends StatelessWidget {
  final R r;
  final Toks T;
  final String title;
  final Widget child;
  const _Section({
    required this.r,
    required this.T,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: r.vs(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: r.s(16)),
            child: Text(
              title,
              style: TextStyle(
                color: T.onBackground,
                fontWeight: FontWeight.w900,
                fontSize: r.ms(14),
              ),
            ),
          ),
          SizedBox(height: r.vs(10)),
          Container(
            margin: EdgeInsets.symmetric(horizontal: r.s(16)),
            decoration: BoxDecoration(
              color: T.elevated,
              borderRadius: BorderRadius.circular(r.s(18)),
              border: Border.all(color: T.border.withOpacity(0.55), width: 1),
              boxShadow: softShadow(),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _RowIconText extends StatelessWidget {
  final R r;
  final Toks T;
  final IconData icon;
  final String text;
  final bool last;
  const _RowIconText({
    required this.r,
    required this.T,
    required this.icon,
    required this.text,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.vs(12)),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: last ? Colors.transparent : T.border.withOpacity(0.55),
            width: last ? 0 : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: r.s(38),
            height: r.s(38),
            margin: EdgeInsets.only(right: r.s(10)),
            decoration: BoxDecoration(
              color: T.surface,
              borderRadius: BorderRadius.circular(r.s(12)),
              boxShadow: softShadow(),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: r.ms(18), color: T.onBackground),
          ),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: T.onBackground,
                fontWeight: FontWeight.w900,
                fontSize: r.ms(13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  final R r;
  final Toks T;
  final IconData icon;
  final String label;
  final String value;
  final bool last;
  const _PrefRow({
    required this.r,
    required this.T,
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.vs(12)),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: last ? Colors.transparent : T.border.withOpacity(0.55),
            width: last ? 0 : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: r.s(38),
            height: r.s(38),
            margin: EdgeInsets.only(right: r.s(10)),
            decoration: BoxDecoration(
              color: T.surface,
              borderRadius: BorderRadius.circular(r.s(12)),
              boxShadow: softShadow(),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: r.ms(18), color: T.onBackground),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: r.ms(13),
                    color: T.onBackground,
                  ),
                ),
                SizedBox(height: r.vs(2)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: r.ms(11),
                    color: T.muted,
                    fontWeight: FontWeight.w700,
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

class _ListItem extends StatelessWidget {
  final R r;
  final Toks T;
  final IconData icon;
  final String label;
  final String? sub;
  final VoidCallback? onTap;
  final bool last;
  const _ListItem({
    required this.r,
    required this.T,
    required this.icon,
    required this.label,
    this.sub,

    this.onTap,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: r.s(12),
            vertical: r.vs(12),
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: last ? Colors.transparent : T.border.withOpacity(0.55),
                width: last ? 0 : 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: r.s(38),
                height: r.s(38),
                margin: EdgeInsets.only(right: r.s(10)),
                decoration: BoxDecoration(
                  color: T.surface,
                  borderRadius: BorderRadius.circular(r.s(12)),
                  boxShadow: softShadow(),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: r.ms(18), color: T.onBackground),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: r.ms(13),
                        color: T.onBackground,
                      ),
                    ),
                    if (sub != null) ...[
                      SizedBox(height: r.vs(2)),
                      Text(
                        sub!,
                        style: TextStyle(
                          fontSize: r.ms(11),
                          color: T.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(MdiIcons.chevronRight, size: r.ms(22), color: T.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListSwitch extends StatelessWidget {
  final R r;
  final Toks T;
  final IconData icon;
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  const _ListSwitch({
    required this.r,
    required this.T,
    required this.icon,
    required this.label,
    this.sub,
    required this.value,
    required this.onChanged,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.vs(12)),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: last ? Colors.transparent : T.border.withOpacity(0.55),
            width: last ? 0 : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: r.s(38),
            height: r.s(38),
            margin: EdgeInsets.only(right: r.s(10)),
            decoration: BoxDecoration(
              color: T.surface,
              borderRadius: BorderRadius.circular(r.s(12)),
              boxShadow: softShadow(),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: r.ms(18), color: T.onBackground),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: r.ms(13),
                    color: T.onBackground,
                  ),
                ),
                if (sub != null) ...[
                  SizedBox(height: r.vs(2)),
                  Text(
                    sub!,
                    style: TextStyle(
                      fontSize: r.ms(11),
                      color: T.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: T.onPrimary,
            activeTrackColor: T.primary,
            inactiveThumbColor: Colors.grey.shade300,
            inactiveTrackColor: T.disabled,
          ),
        ],
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  final R r;
  final Toks T;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GhostBtn({
    required this.r,
    required this.T,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: r.s(4)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r.s(14)),
          child: Container(
            height: r.vs(42),
            decoration: BoxDecoration(
              color: T.surface,
              borderRadius: BorderRadius.circular(r.s(14)),
              border: Border.all(color: T.border.withOpacity(0.55), width: 1),
              boxShadow: softShadow(),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: r.ms(16), color: T.onBackground),
                SizedBox(width: r.s(6)),
                Text(
                  label,
                  style: TextStyle(
                    color: T.onBackground,
                    fontWeight: FontWeight.w900,
                    fontSize: r.ms(12),
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

class _SmallBtn extends StatelessWidget {
  final R r;
  final Toks T;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SmallBtn({
    required this.r,
    required this.T,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(r.s(12)),
      child: Container(
        height: r.vs(32),
        padding: EdgeInsets.symmetric(horizontal: r.s(10)),
        decoration: BoxDecoration(
          color: T.accent,
          borderRadius: BorderRadius.circular(r.s(12)),
          boxShadow: softShadow(),
        ),
        child: Row(
          children: [
            Icon(icon, size: r.ms(14), color: T.onPrimary),
            SizedBox(width: r.s(6)),
            Text(
              label,
              style: TextStyle(
                color: T.onPrimary,
                fontWeight: FontWeight.w900,
                fontSize: r.ms(11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final R r;
  final Toks T;
  final String name;
  final String status;
  final bool last;
  final Widget right;

  const _DocRow({
    required this.r,
    required this.T,
    required this.name,
    required this.status,
    required this.last,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    final ok = status == "Verified";
    final tint = ok ? T.success : T.warning;
    final icon = ok ? MdiIcons.checkDecagramOutline : MdiIcons.clockOutline;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.vs(12)),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: last ? Colors.transparent : T.border.withOpacity(0.55),
            width: last ? 0 : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: r.s(38),
            height: r.s(38),
            margin: EdgeInsets.only(right: r.s(10)),
            decoration: BoxDecoration(
              color: T.surface,
              borderRadius: BorderRadius.circular(r.s(12)),
              boxShadow: softShadow(),
            ),
            alignment: Alignment.center,
            child: Icon(
              MdiIcons.fileDocumentOutline,
              size: r.ms(18),
              color: T.onBackground,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: r.ms(13),
                    color: T.onBackground,
                  ),
                ),
                SizedBox(height: r.vs(2)),
                Row(
                  children: [
                    Icon(icon, size: r.ms(14), color: tint),
                    SizedBox(width: r.s(6)),
                    Text(
                      status,
                      style: TextStyle(
                        color: tint,
                        fontWeight: FontWeight.w900,
                        fontSize: r.ms(11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          right,
        ],
      ),
    );
  }
}

class _ThumbItem {
  final String label;
  final String? url;
  final String kind;
  const _ThumbItem({
    required this.label,
    required this.url,
    required this.kind,
  });
}

class _ThumbRow extends StatelessWidget {
  final R r;
  final Toks T;
  final List<_ThumbItem> items;
  final void Function(String kind) onTap;
  final void Function(String kind) onAdd;
  final void Function(String kind) onDelete;

  const _ThumbRow({
    required this.r,
    required this.T,
    required this.items,
    required this.onTap,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(12), 0, r.s(12), r.vs(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(items.length, (i) {
          final it = items[i];
          final has = it.url != null;

          return Expanded(
            child: Padding(
              // ✅ FIX 3: Aadhaar front/back space
              padding: EdgeInsets.only(
                right: i == items.length - 1 ? 0 : r.s(10),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => has ? onTap(it.kind) : onAdd(it.kind),
                    onLongPress: () => has ? onDelete(it.kind) : null,
                    child: Container(
                      height: r.s(86),
                      decoration: BoxDecoration(
                        color: T.surface,
                        borderRadius: BorderRadius.circular(r.s(14)),
                        border: Border.all(
                          color: T.border.withOpacity(0.55),
                          width: 1,
                        ),
                        boxShadow: softShadow(),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: has
                          ? CachedNetworkImage(
                              imageUrl: it.url!,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Icon(
                                MdiIcons.imagePlus,
                                size: r.ms(20),
                                color: T.muted,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: r.vs(8)),
                  Text(
                    it.label,
                    style: TextStyle(
                      color: T.onBackground,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DangerBtn extends StatelessWidget {
  final R r;
  final Toks T;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DangerBtn({
    required this.r,
    required this.T,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r.s(14)),
        child: Container(
          height: r.vs(46),
          decoration: BoxDecoration(
            color: T.surface,
            borderRadius: BorderRadius.circular(r.s(14)),
            border: Border.all(color: T.border.withOpacity(0.55), width: 1),
            boxShadow: softShadow(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: r.ms(16), color: T.error),
              SizedBox(width: r.s(8)),
              Text(
                label,
                style: TextStyle(
                  color: T.error,
                  fontWeight: FontWeight.w900,
                  fontSize: r.ms(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------- Photo Source Sheet -------------------- */
class _PhotoSourceSheet extends StatefulWidget {
  final Toks T;
  final VoidCallback onClose;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;

  const _PhotoSourceSheet({
    required this.T,
    required this.onClose,
    required this.onPickCamera,
    required this.onPickGallery,
  });

  @override
  State<_PhotoSourceSheet> createState() => _PhotoSourceSheetState();
}

class _PhotoSourceSheetState extends State<_PhotoSourceSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..forward();
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final r = R(mq.size.width, mq.size.height);

    return Stack(
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0, end: 0.55).animate(_fade),
          child: Container(color: Colors.black),
        ),
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(color: Colors.transparent),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(_slide),
            child: Container(
              margin: EdgeInsets.all(r.s(12)),
              padding: EdgeInsets.fromLTRB(
                r.s(14),
                r.vs(12),
                r.s(14),
                r.vs(12),
              ),
              decoration: BoxDecoration(
                color: widget.T.elevated,
                borderRadius: BorderRadius.circular(r.s(20)),
                border: Border.all(
                  color: widget.T.border.withOpacity(0.55),
                  width: 1,
                ),
                boxShadow: strongShadow(),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: r.s(44),
                      height: r.vs(4),
                      decoration: BoxDecoration(
                        color: widget.T.border.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: r.vs(10)),
                  Text(
                    "Update photo",
                    style: TextStyle(
                      color: widget.T.onBackground,
                      fontWeight: FontWeight.w900,
                      fontSize: r.ms(14),
                    ),
                  ),
                  SizedBox(height: r.vs(4)),
                  Text(
                    "Choose a source",
                    style: TextStyle(
                      color: widget.T.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: r.vs(12)),
                  _PickerRow(
                    r: r,
                    T: widget.T,
                    icon: MdiIcons.cameraOutline,
                    title: "Camera",
                    subtitle: "Take a new photo",
                    onTap: widget.onPickCamera,
                  ),
                  SizedBox(height: r.vs(10)),
                  _PickerRow(
                    r: r,
                    T: widget.T,
                    icon: MdiIcons.imageMultipleOutline,
                    title: "Gallery",
                    subtitle: "Pick from your library",
                    onTap: widget.onPickGallery,
                  ),
                  SizedBox(height: r.vs(14)),
                  InkWell(
                    onTap: widget.onClose,
                    borderRadius: BorderRadius.circular(r.s(14)),
                    child: Container(
                      height: r.vs(46),
                      decoration: BoxDecoration(
                        color: widget.T.surface,
                        borderRadius: BorderRadius.circular(r.s(14)),
                        border: Border.all(
                          color: widget.T.border.withOpacity(0.55),
                          width: 1,
                        ),
                        boxShadow: softShadow(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            MdiIcons.close,
                            size: r.ms(16),
                            color: widget.T.onBackground,
                          ),
                          SizedBox(width: r.s(6)),
                          Text(
                            "Cancel",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: r.ms(12),
                              color: widget.T.onBackground,
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
        ),
      ],
    );
  }
}

class _PickerRow extends StatelessWidget {
  final R r;
  final Toks T;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerRow({
    required this.r,
    required this.T,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(r.s(14)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.vs(12)),
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: BorderRadius.circular(r.s(14)),
          border: Border.all(color: T.border.withOpacity(0.55), width: 1),
          boxShadow: softShadow(),
        ),
        child: Row(
          children: [
            Container(
              width: r.s(38),
              height: r.s(38),
              margin: EdgeInsets.only(right: r.s(10)),
              decoration: BoxDecoration(
                color: T.elevated,
                borderRadius: BorderRadius.circular(r.s(12)),
                boxShadow: softShadow(),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: r.ms(18), color: T.onBackground),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: T.onBackground,
                      fontWeight: FontWeight.w900,
                      fontSize: r.ms(13),
                    ),
                  ),
                  SizedBox(height: r.vs(2)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: T.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(MdiIcons.chevronRight, size: r.ms(22), color: T.muted),
          ],
        ),
      ),
    );
  }
}

/* -------------------- Image Preview Modal -------------------- */
class _ImagePreviewModal extends StatelessWidget {
  final Toks T;
  final String url;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  const _ImagePreviewModal({
    required this.T,
    required this.url,
    required this.onClose,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final r = R(mq.size.width, mq.size.height);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: Container(color: const Color(0x88000000)),
          ),
        ),
        Center(
          child: Container(
            margin: EdgeInsets.all(r.s(16)),
            padding: EdgeInsets.all(r.s(12)),
            decoration: BoxDecoration(
              color: T.elevated,
              borderRadius: BorderRadius.circular(r.s(18)),
              border: Border.all(color: T.border.withOpacity(0.55), width: 1),
              boxShadow: strongShadow(),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(r.s(14)),
                  child: SizedBox(
                    width: double.infinity,
                    height: r.vs(280),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: r.vs(12)),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(r.s(14)),
                        child: Container(
                          height: r.vs(46),
                          decoration: BoxDecoration(
                            color: T.surface,
                            borderRadius: BorderRadius.circular(r.s(14)),
                            border: Border.all(
                              color: T.border.withOpacity(0.55),
                              width: 1,
                            ),
                            boxShadow: softShadow(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                MdiIcons.close,
                                size: r.ms(16),
                                color: T.onBackground,
                              ),
                              SizedBox(width: r.s(6)),
                              Text(
                                "Close",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: r.ms(13),
                                  color: T.onBackground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: r.s(10)),
                    Expanded(
                      child: InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(r.s(14)),
                        child: Container(
                          height: r.vs(46),
                          decoration: BoxDecoration(
                            color: T.error,
                            borderRadius: BorderRadius.circular(r.s(14)),
                            border: Border.all(color: T.error, width: 1),
                            boxShadow: strongShadow(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                MdiIcons.deleteOutline,
                                size: r.ms(16),
                                color: T.onPrimary,
                              ),
                              SizedBox(width: r.s(6)),
                              Text(
                                "Delete",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: r.ms(13),
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
      ],
    );
  }
}

/* -------------------- Confirm Modal -------------------- */
enum _ConfirmTone { primary, info, warning, danger }

class _ConfirmModal extends StatefulWidget {
  final Toks T;
  final bool open;
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final _ConfirmTone tone;
  final VoidCallback onCancel;
  final FutureOr<void> Function() onConfirm;

  const _ConfirmModal({
    required this.T,
    required this.open,
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = "Cancel",
    required this.tone,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<_ConfirmModal> createState() => _ConfirmModalState();
}

class _ConfirmModalState extends State<_ConfirmModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _scale = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
  }

  @override
  void didUpdateWidget(covariant _ConfirmModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open && !oldWidget.open) _c.forward(from: 0);
    if (!widget.open && oldWidget.open) _c.reset();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.open) return const SizedBox.shrink();
    final mq = MediaQuery.of(context);
    final r = R(mq.size.width, mq.size.height);

    Color bg, fg, bd;
    switch (widget.tone) {
      case _ConfirmTone.info:
        bg = widget.T.info;
        fg = widget.T.onPrimary;
        bd = widget.T.info;
        break;
      case _ConfirmTone.warning:
        bg = widget.T.warning;
        fg = widget.T.onPrimary;
        bd = widget.T.warning;
        break;
      case _ConfirmTone.danger:
        bg = widget.T.error;
        fg = widget.T.onPrimary;
        bd = widget.T.error;
        break;
      default:
        bg = widget.T.primary;
        fg = widget.T.onPrimary;
        bd = widget.T.primary;
        break;
    }

    return Stack(
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0, end: 0.45).animate(_fade),
          child: Container(color: Colors.black),
        ),
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onCancel,
            child: Container(color: Colors.transparent),
          ),
        ),
        Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(_scale),
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.all(r.s(16)),
              padding: EdgeInsets.all(r.s(14)),
              decoration: BoxDecoration(
                color: widget.T.elevated,
                borderRadius: BorderRadius.circular(r.s(18)),
                border: Border.all(
                  color: widget.T.border.withOpacity(0.55),
                  width: 1,
                ),
                boxShadow: strongShadow(),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: r.s(54),
                    height: r.s(54),
                    decoration: BoxDecoration(
                      color: widget.T.surface,
                      borderRadius: BorderRadius.circular(r.s(16)),
                      border: Border.all(
                        color: widget.T.border.withOpacity(0.55),
                        width: 1,
                      ),
                      boxShadow: softShadow(),
                    ),
                    alignment: Alignment.center,
                    child: Icon(widget.icon, size: r.ms(24), color: bg),
                  ),
                  SizedBox(height: r.vs(10)),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.T.onBackground,
                      fontWeight: FontWeight.w900,
                      fontSize: r.ms(16),
                    ),
                  ),
                  SizedBox(height: r.vs(6)),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.T.muted,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: r.vs(14)),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: widget.onCancel,
                          borderRadius: BorderRadius.circular(r.s(14)),
                          child: Container(
                            height: r.vs(46),
                            decoration: BoxDecoration(
                              color: widget.T.surface,
                              borderRadius: BorderRadius.circular(r.s(14)),
                              border: Border.all(
                                color: widget.T.border.withOpacity(0.55),
                                width: 1,
                              ),
                              boxShadow: softShadow(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  MdiIcons.close,
                                  size: r.ms(16),
                                  color: widget.T.onBackground,
                                ),
                                SizedBox(width: r.s(6)),
                                Text(
                                  widget.cancelLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: r.ms(13),
                                    color: widget.T.onBackground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: r.s(10)),
                      Expanded(
                        child: InkWell(
                          onTap: () async => widget.onConfirm(),
                          borderRadius: BorderRadius.circular(r.s(14)),
                          child: Container(
                            height: r.vs(46),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(r.s(14)),
                              border: Border.all(color: bd, width: 1),
                              boxShadow: strongShadow(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(MdiIcons.check, size: r.ms(16), color: fg),
                                SizedBox(width: r.s(6)),
                                Text(
                                  widget.confirmLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: r.ms(13),
                                    color: fg,
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
        ),
      ],
    );
  }
}

/* -------------------- Auth Expired Modal -------------------- */
class _AuthExpiredModal extends StatelessWidget {
  final Toks T;
  final VoidCallback onOK;
  const _AuthExpiredModal({required this.T, required this.onOK});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final r = R(mq.size.width, mq.size.height);

    return Stack(
      children: [
        Positioned.fill(child: Container(color: const Color(0x66000000))),
        Center(
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.all(r.s(16)),
            padding: EdgeInsets.all(r.s(14)),
            decoration: BoxDecoration(
              color: T.elevated,
              borderRadius: BorderRadius.circular(r.s(18)),
              border: Border.all(color: T.border.withOpacity(0.55), width: 1),
              boxShadow: strongShadow(),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: r.s(54),
                  height: r.s(54),
                  decoration: BoxDecoration(
                    color: T.surface,
                    borderRadius: BorderRadius.circular(r.s(16)),
                    border: Border.all(
                      color: T.border.withOpacity(0.55),
                      width: 1,
                    ),
                    boxShadow: softShadow(),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    MdiIcons.alertCircleOutline,
                    size: r.ms(24),
                    color: T.error,
                  ),
                ),
                SizedBox(height: r.vs(10)),
                Text(
                  "Session expired",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: T.onBackground,
                    fontWeight: FontWeight.w900,
                    fontSize: r.ms(16),
                  ),
                ),
                SizedBox(height: r.vs(6)),
                Text(
                  "Your login session has expired. Please sign in again to continue.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: T.muted,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: r.vs(14)),
                InkWell(
                  onTap: onOK,
                  borderRadius: BorderRadius.circular(r.s(14)),
                  child: Container(
                    height: r.vs(46),
                    decoration: BoxDecoration(
                      color: T.primary,
                      borderRadius: BorderRadius.circular(r.s(14)),
                      border: Border.all(color: T.primary, width: 1),
                      boxShadow: strongShadow(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          MdiIcons.login,
                          size: r.ms(16),
                          color: T.onPrimary,
                        ),
                        SizedBox(width: r.s(6)),
                        Text(
                          "OK",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: r.ms(13),
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
        ),
      ],
    );
  }
}
