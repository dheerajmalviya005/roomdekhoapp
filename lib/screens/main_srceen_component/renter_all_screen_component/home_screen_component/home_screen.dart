import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/* -------------------- Responsive scaling -------------------- */
class R {
  final double w;
  final double h;
  R(this.w, this.h);

  double s(double size) => (w / 375.0) * size; // scale
  double vs(double size) => (h / 667.0) * size; // verticalScale
  double ms(double size, [double factor = 0.5]) =>
      size + (s(size) - size) * factor; // moderateScale
}

/* -------------------- Theme Tokens -------------------- */
class Toks {
  final Color background;
  final Color surface;
  final Color elevated;
  final Color border;
  final Color primary;
  final Color onPrimary;
  final Color onBackground;
  final Color muted;
  final Color accent;
  final Color ripple;

  const Toks({
    required this.background,
    required this.surface,
    required this.elevated,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.onBackground,
    required this.muted,
    required this.accent,
    required this.ripple,
  });

  factory Toks.fromTheme(BuildContext context) {
    final th = Theme.of(context);
    final cs = th.colorScheme;

    return Toks(
      background: cs.surface,
      surface: cs.surfaceContainerHighest.withOpacity(0.55),
      elevated: cs.surfaceContainerHighest,
      border: cs.outlineVariant.withOpacity(0.55),
      primary: cs.primary,
      onPrimary: cs.onPrimary,
      onBackground: cs.onSurface,
      muted: cs.onSurface.withOpacity(0.6),
      accent: cs.primary.withOpacity(0.15),
      ripple: cs.primary.withOpacity(0.10),
    );
  }
}

/* -------------------- DATA MODELS -------------------- */
class BannerItem {
  final String id;
  final String title;
  final String sub;
  final String asset;
  final List<Color> gradient;
  const BannerItem({
    required this.id,
    required this.title,
    required this.sub,
    required this.asset,
    required this.gradient,
  });
}

class PosterItem {
  final String id;
  final String title;
  final String description;
  final String code;
  final List<Color> gradient;
  final IconData icon;
  final String timeLeft;
  final String bgAsset;
  final String? discount;
  final String? reward;
  final String? offer;

  const PosterItem({
    required this.id,
    required this.title,
    required this.description,
    required this.code,
    required this.gradient,
    required this.icon,
    required this.timeLeft,
    required this.bgAsset,
    this.discount,
    this.reward,
    this.offer,
  });

  String get badgeText => discount ?? reward ?? offer ?? "";
}

class CategoryItem {
  final String id;
  final IconData icon;
  final String label;
  final Color color;
  const CategoryItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
  });
}

class PropertyItem {
  final String id;
  final String title;
  final String area;
  final String price;
  final double rating;
  final String distance;
  final String asset;
  final List<String> features;

  const PropertyItem({
    required this.id,
    required this.title,
    required this.area,
    required this.price,
    required this.rating,
    required this.distance,
    required this.asset,
    required this.features,
  });
}

/* -------------------- STATIC DATA -------------------- */
const _assets = (
  a0: "assets/icon/splash.png",
  a1: "assets/icon/png-transparent-reset-password-illustration-removebg-preview.png",
  a2: "assets/icon/splash.png", // ✅ fixed typo
);

final List<BannerItem> BANNERS = [
  BannerItem(
    id: "b1",
    title: "Early Bird Discounts",
    sub: "Book now & save up to 25%",
    asset: _assets.a0,
    gradient: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
  ),
  BannerItem(
    id: "b2",
    title: "Zero Brokerage",
    sub: "Direct verified properties only",
    asset: _assets.a1,
    gradient: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
  ),
  BannerItem(
    id: "b3",
    title: "Group Bookings",
    sub: "Extra benefits for 3+ friends",
    asset: _assets.a2,
    gradient: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
  ),
];

