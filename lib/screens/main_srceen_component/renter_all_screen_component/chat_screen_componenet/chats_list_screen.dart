import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

class ChatItem {
  final String id;
  final String name;
  final String? avatar;
  final String lastMsg;
  final DateTime lastAt;
  final int unread;
  final bool typing;
  final bool online;
  final bool pinned;
  final String label;

  const ChatItem({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMsg,
    required this.lastAt,
    required this.unread,
    required this.typing,
    required this.online,
    required this.pinned,
    required this.label,
  });

  ChatItem copyWith({
    String? id,
    String? name,
    String? avatar,
    String? lastMsg,
    DateTime? lastAt,
    int? unread,
    bool? typing,
    bool? online,
    bool? pinned,
    String? label,
  }) {
    return ChatItem(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      lastMsg: lastMsg ?? this.lastMsg,
      lastAt: lastAt ?? this.lastAt,
      unread: unread ?? this.unread,
      typing: typing ?? this.typing,
      online: online ?? this.online,
      pinned: pinned ?? this.pinned,
      label: label ?? this.label,
    );
  }
}

/* -------------------- Responsive scaling -------------------- */
class R {
  final double w;
  final double h;
  R(this.w, this.h);

  double s(double v) => (w / 375.0) * v;
  double vs(double v) => (h / 812.0) * v;
  double ms(double v, [double factor = 0.5]) => v + (s(v) - v) * factor;
}

/* -------------------- Mini Gradient helper -------------------- */
class _G extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final BorderRadius? radius;
  final Alignment begin;
  final Alignment end;

  const _G({
    required this.colors,
    required this.child,
    this.radius,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: begin, end: end),
        borderRadius: radius,
      ),
      child: child,
    );
  }
}

