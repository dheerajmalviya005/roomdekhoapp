import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

const String me = "u1";
const String peer = "u2";

class ChatMessage {
  final String id;
  final String userId;
  final String text;
  final String? image;
  final DateTime createdAt;
  final String status; // sent/delivered/read
  final String type; // msg/listing/separator
  final Map<String, dynamic>? listing;

  const ChatMessage({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
    required this.status,
    this.image,
    this.type = "msg",
    this.listing,
  });
}

class _SepItem {
  final String id;
  final DateTime createdAt;
  const _SepItem({required this.id, required this.createdAt});
}

/// Responsive scaler (same concept)
class R {
  final double w;
  final double h;
  R(this.w, this.h);

  double s(double v) => (w / 375.0) * v;
  double vs(double v) => (h / 812.0) * v;
  double ms(double v, [double factor = 0.5]) => v + (s(v) - v) * factor;
}

/// ====== UTIL ======
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String fmtDate(DateTime d) {
  // "02 Dec 2025"
  const months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];
  final dd = d.day.toString().padLeft(2, "0");
  return "$dd ${months[d.month - 1]} ${d.year}";
}

String fmtTime(DateTime d) {
  // HH:MM
  final hh = d.hour.toString().padLeft(2, "0");
  final mm = d.minute.toString().padLeft(2, "0");
  return "$hh:$mm";
}

/// ====== THEME MODEL (same keys as RN T.*) ======
/// IMPORTANT: keep your app theme mapping here so design stays identical.
/// If you already have theme tokens, replace values in `ThemeTokens.fromContext`.
class ThemeTokens {
  final Color background;
  final Color elevated;
  final Color surface;
  final Color border;

  final Color onBackground;
  final Color muted;

  final Color primary;
  final Color onPrimary;

  final Color success;
  final Color info;
  final Color warning;
  final Color error;
  final Color disabled;

  ThemeTokens({
    required this.background,
    required this.elevated,
    required this.surface,
    required this.border,
    required this.onBackground,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.success,
    required this.info,
    required this.warning,
    required this.error,
    required this.disabled,
  });

  /// Replace this mapping with your exact palette if you already have it
  factory ThemeTokens.fromContext(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return ThemeTokens(
        background: const Color(0xFF0B1220),
        elevated: const Color(0xFF111827),
        surface: const Color(0xFF1F2937),
        border: Colors.white.withOpacity(0.10),
        onBackground: Colors.white,
        muted: const Color(0xFF9CA3AF),
        primary: const Color(0xFF6366F1),
        onPrimary: Colors.white,
        success: const Color(0xFF10B981),
        info: const Color(0xFF3B82F6),
        warning: const Color(0xFFF59E0B),
        error: const Color(0xFFEF4444),
        disabled: Colors.white.withOpacity(0.12),
      );
    }
    return ThemeTokens(
      background: const Color(0xFFF5F7FF),
      elevated: Colors.white,
      surface: const Color(0xFFF3F4F6),
      border: Colors.black.withOpacity(0.06),
      onBackground: const Color(0xFF0B1220),
      muted: const Color(0xFF6B7280),
      primary: const Color(0xFF6366F1),
      onPrimary: Colors.white,
      success: const Color(0xFF10B981),
      info: const Color(0xFF3B82F6),
      warning: const Color(0xFFF59E0B),
      error: const Color(0xFFEF4444),
      disabled: Colors.black.withOpacity(0.10),
    );
  }
}

/// ====== WHITE GLOW SHADOW (#FFFFFFFF) ======
List<BoxShadow> whiteGlow(
  R r, {
  double op = 0.16,
  double blur = 18,
  double y = 10,
}) {
  return [
    BoxShadow(
      color: const Color(0xFFFFFFFF).withOpacity(op),
      blurRadius: r.s(blur),
      spreadRadius: 0,
      offset: Offset(0, r.vs(y)),
    ),
    BoxShadow(
      color: const Color(0xFFFFFFFF).withOpacity(op * 0.6),
      blurRadius: r.s(10),
      spreadRadius: 0,
      offset: Offset(0, r.vs(4)),
    ),
  ];
}

/// ====== SCREEN ======
class ChatScreenFlutter extends StatefulWidget {
  const ChatScreenFlutter({super.key});

  @override
  State<ChatScreenFlutter> createState() => _ChatScreenFlutterState();
}

