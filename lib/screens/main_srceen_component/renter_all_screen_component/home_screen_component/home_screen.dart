import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// -------------------- DATA MODELS --------------------
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
  final String asset;
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
    required this.asset,
    this.discount,
    this.reward,
    this.offer,
  });
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

// -------------------- MAIN --------------------
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ---- controllers ----
  final PageController _bannerCtrl = PageController();
  late final PageController _posterCtrl;

  // ---- intro anims like RN ----
  late final AnimationController _intro;
  late final Animation<double> _headerA;
  late final Animation<double> _searchA;
  late final Animation<double> _catA;
  late final Animation<double> _posterA;
  late final Animation<double> _cardA;

  // ---- state ----
  final Map<String, bool> _liked = {};
  String _activeCategory = "c1";
  bool _searchFocused = false;
  bool _hasFilters = false;
  String? _copiedCode;

  double _bannerPage = 0;
  double _posterPage = 0;

  static const double _tabBarSpace = 80;

  static const List<BannerItem> BANNERS = [
    BannerItem(
      id: "b1",
      title: "Early Bird Discounts",
      sub: "Book now & save up to 25%",
      asset: "assets/icon/splash.png",
      gradient: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    ),
    BannerItem(
      id: "b2",
      title: "Zero Brokerage",
      sub: "Direct verified properties only",
      asset:
          "assets/icon/png-transparent-reset-password-illustration-removebg-preview.png",
      gradient: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
    ),
    BannerItem(
      id: "b3",
      title: "Group Bookings",
      sub: "Extra benefits for 3+ friends",
      asset:
          "assets/icon/pngtree-worries-before-exams-isolated-cartoon-vector-illustrations-picture-image_8710545.png",
      gradient: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    ),
  ];

  static final List<PosterItem> POSTERS = [
    PosterItem(
      id: "ad1",
      title: "Pre-Book Exclusive",
      description: "Get ₹2000 Cashback + Free Relocation",
      code: "STU2000",
      gradient: const [Color(0xFFFF0080), Color(0xFFFF8C00)],
      icon: MdiIcons.giftOutline,
      timeLeft: "2 days left",
      asset: "assets/icon/splash.png",
      discount: "20% OFF",
    ),
    PosterItem(
      id: "ad2",
      title: "Refer & Earn",
      description: "Refer friends and earn up to ₹5000",
      code: "REFER500",
      gradient: const [Color(0xFF00B4DB), Color(0xFF0083B0)],
      icon: MdiIcons.accountGroup,
      timeLeft: "Limited time",
      asset:
          "assets/icon/png-transparent-reset-password-illustration-removebg-preview.png",
      reward: "₹5000",
    ),
    PosterItem(
      id: "ad3",
      title: "Festival Special",
      description: "Diwali Dhamaka - No Security Deposit",
      code: "DIWALI23",
      gradient: const [Color(0xFF7F00FF), Color(0xFFE100FF)],
      icon: MdiIcons.partyPopper, // ✅ festival ki jagah (safe icon)
      timeLeft: "1 week left",
      asset:
          "assets/icon/pngtree-worries-before-exams-isolated-cartoon-vector-illustrations-picture-image_8710545.png",
      offer: "No Deposit",
    ),
  ];

  static final List<CategoryItem> CATEGORIES = [
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

  static const List<PropertyItem> PROPERTIES = [
    PropertyItem(
      id: "p1",
      title: "City View Residency",
      area: "Near ABC University",
      price: "₹11,500/mo",
      rating: 4.8,
      distance: "1.2 km",
      asset: "assets/icon/splash.png",
      features: ["AC", "WiFi", "Laundry"],
    ),
    PropertyItem(
      id: "p2",
      title: "Green Park Studios",
      area: "5 min from campus",
      price: "₹14,000/mo",
      rating: 4.6,
      distance: "800 m",
      asset:
          "assets/icon/png-transparent-reset-password-illustration-removebg-preview.png",
      features: ["Furnished", "Gym", "Parking"],
    ),
    PropertyItem(
      id: "p3",
      title: "Riverside PG",
      area: "Downtown Location",
      price: "₹9,500/mo",
      rating: 4.4,
      distance: "2.1 km",
      asset:
          "assets/icon/pngtree-worries-before-exams-isolated-cartoon-vector-illustrations-picture-image_8710545.png",
      features: ["Food", "Security", "Cleaning"],
    ),
    PropertyItem(
      id: "p4",
      title: "Campus Heights",
      area: "Walking distance to college",
      price: "₹12,800/mo",
      rating: 4.9,
      distance: "500 m",
      asset: "assets/icon/splash.png",
      features: ["Study Room", "Cafeteria", "24/7 Power"],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _posterCtrl = PageController(viewportFraction: 0.82);

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerA = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.00, 0.35, curve: Curves.easeOut),
    );
    _searchA = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.10, 0.55, curve: Curves.easeOut),
    );
    _catA = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.20, 0.70, curve: Curves.easeOut),
    );
    _posterA = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.30, 0.85, curve: Curves.easeOut),
    );
    _cardA = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.40, 1.00, curve: Curves.easeOut),
    );

    _intro.forward();

    _bannerCtrl.addListener(() {
      final p = _bannerCtrl.page ?? 0;
      setState(() => _bannerPage = p);
    });

    _posterCtrl.addListener(() {
      final p = _posterCtrl.page ?? 0;
      setState(() => _posterPage = p);
    });
  }

  @override
  void dispose() {
    _bannerCtrl.dispose();
    _posterCtrl.dispose();
    _intro.dispose();
    super.dispose();
  }

  // ---- RN size-matters style scaling (same spirit) ----
  double _scale(BuildContext context, double v) {
    final w = MediaQuery.of(context).size.width;
    return (w / 375.0) * v;
  }

  double _vScale(BuildContext context, double v) {
    final h = MediaQuery.of(context).size.height;
    return (h / 667.0) * v;
  }

  double _mScale(BuildContext context, double v, [double factor = 0.5]) {
    final s = _scale(context, v);
    return v + (s - v) * factor;
  }

  void _toggleLike(String id) {
    setState(() {
      _liked[id] = !(_liked[id] ?? false);
    });
  }

  void _copyCouponCode(String code) async {
    setState(() => _copiedCode = code);
    await Clipboard.setData(ClipboardData(text: code));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedCode = null);
    });
  }

  // -------------------- WIDGETS --------------------
  Widget _dotsBar({
    required BuildContext context,
    required int count,
    required double page,
    required Color activeColor,
    required double height,
    required double minW,
    required double maxW,
  }) {
    final s = _scale(context, 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final t = (1 - (page - i).abs()).clamp(0.0, 1.0);
        final w = minW + (maxW - minW) * t;
        final opacity = 0.3 + (1.0 - 0.3) * t;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: EdgeInsets.symmetric(horizontal: _scale(context, 4)),
          width: w * s,
          height: height * s,
          decoration: BoxDecoration(
            color: activeColor.withOpacity(opacity),
            borderRadius: BorderRadius.circular((height / 2) * s),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // ---- Theme mapping like your RN T ----
    final Tbackground = cs.surface;
    final Tsurface = cs.surface;
    final Televated = cs.surfaceContainerHighest; // close to elevated look
    final Tborder = cs.outlineVariant;
    final Tprimary = cs.primary;
    final TonPrimary = cs.onPrimary;
    final TonBackground = cs.onSurface;
    final Tmuted = cs.onSurface.withOpacity(0.65);
    final Tripple = cs.surfaceTint.withOpacity(0.10);

    final topProperties = PROPERTIES.take(3).toList();
    final remainingProperties = PROPERTIES.skip(3).toList();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Tbackground,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: theme.brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Column(
            children: [
              // ---------------- HEADER ----------------
              FadeTransition(
                opacity: _headerA,
                child: SlideTransition(
                  position: _headerA.drive(
                    Tween(
                      begin: const Offset(0, -0.25),
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeOut)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _scale(context, 20),
                      vertical: _vScale(context, 10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                MdiIcons.mapMarkerRadius,
                                size: _mScale(context, 22),
                                color: Tprimary,
                              ),
                              SizedBox(width: _scale(context, 10)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Current Location",
                                    style: TextStyle(
                                      fontSize: _mScale(context, 14),
                                      fontWeight: FontWeight.w700,
                                      color: TonBackground,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "University Campus Area",
                                    style: TextStyle(
                                      fontSize: _mScale(context, 12),
                                      color: Tmuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // BellBadge (simple)
                        _BellBadge(
                          count: 3,
                          bg: cs.secondary,
                          iconColor: TonPrimary,
                          badgeBg: Tprimary,
                          badgeText: TonPrimary,
                          onTap: () => Navigator.pushNamed(
                            context,
                            "NotificationScreen",
                          ),
                          size: _scale(context, 26),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ---------------- SEARCH ----------------
              FadeTransition(
                opacity: _searchA,
                child: SlideTransition(
                  position: _searchA.drive(
                    Tween(
                      begin: const Offset(0, -0.15),
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeOut)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _scale(context, 20),
                    ),
                    child: Container(
                      height: _vScale(context, 42),
                      decoration: BoxDecoration(
                        color: Tsurface,
                        borderRadius: BorderRadius.circular(
                          _scale(context, 12),
                        ),
                        border: Border.all(color: Tborder, width: 1),
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
                                horizontal: _scale(context, 12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    MdiIcons.magnify,
                                    size: _mScale(context, 18),
                                    color: Tmuted,
                                  ),
                                  SizedBox(width: _scale(context, 10)),
                                  Expanded(
                                    child: Focus(
                                      onFocusChange: (f) =>
                                          setState(() => _searchFocused = f),
                                      child: TextField(
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText:
                                              "Search properties or areas...",
                                          hintStyle: TextStyle(color: Tmuted),
                                        ),
                                        style: TextStyle(
                                          color: TonBackground,
                                          fontSize: _mScale(context, 14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: _scale(context, 8)),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                InkWell(
                                  onTap: () => setState(
                                    () => _hasFilters = !_hasFilters,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    _scale(context, 8),
                                  ),
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 150),
                                    opacity: _searchFocused ? 0.9 : 1,
                                    child: Container(
                                      height: _vScale(context, 42) * 0.80,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: _scale(context, 14),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Tprimary,
                                        borderRadius: BorderRadius.circular(
                                          _scale(context, 8),
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          MdiIcons.filterVariant,
                                          size: _mScale(context, 16),
                                          color: TonPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_hasFilters)
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: Container(
                                      width: _scale(context, 18),
                                      height: _scale(context, 18),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF4757),
                                        borderRadius: BorderRadius.circular(
                                          _scale(context, 9),
                                        ),
                                        border: Border.all(
                                          color: Tsurface,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        "3",
                                        style: TextStyle(
                                          fontSize: _mScale(context, 10),
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
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
                ),
              ),

              SizedBox(height: _vScale(context, 10)),

              // ---------------- CONTENT ----------------
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: _vScale(context, 20)),
                    child: Column(
                      children: [
                        // ---------- Banner carousel ----------
                        SizedBox(
                          height: _vScale(context, 160) + _vScale(context, 32),
                          child: Column(
                            children: [
                              SizedBox(
                                height: _vScale(context, 160),
                                child: PageView.builder(
                                  controller: _bannerCtrl,
                                  itemCount: BANNERS.length,
                                  itemBuilder: (context, index) {
                                    final item = BANNERS[index];
                                    final t = (1 - (_bannerPage - index).abs())
                                        .clamp(0.0, 1.0);
                                    final scale = 0.9 + (1 - 0.9) * t;

                                    return Transform.scale(
                                      scale: scale,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: _scale(context, 20),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            _scale(context, 20),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: item.gradient,
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                            ),
                                            child: Stack(
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(
                                                    _scale(context, 20),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        _scale(
                                                                          context,
                                                                          10,
                                                                        ),
                                                                    vertical:
                                                                        _vScale(
                                                                          context,
                                                                          4,
                                                                        ),
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                      0.20,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      _scale(
                                                                        context,
                                                                        20,
                                                                      ),
                                                                    ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Icon(
                                                                    MdiIcons
                                                                        .lightningBolt,
                                                                    size: _mScale(
                                                                      context,
                                                                      14,
                                                                    ),
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                  SizedBox(
                                                                    width: _scale(
                                                                      context,
                                                                      5,
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    "LIMITED OFFER",
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          _mScale(
                                                                            context,
                                                                            10,
                                                                          ),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height: _vScale(
                                                                context,
                                                                10,
                                                              ),
                                                            ),
                                                            Text(
                                                              item.title,
                                                              style: TextStyle(
                                                                fontSize:
                                                                    _mScale(
                                                                      context,
                                                                      22,
                                                                    ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height: _vScale(
                                                                context,
                                                                5,
                                                              ),
                                                            ),
                                                            Text(
                                                              item.sub,
                                                              style: TextStyle(
                                                                fontSize:
                                                                    _mScale(
                                                                      context,
                                                                      14,
                                                                    ),
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                      0.90,
                                                                    ),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height: _vScale(
                                                                context,
                                                                15,
                                                              ),
                                                            ),
                                                            InkWell(
                                                              onTap: () {},
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    _scale(
                                                                      context,
                                                                      12,
                                                                    ),
                                                                  ),
                                                              child: Container(
                                                                padding: EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      _scale(
                                                                        context,
                                                                        16,
                                                                      ),
                                                                  vertical:
                                                                      _vScale(
                                                                        context,
                                                                        8,
                                                                      ),
                                                                ),
                                                                decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .white
                                                                      .withOpacity(
                                                                        0.20,
                                                                      ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        _scale(
                                                                          context,
                                                                          12,
                                                                        ),
                                                                      ),
                                                                  border: Border.all(
                                                                    color: Colors
                                                                        .white
                                                                        .withOpacity(
                                                                          0.30,
                                                                        ),
                                                                    width: 1,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Text(
                                                                      "Explore Now",
                                                                      style: TextStyle(
                                                                        fontSize: _mScale(
                                                                          context,
                                                                          13,
                                                                        ),
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width: _scale(
                                                                        context,
                                                                        5,
                                                                      ),
                                                                    ),
                                                                    Icon(
                                                                      MdiIcons
                                                                          .arrowRight,
                                                                      size: _mScale(
                                                                        context,
                                                                        16,
                                                                      ),
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: _scale(
                                                          context,
                                                          10,
                                                        ),
                                                      ),
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              _scale(
                                                                context,
                                                                15,
                                                              ),
                                                            ),
                                                        child: Image.asset(
                                                          item.asset,
                                                          width: _scale(
                                                            context,
                                                            120,
                                                          ),
                                                          height: _vScale(
                                                            context,
                                                            120,
                                                          ),
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: _vScale(context, 15)),
                              _dotsBar(
                                context: context,
                                count: BANNERS.length,
                                page: _bannerPage,
                                activeColor: Tprimary,
                                height: 8,
                                minW: 8,
                                maxW: 20,
                              ),
                            ],
                          ),
                        ),

                        // ---------- Categories ----------
                        FadeTransition(
                          opacity: _catA,
                          child: SlideTransition(
                            position: _catA.drive(
                              Tween(
                                begin: const Offset(0, 0.15),
                                end: Offset.zero,
                              ).chain(CurveTween(curve: Curves.easeOut)),
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: _vScale(context, 25),
                              ),
                              child: Column(
                                children: [
                                  _SectionHeader(
                                    context: context,
                                    title: "Browse Categories",
                                    rightText: "See all",
                                    titleColor: TonBackground,
                                    rightColor: Tprimary,
                                    onRightTap: () {},
                                  ),
                                  SizedBox(
                                    height: _vScale(context, 104),
                                    child: ListView.builder(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: _scale(context, 20),
                                      ),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: CATEGORIES.length,
                                      itemBuilder: (context, i) {
                                        final c = CATEGORIES[i];
                                        final active = _activeCategory == c.id;

                                        return GestureDetector(
                                          onTap: () => setState(
                                            () => _activeCategory = c.id,
                                          ),
                                          child: Container(
                                            margin: EdgeInsets.only(
                                              right: _scale(context, 12),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: _scale(context, 15),
                                              vertical: _vScale(context, 12),
                                            ),
                                            decoration: BoxDecoration(
                                              color: active
                                                  ? c.color
                                                  : Tsurface,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    _scale(context, 15),
                                                  ),
                                              border: Border.all(
                                                color: active
                                                    ? c.color
                                                    : Tborder,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(
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
                                                  width: _scale(context, 45),
                                                  height: _scale(context, 45),
                                                  decoration: BoxDecoration(
                                                    color: active
                                                        ? Colors.white
                                                        : Tripple,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          _scale(context, 22.5),
                                                        ),
                                                    boxShadow: active
                                                        ? [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                    0.20,
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
                                                    size: _mScale(context, 20),
                                                    color: active
                                                        ? c.color
                                                        : TonBackground,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: _vScale(context, 8),
                                                ),
                                                Text(
                                                  c.label,
                                                  style: TextStyle(
                                                    fontSize: _mScale(
                                                      context,
                                                      12,
                                                    ),
                                                    fontWeight: FontWeight.w700,
                                                    color: active
                                                        ? Colors.white
                                                        : TonBackground,
                                                  ),
                                                ),
                                              ],
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
                        ),

                        // ---------- Top Picks ----------
                        if (topProperties.isNotEmpty)
                          FadeTransition(
                            opacity: _cardA,
                            child: SlideTransition(
                              position: _cardA.drive(
                                Tween(
                                  begin: const Offset(0, 0.15),
                                  end: Offset.zero,
                                ).chain(CurveTween(curve: Curves.easeOut)),
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: _vScale(context, 25),
                                ),
                                child: Column(
                                  children: [
                                    _SectionHeader(
                                      context: context,
                                      title: "Top Picks for You",
                                      subtitle:
                                          "Handpicked options based on students like you",
                                      rightText: "View all",
                                      titleColor: TonBackground,
                                      subtitleColor: Tmuted,
                                      rightColor: Tprimary,
                                      onRightTap: () => Navigator.pushNamed(
                                        context,
                                        "FeaturedListSeeAllScreen",
                                      ),
                                    ),
                                    for (final p in topProperties)
                                      _PropertyCard(
                                        context: context,
                                        Tprimary: Tprimary,
                                        TonPrimary: TonPrimary,
                                        TonBackground: TonBackground,
                                        Tmuted: Tmuted,
                                        Televated: Televated,
                                        Tborder: Tborder,
                                        item: p,
                                        liked: _liked[p.id] ?? false,
                                        onLike: () => _toggleLike(p.id),
                                        onOpen: () => Navigator.pushNamed(
                                          context,
                                          "PropertyDetailScreen",
                                        ),
                                        onChat: () => Navigator.pushNamed(
                                          context,
                                          "DetailChatScreen",
                                          arguments: {
                                            "listing": p,
                                            "draft":
                                                "Hi, I'm interested in ${p.title}.",
                                          },
                                        ),
                                        scale: _scale,
                                        vScale: _vScale,
                                        mScale: _mScale,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // ---------- Special Offers ----------
                        FadeTransition(
                          opacity: _posterA,
                          child: SlideTransition(
                            position: _posterA.drive(
                              Tween(
                                begin: const Offset(0, 0.15),
                                end: Offset.zero,
                              ).chain(CurveTween(curve: Curves.easeOut)),
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: _vScale(context, 25),
                              ),
                              child: Column(
                                children: [
                                  _SectionHeader(
                                    context: context,
                                    title: "Special Offers",
                                    subtitle: "Exclusive deals for students",
                                    rightText: "View all",
                                    titleColor: TonBackground,
                                    subtitleColor: Tmuted,
                                    rightColor: Tprimary,
                                    onRightTap: () {},
                                  ),
                                  SizedBox(height: _vScale(context, 5)),
                                  SizedBox(
                                    height:
                                        _vScale(context, 200) +
                                        _vScale(context, 40),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: _vScale(context, 200),
                                          child: PageView.builder(
                                            controller: _posterCtrl,
                                            itemCount: POSTERS.length,
                                            itemBuilder: (context, index) {
                                              final item = POSTERS[index];
                                              final t =
                                                  (1 -
                                                          (_posterPage - index)
                                                              .abs())
                                                      .clamp(0.0, 1.0);
                                              final scale =
                                                  0.95 + (1 - 0.95) * t;

                                              final offerText =
                                                  item.discount ??
                                                  item.reward ??
                                                  item.offer ??
                                                  "";

                                              return Transform.scale(
                                                scale: scale,
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    right: _scale(context, 20),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          _scale(context, 20),
                                                        ),
                                                    child: Stack(
                                                      fit: StackFit.expand,
                                                      children: [
                                                        Container(
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              colors:
                                                                  item.gradient,
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                            ),
                                                          ),
                                                        ),

                                                        // pattern circles (opacity 0.1 like RN)
                                                        Opacity(
                                                          opacity: 0.10,
                                                          child: Stack(
                                                            children: [
                                                              Positioned(
                                                                top: -50,
                                                                right: -50,
                                                                child: Container(
                                                                  width: _scale(
                                                                    context,
                                                                    150,
                                                                  ),
                                                                  height:
                                                                      _scale(
                                                                        context,
                                                                        150,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .white,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          _scale(
                                                                            context,
                                                                            75,
                                                                          ),
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Positioned(
                                                                bottom: -30,
                                                                left: -30,
                                                                child: Container(
                                                                  width: _scale(
                                                                    context,
                                                                    100,
                                                                  ),
                                                                  height:
                                                                      _scale(
                                                                        context,
                                                                        100,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .white,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          _scale(
                                                                            context,
                                                                            50,
                                                                          ),
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),

                                                        // bg image (opacity 0.15 like RN)
                                                        Opacity(
                                                          opacity: 0.15,
                                                          child: Image.asset(
                                                            item.asset,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),

                                                        Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                _scale(
                                                                  context,
                                                                  20,
                                                                ),
                                                              ),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              // offer badge
                                                              Container(
                                                                padding: EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      _scale(
                                                                        context,
                                                                        12,
                                                                      ),
                                                                  vertical:
                                                                      _vScale(
                                                                        context,
                                                                        6,
                                                                      ),
                                                                ),
                                                                decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .white
                                                                      .withOpacity(
                                                                        0.25,
                                                                      ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        _scale(
                                                                          context,
                                                                          20,
                                                                        ),
                                                                      ),
                                                                  border: Border.all(
                                                                    color: Colors
                                                                        .white
                                                                        .withOpacity(
                                                                          0.30,
                                                                        ),
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Icon(
                                                                      item.icon,
                                                                      size: _mScale(
                                                                        context,
                                                                        14,
                                                                      ),
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                    SizedBox(
                                                                      width: _scale(
                                                                        context,
                                                                        6,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      offerText,
                                                                      style: TextStyle(
                                                                        fontSize: _mScale(
                                                                          context,
                                                                          12,
                                                                        ),
                                                                        fontWeight:
                                                                            FontWeight.w800,
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),

                                                              // timer badge
                                                              Align(
                                                                alignment:
                                                                    Alignment
                                                                        .topRight,
                                                                child: Container(
                                                                  padding: EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        _scale(
                                                                          context,
                                                                          10,
                                                                        ),
                                                                    vertical:
                                                                        _vScale(
                                                                          context,
                                                                          4,
                                                                        ),
                                                                  ),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .black
                                                                        .withOpacity(
                                                                          0.30,
                                                                        ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          _scale(
                                                                            context,
                                                                            12,
                                                                          ),
                                                                        ),
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      Icon(
                                                                        MdiIcons
                                                                            .clockOutline,
                                                                        size: _mScale(
                                                                          context,
                                                                          12,
                                                                        ),
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                      SizedBox(
                                                                        width: _scale(
                                                                          context,
                                                                          4,
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        item.timeLeft,
                                                                        style: TextStyle(
                                                                          fontSize: _mScale(
                                                                            context,
                                                                            10,
                                                                          ),
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                          color:
                                                                              Colors.white,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),

                                                              const Spacer(),

                                                              Text(
                                                                item.title,
                                                                style: TextStyle(
                                                                  fontSize:
                                                                      _mScale(
                                                                        context,
                                                                        22,
                                                                      ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900,
                                                                  color: Colors
                                                                      .white,
                                                                  shadows: [
                                                                    Shadow(
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                            0.30,
                                                                          ),
                                                                      blurRadius:
                                                                          3,
                                                                      offset:
                                                                          const Offset(
                                                                            1,
                                                                            1,
                                                                          ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: _vScale(
                                                                  context,
                                                                  5,
                                                                ),
                                                              ),
                                                              Text(
                                                                item.description,
                                                                style: TextStyle(
                                                                  fontSize:
                                                                      _mScale(
                                                                        context,
                                                                        14,
                                                                      ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: Colors
                                                                      .white
                                                                      .withOpacity(
                                                                        0.95,
                                                                      ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: _vScale(
                                                                  context,
                                                                  20,
                                                                ),
                                                              ),

                                                              // coupon row
                                                              Row(
                                                                children: [
                                                                  Expanded(
                                                                    child: Container(
                                                                      padding: EdgeInsets.symmetric(
                                                                        horizontal: _scale(
                                                                          context,
                                                                          15,
                                                                        ),
                                                                        vertical: _vScale(
                                                                          context,
                                                                          10,
                                                                        ),
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors
                                                                            .white
                                                                            .withOpacity(
                                                                              0.15,
                                                                            ),
                                                                        borderRadius: BorderRadius.circular(
                                                                          _scale(
                                                                            context,
                                                                            12,
                                                                          ),
                                                                        ),
                                                                        border: Border.all(
                                                                          color: Colors.white.withOpacity(
                                                                            0.25,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      child: Row(
                                                                        children: [
                                                                          Icon(
                                                                            MdiIcons.tagOutline,
                                                                            size: _mScale(
                                                                              context,
                                                                              16,
                                                                            ),
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                          SizedBox(
                                                                            width: _scale(
                                                                              context,
                                                                              10,
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            item.code,
                                                                            style: TextStyle(
                                                                              fontSize: _mScale(
                                                                                context,
                                                                                16,
                                                                              ),
                                                                              fontWeight: FontWeight.w800,
                                                                              letterSpacing: 1,
                                                                              color: Colors.white,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    width: _scale(
                                                                      context,
                                                                      10,
                                                                    ),
                                                                  ),
                                                                  InkWell(
                                                                    onTap: () =>
                                                                        _copyCouponCode(
                                                                          item.code,
                                                                        ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          _scale(
                                                                            context,
                                                                            12,
                                                                          ),
                                                                        ),
                                                                    child: Container(
                                                                      padding: EdgeInsets.symmetric(
                                                                        horizontal: _scale(
                                                                          context,
                                                                          15,
                                                                        ),
                                                                        vertical: _vScale(
                                                                          context,
                                                                          10,
                                                                        ),
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                            (_copiedCode ==
                                                                                item.code)
                                                                            ? const Color.fromRGBO(
                                                                                76,
                                                                                217,
                                                                                100,
                                                                                0.80,
                                                                              )
                                                                            : Colors.white.withOpacity(
                                                                                0.25,
                                                                              ),
                                                                        borderRadius: BorderRadius.circular(
                                                                          _scale(
                                                                            context,
                                                                            12,
                                                                          ),
                                                                        ),
                                                                        border: Border.all(
                                                                          color: Colors.white.withOpacity(
                                                                            0.30,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      child: Row(
                                                                        children: [
                                                                          Icon(
                                                                            _copiedCode ==
                                                                                    item.code
                                                                                ? MdiIcons.check
                                                                                : MdiIcons.contentCopy,
                                                                            size: _mScale(
                                                                              context,
                                                                              14,
                                                                            ),
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                          SizedBox(
                                                                            width: _scale(
                                                                              context,
                                                                              6,
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            _copiedCode ==
                                                                                    item.code
                                                                                ? "Copied!"
                                                                                : "Copy",
                                                                            style: TextStyle(
                                                                              fontSize: _mScale(
                                                                                context,
                                                                                12,
                                                                              ),
                                                                              fontWeight: FontWeight.w700,
                                                                              color: Colors.white,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),

                                                              SizedBox(
                                                                height: _vScale(
                                                                  context,
                                                                  16,
                                                                ),
                                                              ),

                                                              // CTA button (white)
                                                              Center(
                                                                child: InkWell(
                                                                  onTap: () =>
                                                                      Navigator.pushNamed(
                                                                        context,
                                                                        "OffersScreen",
                                                                      ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        _scale(
                                                                          context,
                                                                          15,
                                                                        ),
                                                                      ),
                                                                  child: Container(
                                                                    padding: EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          _scale(
                                                                            context,
                                                                            16,
                                                                          ),
                                                                      vertical:
                                                                          _vScale(
                                                                            context,
                                                                            5,
                                                                          ),
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: Colors
                                                                          .white,
                                                                      borderRadius: BorderRadius.circular(
                                                                        _scale(
                                                                          context,
                                                                          15,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        Text(
                                                                          "Claim Offer",
                                                                          style: TextStyle(
                                                                            fontSize: _mScale(
                                                                              context,
                                                                              15,
                                                                            ),
                                                                            fontWeight:
                                                                                FontWeight.w900,
                                                                            color:
                                                                                Colors.black,
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          width: _scale(
                                                                            context,
                                                                            8,
                                                                          ),
                                                                        ),
                                                                        Icon(
                                                                          MdiIcons
                                                                              .arrowRight,
                                                                          size: _mScale(
                                                                            context,
                                                                            16,
                                                                          ),
                                                                          color:
                                                                              Colors.white,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),

                                                        // decorative circle + triangle (same feel)
                                                        Positioned(
                                                          bottom: -30,
                                                          right: -30,
                                                          child: Container(
                                                            width: _scale(
                                                              context,
                                                              100,
                                                            ),
                                                            height: _scale(
                                                              context,
                                                              100,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    0.10,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    _scale(
                                                                      context,
                                                                      50,
                                                                    ),
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                        Positioned(
                                                          top: -20,
                                                          left: -20,
                                                          child: Transform.rotate(
                                                            angle: -math.pi / 4,
                                                            child: Container(
                                                              width: _scale(
                                                                context,
                                                                60,
                                                              ),
                                                              height: _scale(
                                                                context,
                                                                60,
                                                              ),
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    0.10,
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
                                        SizedBox(height: _vScale(context, 15)),
                                        _dotsBar(
                                          context: context,
                                          count: POSTERS.length,
                                          page: _posterPage,
                                          activeColor: Tprimary,
                                          height: 6,
                                          minW: 6,
                                          maxW: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ---------- Sponsored Space ----------
                        Padding(
                          padding: EdgeInsets.only(top: _vScale(context, 25)),
                          child: Column(
                            children: [
                              _SectionHeader(
                                context: context,
                                title: "Sponsored Space",
                                subtitle:
                                    "Perfect spot for partner brands & services",
                                titleColor: TonBackground,
                                subtitleColor: Tmuted,
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: _scale(context, 20),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    _scale(context, 20),
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(
                                      _scale(context, 18),
                                    ),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF232526),
                                          Color(0xFF414345),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: _scale(context, 10),
                                            vertical: _vScale(context, 4),
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.16,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              _scale(context, 20),
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.35,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                MdiIcons.bullhornOutline,
                                                size: _mScale(context, 14),
                                                color: Colors.white,
                                              ),
                                              SizedBox(
                                                width: _scale(context, 6),
                                              ),
                                              Text(
                                                "PROMOTED SPACE",
                                                style: TextStyle(
                                                  fontSize: _mScale(
                                                    context,
                                                    10,
                                                  ),
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: _vScale(context, 12)),
                                        Text(
                                          "Your Brand, In Front of Thousands of Students",
                                          style: TextStyle(
                                            fontSize: _mScale(context, 18),
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: _vScale(context, 8)),
                                        Text(
                                          "Promote packers & movers, furniture rental, internet plans, coaching classes or any student-focused service right here.",
                                          style: TextStyle(
                                            fontSize: _mScale(context, 13),
                                            height: 1.3,
                                            color: Colors.white.withOpacity(
                                              0.90,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: _vScale(context, 16)),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "Want to advertise here?",
                                                style: TextStyle(
                                                  fontSize: _mScale(
                                                    context,
                                                    12,
                                                  ),
                                                  color: Colors.white
                                                      .withOpacity(0.80),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => Navigator.pushNamed(
                                                context,
                                                "AdvertiseWithUsScreen",
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    _scale(context, 20),
                                                  ),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: _scale(
                                                    context,
                                                    14,
                                                  ),
                                                  vertical: _vScale(context, 8),
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        _scale(context, 20),
                                                      ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      "Contact Sales",
                                                      style: TextStyle(
                                                        fontSize: _mScale(
                                                          context,
                                                          12,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: _scale(context, 6),
                                                    ),
                                                    Icon(
                                                      MdiIcons.arrowRight,
                                                      size: _mScale(
                                                        context,
                                                        14,
                                                      ),
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
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ---------- Remaining properties ----------
                        if (remainingProperties.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: _vScale(context, 25)),
                            child: Column(
                              children: [
                                _SectionHeader(
                                  context: context,
                                  title: "More Properties Near You",
                                  subtitle: "Explore more living options",
                                  rightText: "View all",
                                  titleColor: TonBackground,
                                  subtitleColor: Tmuted,
                                  rightColor: Tprimary,
                                  onRightTap: () => Navigator.pushNamed(
                                    context,
                                    "FeaturedListSeeAllScreen",
                                  ),
                                ),
                                for (final p in remainingProperties)
                                  _PropertyCard(
                                    context: context,
                                    Tprimary: Tprimary,
                                    TonPrimary: TonPrimary,
                                    TonBackground: TonBackground,
                                    Tmuted: Tmuted,
                                    Televated: Televated,
                                    Tborder: Tborder,
                                    item: p,
                                    liked: _liked[p.id] ?? false,
                                    onLike: () => _toggleLike(p.id),
                                    onOpen: () => Navigator.pushNamed(
                                      context,
                                      "PropertyDetailScreen",
                                    ),
                                    onChat: () => Navigator.pushNamed(
                                      context,
                                      "DetailChatScreen",
                                      arguments: {
                                        "listing": p,
                                        "draft":
                                            "Hi, I'm interested in ${p.title}.",
                                      },
                                    ),
                                    scale: _scale,
                                    vScale: _vScale,
                                    mScale: _mScale,
                                  ),
                              ],
                            ),
                          ),

                        SizedBox(height: _vScale(context, _tabBarSpace)),
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

// -------------------- SECTION HEADER --------------------
class _SectionHeader extends StatelessWidget {
  final BuildContext context;
  final String title;
  final String? subtitle;
  final String? rightText;
  final Color titleColor;
  final Color? subtitleColor;
  final Color? rightColor;
  final VoidCallback? onRightTap;

  const _SectionHeader({
    required this.context,
    required this.title,
    this.subtitle,
    this.rightText,
    required this.titleColor,
    this.subtitleColor,
    this.rightColor,
    this.onRightTap,
  });

  double _scale(BuildContext context, double v) {
    final w = MediaQuery.of(context).size.width;
    return (w / 375.0) * v;
  }

  double _vScale(BuildContext context, double v) {
    final h = MediaQuery.of(context).size.height;
    return (h / 667.0) * v;
  }

  double _mScale(BuildContext context, double v, [double factor = 0.5]) {
    final s = _scale(context, v);
    return v + (s - v) * factor;
  }

  @override
  Widget build(BuildContext _) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _scale(context, 20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _mScale(context, 20),
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: _vScale(context, 2)),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: _mScale(context, 12),
                      color: subtitleColor ?? titleColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (rightText != null)
            InkWell(
              onTap: onRightTap,
              child: Text(
                rightText!,
                style: TextStyle(
                  fontSize: _mScale(context, 14),
                  fontWeight: FontWeight.w700,
                  color: rightColor ?? titleColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// -------------------- PROPERTY CARD --------------------
class _PropertyCard extends StatelessWidget {
  final BuildContext context;
  final Color Tprimary;
  final Color TonPrimary;
  final Color TonBackground;
  final Color Tmuted;
  final Color Televated;
  final Color Tborder;

  final PropertyItem item;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback onOpen;
  final VoidCallback onChat;

  final double Function(BuildContext, double) scale;
  final double Function(BuildContext, double) vScale;
  final double Function(BuildContext, double, [double]) mScale;

  const _PropertyCard({
    required this.context,
    required this.Tprimary,
    required this.TonPrimary,
    required this.TonBackground,
    required this.Tmuted,
    required this.Televated,
    required this.Tborder,
    required this.item,
    required this.liked,
    required this.onLike,
    required this.onOpen,
    required this.onChat,
    required this.scale,
    required this.vScale,
    required this.mScale,
  });

  @override
  Widget build(BuildContext _) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: scale(context, 20),
      ).copyWith(bottom: vScale(context, 20)),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(scale(context, 20)),
        child: Container(
          decoration: BoxDecoration(
            color: Televated,
            borderRadius: BorderRadius.circular(scale(context, 20)),
            border: Border.all(color: Tborder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // image section
              SizedBox(
                height: vScale(context, 180),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(item.asset, fit: BoxFit.cover),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: vScale(context, 180) * 0.50,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color.fromRGBO(0, 0, 0, 0.70),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    // price tag
                    Positioned(
                      top: scale(context, 15),
                      left: scale(context, 15),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: scale(context, 12),
                          vertical: vScale(context, 6),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            scale(context, 20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.20),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          item.price,
                          style: TextStyle(
                            fontSize: mScale(context, 14),
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    // like
                    Positioned(
                      top: scale(context, 15),
                      right: scale(context, 15),
                      child: InkWell(
                        onTap: onLike,
                        borderRadius: BorderRadius.circular(scale(context, 20)),
                        child: Container(
                          width: scale(context, 40),
                          height: scale(context, 40),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.30),
                            borderRadius: BorderRadius.circular(
                              scale(context, 20),
                            ),
                          ),
                          child: Icon(
                            liked ? MdiIcons.heart : MdiIcons.heartOutline,
                            size: mScale(context, 22),
                            color: liked
                                ? const Color(0xFFFF4757)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // rating
                    Positioned(
                      bottom: scale(context, 15),
                      right: scale(context, 15),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: scale(context, 10),
                          vertical: vScale(context, 4),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.60),
                          borderRadius: BorderRadius.circular(
                            scale(context, 20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              MdiIcons.star,
                              size: mScale(context, 12),
                              color: const Color(0xFFFFD700),
                            ),
                            SizedBox(width: scale(context, 4)),
                            Text(
                              item.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: mScale(context, 12),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // details
              Padding(
                padding: EdgeInsets.all(scale(context, 15)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: mScale(context, 18),
                        fontWeight: FontWeight.w800,
                        color: TonBackground,
                      ),
                    ),
                    SizedBox(height: vScale(context, 5)),
                    Row(
                      children: [
                        Icon(
                          MdiIcons.mapMarkerOutline,
                          size: mScale(context, 12),
                          color: Tmuted,
                        ),
                        SizedBox(width: scale(context, 5)),
                        Expanded(
                          child: Text(
                            "${item.area} • ${item.distance}",
                            style: TextStyle(
                              fontSize: mScale(context, 12),
                              color: Tmuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: vScale(context, 10)),
                    Wrap(
                      spacing: scale(context, 8),
                      runSpacing: vScale(context, 5),
                      children: item.features
                          .map(
                            (f) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: scale(context, 10),
                                vertical: vScale(context, 5),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(
                                  scale(context, 15),
                                ),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  fontSize: mScale(context, 11),
                                  fontWeight: FontWeight.w600,
                                  color: TonBackground,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),

                    SizedBox(height: vScale(context, 15)),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: onOpen,
                            borderRadius: BorderRadius.circular(
                              scale(context, 12),
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: vScale(context, 10),
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  scale(context, 12),
                                ),
                                border: Border.all(color: Tborder, width: 1),
                              ),
                              child: Center(
                                child: Text(
                                  "View Details",
                                  style: TextStyle(
                                    fontSize: mScale(context, 14),
                                    fontWeight: FontWeight.w700,
                                    color: TonBackground,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: scale(context, 10)),
                        Expanded(
                          child: InkWell(
                            onTap: onChat,
                            borderRadius: BorderRadius.circular(
                              scale(context, 12),
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: vScale(context, 10),
                              ),
                              decoration: BoxDecoration(
                                color: Tprimary,
                                borderRadius: BorderRadius.circular(
                                  scale(context, 12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Book Now",
                                    style: TextStyle(
                                      fontSize: mScale(context, 14),
                                      fontWeight: FontWeight.w800,
                                      color: TonPrimary,
                                    ),
                                  ),
                                  SizedBox(width: scale(context, 5)),
                                  Icon(
                                    MdiIcons.arrowRight,
                                    size: mScale(context, 16),
                                    color: TonPrimary,
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
      ),
    );
  }
}

// -------------------- SIMPLE BELL BADGE --------------------
class _BellBadge extends StatelessWidget {
  final int count;
  final Color bg;
  final Color iconColor;
  final Color badgeBg;
  final Color badgeText;
  final VoidCallback onTap;
  final double size;

  const _BellBadge({
    required this.count,
    required this.bg,
    required this.iconColor,
    required this.badgeBg,
    required this.badgeText,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(size / 2),
            ),
            child: Icon(
              MdiIcons.bellOutline,
              size: size * 0.62,
              color: iconColor,
            ),
          ),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$count",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeText,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