final List<PosterItem> POSTERS = [
  PosterItem(
    id: "ad1",
    title: "Pre-Book Exclusive",
    description: "Get ₹2000 Cashback + Free Relocation",
    code: "STU2000",
    gradient: [Color(0xFFFF0080), Color(0xFFFF8C00)],
    icon: MdiIcons.giftOutline,
    timeLeft: "2 days left",
    bgAsset: _assets.a0,
    discount: "20% OFF",
  ),
  PosterItem(
    id: "ad2",
    title: "Refer & Earn",
    description: "Refer friends and earn up to ₹5000",
    code: "REFER500",
    gradient: [Color(0xFF00B4DB), Color(0xFF0083B0)],
    icon: MdiIcons.accountGroup,
    timeLeft: "Limited time",
    bgAsset: _assets.a1,
    reward: "₹5000",
  ),
  PosterItem(
    id: "ad3",
    title: "Festival Special",
    description: "Diwali Dhamaka - No Security Deposit",
    code: "DIWALI23",
    gradient: [Color(0xFF7F00FF), Color(0xFFE100FF)],
    icon: MdiIcons.firework,
    timeLeft: "1 week left",
    bgAsset: _assets.a2,
    offer: "No Deposit",
  ),
];

final List<CategoryItem> CATEGORIES = [
  CategoryItem(
    id: "c1",
    icon: MdiIcons.homeCityOutline,
    label: "Apartments",
    color: Color(0xFFFF6B6B),
  ),
  CategoryItem(
    id: "c2",
    icon: MdiIcons.homeHeart,
    label: "Studios",
    color: Color(0xFF4ECDC4),
  ),
  CategoryItem(
    id: "c3",
    icon: MdiIcons.homeGroup,
    label: "Shared Rooms",
    color: Color(0xFF8E2DE2),
  ),
  CategoryItem(
    id: "c4",
    icon: MdiIcons.shieldCheck,
    label: "Verified",
    color: Color(0xFFFFD166),
  ),
  CategoryItem(
    id: "c5",
    icon: MdiIcons.currencyInr,
    label: "Budget",
    color: Color(0xFF06D6A0),
  ),
  CategoryItem(
    id: "c6",
    icon: MdiIcons.mapMarkerRadiusOutline,
    label: "Near Campus",
    color: Color(0xFF118AB2),
  ),
];