/* -------------------- Screen -------------------- */
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  final List<Color> primaryGradient = const [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];
  final List<Color> accentGradient = const [
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  final List<Map<String, String>> wallpapers = const [
    {
      "id": "w1",
      "name": "Ocean Mist",
      "uri":
          "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1200&auto=format",
    },
    {
      "id": "w2",
      "name": "Emerald Hills",
      "uri":
          "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?q=80&w=1200&auto=format",
    },
    {
      "id": "w3",
      "name": "Sunset Glow",
      "uri":
          "https://images.unsplash.com/photo-1518837695005-2083093ee35b?q=80&w=1200&auto=format",
    },
    {
      "id": "w4",
      "name": "Midnight Sky",
      "uri":
          "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?q=80&w=1200&auto=format",
    },
    {
      "id": "w5",
      "name": "City Lights",
      "uri":
          "https://images.unsplash.com/photo-1469474968028-56623f02e42e?q=80&w=1200&auto=format",
    },
    {
      "id": "w6",
      "name": "Royal Purple",
      "uri":
          "https://images.unsplash.com/photo-1496307042754-b4aa456c4a2d?q=80&w=1200&auto=format",
    },
    {
      "id": "w7",
      "name": "Blush Clouds",
      "uri":
          "https://images.unsplash.com/photo-1519681393784-d120267933ba?q=80&w=1200&auto=format",
    },
    {
      "id": "w8",
      "name": "Soft Slate",
      "uri":
          "https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1200&auto=format",
    },
    {
      "id": "w9",
      "name": "Coffee Grain",
      "uri":
          "https://images.unsplash.com/photo-1509042239860-f550ce710b93?q=80&w=1200&auto=format",
    },
    {
      "id": "w10",
      "name": "Abstract Wave",
      "uri":
          "https://images.unsplash.com/photo-1496307042754-41f2d7c38a30?q=80&w=1200&auto=format",
    },
  ];

  late List<ChatItem> chats;

  String query = "";
  String tab = "all";

  Map<String, String>? bgImage; // {uri, name}

  late final AnimationController _swipeCtrl;
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();

    _swipeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _searchCtrl = TextEditingController(text: query);

    final now = DateTime.now();
    DateTime minsAgo(int m) => now.subtract(Duration(minutes: m));

    chats = [
      ChatItem(
        id: "c1",
        name: "Accommodation Support",
        avatar: null,
        lastMsg: "We've confirmed your viewing for Friday 3 PM.",
        lastAt: minsAgo(8),
        unread: 2,
        typing: false,
        online: true,
        pinned: true,
        label: "Team",
      ),
      ChatItem(
        id: "c2",
        name: "Landlord • Mr. Patel",
        avatar: null,
        lastMsg: "Great. I'll share the tenancy docs shortly.",
        lastAt: minsAgo(42),
        unread: 0,
        typing: true,
        online: true,
        pinned: false,
        label: "Landlord",
      ),
      ChatItem(
        id: "c3",
        name: "Booking • UL Finance",
        avatar: null,
        lastMsg: "Refund has been processed. It'll reflect in 2–3 days.",
        lastAt: minsAgo(160),
        unread: 0,
        typing: false,
        online: false,
        pinned: false,
        label: "Payments",
      ),
      ChatItem(
        id: "c4",
        name: "Maintenance Desk",
        avatar: null,
        lastMsg: "Can you send a short video of the issue?",
        lastAt: minsAgo(6),
        unread: 3,
        typing: false,
        online: true,
        pinned: true,
        label: "Maintenance",
      ),
      ChatItem(
        id: "c5",
        name: "Landlord • Ms. Turner",
        avatar: null,
        lastMsg: "Noted. See you tomorrow!",
        lastAt: minsAgo(1200),
        unread: 0,
        typing: false,
        online: false,
        pinned: false,
        label: "Landlord",
      ),
    ];
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _swipeCtrl.dispose();
    super.dispose();
  }

  String fmtTime(DateTime? d) {
    if (d == null) return "—";
    final now = DateTime.now();
    final sameDay =
        d.year == now.year && d.month == now.month && d.day == now.day;
    if (sameDay) {
      final hh = d.hour;
      final mm = d.minute.toString().padLeft(2, "0");
      final ap = hh >= 12 ? "PM" : "AM";
      final hh12 = hh % 12 == 0 ? 12 : hh % 12;
      return "$hh12:$mm $ap";
    }
    const mos = [
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
    return "$dd ${mos[d.month - 1]}";
  }

  List<ChatItem> get filtered {
    final q = query.trim().toLowerCase();
    List<ChatItem> list = List.of(chats);

    if (q.isNotEmpty) {
      list = list.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.lastMsg.toLowerCase().contains(q) ||
            c.label.toLowerCase().contains(q);
      }).toList();
    }

    if (tab == "unread") list = list.where((c) => c.unread > 0).toList();

    // pinned on top + latest time
    list.sort((a, b) => (b.pinned ? 1 : 0) - (a.pinned ? 1 : 0));
    list.sort((a, b) => b.lastAt.compareTo(a.lastAt));
    return list;
  }

  void onOpenChat(ChatItem item) {
    setState(() {
      if (item.unread > 0) {
        chats = chats
            .map((c) => c.id == item.id ? c.copyWith(unread: 0) : c)
            .toList();
      }
    });

    context.pushNamed('chat', extra: item); // ✅ navigate
  }

  void togglePin(String id) {
    setState(() {
      chats = chats
          .map((c) => c.id == id ? c.copyWith(pinned: !c.pinned) : c)
          .toList();
    });
  }

  void applyWallpaper(Map<String, String> w) {
    setState(() => bgImage = {"uri": w["uri"]!, "name": w["name"]!});
    Navigator.pop(context);
  }

  // ✅ Premium WHITE glow shadow (still #FFFFFFFF, just better depth)
  List<BoxShadow> whiteGlowStrong(R r) => [
    BoxShadow(
      color: const Color(0xFFFFFFFF).withOpacity(0.18),
      blurRadius: r.s(22),
      spreadRadius: 0,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: const Color(0xFFFFFFFF).withOpacity(0.10),
      blurRadius: r.s(10),
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  List<BoxShadow> whiteGlowSoft(R r) => [
    BoxShadow(
      color: const Color(0xFFFFFFFF).withOpacity(0.14),
      blurRadius: r.s(16),
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final r = R(mq.size.width, mq.size.height);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = bgImage != null
        ? Colors.transparent
        : (isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FF));
    final onBg = isDark ? Colors.white : const Color(0xFF0B1220);
    final muted = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    // same base cards
    final card = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final border = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.06);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          if (bgImage != null) ...[
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: bgImage!["uri"]!,
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.25)),
            ),
          ],

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: r.s(16),
                    vertical: r.vs(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Chats",
                            style: TextStyle(
                              fontSize: r.ms(26),
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: onBg,
                            ),
                          ),
                          SizedBox(height: r.vs(2)),
                          Text(
                            "${filtered.length} conversation${filtered.length == 1 ? "" : "s"}",
                            style: TextStyle(
                              fontSize: r.ms(12),
                              fontWeight: FontWeight.w500,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _IconBtn(
                            r: r,
                            onTap: () => _openWallpaperModal(
                              context,
                              r,
                              isDark,
                              onBg,
                              muted,
                              border,
                            ),
                            shadow: whiteGlowSoft(r),
                            child: _G(
                              colors: isDark
                                  ? [
                                      const Color(0xFF374151),
                                      const Color(0xFF1F2937),
                                    ]
                                  : [
                                      const Color(0xFFF3F4F6),
                                      const Color(0xFFE5E7EB),
                                    ],
                              radius: BorderRadius.circular(r.s(12)),
                              child: Center(
                                child: Icon(
                                  MdiIcons.imageMultiple,
                                  size: r.ms(18),
                                  color: onBg,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: r.s(10)),
                          _IconBtn(
                            r: r,
                            onTap: () {},
                            shadow: whiteGlowStrong(r),
                            child: _G(
                              colors: primaryGradient,
                              radius: BorderRadius.circular(r.s(12)),
                              child: Center(
                                child: Icon(
                                  MdiIcons.lifebuoy,
                                  size: r.ms(18),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search + Chips
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.s(16)),
                  child: Column(
                    children: [
                      Container(
                        height: r.vs(52),
                        padding: EdgeInsets.symmetric(horizontal: r.s(16)),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E2332).withOpacity(0.95)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(r.s(16)),
                          border: Border.all(color: border, width: 1.5),
                          boxShadow: whiteGlowSoft(r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              MdiIcons.magnify,
                              size: r.ms(20),
                              color: muted,
                            ),
                            SizedBox(width: r.s(10)),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (t) => setState(() => query = t),
                                style: TextStyle(
                                  color: onBg,
                                  fontSize: r.ms(14),
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Search users, teams, messages…",
                                  hintStyle: TextStyle(color: muted),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (query.isNotEmpty)
                              InkWell(
                                onTap: () => setState(() {
                                  query = "";
                                  _searchCtrl.clear();
                                }),
                                child: Padding(
                                  padding: EdgeInsets.all(r.s(6)),
                                  child: Icon(
                                    MdiIcons.closeCircle,
                                    size: r.ms(18),
                                    color: muted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: r.vs(14)),
                      Row(
                        children: [
                          _Chip(
                            r: r,
                            active: tab == "all",
                            label: "All",
                            icon: MdiIcons.messageTextOutline,
                            primaryGradient: primaryGradient,
                            onTap: () => setState(() => tab = "all"),
                            isDark: isDark,
                            muted: muted,
                            border: border,
                          ),
                          SizedBox(width: r.s(10)),
                          _Chip(
                            r: r,
                            active: tab == "unread",
                            label: "Unread",
                            icon: MdiIcons.emailMarkAsUnread,
                            primaryGradient: primaryGradient,
                            onTap: () => setState(() => tab = "unread"),
                            isDark: isDark,
                            muted: muted,
                            border: border,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: r.vs(12)),

                // List
                Expanded(
                  child: NotificationListener<ScrollStartNotification>(
                    onNotification: (n) {
                      _swipeCtrl
                          .forward(from: 0)
                          .then((_) => _swipeCtrl.reverse());
                      return false;
                    },
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: r.s(12),
                        vertical: r.vs(10),
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => SizedBox(height: r.vs(10)),
                      itemBuilder: (context, i) {
                        final item = filtered[i];

                        final slideLeft = Tween<double>(begin: 0, end: -r.s(14))
                            .animate(
                              CurvedAnimation(
                                parent: _swipeCtrl,
                                curve: Curves.easeOut,
                              ),
                            );

                        return AnimatedBuilder(
                          animation: _swipeCtrl,
                          builder: (_, __) {
                            return Transform.translate(
                              offset: Offset(slideLeft.value, 0),
                              child: GestureDetector(
                                onLongPress: () => togglePin(item.id),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(r.s(16)),
                                  onTap: () => onOpenChat(item),
                                  child: Container(
                                    padding: EdgeInsets.all(r.s(10)),
                                    decoration: BoxDecoration(
                                      color: card,
                                      borderRadius: BorderRadius.circular(
                                        r.s(16),
                                      ),
                                      border: Border.all(
                                        color: border,
                                        width: 1,
                                      ),
                                      boxShadow: whiteGlowSoft(r),
                                    ),
                                    child: Stack(
                                      children: [
                                        // ✅ pinned strip + pin (premium)

                                        // content
                                        Row(
                                          children: [
                                            _Avatar(
                                              r: r,
                                              online: item.online,
                                              url: item.avatar,
                                              isDark: isDark,
                                              shadow: whiteGlowSoft(r),
                                            ),
                                            SizedBox(width: r.s(10)),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          item.name,
                                                          maxLines: 3,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            color: onBg,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: r.ms(15),
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: r.s(8)),
                                                      Text(
                                                        fmtTime(item.lastAt),
                                                        style: TextStyle(
                                                          color: item.unread > 0
                                                              ? primaryGradient
                                                                    .first
                                                              : muted,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: r.ms(11),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: r.vs(4)),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: item.typing
                                                            ? _TypingRow(
                                                                r: r,
                                                                color:
                                                                    primaryGradient
                                                                        .first,
                                                              )
                                                            : Text(
                                                                item
                                                                        .lastMsg
                                                                        .isEmpty
                                                                    ? "—"
                                                                    : item.lastMsg,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                  color:
                                                                      item.unread >
                                                                          0
                                                                      ? onBg
                                                                      : muted,
                                                                  fontWeight:
                                                                      item.unread >
                                                                          0
                                                                      ? FontWeight
                                                                            .w600
                                                                      : FontWeight
                                                                            .w400,
                                                                  fontSize: r
                                                                      .ms(13),
                                                                ),
                                                              ),
                                                      ),
                                                      SizedBox(width: r.s(8)),
                                                      if (item.unread > 0)
                                                        _G(
                                                          colors:
                                                              primaryGradient,
                                                          radius:
                                                              BorderRadius.circular(
                                                                r.s(11),
                                                              ),
                                                          child: Container(
                                                            constraints:
                                                                BoxConstraints(
                                                                  minWidth: r.s(
                                                                    22,
                                                                  ),
                                                                  minHeight: r
                                                                      .s(22),
                                                                ),
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal: r
                                                                      .s(6),
                                                                ),
                                                            alignment: Alignment
                                                                .center,
                                                            child: Text(
                                                              "${item.unread}",
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                fontSize: r.ms(
                                                                  11,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      else
                                                        Container(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: r.s(
                                                                  8,
                                                                ),
                                                                vertical: r.vs(
                                                                  3,
                                                                ),
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: isDark
                                                                ? Colors.white
                                                                      .withOpacity(
                                                                        0.08,
                                                                      )
                                                                : const Color(
                                                                    0xFF6366F1,
                                                                  ).withOpacity(
                                                                    0.08,
                                                                  ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  r.s(8),
                                                                ),
                                                          ),
                                                          child: Text(
                                                            item.label,
                                                            style: TextStyle(
                                                              color:
                                                                  primaryGradient
                                                                      .first,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: r.ms(
                                                                10,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        // ✅ subtle inner highlight (premium)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      r.s(16),
                                                    ),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.white.withOpacity(
                                                      isDark ? 0.04 : 0.06,
                                                    ),
                                                    Colors.transparent,
                                                    Colors.black.withOpacity(
                                                      isDark ? 0.04 : 0.00,
                                                    ),
                                                  ],
                                                ),
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
                          },
                        );
                      },
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

  void _openWallpaperModal(
    BuildContext context,
    R r,
    bool isDark,
    Color onBg,
    Color muted,
    Color border,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: r.s(16),
            vertical: r.vs(20),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.80,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(r.s(20)),
              boxShadow: whiteGlowStrong(r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(r.s(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _G(
                    colors: isDark
                        ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                        : [const Color(0xFFF9FAFB), const Color(0xFFF3F4F6)],
                    child: Container(
                      padding: EdgeInsets.all(r.s(16)),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.10),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Choose Theme",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                  fontWeight: FontWeight.w800,
                                  fontSize: r.ms(18),
                                ),
                              ),
                              SizedBox(height: r.vs(2)),
                              Text(
                                "Personalize your chat background",
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
                                  fontSize: r.ms(12),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(r.s(12)),
                            child: Container(
                              width: r.s(36),
                              height: r.s(36),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.10)
                                    : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(r.s(12)),
                              ),
                              child: Icon(
                                MdiIcons.close,
                                size: r.ms(18),
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF374151),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (bgImage != null)
                    InkWell(
                      onTap: () {
                        setState(() => bgImage = null);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: EdgeInsets.fromLTRB(
                          r.s(12),
                          r.s(12),
                          r.s(12),
                          0,
                        ),
                        padding: EdgeInsets.symmetric(vertical: r.vs(10)),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(r.s(10)),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              MdiIcons.refresh,
                              size: r.ms(16),
                              color: primaryGradient.first,
                            ),
                            SizedBox(width: r.s(6)),
                            Text(
                              "Reset to Default",
                              style: TextStyle(
                                color: primaryGradient.first,
                                fontWeight: FontWeight.w600,
                                fontSize: r.ms(13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  Flexible(
                    child: GridView.builder(
                      padding: EdgeInsets.all(r.s(12)),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: r.s(12),
                        crossAxisSpacing: r.s(12),
                        childAspectRatio: 1.3,
                      ),
                      itemCount: wallpapers.length,
                      itemBuilder: (_, i) {
                        final w = wallpapers[i];
                        final uri = w["uri"]!;
                        final selected = bgImage?["uri"] == uri;

                        return InkWell(
                          onTap: () => applyWallpaper(w),
                          borderRadius: BorderRadius.circular(r.s(14)),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(r.s(14)),
                              color: Colors.black,
                              boxShadow: whiteGlowSoft(r),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(r.s(14)),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: CachedNetworkImage(
                                      imageUrl: uri,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: _G(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: r.s(10),
                                          horizontal: r.s(12),
                                        ),
                                        child: Text(
                                          w["name"]!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: r.ms(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (selected)
                                    Positioned(
                                      top: r.s(8),
                                      right: r.s(8),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            r.s(12),
                                          ),
                                          boxShadow: whiteGlowStrong(r),
                                        ),
                                        child: _G(
                                          colors: primaryGradient,
                                          radius: BorderRadius.circular(
                                            r.s(12),
                                          ),
                                          child: SizedBox(
                                            width: r.s(24),
                                            height: r.s(24),
                                            child: Icon(
                                              MdiIcons.check,
                                              color: Colors.white,
                                              size: r.ms(14),
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
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/* -------------------- UI pieces -------------------- */

class _IconBtn extends StatelessWidget {
  final R r;
  final Widget child;
  final VoidCallback onTap;
  final List<BoxShadow> shadow;

  const _IconBtn({
    required this.r,
    required this.child,
    required this.onTap,
    required this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.s(12)),
        boxShadow: shadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(r.s(12)),
        onTap: onTap,
        child: SizedBox(width: r.s(40), height: r.s(40), child: child),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final R r;
  final bool active;
  final String label;
  final IconData icon;
  final List<Color> primaryGradient;
  final VoidCallback onTap;
  final bool isDark;
  final Color muted;
  final Color border;

  const _Chip({
    required this.r,
    required this.active,
    required this.label,
    required this.icon,
    required this.primaryGradient,
    required this.onTap,
    required this.isDark,
    required this.muted,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(r.s(22));

    if (active) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFFFFF).withOpacity(0.22),
              blurRadius: r.s(14),
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: _G(
            colors: primaryGradient,
            radius: radius,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: r.s(14),
                vertical: r.vs(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: r.ms(14), color: Colors.white),
                  SizedBox(width: r.s(4)),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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

    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r.s(14), vertical: r.vs(10)),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.04),
          borderRadius: radius,
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: r.ms(14), color: muted),
            SizedBox(width: r.s(4)),
            Text(
              label,
              style: TextStyle(
                color: muted,
                fontWeight: FontWeight.w600,
                fontSize: r.ms(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final R r;
  final bool online;
  final String? url;
  final bool isDark;
  final List<BoxShadow> shadow;

  const _Avatar({
    required this.r,
    required this.online,
    required this.url,
    required this.isDark,
    required this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final size = r.s(52);

    final img = ClipRRect(
      borderRadius: BorderRadius.circular(r.s(24)),
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
            )
          : Image.asset(
              "assets/icon/splash.png",
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
    );

    final ring = _G(
      colors: const [Color(0xFF10B981), Color(0xFF34D399)],
      radius: BorderRadius.circular(r.s(26)),
      child: Padding(
        padding: EdgeInsets.all(r.s(2)),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(r.s(24)),
          ),
          padding: EdgeInsets.all(r.s(1)),
          child: img,
        ),
      ),
    );

    return SizedBox(
      width: size + r.s(8),
      height: size + r.s(8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r.s(26)),
              boxShadow: shadow,
            ),
            child: online
                ? ring
                : Container(
                    width: size,
                    height: size,
                    padding: EdgeInsets.all(r.s(1)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(r.s(26)),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.15)
                            : Colors.black.withOpacity(0.08),
                        width: 2,
                      ),
                    ),
                    child: img,
                  ),
          ),
          if (online)
            Positioned(
              right: r.s(0),
              bottom: r.s(0),
              child: Container(
                width: r.s(16),
                height: r.s(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(r.s(8)),
                  boxShadow: shadow,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: r.s(10),
                  height: r.s(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(r.s(5)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingRow extends StatelessWidget {
  final R r;
  final Color color;

  const _TypingRow({required this.r, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(0.70),
        SizedBox(width: r.s(3)),
        _dot(0.50),
        SizedBox(width: r.s(3)),
        _dot(0.30),
        SizedBox(width: r.s(6)),
        Text(
          "typing",
          style: TextStyle(
            color: color,
            fontSize: r.ms(12),
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _dot(double opacity) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: r.s(5),
        height: r.s(5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(r.s(2.5)),
        ),
      ),
    );
  }
}