class _ChatScreenFlutterState extends State<ChatScreenFlutter>
    with TickerProviderStateMixin {
  late List<ChatMessage> messages;
  String input = "";
  bool online = true;
  bool showEmoji = false;

  Map<String, dynamic>? queuedListing;
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool galleryOpen = false;
  int galleryIndex = 0;
  List<String> galleryImages = [];

  bool menuOpen = false;
  bool blockOpen = false;
  bool reportOpen = false;

  late final AnimationController headerCtrl;
  late final AnimationController inputCtrl;
  late final AnimationController msgCtrl;
  late final AnimationController scrollBtnCtrl;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    DateTime minsAgo(int m) => now.subtract(Duration(minutes: m));

    messages = [
      ChatMessage(
        id: "m1",
        userId: peer,
        text: "Hi! Welcome to University Living Admin 👋",
        createdAt: minsAgo(300),
        status: "read",
      ),
      ChatMessage(
        id: "m2",
        userId: me,
        text: "Hey! I need to update a listing and share the new media.",
        createdAt: minsAgo(299),
        status: "read",
      ),
      ChatMessage(
        id: "m3",
        userId: peer,
        text:
            "Sure — send them here. Also note: tenants asked for an earlier check-in.",
        createdAt: minsAgo(240),
        status: "read",
      ),
      ChatMessage(
        id: "m4",
        userId: me,
        text: "",
        image: "https://picsum.photos/500/300?image=29",
        createdAt: minsAgo(40),
        status: "delivered",
      ),
      ChatMessage(
        id: "m5",
        userId: me,
        text: "Uploaded one image. Will add videos soon.",
        createdAt: minsAgo(39),
        status: "delivered",
      ),
      ChatMessage(
        id: "m6",
        userId: peer,
        text: "Looks good 👍",
        createdAt: minsAgo(38),
        status: "read",
      ),
      ChatMessage(
        id: "m7",
        userId: peer,
        text: "Can you also share the floor plan?",
        createdAt: minsAgo(20),
        status: "read",
      ),
      ChatMessage(
        id: "m8",
        userId: me,
        text: "Sure, I'll upload it in the next 30 minutes.",
        createdAt: minsAgo(15),
        status: "delivered",
      ),
    ];

    _rebuildGallery();

    headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    inputCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    msgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    scrollBtnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    Future.microtask(() async {
      headerCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 140));
      msgCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 140));
      inputCtrl.forward();
    });

    _scroll.addListener(() {
      final show = _scroll.offset > 200;
      if (show) {
        scrollBtnCtrl.forward();
      } else {
        scrollBtnCtrl.reverse();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    headerCtrl.dispose();
    inputCtrl.dispose();
    msgCtrl.dispose();
    scrollBtnCtrl.dispose();
    super.dispose();
  }

  void _rebuildGallery() {
    galleryImages = messages
        .where((m) => m.image != null)
        .map((m) => m.image!)
        .toList();
  }

  List<dynamic> get dataWithSeparators {
    final out = <dynamic>[];
    ChatMessage? last;
    for (final m in messages) {
      if (last == null || !isSameDay(last.createdAt, m.createdAt)) {
        out.add(_SepItem(id: "sep-${m.id}", createdAt: m.createdAt));
      }
      out.add(m);
      last = m;
    }
    out.sort((a, b) {
      final ta = (a is _SepItem) ? a.createdAt : (a as ChatMessage).createdAt;
      final tb = (b is _SepItem) ? b.createdAt : (b as ChatMessage).createdAt;
      return tb.compareTo(ta);
    });
    return out;
  }

  void scrollToBottom() {
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void onSend() {
    final text = input.trim();
    if (text.isEmpty && queuedListing == null) return;

    setState(() {
      if (queuedListing != null) {
        messages.add(
          ChatMessage(
            id: "list-${DateTime.now().millisecondsSinceEpoch}",
            userId: me,
            text: "",
            createdAt: DateTime.now().subtract(const Duration(milliseconds: 1)),
            status: "sent",
            type: "listing",
            listing: queuedListing,
          ),
        );
        queuedListing = null;
      }

      if (text.isNotEmpty) {
        messages.add(
          ChatMessage(
            id: "m${DateTime.now().millisecondsSinceEpoch}",
            userId: me,
            text: text,
            createdAt: DateTime.now(),
            status: "sent",
          ),
        );
      }

      input = "";
      _ctrl.clear();
      showEmoji = false;

      _rebuildGallery();
    });

    scrollToBottom();
  }

  void onAttach() {
    final uri =
        "https://picsum.photos/600/400?random=${math.Random().nextInt(9999)}";
    setState(() {
      messages.add(
        ChatMessage(
          id: "m${DateTime.now().millisecondsSinceEpoch}",
          userId: me,
          text: "",
          image: uri,
          createdAt: DateTime.now(),
          status: "sent",
        ),
      );
      _rebuildGallery();
    });
  }

  void openGallery(String uri) {
    final idx = galleryImages.indexOf(uri);
    if (idx < 0) return;
    setState(() {
      galleryIndex = idx;
      galleryOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final T = ThemeTokens.fromContext(context);
    final mq = MediaQuery.of(context);
    final r = R(mq.size.width, mq.size.height);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: T.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ===== Header (animated) =====
                FadeTransition(
                  opacity: headerCtrl.drive(CurveTween(curve: Curves.easeOut)),
                  child: SlideTransition(
                    position: headerCtrl.drive(
                      Tween<Offset>(
                        begin: const Offset(0, -0.25),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOutCubic)),
                    ),
                    child: Container(
                      padding: EdgeInsets.only(
                        top: r.vs(Platform.isIOS ? 10 : 14),
                        bottom: r.vs(12),
                      ),
                      decoration: BoxDecoration(
                        color: T.elevated,
                        border: Border(
                          bottom: BorderSide(color: T.border, width: 1),
                        ),
                        boxShadow: whiteGlow(r, op: 0.12, blur: 14, y: 6),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: r.s(16)),
                        child: Row(
                          children: [
                            _IconSquare(
                              r: r,
                              bg: T.surface,
                              icon: Icons.arrow_back,
                              iconColor: T.onBackground,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                            SizedBox(width: r.s(12)),

                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(r.s(14)),
                                onTap: () {},
                                child: Row(
                                  children: [
                                    Container(
                                      width: r.s(44),
                                      height: r.s(44),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          r.s(12),
                                        ),
                                        border: Border.all(
                                          color: T.primary,
                                          width: 2,
                                        ),
                                        image: const DecorationImage(
                                          image: AssetImage(
                                            "assets/icon/splash.png",
                                          ), // same idea as ImageIcon
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              width: r.s(12),
                                              height: r.s(12),
                                              decoration: BoxDecoration(
                                                color: online
                                                    ? T.success
                                                    : T.muted,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      r.s(6),
                                                    ),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: r.s(12)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "Support Team",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: r.ms(16),
                                              fontWeight: FontWeight.w800,
                                              color: T.onBackground,
                                            ),
                                          ),
                                          SizedBox(height: r.vs(2)),
                                          Text(
                                            "${online ? "Online" : "Offline"} · replies in 5 min",
                                            style: TextStyle(
                                              fontSize: r.ms(12),
                                              fontWeight: FontWeight.w500,
                                              color: T.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(width: r.s(10)),
                            _IconSquare(
                              r: r,
                              bg: T.surface,
                              icon: Icons.phone,
                              iconColor: T.primary,
                              onTap: () {},
                            ),
                            SizedBox(width: r.s(8)),
                            _IconSquare(
                              r: r,
                              bg: T.surface,
                              icon: Icons.more_vert,
                              iconColor: T.onBackground,
                              onTap: () => setState(() => menuOpen = true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ===== Chat list =====
                Expanded(
                  child: FadeTransition(
                    opacity: msgCtrl.drive(CurveTween(curve: Curves.easeOut)),
                    child: ListView.separated(
                      controller: _scroll,
                      reverse: true, // inverted like RN
                      padding: EdgeInsets.fromLTRB(
                        r.s(16),
                        r.vs(16),
                        r.s(16),
                        r.vs(20),
                      ),
                      itemCount: dataWithSeparators.length,
                      separatorBuilder: (_, __) => SizedBox(height: r.vs(10)),
                      itemBuilder: (context, index) {
                        final item = dataWithSeparators[index];

                        if (item is _SepItem) {
                          return Align(
                            alignment: Alignment.center,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: r.s(16),
                                vertical: r.vs(8),
                              ),
                              decoration: BoxDecoration(
                                color: T.elevated,
                                borderRadius: BorderRadius.circular(r.s(20)),
                                border: Border.all(color: T.border, width: 1),
                                boxShadow: whiteGlow(
                                  r,
                                  op: 0.10,
                                  blur: 12,
                                  y: 6,
                                ),
                              ),
                              child: Text(
                                fmtDate(item.createdAt),
                                style: TextStyle(
                                  color: T.muted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: r.ms(11),
                                ),
                              ),
                            ),
                          );
                        }

                        final m = item as ChatMessage;

                        if (m.type == "listing") {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: _ListingCardFlutter(
                              r: r,
                              T: T,
                              listing: m.listing ?? const {},
                              compact: false,
                            ),
                          );
                        }

                        final isMe = m.userId == me;

                        // avatar logic like RN (simplified with time gap)
                        bool showAvatar = false;
                        if (!isMe) {
                          final next = index + 1 < dataWithSeparators.length
                              ? dataWithSeparators[index + 1]
                              : null;
                          if (next is ChatMessage) {
                            showAvatar =
                                next.userId != m.userId ||
                                (m.createdAt
                                            .difference(next.createdAt)
                                            .inMinutes)
                                        .abs() >
                                    5;
                          } else {
                            showAvatar = true;
                          }
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              SizedBox(
                                width: r.s(40),
                                child: showAvatar
                                    ? Container(
                                        width: r.s(32),
                                        height: r.s(32),
                                        decoration: BoxDecoration(
                                          color: T.primary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            r.s(10),
                                          ),
                                          border: Border.all(
                                            color: T.primary,
                                            width: 2,
                                          ),
                                          boxShadow: whiteGlow(
                                            r,
                                            op: 0.10,
                                            blur: 10,
                                            y: 4,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.person,
                                          size: r.ms(16),
                                          color: T.primary,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              SizedBox(width: r.s(8)),
                            ],

                            Flexible(
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!isMe && showAvatar)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: r.s(8),
                                        bottom: r.vs(4),
                                      ),
                                      child: Text(
                                        "Support",
                                        style: TextStyle(
                                          fontSize: r.ms(12),
                                          fontWeight: FontWeight.w700,
                                          color: T.onBackground,
                                        ),
                                      ),
                                    ),

                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: r.s(14),
                                      vertical: r.vs(10),
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe ? T.primary : T.elevated,
                                      borderRadius: BorderRadius.circular(
                                        r.s(18),
                                      ),
                                      border: Border.all(
                                        color: isMe ? T.primary : T.border,
                                        width: 1,
                                      ),
                                      boxShadow: whiteGlow(
                                        r,
                                        op: 0.14,
                                        blur: 14,
                                        y: 6,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (m.image != null) ...[
                                          GestureDetector(
                                            onTap: () => openGallery(m.image!),
                                            child: Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        r.s(12),
                                                      ),
                                                  child: CachedNetworkImage(
                                                    imageUrl: m.image!,
                                                    width: r.s(200),
                                                    height: r.vs(130),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                Positioned(
                                                  top: r.s(10),
                                                  right: r.s(10),
                                                  child: Container(
                                                    width: r.s(30),
                                                    height: r.s(30),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.50),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            r.s(15),
                                                          ),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Icon(
                                                      Icons.zoom_in,
                                                      color: Colors.white,
                                                      size: r.ms(18),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: r.vs(8)),
                                        ],

                                        if (m.text.trim().isNotEmpty)
                                          Text(
                                            m.text,
                                            style: TextStyle(
                                              color: isMe
                                                  ? T.onPrimary
                                                  : T.onBackground,
                                              fontSize: r.ms(14),
                                              height: 1.35,
                                            ),
                                          ),

                                        SizedBox(height: r.vs(6)),

                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              fmtTime(m.createdAt),
                                              style: TextStyle(
                                                color: isMe
                                                    ? T.onPrimary.withOpacity(
                                                        0.80,
                                                      )
                                                    : T.muted,
                                                fontSize: r.ms(11),
                                              ),
                                            ),
                                            if (isMe) ...[
                                              SizedBox(width: r.s(4)),
                                              Icon(
                                                m.status == "read" ||
                                                        m.status == "delivered"
                                                    ? Icons.done_all
                                                    : Icons.check,
                                                size: r.ms(14),
                                                color: T.onPrimary.withOpacity(
                                                  m.status == "read" ? 1 : 0.7,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // ===== Queued listing preview =====
                if (queuedListing != null)
                  FadeTransition(
                    opacity: inputCtrl.drive(CurveTween(curve: Curves.easeOut)),
                    child: Container(
                      margin: EdgeInsets.fromLTRB(
                        r.s(16),
                        0,
                        r.s(16),
                        r.vs(12),
                      ),
                      padding: EdgeInsets.all(r.s(12)),
                      decoration: BoxDecoration(
                        color: T.elevated,
                        borderRadius: BorderRadius.circular(r.s(16)),
                        border: Border.all(color: T.border, width: 1),
                        boxShadow: whiteGlow(r, op: 0.12, blur: 14, y: 6),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Sending Property",
                                  style: TextStyle(
                                    color: T.onBackground,
                                    fontWeight: FontWeight.w700,
                                    fontSize: r.ms(14),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () =>
                                    setState(() => queuedListing = null),
                                child: Icon(
                                  Icons.close,
                                  color: T.muted,
                                  size: r.ms(20),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: r.vs(12)),
                          _ListingCardFlutter(
                            r: r,
                            T: T,
                            listing: queuedListing!,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                // ===== Emoji picker (optional) =====
                if (showEmoji)
                  Container(
                    height: r.vs(250),
                    decoration: BoxDecoration(
                      color: T.elevated,
                      border: Border(
                        top: BorderSide(color: T.border, width: 1),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Emoji Picker (optional)\nInstall emoji_picker_flutter to enable",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: T.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // ===== Input bar =====
                FadeTransition(
                  opacity: inputCtrl.drive(CurveTween(curve: Curves.easeOut)),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: r.s(16),
                      vertical: r.vs(12),
                    ),
                    decoration: BoxDecoration(
                      color: T.elevated,
                      border: Border(
                        top: BorderSide(color: T.border, width: 1),
                      ),
                      boxShadow: whiteGlow(r, op: 0.10, blur: 12, y: -2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _IconSquare(
                          r: r,
                          bg: T.surface,
                          icon: Icons.attach_file,
                          iconColor: T.onBackground,
                          onTap: onAttach,
                        ),
                        SizedBox(width: r.s(8)),

                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: r.s(12)),
                            decoration: BoxDecoration(
                              color: T.surface,
                              borderRadius: BorderRadius.circular(r.s(16)),
                              border: Border.all(color: T.border, width: 1),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _ctrl,
                                    minLines: 1,
                                    maxLines: 4,
                                    onChanged: (v) => setState(() => input = v),
                                    style: TextStyle(
                                      color: T.onBackground,
                                      fontSize: r.ms(14),
                                      height: 1.35,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "Type a message...",
                                      hintStyle: TextStyle(color: T.muted),
                                    ),
                                    onTap: () {
                                      if (showEmoji)
                                        setState(() => showEmoji = false);
                                    },
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    setState(() => showEmoji = !showEmoji);
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(r.s(6)),
                                    child: Icon(
                                      showEmoji
                                          ? Icons.keyboard
                                          : Icons.emoji_emotions_outlined,
                                      color: T.muted,
                                      size: r.ms(22),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(width: r.s(8)),

                        _SendBtn(
                          r: r,
                          enabled:
                              input.trim().isNotEmpty || queuedListing != null,
                          bg: (input.trim().isNotEmpty || queuedListing != null)
                              ? T.primary
                              : T.disabled,
                          iconColor:
                              (input.trim().isNotEmpty || queuedListing != null)
                              ? T.onPrimary
                              : T.onBackground,
                          onTap: onSend,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: r.vs(4)),
              ],
            ),

            // ===== Scroll-to-bottom button =====
            Positioned(
              right: r.s(16),
              bottom: r.vs(100),
              child: FadeTransition(
                opacity: scrollBtnCtrl.drive(CurveTween(curve: Curves.easeOut)),
                child: ScaleTransition(
                  scale: scrollBtnCtrl.drive(
                    Tween<double>(
                      begin: 0.85,
                      end: 1,
                    ).chain(CurveTween(curve: Curves.easeOut)),
                  ),
                  child: InkWell(
                    onTap: scrollToBottom,
                    borderRadius: BorderRadius.circular(r.s(22)),
                    child: Container(
                      width: r.s(44),
                      height: r.s(44),
                      decoration: BoxDecoration(
                        color: T.primary,
                        borderRadius: BorderRadius.circular(r.s(22)),
                        boxShadow: whiteGlow(r, op: 0.18, blur: 18, y: 10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_downward,
                        color: T.onPrimary,
                        size: r.ms(20),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ===== Gallery modal =====
            if (galleryOpen)
              _GalleryOverlay(
                r: r,
                T: T,
                images: galleryImages,
                startIndex: galleryIndex,
                isDark: isDark,
                onClose: () => setState(() => galleryOpen = false),
              ),

            // ===== Options sheet + confirm modals =====
            if (menuOpen)
              _OptionsSheet(
                r: r,
                T: T,
                onClose: () => setState(() => menuOpen = false),
                onBlock: () {
                  setState(() {
                    menuOpen = false;
                    blockOpen = true;
                  });
                },
                onReport: () {
                  setState(() {
                    menuOpen = false;
                    reportOpen = true;
                  });
                },
              ),

            if (blockOpen)
              _ConfirmModal(
                r: r,
                T: T,
                tone: "danger",
                title: "Block this user?",
                message:
                    "You won't receive messages from this user. You can unblock later from settings.",
                confirmLabel: "Block",
                onCancel: () => setState(() => blockOpen = false),
                onConfirm: () => setState(() => blockOpen = false),
              ),

            if (reportOpen)
              _ConfirmModal(
                r: r,
                T: T,
                tone: "warning",
                title: "Report conversation?",
                message:
                    "We'll review this chat for guideline violations. Thanks for helping keep the community safe.",
                confirmLabel: "Report",
                onCancel: () => setState(() => reportOpen = false),
                onConfirm: () => setState(() => reportOpen = false),
              ),
          ],
        ),
      ),
    );
  }
}

/// ====== SMALL UI WIDGETS ======
class _IconSquare extends StatelessWidget {
  final R r;
  final Color bg;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _IconSquare({
    required this.r,
    required this.bg,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(r.s(12)),
      onTap: onTap,
      child: Container(
        width: r.s(40),
        height: r.s(40),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(r.s(12)),
          boxShadow: whiteGlow(r, op: 0.10, blur: 12, y: 6),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: iconColor, size: r.ms(22)),
      ),
    );
  }
}

class _SendBtn extends StatelessWidget {
  final R r;
  final bool enabled;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;

  const _SendBtn({
    required this.r,
    required this.enabled,
    required this.bg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(r.s(12)),
      child: Container(
        width: r.s(44),
        height: r.s(44),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(r.s(12)),
          boxShadow: whiteGlow(r, op: enabled ? 0.16 : 0.08, blur: 14, y: 8),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.send, color: iconColor, size: r.ms(20)),
      ),
    );
  }
}

/// ===== Listing Card (same look idea) =====
class _ListingCardFlutter extends StatelessWidget {
  final R r;
  final ThemeTokens T;
  final Map<String, dynamic> listing;
  final bool compact;

  const _ListingCardFlutter({
    required this.r,
    required this.T,
    required this.listing,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final title = (listing["title"] ?? "Property").toString();
    final price = (listing["price"] ?? "—").toString();
    final area = (listing["area"] ?? "Location not specified").toString();
    final verified = (listing["verified"] == true);
    final rating = listing["rating"];
    final distance = listing["distance"];

    return Container(
      width: compact ? double.infinity : r.s(260),
      decoration: BoxDecoration(
        color: T.elevated,
        borderRadius: BorderRadius.circular(r.s(16)),
        border: Border.all(color: T.border, width: 1),
        boxShadow: whiteGlow(r, op: 0.14, blur: 16, y: 10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: r.vs(140),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // placeholder image
                Image.asset("assets/icon/splash.png", fit: BoxFit.cover),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.60),
                        ],
                      ),
                    ),
                  ),
                ),
                if (verified)
                  Positioned(
                    top: r.s(10),
                    left: r.s(10),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: r.s(8),
                        vertical: r.vs(4),
                      ),
                      decoration: BoxDecoration(
                        color: T.success,
                        borderRadius: BorderRadius.circular(r.s(12)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            color: Colors.white,
                            size: r.ms(12),
                          ),
                          SizedBox(width: r.s(4)),
                          Text(
                            "Verified",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: r.ms(10),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: r.s(10),
                  bottom: r.s(10),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: r.s(12),
                      vertical: r.vs(6),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.80),
                      borderRadius: BorderRadius.circular(r.s(12)),
                    ),
                    child: Text(
                      price,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: r.ms(14),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(r.s(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: T.onBackground,
                    fontSize: r.ms(16),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: r.vs(4)),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: T.muted,
                      size: r.ms(14),
                    ),
                    SizedBox(width: r.s(4)),
                    Expanded(
                      child: Text(
                        area,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: T.muted, fontSize: r.ms(12)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.vs(8)),
                Row(
                  children: [
                    if (rating != null) ...[
                      Icon(
                        Icons.star,
                        color: const Color(0xFFFFD166),
                        size: r.ms(16),
                      ),
                      SizedBox(width: r.s(4)),
                      Text(
                        rating.toString(),
                        style: TextStyle(
                          color: T.onBackground,
                          fontWeight: FontWeight.w700,
                          fontSize: r.ms(12),
                        ),
                      ),
                      SizedBox(width: r.s(12)),
                    ],
                    if (distance != null) ...[
                      Icon(Icons.place, color: T.primary, size: r.ms(16)),
                      SizedBox(width: r.s(4)),
                      Text(
                        distance.toString(),
                        style: TextStyle(
                          color: T.onBackground,
                          fontWeight: FontWeight.w700,
                          fontSize: r.ms(12),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ====== Gallery Overlay (simple) ======
class _GalleryOverlay extends StatefulWidget {
  final R r;
  final ThemeTokens T;
  final List<String> images;
  final int startIndex;
  final bool isDark;
  final VoidCallback onClose;

  const _GalleryOverlay({
    required this.r,
    required this.T,
    required this.images,
    required this.startIndex,
    required this.isDark,
    required this.onClose,
  });

  @override
  State<_GalleryOverlay> createState() => _GalleryOverlayState();
}

class _GalleryOverlayState extends State<_GalleryOverlay> {
  late final PageController _page;

  @override
  void initState() {
    super.initState();
    _page = PageController(initialPage: widget.startIndex);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark
        ? Colors.black.withOpacity(0.90)
        : Colors.white.withOpacity(0.98);
    return Positioned.fill(
      child: Material(
        color: bg,
        child: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: _page,
                itemCount: widget.images.length,
                itemBuilder: (_, i) {
                  final uri = widget.images[i];
                  return Center(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: CachedNetworkImage(
                        imageUrl: uri,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),

              Positioned(
                top: widget.r.s(10),
                right: widget.r.s(10),
                child: InkWell(
                  onTap: widget.onClose,
                  borderRadius: BorderRadius.circular(widget.r.s(14)),
                  child: Container(
                    width: widget.r.s(40),
                    height: widget.r.s(40),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(widget.r.s(14)),
                      boxShadow: whiteGlow(widget.r, op: 0.10, blur: 12, y: 6),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: widget.r.ms(22),
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: widget.r.s(20),
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.r.s(12),
                      vertical: widget.r.vs(6),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.60),
                      borderRadius: BorderRadius.circular(widget.r.s(20)),
                    ),
                    child: Text(
                      "Swipe • Pinch to zoom",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: widget.r.ms(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ====== Options Sheet ======
class _OptionsSheet extends StatelessWidget {
  final R r;
  final ThemeTokens T;
  final VoidCallback onClose;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  const _OptionsSheet({
    required this.r,
    required this.T,
    required this.onClose,
    required this.onBlock,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.40),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(onTap: onClose, child: const SizedBox()),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.all(r.s(16)),
                padding: EdgeInsets.symmetric(
                  horizontal: r.s(16),
                  vertical: r.vs(16),
                ),
                decoration: BoxDecoration(
                  color: T.elevated,
                  borderRadius: BorderRadius.circular(r.s(20)),
                  border: Border.all(color: T.border, width: 1),
                  boxShadow: whiteGlow(r, op: 0.14, blur: 18, y: 10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: r.s(40),
                      height: r.vs(4),
                      decoration: BoxDecoration(
                        color: T.border,
                        borderRadius: BorderRadius.circular(r.s(2)),
                      ),
                    ),
                    SizedBox(height: r.vs(12)),

                    _OptionTile(
                      r: r,
                      T: T,
                      icon: Icons.block_outlined,
                      title: "Block",
                      subtitle: "Stop receiving messages from this user",
                      tone: T.error,
                      onTap: onBlock,
                    ),
                    SizedBox(height: r.vs(10)),
                    _OptionTile(
                      r: r,
                      T: T,
                      icon: Icons.report_gmailerrorred_outlined,
                      title: "Report",
                      subtitle: "Flag this conversation for review",
                      tone: T.warning,
                      onTap: onReport,
                    ),

                    SizedBox(height: r.vs(16)),
                    InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(r.s(14)),
                      child: Container(
                        height: r.vs(48),
                        decoration: BoxDecoration(
                          color: T.surface,
                          borderRadius: BorderRadius.circular(r.s(14)),
                          border: Border.all(color: T.border, width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.close,
                              size: r.ms(18),
                              color: T.onBackground,
                            ),
                            SizedBox(width: r.s(8)),
                            Text(
                              "Cancel",
                              style: TextStyle(
                                color: T.onBackground,
                                fontWeight: FontWeight.w700,
                                fontSize: r.ms(14),
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
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final R r;
  final ThemeTokens T;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tone;
  final VoidCallback onTap;

  const _OptionTile({
    required this.r,
    required this.T,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(r.s(14)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.vs(14)),
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: BorderRadius.circular(r.s(14)),
          border: Border.all(color: T.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: r.s(40),
              height: r.s(40),
              decoration: BoxDecoration(
                color: tone.withOpacity(0.12),
                borderRadius: BorderRadius.circular(r.s(12)),
                border: Border.all(color: tone.withOpacity(0.25), width: 1),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: tone, size: r.ms(20)),
            ),
            SizedBox(width: r.s(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: T.onBackground,
                      fontWeight: FontWeight.w700,
                      fontSize: r.ms(15),
                    ),
                  ),
                  SizedBox(height: r.vs(4)),
                  Text(
                    subtitle,
                    style: TextStyle(color: T.muted, fontSize: r.ms(12)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: T.muted, size: r.ms(24)),
          ],
        ),
      ),
    );
  }
}

/// ====== Confirm Modal ======
class _ConfirmModal extends StatelessWidget {
  final R r;
  final ThemeTokens T;
  final String tone; // primary/info/warning/danger
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _ConfirmModal({
    required this.r,
    required this.T,
    required this.tone,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg = T.onPrimary;
    Color bd;

    switch (tone) {
      case "warning":
        bg = T.warning;
        bd = T.warning;
        break;
      case "danger":
        bg = T.error;
        bd = T.error;
        break;
      case "info":
        bg = T.info;
        bd = T.info;
        break;
      default:
        bg = T.primary;
        bd = T.primary;
    }

    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.40),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(onTap: onCancel, child: const SizedBox()),
            ),
            Center(
              child: Container(
                margin: EdgeInsets.all(r.s(20)),
                padding: EdgeInsets.all(r.s(20)),
                decoration: BoxDecoration(
                  color: T.elevated,
                  borderRadius: BorderRadius.circular(r.s(20)),
                  border: Border.all(color: T.border, width: 1),
                  boxShadow: whiteGlow(r, op: 0.16, blur: 18, y: 10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: r.s(60),
                      height: r.s(60),
                      decoration: BoxDecoration(
                        color: T.surface,
                        borderRadius: BorderRadius.circular(r.s(16)),
                        border: Border.all(color: T.border, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        tone == "warning"
                            ? Icons.report_outlined
                            : tone == "danger"
                            ? Icons.block_outlined
                            : Icons.info_outline,
                        color: bg,
                        size: r.ms(28),
                      ),
                    ),
                    SizedBox(height: r.vs(16)),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: T.onBackground,
                        fontWeight: FontWeight.w800,
                        fontSize: r.ms(18),
                      ),
                    ),
                    SizedBox(height: r.vs(8)),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: T.muted,
                        fontSize: r.ms(14),
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: r.vs(24)),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: onCancel,
                            borderRadius: BorderRadius.circular(r.s(14)),
                            child: Container(
                              height: r.vs(48),
                              decoration: BoxDecoration(
                                color: T.surface,
                                borderRadius: BorderRadius.circular(r.s(14)),
                                border: Border.all(color: T.border, width: 1),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.close,
                                    size: r.ms(18),
                                    color: T.onBackground,
                                  ),
                                  SizedBox(width: r.s(8)),
                                  Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: T.onBackground,
                                      fontWeight: FontWeight.w700,
                                      fontSize: r.ms(14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: r.s(12)),
                        Expanded(
                          child: InkWell(
                            onTap: onConfirm,
                            borderRadius: BorderRadius.circular(r.s(14)),
                            child: Container(
                              height: r.vs(48),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(r.s(14)),
                                border: Border.all(color: bd, width: 1),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, size: r.ms(18), color: fg),
                                  SizedBox(width: r.s(8)),
                                  Text(
                                    confirmLabel,
                                    style: TextStyle(
                                      color: fg,
                                      fontWeight: FontWeight.w700,
                                      fontSize: r.ms(14),
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
        ),
      ),
    );
  }
}