final List<PropertyItem> PROPERTIES = [
  PropertyItem(
    id: "p1",
    title: "City View Residency",
    area: "Near ABC University",
    price: "₹11,500/mo",
    rating: 4.8,
    distance: "1.2 km",
    asset: _assets.a0,
    features: ["AC", "WiFi", "Laundry"],
  ),
  PropertyItem(
    id: "p2",
    title: "Green Park Studios",
    area: "5 min from campus",
    price: "₹14,000/mo",
    rating: 4.6,
    distance: "800 m",
    asset: _assets.a1,
    features: ["Furnished", "Gym", "Parking"],
  ),
  PropertyItem(
    id: "p3",
    title: "Riverside PG",
    area: "Downtown Location",
    price: "₹9,500/mo",
    rating: 4.4,
    distance: "2.1 km",
    asset: _assets.a2,
    features: ["Food", "Security", "Cleaning"],
  ),
  PropertyItem(
    id: "p4",
    title: "Campus Heights",
    area: "Walking distance to college",
    price: "₹12,800/mo",
    rating: 4.9,
    distance: "500 m",
    asset: _assets.a0,
    features: ["Study Room", "Cafeteria", "24/7 Power"],
  ),
];

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _headerCtrl;
  late final AnimationController _searchCtrl;
  late final AnimationController _catCtrl;
  late final AnimationController _posterCtrl;
  late final AnimationController _cardCtrl;

  late final PageController _bannerPC;
  late PageController _posterPC;

  double _bannerPage = 0;
  double _posterPage = 0;

  String _activeCategory = "c1";
  bool _searchFocused = false;
  bool _hasFilters = false;
  String? _copiedCode;

  final Map<String, bool> _liked = {};
  late final ScrollController _scrollCtrl;
  double _scrollY = 0;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _searchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _catCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _posterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scrollCtrl = ScrollController()
      ..addListener(() {
        if (!mounted) return;
        setState(() => _scrollY = _scrollCtrl.offset);
      });

    _bannerPC = PageController(viewportFraction: 1.0)
      ..addListener(() {
        setState(() => _bannerPage = _bannerPC.page ?? 0);
      });

    _posterPC = PageController(viewportFraction: 0.78)
      ..addListener(() {
        setState(() => _posterPage = _posterPC.page ?? 0);
      });

    Future.microtask(() async {
      _headerCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 100));
      _searchCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 100));
      _catCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 100));
      _posterCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 100));
      _cardCtrl.forward();
    });
  }

  @override
  void dispose() {
    _bannerPC.dispose();
    _posterPC.dispose();
    _headerCtrl.dispose();
    _searchCtrl.dispose();
    _catCtrl.dispose();
    _posterCtrl.dispose();
    _cardCtrl.dispose();
    _scrollCtrl.dispose();

    super.dispose();
  }

  void _toggleLike(String id) {
    setState(() {
      _liked[id] = !(_liked[id] ?? false);
    });
  }

  void _copyCoupon(String code) async {
    setState(() => _copiedCode = code);
    await Clipboard.setData(ClipboardData(text: code));
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    setState(() => _copiedCode = null);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final r = R(mq.size.width, mq.size.height);
    final T = Toks.fromTheme(context);
    final double headerMaxH = r.vs(56); // aap yaha 50-70 adjust kar sakte ho
    final double t = (_scrollY / headerMaxH).clamp(0.0, 1.0);

    final double headerH = lerpDouble(headerMaxH, 0, t)!;
    final double headerOpacity = lerpDouble(1, 0, t)!;
    final tabBarSpace = r.vs(80);

    final topProps = PROPERTIES.take(3).toList();
    final remainingProps = PROPERTIES.skip(3).toList();

    // 🔥 Almost full-width cards
    final posterVF = mq.size.width < 380 ? 0.94 : 0.90;

    if ((_posterPC.viewportFraction - posterVF).abs() > 0.001) {
      final old = _posterPC;
      _posterPC =
          PageController(
            viewportFraction: posterVF,
            initialPage: old.initialPage,
          )..addListener(() {
            setState(() => _posterPage = _posterPC.page ?? 0);
          });
    }

    // ✅ equal spacing token
    final sectionGap = r.vs(22);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: T.background,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.dark
            : Brightness.light,
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: T.background,
          body: Column(
            children: [
              // ---------------- Header (Animated) ----------------
              // ---------------- Header (Collapsible) ----------------
              ClipRect(
                child: SizedBox(
                  height: headerH,
                  child: IgnorePointer(
                    ignoring: t > 0.98, // fully hidden => no taps
                    child: Opacity(
                      opacity: headerOpacity,
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _headerCtrl,
                          curve: Curves.easeOut,
                        ),
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, -0.15),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _headerCtrl,
                                  curve: Curves.easeOut,
                                ),
                              ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: r.s(20),
                              vertical: r.vs(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        MdiIcons.mapMarkerRadius,
                                        size: r.ms(22),
                                        color: T.primary,
                                      ),
                                      SizedBox(width: r.s(10)),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Current Location",
                                            style: TextStyle(
                                              fontSize: r.ms(14),
                                              fontWeight: FontWeight.w700,
                                              color: T.onBackground,
                                            ),
                                          ),
                                          SizedBox(height: r.vs(2)),
                                          Text(
                                            "University Campus Area",
                                            style: TextStyle(
                                              fontSize: r.ms(12),
                                              color: T.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      context.pushNamed('notification'),
                                  child: Container(
                                    width: r.s(36),
                                    height: r.s(36),
                                    decoration: BoxDecoration(
                                      color: T.elevated,
                                      borderRadius: BorderRadius.circular(
                                        r.s(14),
                                      ),
                                      border: Border.all(
                                        color: T.border,
                                        width: 1,
                                      ),
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          MdiIcons.bellOutline,
                                          size: r.ms(18),
                                          color: T.onBackground,
                                        ),
                                        Positioned(
                                          right: r.s(2),
                                          top: r.s(-3),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: r.s(5),
                                              vertical: r.vs(1.5),
                                            ),
                                            decoration: BoxDecoration(
                                              color: T.primary,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    r.s(10),
                                                  ),
                                            ),
                                            child: Text(
                                              "3",
                                              style: TextStyle(
                                                fontSize: r.ms(10),
                                                fontWeight: FontWeight.w900,
                                                color: T.onPrimary,
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
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ---------------- Search (Animated) ----------------
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _searchCtrl,
                  curve: Curves.easeOut,
                ),
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, -0.12),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _searchCtrl,
                          curve: Curves.easeOut,
                        ),
                      ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      r.s(20),
                      r.vs(5),
                      r.s(20),
                      r.vs(10),
                    ),
                    child: Container(
                      height: r.vs(42),
                      decoration: BoxDecoration(
                        color: T.surface,
                        borderRadius: BorderRadius.circular(r.s(12)),
                        border: Border.all(color: T.border, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: r.s(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    MdiIcons.magnify,
                                    size: r.ms(18),
                                    color: T.muted,
                                  ),
                                  SizedBox(width: r.s(10)),
                                  Expanded(
                                    child: Focus(
                                      onFocusChange: (f) =>
                                          setState(() => _searchFocused = f),
                                      child: TextField(
                                        style: TextStyle(
                                          fontSize: r.ms(14),
                                          color: T.onBackground,
                                        ),
                                        decoration: InputDecoration(
                                          hintText:
                                              "Search properties or areas...",
                                          hintStyle: TextStyle(color: T.muted),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: r.s(8)),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _hasFilters = !_hasFilters),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: _searchFocused ? 0.9 : 1.0,
                                child: Container(
                                  height: r.vs(42) * 0.80,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: r.s(14),
                                  ),
                                  decoration: BoxDecoration(
                                    color: T.primary,
                                    borderRadius: BorderRadius.circular(r.s(8)),
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        MdiIcons.filterVariant,
                                        size: r.ms(16),
                                        color: T.onPrimary,
                                      ),
                                      if (_hasFilters)
                                        Positioned(
                                          right: -6,
                                          top: -6,
                                          child: Container(
                                            width: r.s(18),
                                            height: r.s(18),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF4757),
                                              borderRadius:
                                                  BorderRadius.circular(r.s(9)),
                                              border: Border.all(
                                                color: T.surface,
                                                width: 2,
                                              ),
                                            ),
                                          ),
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
              ),

              // ---------------- Content ----------------
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: EdgeInsets.only(bottom: r.vs(16)),
                  child: Column(
                    children: [
                      SizedBox(height: sectionGap),

                      _BannerCarousel(
                        r: r,
                        T: T,
                        page: _bannerPage,
                        controller: _bannerPC,
                      ),

                      SizedBox(height: sectionGap),

                      // -------- Categories --------
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _catCtrl,
                          curve: Curves.easeOut,
                        ),
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, 0.10),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _catCtrl,
                                  curve: Curves.easeOut,
                                ),
                              ),
                          child: Column(
                            children: [
                              _SectionHeader(
                                r: r,
                                T: T,
                                title: "Browse Categories",
                                rightText: "See all",
                                onRightTap: () {},
                              ),
                              SizedBox(height: r.vs(8)),
                              SizedBox(
                                height: r.vs(110),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: r.s(20),
                                  ),
                                  itemCount: CATEGORIES.length,
                                  itemBuilder: (context, i) {
                                    final c = CATEGORIES[i];
                                    final active = _activeCategory == c.id;

                                    return Padding(
                                      padding: EdgeInsets.only(right: r.s(12)),
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () => _activeCategory = c.id,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: r.s(15),
                                            vertical: r.vs(12),
                                          ),
                                          decoration: BoxDecoration(
                                            color: active ? c.color : T.surface,
                                            borderRadius: BorderRadius.circular(
                                              r.s(15),
                                            ),
                                            border: Border.all(
                                              color: active
                                                  ? c.color
                                                  : T.border,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  active ? 0.20 : 0.10,
                                                ),
                                                blurRadius: active ? 8 : 6,
                                                offset: Offset(
                                                  0,
                                                  active ? 4 : 2,
                                                ),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: r.s(45),
                                                height: r.s(45),
                                                decoration: BoxDecoration(
                                                  color: active
                                                      ? Colors.white
                                                      : T.ripple,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        r.s(22.5),
                                                      ),
                                                  boxShadow: active
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                  0.2,
                                                                ),
                                                            blurRadius: 4,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  2,
                                                                ),
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: Icon(
                                                  c.icon,
                                                  size: r.ms(20),
                                                  color: active
                                                      ? c.color
                                                      : T.onBackground,
                                                ),
                                              ),
                                              SizedBox(height: r.vs(8)),
                                              Text(
                                                c.label,
                                                style: TextStyle(
                                                  fontSize: r.ms(12),
                                                  fontWeight: FontWeight.w700,
                                                  color: active
                                                      ? Colors.white
                                                      : T.onBackground,
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

                      // -------- Top Picks --------
                      if (topProps.isNotEmpty) ...[
                        SizedBox(height: sectionGap),
                        FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _cardCtrl,
                            curve: Curves.easeOut,
                          ),
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 0.10),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _cardCtrl,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                            child: Column(
                              children: [
                                _SectionHeader(
                                  r: r,
                                  T: T,
                                  title: "Top Picks for You",
                                  subtitle:
                                      "Handpicked options based on students like you",
                                  rightText: "View all",
                                  onRightTap: () {},
                                ),
                                SizedBox(height: r.vs(12)),
                                ...topProps.map(
                                  (p) => _PropertyCard(
                                    r: r,
                                    T: T,
                                    p: p,
                                    liked: _liked[p.id] ?? false,
                                    onLike: () => _toggleLike(p.id),
                                    onView: () {},
                                    onBook: () {
                                      final msg =
                                          "Hi, I'm interested in booking this property:\n"
                                          "🏠 ${p.title}\n"
                                          "📍 ${p.area} • ${p.distance}\n"
                                          "💰 ${p.price}\n"
                                          "⭐ ${p.rating.toStringAsFixed(1)}\n"
                                          "✅ ${p.features.join(", ")}\n\n"
                                          "Please share availability & next steps.";

                                      context.pushNamed(
                                        'chat',
                                        extra: {
                                          "thread_type": "booking",
                                          "prefill_message": msg,

                                          // ✅ full property object (image + all fields)
                                          "property": {
                                            "id": p.id,
                                            "title": p.title,
                                            "area": p.area,
                                            "price": p.price,
                                            "rating": p.rating,
                                            "distance": p.distance,
                                            "asset": p.asset, // ✅ image path
                                            "features": p.features, // ✅ list
                                          },
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // -------- Special Offers (✅ overflow fixed) --------
                      SizedBox(height: sectionGap),
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _posterCtrl,
                          curve: Curves.easeOut,
                        ),
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, 0.10),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _posterCtrl,
                                  curve: Curves.easeOut,
                                ),
                              ),
                          child: Column(
                            children: [
                              _SectionHeader(
                                r: r,
                                T: T,
                                title: "Special Offers",
                                subtitle: "Exclusive deals for students",
                                rightText: "View all",
                                onRightTap: () {
                                  // ✅ GoRouter navigation
                                  context.pushNamed('offers');
                                },
                              ),
                              SizedBox(height: r.vs(12)),
                              Builder(
                                builder: (_) {
                                  final offerH = math.min(
                                    r.vs(230),
                                    mq.size.width * 0.62,
                                  );

                                  return SizedBox(
                                    height: offerH + r.vs(34),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: offerH,
                                          child: PageView.builder(
                                            controller: _posterPC,
                                            itemCount: POSTERS.length,
                                            itemBuilder: (context, index) {
                                              final item = POSTERS[index];
                                              final delta =
                                                  (index - _posterPage);
                                              final scale =
                                                  (1 - (delta.abs() * 0.05))
                                                      .clamp(0.95, 1.0);

                                              return Transform.scale(
                                                scale: scale,
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    left: index == 0
                                                        ? r.s(16)
                                                        : r.s(8),
                                                    right: r.s(8),
                                                  ),

                                                  child: _PosterCard(
                                                    r: r,
                                                    item: item,
                                                    copied:
                                                        _copiedCode ==
                                                        item.code,
                                                    onCopy: () =>
                                                        _copyCoupon(item.code),
                                                    onClaim: () {},
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        SizedBox(height: r.vs(12)),
                                        _PosterDots(
                                          r: r,
                                          T: T,
                                          page: _posterPage,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // -------- Sponsored Space --------
                      SizedBox(height: sectionGap),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: r.s(20)),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Sponsored Space",
                                    style: TextStyle(
                                      fontSize: r.ms(20),
                                      fontWeight: FontWeight.w800,
                                      color: T.onBackground,
                                    ),
                                  ),
                                  SizedBox(height: r.vs(2)),
                                  Text(
                                    "Perfect spot for partner brands & services",
                                    style: TextStyle(
                                      fontSize: r.ms(12),
                                      color: T.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: r.vs(15)),
                            Container(
                              padding: EdgeInsets.all(r.s(18)),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(r.s(20)),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF232526),
                                    Color(0xFF414345),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: r.s(10),
                                      vertical: r.vs(4),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.16),
                                      borderRadius: BorderRadius.circular(
                                        r.s(20),
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.35),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          MdiIcons.bullhornOutline,
                                          size: r.ms(14),
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: r.s(6)),
                                        Text(
                                          "PROMOTED SPACE",
                                          style: TextStyle(
                                            fontSize: r.ms(10),
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: r.vs(12)),
                                  Text(
                                    "Your Brand, In Front of Thousands of Students",
                                    style: TextStyle(
                                      fontSize: r.ms(18),
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: r.vs(8)),
                                  Text(
                                    "Promote packers & movers, furniture rental, internet plans, coaching classes or any student-focused service right here.",
                                    style: TextStyle(
                                      fontSize: r.ms(13),
                                      height: 1.35,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  SizedBox(height: r.vs(16)),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Want to advertise here?",
                                          style: TextStyle(
                                            fontSize: r.ms(12),
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {},
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: r.s(14),
                                            vertical: r.vs(8),
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              r.s(20),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                "Contact Sales",
                                                style: TextStyle(
                                                  fontSize: r.ms(12),
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              SizedBox(width: r.s(6)),
                                              Icon(
                                                MdiIcons.arrowRight,
                                                size: r.ms(14),
                                                color: Colors.black,
                                              ),
                                            ],
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
                      ),

                      // -------- Remaining Properties --------
                      if (remainingProps.isNotEmpty) ...[
                        SizedBox(height: sectionGap),
                        FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _cardCtrl,
                            curve: Curves.easeOut,
                          ),
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 0.10),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _cardCtrl,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                            child: Column(
                              children: [
                                _SectionHeader(
                                  r: r,
                                  T: T,
                                  title: "More Properties Near You",
                                  subtitle: "Explore more living options",
                                  rightText: "View all",
                                  onRightTap: () {},
                                ),
                                SizedBox(height: r.vs(12)),
                                ...remainingProps.map(
                                  (p) => _PropertyCard(
                                    r: r,
                                    T: T,
                                    p: p,
                                    liked: _liked[p.id] ?? false,
                                    onLike: () => _toggleLike(p.id),
                                    onView: () {},
                                    onBook: () {
                                      final msg =
                                          "Hi, I'm interested in booking this property:\n"
                                          "🏠 ${p.title}\n"
                                          "📍 ${p.area} • ${p.distance}\n"
                                          "💰 ${p.price}\n"
                                          "⭐ ${p.rating.toStringAsFixed(1)}\n"
                                          "✅ ${p.features.join(", ")}\n\n"
                                          "Please share availability & next steps.";

                                      context.pushNamed(
                                        'chat',
                                        extra: {
                                          "thread_type": "booking",
                                          "prefill_message": msg,

                                          // ✅ full property object (image + all fields)
                                          "property": {
                                            "id": p.id,
                                            "title": p.title,
                                            "area": p.area,
                                            "price": p.price,
                                            "rating": p.rating,
                                            "distance": p.distance,
                                            "asset": p.asset, // ✅ image path
                                            "features": p.features, // ✅ list
                                          },
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: tabBarSpace),
                    ],
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

/* -------------------- Widgets -------------------- */

class _SectionHeader extends StatelessWidget {
  final R r;
  final Toks T;
  final String title;
  final String? subtitle;
  final String? rightText;
  final VoidCallback? onRightTap;

  const _SectionHeader({
    required this.r,
    required this.T,
    required this.title,
    this.subtitle,
    this.rightText,
    this.onRightTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.s(20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: r.ms(20),
                    fontWeight: FontWeight.w800,
                    color: T.onBackground,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: r.vs(2)),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: r.ms(12), color: T.muted),
                  ),
                ],
              ],
            ),
          ),
          if (rightText != null)
            GestureDetector(
              onTap: onRightTap,
              child: Text(
                rightText!,
                style: TextStyle(
                  fontSize: r.ms(14),
                  fontWeight: FontWeight.w700,
                  color: T.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  final R r;
  final Toks T;
  final double page;
  final PageController controller;

  const _BannerCarousel({
    required this.r,
    required this.T,
    required this.page,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    // ✅ responsive banner height (overflow safe)
    final bannerH = math.min(r.vs(190), w * 0.46);

    return Column(
      children: [
        SizedBox(
          height: bannerH,
          child: PageView.builder(
            controller: controller,
            itemCount: BANNERS.length,
            itemBuilder: (context, index) {
              final item = BANNERS[index];
              final delta = (index - page);
              final scale = (1 - (delta.abs() * 0.10)).clamp(0.90, 1.0);

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: w - r.s(40),
                  margin: EdgeInsets.symmetric(horizontal: r.s(20)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(r.s(20)),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: item.gradient,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(r.s(20)),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final imgSize = math.min(
                          r.s(120),
                          c.maxHeight - r.vs(32),
                        );

                        return Padding(
                          padding: EdgeInsets.all(r.s(16)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: r.s(10),
                                        vertical: r.vs(4),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.20),
                                        borderRadius: BorderRadius.circular(
                                          r.s(20),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            MdiIcons.lightningBolt,
                                            size: r.ms(14),
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: r.s(5)),
                                          Text(
                                            "LIMITED OFFER",
                                            style: TextStyle(
                                              fontSize: r.ms(10),
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: r.vs(8)),
                                    Text(
                                      item.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: r.ms(20),
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                    ),
                                    SizedBox(height: r.vs(4)),
                                    Text(
                                      item.sub,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: r.ms(13),
                                        height: 1.2,
                                      ),
                                    ),
                                    const Spacer(),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: r.s(14),
                                          vertical: r.vs(8),
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.20),
                                          borderRadius: BorderRadius.circular(
                                            r.s(12),
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.30,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "Explore Now",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: r.ms(13),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            SizedBox(width: r.s(6)),
                                            Icon(
                                              MdiIcons.arrowRight,
                                              size: r.ms(16),
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: r.s(10)),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(r.s(15)),
                                child: Image.asset(
                                  item.asset,
                                  width: imgSize,
                                  height: imgSize,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: r.vs(12)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(BANNERS.length, (i) {
            final t = (1 - (page - i).abs()).clamp(0.0, 1.0);
            final dotW = lerpDouble(8, 20, t)!;
            final dotO = lerpDouble(0.3, 1.0, t)!;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: EdgeInsets.symmetric(horizontal: r.s(4)),
              width: dotW,
              height: r.s(8),
              decoration: BoxDecoration(
                color: T.primary.withOpacity(dotO),
                borderRadius: BorderRadius.circular(r.s(4)),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PosterDots extends StatelessWidget {
  final R r;
  final Toks T;
  final double page;
  const _PosterDots({required this.r, required this.T, required this.page});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(POSTERS.length, (i) {
        final t = (1 - (page - i).abs()).clamp(0.0, 1.0);
        final w = lerpDouble(6, 16, t)!;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: r.s(3)),
          width: w,
          height: r.s(6),
          decoration: BoxDecoration(
            color: T.primary,
            borderRadius: BorderRadius.circular(r.s(3)),
          ),
        );
      }),
    );
  }
}

class _PosterCard extends StatelessWidget {
  final R r;
  final PosterItem item;
  final bool copied;
  final VoidCallback onCopy;
  final VoidCallback onClaim;

  const _PosterCard({
    required this.r,
    required this.item,
    required this.copied,
    required this.onCopy,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(r.s(20)),
      child: LayoutBuilder(
        builder: (context, c) {
          // ✅ responsive padding/gaps
          final pad = math.min(r.s(18), c.maxHeight * 0.10);
          final gap = math.max(r.vs(8), c.maxHeight * 0.04);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: item.gradient,
              ),
            ),
            child: Stack(
              children: [
                Opacity(
                  opacity: 0.10,
                  child: Stack(
                    children: [
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.15,
                    child: Image.asset(item.bgAsset, fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(pad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: r.s(12),
                              vertical: r.vs(6),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(r.s(20)),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.30),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.icon,
                                  size: r.ms(14),
                                  color: Colors.white,
                                ),
                                SizedBox(width: r.s(6)),
                                Text(
                                  item.badgeText,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: r.ms(12),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: r.s(10),
                              vertical: r.vs(4),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.30),
                              borderRadius: BorderRadius.circular(r.s(12)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  MdiIcons.clockOutline,
                                  size: r.ms(12),
                                  color: Colors.white,
                                ),
                                SizedBox(width: r.s(4)),
                                Text(
                                  item.timeLeft,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: r.ms(10),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: gap),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: r.ms(20),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: r.vs(4)),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: r.ms(13),
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: r.s(12),
                                vertical: r.vs(10),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(r.s(12)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    MdiIcons.tagOutline,
                                    size: r.ms(16),
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: r.s(8)),
                                  Expanded(
                                    child: Text(
                                      item.code,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: r.ms(15),
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: r.s(10)),
                          GestureDetector(
                            onTap: onCopy,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: r.s(12),
                                vertical: r.vs(10),
                              ),
                              decoration: BoxDecoration(
                                color: copied
                                    ? const Color(0xCC4CD964)
                                    : Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(r.s(12)),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.30),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    copied
                                        ? MdiIcons.check
                                        : MdiIcons.contentCopy,
                                    size: r.ms(14),
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: r.s(6)),
                                  Text(
                                    copied ? "Copied!" : "Copy",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: r.ms(12),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: gap),
                      Align(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: GestureDetector(
                            onTap: onClaim,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: r.s(16),
                                vertical: r.vs(8),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(r.s(15)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Claim Offer",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: r.ms(14),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(width: r.s(8)),
                                  Icon(
                                    MdiIcons.arrowRight,
                                    size: r.ms(16),
                                    color: Colors.black,
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
                Positioned(
                  bottom: -30,
                  right: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: -20,
                  left: -20,
                  child: CustomPaint(
                    size: const Size(60, 60),
                    painter: _TrianglePainter(
                      color: Colors.white.withOpacity(0.10),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PropertyCard extends StatelessWidget {
  final R r;
  final Toks T;
  final PropertyItem p;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback onView;
  final VoidCallback onBook;

  const _PropertyCard({
    required this.r,
    required this.T,
    required this.p,
    required this.liked,
    required this.onLike,
    required this.onView,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.vs(20)),
      child: Container(
        decoration: BoxDecoration(
          color: T.elevated,
          borderRadius: BorderRadius.circular(r.s(20)),
          border: Border.all(color: T.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            SizedBox(
              height: r.vs(180),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(p.asset, fit: BoxFit.cover),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: r.vs(180) * 0.50,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xB3000000)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: r.s(15),
                    left: r.s(15),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: r.s(12),
                        vertical: r.vs(6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(r.s(20)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.20),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        p.price,
                        style: TextStyle(
                          fontSize: r.ms(14),
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: r.s(15),
                    right: r.s(15),
                    child: GestureDetector(
                      onTap: onLike,
                      child: Container(
                        width: r.s(40),
                        height: r.s(40),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.30),
                          borderRadius: BorderRadius.circular(r.s(20)),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          liked ? MdiIcons.heart : MdiIcons.heartOutline,
                          size: r.ms(22),
                          color: liked ? const Color(0xFFFF4757) : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: r.s(15),
                    right: r.s(15),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: r.s(10),
                        vertical: r.vs(4),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.60),
                        borderRadius: BorderRadius.circular(r.s(20)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            MdiIcons.star,
                            size: r.ms(12),
                            color: const Color(0xFFFFD700),
                          ),
                          SizedBox(width: r.s(4)),
                          Text(
                            p.rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: r.ms(12),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(r.s(15)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: TextStyle(
                      fontSize: r.ms(18),
                      fontWeight: FontWeight.w800,
                      color: T.onBackground,
                    ),
                  ),
                  SizedBox(height: r.vs(5)),
                  Row(
                    children: [
                      Icon(
                        MdiIcons.mapMarkerOutline,
                        size: r.ms(12),
                        color: T.muted,
                      ),
                      SizedBox(width: r.s(5)),
                      Expanded(
                        child: Text(
                          "${p.area} • ${p.distance}",
                          style: TextStyle(fontSize: r.ms(12), color: T.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.vs(10)),
                  Wrap(
                    spacing: r.s(8),
                    runSpacing: r.vs(5),
                    children: p.features
                        .map(
                          (f) => Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: r.s(10),
                              vertical: r.vs(5),
                            ),
                            decoration: BoxDecoration(
                              color: T.ripple,
                              borderRadius: BorderRadius.circular(r.s(15)),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: r.ms(11),
                                fontWeight: FontWeight.w600,
                                color: T.onBackground,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: r.vs(15)),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(r.s(12)),
                          onTap: () {
                            context.pushNamed('propertydetails');
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: r.vs(10)),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(r.s(12)),
                              border: Border.all(color: T.border, width: 1),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "View Details",
                              style: TextStyle(
                                fontSize: r.ms(14),
                                fontWeight: FontWeight.w700,
                                color: T.onBackground,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: r.s(10)),
                      Expanded(
                        child: GestureDetector(
                          onTap: onBook,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: r.vs(10)),
                            decoration: BoxDecoration(
                              color: T.primary,
                              borderRadius: BorderRadius.circular(r.s(12)),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Book Now",
                                  style: TextStyle(
                                    fontSize: r.ms(14),
                                    fontWeight: FontWeight.w800,
                                    color: T.onPrimary,
                                  ),
                                ),
                                SizedBox(width: r.s(5)),
                                Icon(
                                  MdiIcons.arrowRight,
                                  size: r.ms(16),
                                  color: T.onPrimary,
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
          ],
        ),
      ),
    );
  }
}
