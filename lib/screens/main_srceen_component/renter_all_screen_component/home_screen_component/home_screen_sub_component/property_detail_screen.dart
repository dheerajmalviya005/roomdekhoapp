import 'dart:async';
import 'dart:ui' show lerpDouble, ImageFilter;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// ================== RESPONSIVE SCALER ==================
class R {
  final double w;
  final double h;
  R(this.w, this.h);

  double s(double v) => (w / 375.0) * v;
  double vs(double v) => (h / 812.0) * v;
  double ms(double v, [double factor = 0.5]) => v + (s(v) - v) * factor;
}

/// ================== THEME TOKENS ==================
class ThemeTokens {
  final Color background;
  final Color elevated;
  final Color surface;
  final Color border;

  final Color onBackground;
  final Color muted;

  final Color primary;
  final Color onPrimary;

  final Color accent;

  ThemeTokens({
    required this.background,
    required this.elevated,
    required this.surface,
    required this.border,
    required this.onBackground,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.accent,
  });

  factory ThemeTokens.fromContext(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return ThemeTokens(
        background: const Color(0xFF0B1220),
        elevated: const Color(0xFF0F172A),
        surface: const Color(0xFF111827),
        border: Colors.white.withOpacity(0.10),
        onBackground: Colors.white,
        muted: const Color(0xFF9CA3AF),
        primary: const Color(0xFF6366F1),
        onPrimary: Colors.white,
        accent: const Color(0xFFF59E0B),
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
      accent: const Color(0xFFF59E0B),
    );
  }
}

/// ================== SHADOWS (premium) ==================
List<BoxShadow> softShadow(R r) => [
  BoxShadow(
    color: Colors.black.withOpacity(0.10),
    blurRadius: r.s(18),
    offset: Offset(0, r.vs(10)),
  ),
  BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: r.s(8),
    offset: Offset(0, r.vs(4)),
  ),
];

List<BoxShadow> whiteGlow(
  R r, {
  double op = 0.12,
  double blur = 16,
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

/// ================== TABS ==================
class TabItem {
  final String id;
  final String label;
  const TabItem({required this.id, required this.label});
}

final List<TabItem> TABS = List.generate(10, (i) {
  const labels = [
    "Overview",
    "Rooms",
    "Amenities",
    "Policies",
    "Map",
    "Nearby",
    "Reviews",
    "Photos",
    "Host",
    "FAQ",
  ];
  return TabItem(id: "tab-${i + 1}", label: labels[i]);
});

/// ================== SCREEN ==================
class PropertyDetailScreenFlutter extends StatefulWidget {
  const PropertyDetailScreenFlutter({super.key});

  @override
  State<PropertyDetailScreenFlutter> createState() =>
      _PropertyDetailScreenFlutterState();
}

class _PropertyDetailScreenFlutterState
    extends State<PropertyDetailScreenFlutter>
    with TickerProviderStateMixin {
  static const double HEADER_PCT = 0.45; // image height
  late final ScrollController _scroll;
  late final PageController _page;
  Timer? _timer;

  double scrollY = 0;
  int activeIndex = 0;

  bool visitOpen = false;
  bool submitting = false;

  /// ✅ Online images (no asset missing error)
  final List<String> imageUrls = const [
    "https://images.unsplash.com/photo-1505691938895-1758d7feb511?q=80&w=1600&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?q=80&w=1600&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?q=80&w=1600&auto=format&fit=crop",
  ];

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    _page = PageController();

    _scroll.addListener(() {
      setState(() => scrollY = _scroll.offset);
    });

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      if (!_page.hasClients) return;
      final next = (activeIndex + 1) % imageUrls.length;
      _page.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> onSubmitVisit({
    required String fullName,
    required String phone,
    required DateTime date,
    required DateTime time,
  }) async {
    try {
      setState(() => submitting = true);
      await Future.delayed(const Duration(milliseconds: 600));
    } finally {
      if (!mounted) return;
      setState(() {
        submitting = false;
        visitOpen = false;
      });
    }
  }

  double _clamp01(double t) => t < 0 ? 0 : (t > 1 ? 1 : t);

  @override
  Widget build(BuildContext context) {
    final T = ThemeTokens.fromContext(context);
    final mq = MediaQuery.of(context);
    final r = R(mq.size.width, mq.size.height);
    final topPad = MediaQuery.of(context).padding.top;

    final screenH = mq.size.height;
    final headerHMax = screenH * HEADER_PCT;

    // ✅ remove top gap: no SafeArea + correct overlap
    final overlap = r.vs(34);

    // Interpolations
    final tHeader = _clamp01(scrollY / headerHMax);
    final headerOpacity = lerpDouble(1, 0, _clamp01(scrollY / headerHMax))!;
    final tabsStart = headerHMax * 0.40;
    final tabsEnd = headerHMax * 0.75;
    final tabsT = _clamp01((scrollY - tabsStart) / (tabsEnd - tabsStart));
    final tabsOpacity = lerpDouble(0, 1, tabsT)!;
    final tabsTranslateY = lerpDouble(-16, 0, tabsT)!;

    return Scaffold(
      backgroundColor: T.background,
      body: Stack(
        children: [
          // ===== Header =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: headerOpacity,
              child: SizedBox(
                height: headerHMax,
                child: Stack(
                  children: [
                    // Carousel (network)
                    PageView.builder(
                      controller: _page,
                      itemCount: imageUrls.length,
                      onPageChanged: (i) => setState(() => activeIndex = i),
                      itemBuilder: (_, i) {
                        return SizedBox.expand(
                          child: CachedNetworkImage(
                            imageUrl: imageUrls[i],
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: Colors.black12),
                            errorWidget: (_, __, ___) =>
                                Container(color: Colors.black12),
                          ),
                        );
                      },
                    ),

                    // Overlay gradient
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.45),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.65),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Dots
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: r.vs(84),
                      child: IgnorePointer(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(imageUrls.length, (i) {
                            final active = i == activeIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.symmetric(horizontal: r.s(3)),
                              width: active ? r.s(18) : r.s(7),
                              height: r.s(7),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white.withOpacity(0.95)
                                    : Colors.white.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(r.s(10)),
                                boxShadow: active ? whiteGlow(r, op: 0.12) : [],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                    // Top bar (safe via topPad)
                    Positioned(
                      top: topPad + r.vs(10),
                      left: r.s(16),
                      right: r.s(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _GlassIconBtn(
                            r: r,
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          Row(
                            children: [
                              _GlassIconBtn(
                                r: r,
                                icon: Icons.share,
                                onTap: () {},
                                marginRight: r.s(10),
                              ),
                              _GlassIconBtn(
                                r: r,
                                icon: Icons.favorite_border,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===== Tabs bar (appears on scroll) =====
          Positioned(
            top: topPad + r.vs(56),
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: tabsOpacity < 0.05,
              child: Opacity(
                opacity: tabsOpacity,
                child: Transform.translate(
                  offset: Offset(0, tabsTranslateY),
                  child: Container(
                    decoration: BoxDecoration(
                      color: T.background,
                      border: Border(
                        bottom: BorderSide(color: T.border, width: 1),
                      ),
                      boxShadow: softShadow(r),
                    ),
                    child: SizedBox(
                      height: r.vs(52),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: r.s(16)),
                        itemBuilder: (_, i) => _Chip(
                          r: r,
                          T: T,
                          label: TABS[i].label,
                          onTap: () {},
                        ),
                        separatorBuilder: (_, __) => SizedBox(width: r.s(8)),
                        itemCount: TABS.length,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ===== Content =====
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: (_) => false,
              child: SingleChildScrollView(
                controller: _scroll,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: r.vs(10)),
                child: Column(
                  children: [
                    // ✅ no extra blank: just header - overlap
                    SizedBox(height: headerHMax - overlap),

                    // Card container (overlap on header)
                    Transform.translate(
                      offset: Offset(0, -overlap),
                      child: Container(
                        decoration: BoxDecoration(
                          color: T.elevated,
                          border: Border.all(color: T.border, width: 1),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(r.s(28)),
                            topRight: Radius.circular(r.s(28)),
                          ),
                          boxShadow: softShadow(r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // drag handle (premium)
                            Padding(
                              padding: EdgeInsets.only(top: r.vs(10)),
                              child: Center(
                                child: Container(
                                  width: r.s(44),
                                  height: r.vs(5),
                                  decoration: BoxDecoration(
                                    color: T.border,
                                    borderRadius: BorderRadius.circular(
                                      r.s(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                r.s(20),
                                r.vs(14),
                                r.s(20),
                                r.vs(0),
                              ),
                              child: Column(
                                children: [
                                  // title + rating
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "City View Residency",
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: r.ms(22),
                                                fontWeight: FontWeight.w900,
                                                color: T.onBackground,
                                                height: 1.15,
                                              ),
                                            ),
                                            SizedBox(height: r.vs(4)),
                                            Text(
                                              "Near ABC University",
                                              style: TextStyle(
                                                fontSize: r.ms(13),
                                                color: T.muted,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: r.s(10)),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: r.s(10),
                                              vertical: r.vs(6),
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFD166),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    r.s(10),
                                                  ),
                                              boxShadow: whiteGlow(r, op: 0.10),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.star,
                                                  size: r.ms(14),
                                                  color: Colors.black,
                                                ),
                                                SizedBox(width: r.s(4)),
                                                Text(
                                                  "4.6",
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: r.ms(12),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: r.vs(4)),
                                          Text(
                                            "(128 reviews)",
                                            style: TextStyle(
                                              color: T.muted,
                                              fontSize: r.ms(10),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: r.vs(14)),

                                  // location row
                                  Row(
                                    children: [
                                      Container(
                                        width: r.s(34),
                                        height: r.s(34),
                                        decoration: BoxDecoration(
                                          color: T.surface,
                                          borderRadius: BorderRadius.circular(
                                            r.s(18),
                                          ),
                                          border: Border.all(
                                            color: T.border,
                                            width: 1,
                                          ),
                                          boxShadow: softShadow(r),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.location_on,
                                          size: r.ms(18),
                                          color: T.accent,
                                        ),
                                      ),
                                      SizedBox(width: r.s(10)),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Downtown, Sector 4",
                                            style: TextStyle(
                                              color: T.onBackground,
                                              fontSize: r.ms(13),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Text(
                                            "0.8 km from campus",
                                            style: TextStyle(
                                              color: T.muted,
                                              fontSize: r.ms(11),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: r.vs(16)),
                                  Container(height: 1, color: T.border),
                                  SizedBox(height: r.vs(16)),

                                  // rent row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Monthly Rent",
                                            style: TextStyle(
                                              color: T.muted,
                                              fontSize: r.ms(12),
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          SizedBox(height: r.vs(2)),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                "₹11,500",
                                                style: TextStyle(
                                                  color: T.primary,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: r.ms(26),
                                                ),
                                              ),
                                              SizedBox(width: r.s(4)),
                                              Text(
                                                "/mo",
                                                style: TextStyle(
                                                  color: T.muted,
                                                  fontSize: r.ms(14),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: r.s(12),
                                          vertical: r.vs(8),
                                        ),
                                        decoration: BoxDecoration(
                                          color: T.surface,
                                          borderRadius: BorderRadius.circular(
                                            r.s(12),
                                          ),
                                          border: Border.all(
                                            color: T.border,
                                            width: 1,
                                          ),
                                          boxShadow: softShadow(r),
                                        ),
                                        child: Text(
                                          "Bills Included",
                                          style: TextStyle(
                                            color: T.onBackground,
                                            fontSize: r.ms(11),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: r.vs(12)),

                            // Action cards
                            SizedBox(
                              height: r.vs(112),
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(
                                  horizontal: r.s(4),
                                ),
                                children: [
                                  _ActionCard(
                                    r: r,
                                    T: T,
                                    icon: Icons.calendar_month,
                                    iconColor: T.accent,
                                    iconBg: T.accent.withOpacity(0.12),
                                    label: "Schedule Visit",
                                    onTap: () =>
                                        setState(() => visitOpen = true),
                                  ),
                                  SizedBox(width: r.s(12)),
                                  _ActionCard(
                                    r: r,
                                    T: T,
                                    icon: Icons.chat_bubble_outline,
                                    iconColor: const Color(0xFF22C55E),
                                    iconBg: const Color(
                                      0xFF22C55E,
                                    ).withOpacity(0.12),
                                    label: "Chat",
                                    onTap: () {
                                      // context.push('/chat');
                                    },
                                  ),
                                  SizedBox(width: r.s(12)),
                                  _ActionCard(
                                    r: r,
                                    T: T,
                                    icon: Icons.phone,
                                    iconColor: const Color(0xFF3B82F6),
                                    iconBg: const Color(
                                      0xFF3B82F6,
                                    ).withOpacity(0.12),
                                    label: "Call Host",
                                    onTap: () {},
                                  ),
                                  SizedBox(width: r.s(12)),
                                ],
                              ),
                            ),

                            // Amenities
                            AmenitiesFlutter(T: T),

                            SizedBox(height: r.vs(140)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===== Bottom sticky bar =====
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                r.s(20),
                r.vs(14),
                r.s(20),
                r.vs(18),
              ),
              decoration: BoxDecoration(
                color: T.surface,
                border: Border(top: BorderSide(color: T.border, width: 1)),
                boxShadow: softShadow(r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Total Price",
                        style: TextStyle(
                          color: T.muted,
                          fontSize: r.ms(12),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: T.onBackground,
                            fontSize: r.ms(20),
                            fontWeight: FontWeight.w900,
                          ),
                          children: [
                            const TextSpan(text: "₹11,500"),
                            TextSpan(
                              text: "/mo",
                              style: TextStyle(
                                fontSize: r.ms(14),
                                fontWeight: FontWeight.w700,
                                color: T.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(r.s(14)),
                    child: Container(
                      height: r.vs(48),
                      padding: EdgeInsets.symmetric(horizontal: r.s(32)),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: T.primary,
                        borderRadius: BorderRadius.circular(r.s(14)),
                        boxShadow: whiteGlow(r, op: 0.14, blur: 18, y: 10),
                      ),
                      child: Text(
                        "Book Now",
                        style: TextStyle(
                          color: T.onPrimary,
                          fontSize: r.ms(16),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== Schedule Visit Modal =====
          if (visitOpen)
            ScheduleVisitModalFlutter(
              T: T,
              onClose: () => setState(() => visitOpen = false),
              loading: submitting,
              onSubmit: onSubmitVisit,
            ),
        ],
      ),
    );
  }
}

/// ================== UI PARTS ==================
class _GlassIconBtn extends StatelessWidget {
  final R r;
  final IconData icon;
  final VoidCallback onTap;
  final double? marginRight;

  const _GlassIconBtn({
    required this.r,
    required this.icon,
    required this.onTap,
    this.marginRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: marginRight ?? 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.s(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: r.s(14),
            offset: Offset(0, r.vs(8)),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(r.s(20)),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r.s(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: r.s(40),
              height: r.s(40),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.28),
                borderRadius: BorderRadius.circular(r.s(20)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: r.ms(22), color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final R r;
  final ThemeTokens T;
  final String label;
  final VoidCallback onTap;

  const _Chip({
    required this.r,
    required this.T,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(r.s(20)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.vs(8)),
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: BorderRadius.circular(r.s(20)),
          border: Border.all(color: T.border, width: 1),
          boxShadow: softShadow(r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: T.onBackground,
            fontSize: r.ms(12),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final R r;
  final ThemeTokens T;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.r,
    required this.T,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(r.s(16)),
      onTap: onTap,
      child: Container(
        width: r.s(110),
        height: r.vs(96),
        padding: EdgeInsets.all(r.s(10)),
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: BorderRadius.circular(r.s(16)),
          border: Border.all(color: T.border, width: 1),
          boxShadow: softShadow(r),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: r.s(42),
              height: r.s(42),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(r.s(21)),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: r.ms(24)),
            ),
            SizedBox(height: r.vs(10)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: T.onBackground,
                fontSize: r.ms(11),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================== Amenities ==================
class AmenitiesFlutter extends StatelessWidget {
  final ThemeTokens T;
  const AmenitiesFlutter({super.key, required this.T});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final r = R(mq.size.width, mq.size.height);

    final items = const [
      ("Wi-Fi", Icons.wifi),
      ("Laundry", Icons.local_laundry_service),
      ("Gym", Icons.fitness_center),
      ("CCTV", Icons.videocam),
      ("Study", Icons.menu_book),
      ("Cafe", Icons.local_cafe),
      ("AC", Icons.ac_unit),
      ("Parking", Icons.directions_car),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), r.vs(12), r.s(20), r.vs(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Amenities",
            style: TextStyle(
              color: T.onBackground,
              fontWeight: FontWeight.w900,
              fontSize: r.ms(18),
            ),
          ),
          SizedBox(height: r.vs(12)),
          Wrap(
            spacing: r.s(10),
            runSpacing: r.s(10),
            children: items.map((x) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: r.s(12),
                  vertical: r.vs(9),
                ),
                decoration: BoxDecoration(
                  color: T.surface,
                  borderRadius: BorderRadius.circular(r.s(12)),
                  border: Border.all(color: T.border, width: 1),
                  boxShadow: softShadow(r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(x.$2, size: r.ms(16), color: T.accent),
                    SizedBox(width: r.s(6)),
                    Text(
                      x.$1,
                      style: TextStyle(
                        color: T.onBackground,
                        fontWeight: FontWeight.w800,
                        fontSize: r.ms(12),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// ================== Schedule Visit Modal ==================
class ScheduleVisitModalFlutter extends StatefulWidget {
  final ThemeTokens T;
  final VoidCallback onClose;
  final bool loading;
  final Future<void> Function({
    required String fullName,
    required String phone,
    required DateTime date,
    required DateTime time,
  })
  onSubmit;

  const ScheduleVisitModalFlutter({
    super.key,
    required this.T,
    required this.onClose,
    required this.loading,
    required this.onSubmit,
  });

  @override
  State<ScheduleVisitModalFlutter> createState() =>
      _ScheduleVisitModalFlutterState();
}

class _ScheduleVisitModalFlutterState extends State<ScheduleVisitModalFlutter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  final fullNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  DateTime date = DateTime.now();
  DateTime time = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    11,
    0,
  );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.95,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    fullNameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: date.isBefore(now) ? now : date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: time.hour, minute: time.minute),
    );
    if (picked != null) {
      setState(() {
        time = DateTime(
          date.year,
          date.month,
          date.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  String _fmtDate(DateTime d) =>
      "${d.day.toString().padLeft(2, "0")}/${d.month.toString().padLeft(2, "0")}/${d.year}";
  String _fmtTime(DateTime d) {
    final h = d.hour;
    final m = d.minute.toString().padLeft(2, "0");
    final ap = h >= 12 ? "PM" : "AM";
    final hh = h % 12 == 0 ? 12 : h % 12;
    return "${hh.toString().padLeft(2, "0")}:$m $ap";
  }

  @override
  Widget build(BuildContext context) {
    final T = widget.T;
    final mq = MediaQuery.of(context);
    final r = R(mq.size.width, mq.size.height);

    return Positioned.fill(
      child: FadeTransition(
        opacity: _fade,
        child: Material(
          color: Colors.black.withOpacity(0.60),
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: const SizedBox(),
                ),
              ),
              Center(
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    margin: EdgeInsets.all(r.s(20)),
                    decoration: BoxDecoration(
                      color: T.elevated,
                      borderRadius: BorderRadius.circular(r.s(24)),
                      border: Border.all(color: T.border, width: 1),
                      boxShadow: softShadow(r),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(r.s(18)),
                          decoration: BoxDecoration(
                            color: T.surface,
                            border: Border(
                              bottom: BorderSide(color: T.border, width: 1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Schedule a Visit",
                                    style: TextStyle(
                                      color: T.onBackground,
                                      fontWeight: FontWeight.w900,
                                      fontSize: r.ms(18),
                                    ),
                                  ),
                                  SizedBox(height: r.vs(2)),
                                  Text(
                                    "See the property in person",
                                    style: TextStyle(
                                      color: T.muted,
                                      fontSize: r.ms(12),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: widget.onClose,
                                borderRadius: BorderRadius.circular(r.s(12)),
                                child: Container(
                                  padding: EdgeInsets.all(r.s(8)),
                                  decoration: BoxDecoration(
                                    color: T.background,
                                    borderRadius: BorderRadius.circular(
                                      r.s(12),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: r.ms(20),
                                    color: T.onBackground,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(r.s(18)),
                          child: Column(
                            children: [
                              _LabeledInput(
                                r: r,
                                T: T,
                                label: "Full Name",
                                controller: fullNameCtrl,
                                hint: "e.g. John Doe",
                                keyboardType: TextInputType.name,
                              ),
                              SizedBox(height: r.vs(14)),
                              _LabeledInput(
                                r: r,
                                T: T,
                                label: "Phone Number",
                                controller: phoneCtrl,
                                hint: "e.g. 98765 43210",
                                keyboardType: TextInputType.phone,
                              ),
                              SizedBox(height: r.vs(14)),
                              Row(
                                children: [
                                  Expanded(
                                    child: _PickerTile(
                                      r: r,
                                      T: T,
                                      label: "Date",
                                      value: _fmtDate(date),
                                      icon: Icons.calendar_month,
                                      onTap: pickDate,
                                    ),
                                  ),
                                  SizedBox(width: r.s(12)),
                                  Expanded(
                                    child: _PickerTile(
                                      r: r,
                                      T: T,
                                      label: "Time",
                                      value: _fmtTime(time),
                                      icon: Icons.access_time,
                                      onTap: pickTime,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            r.s(18),
                            0,
                            r.s(18),
                            r.s(18),
                          ),
                          child: InkWell(
                            onTap: widget.loading
                                ? null
                                : () => widget.onSubmit(
                                    fullName: fullNameCtrl.text.trim(),
                                    phone: phoneCtrl.text.trim(),
                                    date: date,
                                    time: time,
                                  ),
                            borderRadius: BorderRadius.circular(r.s(14)),
                            child: Container(
                              height: r.vs(52),
                              decoration: BoxDecoration(
                                color: T.primary,
                                borderRadius: BorderRadius.circular(r.s(14)),
                                boxShadow: whiteGlow(
                                  r,
                                  op: 0.14,
                                  blur: 18,
                                  y: 10,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.loading
                                        ? "Processing..."
                                        : "Confirm Schedule",
                                    style: TextStyle(
                                      color: T.onPrimary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: r.ms(16),
                                    ),
                                  ),
                                  SizedBox(width: r.s(8)),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: r.ms(20),
                                    color: T.onPrimary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _LabeledInput extends StatelessWidget {
  final R r;
  final ThemeTokens T;
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _LabeledInput({
    required this.r,
    required this.T,
    required this.label,
    required this.controller,
    required this.hint,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: r.s(4), bottom: r.vs(6)),
          child: Text(
            label,
            style: TextStyle(
              color: T.onBackground,
              fontWeight: FontWeight.w800,
              fontSize: r.ms(12),
            ),
          ),
        ),
        Container(
          height: r.vs(48),
          padding: EdgeInsets.symmetric(horizontal: r.s(16)),
          decoration: BoxDecoration(
            color: T.background,
            borderRadius: BorderRadius.circular(r.s(12)),
            border: Border.all(color: T.border, width: 1),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(
              color: T.onBackground,
              fontWeight: FontWeight.w700,
              fontSize: r.ms(14),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: T.muted),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  final R r;
  final ThemeTokens T;
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerTile({
    required this.r,
    required this.T,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: r.s(4), bottom: r.vs(6)),
          child: Text(
            label,
            style: TextStyle(
              color: T.onBackground,
              fontWeight: FontWeight.w800,
              fontSize: r.ms(12),
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r.s(12)),
          child: Container(
            height: r.vs(48),
            padding: EdgeInsets.symmetric(horizontal: r.s(16)),
            decoration: BoxDecoration(
              color: T.background,
              borderRadius: BorderRadius.circular(r.s(12)),
              border: Border.all(color: T.border, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: T.onBackground,
                    fontWeight: FontWeight.w700,
                    fontSize: r.ms(14),
                  ),
                ),
                Icon(icon, size: r.ms(18), color: T.accent),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
