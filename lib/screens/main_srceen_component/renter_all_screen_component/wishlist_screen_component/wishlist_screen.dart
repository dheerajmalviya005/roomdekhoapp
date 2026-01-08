import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class WishListScreen extends StatefulWidget {
  const WishListScreen({super.key});

  @override
  State<WishListScreen> createState() => _WishlistScreenState();
}

/* -------------------- Responsive scaling -------------------- */
class R {
  final double w;
  final double h;
  R(this.w, this.h);

  double s(double size) => (w / 375.0) * size;
  double vs(double size) => (h / 667.0) * size;
  double ms(double size, [double factor = 0.5]) =>
      size + (s(size) - size) * factor;
}

/* -------------------- Theme Tokens (RN-like mapping) -------------------- */
class Toks {
  final Color background;
  final Color surface;
  final Color elevated;
  final Color border;
  final Color primary;
  final Color onPrimary;
  final Color onBackground;
  final Color muted;
  final Color ripple;
  final Color success;
  final Color disabled;

  const Toks({
    required this.background,
    required this.surface,
    required this.elevated,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.onBackground,
    required this.muted,
    required this.ripple,
    required this.success,
    required this.disabled,
  });

  factory Toks.fromTheme(BuildContext context) {
    final th = Theme.of(context);
    final cs = th.colorScheme;

    // keep the vibe same as RN; use theme colors but consistent mapping
    return Toks(
      background: cs.surface,
      surface: cs.surfaceContainerHighest.withOpacity(0.65),
      elevated: cs.surfaceContainerHighest,
      border: cs.outlineVariant.withOpacity(0.65),
      primary: cs.primary,
      onPrimary: cs.onPrimary,
      onBackground: cs.onSurface,
      muted: cs.onSurface.withOpacity(0.60),
      ripple: cs.primary.withOpacity(0.12),
      success: const Color(0xFF22C55E), // like RN success green
      disabled: cs.onSurface.withOpacity(0.18),
    );
  }
}

/* -------------------- Models -------------------- */
class WishlistItem {
  final String id;
  final String title;
  final String area;
  final int price;
  final String priceText;
  final String perMonth;
  final double rating;
  final String distance;
  final bool verified;
  final List<String> tags;
  final String asset;
  final int amenities;
  final int booked;
  final bool available;

  const WishlistItem({
    required this.id,
    required this.title,
    required this.area,
    required this.price,
    required this.priceText,
    required this.perMonth,
    required this.rating,
    required this.distance,
    required this.verified,
    required this.tags,
    required this.asset,
    required this.amenities,
    required this.booked,
    required this.available,
  });
}

class ChipPreset {
  final String id;
  final String label;
  final IconData icon;
  const ChipPreset({required this.id, required this.label, required this.icon});
}

class SortOption {
  final String id;
  final String label;
  final IconData icon;
  const SortOption({required this.id, required this.label, required this.icon});
}

class OfferCard {
  final String id;
  final String title;
  final String description;
  final String badge;
  final List<Color> gradient;
  final IconData icon;
  const OfferCard({
    required this.id,
    required this.title,
    required this.description,
    required this.badge,
    required this.gradient,
    required this.icon,
  });
}

class AdImageCard {
  final String id;
  final String brand;
  final String tagline;
  final String asset;
  final String badge;
  const AdImageCard({
    required this.id,
    required this.brand,
    required this.tagline,
    required this.asset,
    required this.badge,
  });
}

class DiscoverItem {
  final String id;
  final String title;
  final String sub;
  final IconData icon;
  const DiscoverItem({
    required this.id,
    required this.title,
    required this.sub,
    required this.icon,
  });
}

/* -------------------- Static Data (same content/colors) -------------------- */
const double _TAB_BAR_SPACE_BASE = 80;

final List<WishlistItem> RAW_WISHLIST = [
  WishlistItem(
    id: "w1",
    title: "City View Residency",
    area: "Near ABC University",
    price: 11500,
    priceText: "₹11,500",
    perMonth: "/month",
    rating: 4.6,
    distance: "0.8 km",
    verified: true,
    tags: ["Apartment", "AC"],
    asset: "assets/icon/splash.png",
    amenities: 3,
    booked: 12,
    available: true,
  ),
  WishlistItem(
    id: "w2",
    title: "Green Park Studios",
    area: "5 min from campus",
    price: 14000,
    priceText: "₹14,000",
    perMonth: "/month",
    rating: 4.9,
    distance: "0.5 km",
    verified: true,
    tags: ["Studio", "Furnished"],
    asset: "assets/icon/splash.png",
    amenities: 4,
    booked: 8,
    available: true,
  ),
  WishlistItem(
    id: "w3",
    title: "Riverside PG",
    area: "Downtown Location",
    price: 9500,
    priceText: "₹9,500",
    perMonth: "/month",
    rating: 4.2,
    distance: "2.2 km",
    verified: false,
    tags: ["Shared", "Food"],
    asset: "assets/icon/splash.png",
    amenities: 2,
    booked: 15,
    available: true,
  ),
  WishlistItem(
    id: "w4",
    title: "Campus Corner",
    area: "Main Street",
    price: 10500,
    priceText: "₹10,500",
    perMonth: "/month",
    rating: 4.3,
    distance: "1.1 km",
    verified: true,
    tags: ["Apartment"],
    asset: "assets/icon/splash.png",
    amenities: 3,
    booked: 5,
    available: false,
  ),
  WishlistItem(
    id: "w5",
    title: "Skyline Premium",
    area: "Tech Park Area",
    price: 15000,
    priceText: "₹15,000",
    perMonth: "/month",
    rating: 4.8,
    distance: "1.7 km",
    verified: true,
    tags: ["Studio", "Premium"],
    asset: "assets/icon/splash.png",
    amenities: 5,
    booked: 20,
    available: true,
  ),
  WishlistItem(
    id: "w6",
    title: "Urban Loft",
    area: "City Center",
    price: 12500,
    priceText: "₹12,500",
    perMonth: "/month",
    rating: 4.5,
    distance: "1.3 km",
    verified: true,
    tags: ["Loft", "Modern"],
    asset: "assets/icon/splash.png",
    amenities: 4,
    booked: 10,
    available: true,
  ),
];

final List<ChipPreset> CHIP_PRESETS = [
  ChipPreset(id: "all", label: "All", icon: MdiIcons.formatListBulleted),
  ChipPreset(id: "near", label: "Near Campus", icon: MdiIcons.mapMarkerRadius),
  ChipPreset(id: "verified", label: "Verified", icon: MdiIcons.shieldCheck),
  ChipPreset(id: "budget", label: "Budget", icon: MdiIcons.currencyInr),
  ChipPreset(id: "studio", label: "Studio", icon: MdiIcons.homeHeart),
  ChipPreset(id: "available", label: "Available", icon: MdiIcons.checkCircle),
];

final List<SortOption> SORT_OPTIONS = [
  SortOption(
    id: "recent",
    label: "Recently Added",
    icon: MdiIcons.clockOutline,
  ),
  SortOption(
    id: "priceAsc",
    label: "Price: Low to High",
    icon: MdiIcons.arrowUp,
  ),
  SortOption(
    id: "priceDesc",
    label: "Price: High to Low",
    icon: MdiIcons.arrowDown,
  ),
  SortOption(id: "ratingDesc", label: "Highest Rated", icon: MdiIcons.star),
  SortOption(
    id: "distance",
    label: "Nearest First",
    icon: MdiIcons.mapMarkerDistance,
  ),
];

final List<OfferCard> OFFER_CARDS = [
  OfferCard(
    id: "offer1",
    title: "Exam Season Offer",
    description: "Get up to ₹1,500 off on stays longer than 3 months.",
    badge: "LIMITED TIME",
    gradient: [Color(0xFFFF5F6D), Color(0xFFFFC371)],
    icon: MdiIcons.giftOutline,
  ),
  OfferCard(
    id: "offer2",
    title: "Group Booking Perks",
    description: "Extra discounts when you and your friends book together.",
    badge: "GROUP DEAL",
    gradient: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
    icon: MdiIcons.accountGroup,
  ),
];

final List<AdImageCard> AD_IMAGES = [
  AdImageCard(
    id: "ad1",
    brand: "MoveEasy Packers",
    tagline: "Safe & fast relocation for students.",
    asset: "assets/icon/splash.png",
    badge: "PACKERS & MOVERS",
  ),
  AdImageCard(
    id: "ad2",
    brand: "SpeedNet Fiber",
    tagline: "High-speed WiFi for your new room.",
    asset: "assets/icon/splash.png",
    badge: "WIFI & INTERNET",
  ),
  AdImageCard(
    id: "ad3",
    brand: "RentMyDesk",
    tagline: "Study tables, chairs & more on rent.",
    asset: "assets/icon/splash.png",
    badge: "FURNITURE RENTAL",
  ),
  AdImageCard(
    id: "ad4",
    brand: "CleanNest Services",
    tagline: "Professional cleaning for hostels & flats.",
    asset: "assets/icon/splash.png",
    badge: "CLEANING SERVICE",
  ),
];

final List<DiscoverItem> DISCOVER_ITEMS = [
  DiscoverItem(
    id: "d1",
    title: "Explore New Localities",
    sub: "Try rooms a bit away from campus & save more.",
    icon: MdiIcons.compassOutline,
  ),
  DiscoverItem(
    id: "d2",
    title: "Verified Only Filter",
    sub: "Check only verified properties for extra safety.",
    icon: MdiIcons.shieldCheck,
  ),
  DiscoverItem(
    id: "d3",
    title: "Try Studio Rooms",
    sub: "Perfect for solo stay with more privacy.",
    icon: MdiIcons.homeHeart,
  ),
];

/* -------------------- Screen -------------------- */
class _WishlistScreenState extends State<WishListScreen>
    with TickerProviderStateMixin {
  late final AnimationController _headerCtrl;
  late final AnimationController _bannerCtrl;
  late final AnimationController _searchCtrl;
  late final AnimationController _cardsCtrl;
  late final AnimationController _sortCtrl;

  String _query = "";
  String _activeChip = "all";
  String _sortBy = "recent";
  bool _showSort = false;

  final List<WishlistItem> _items = List.of(RAW_WISHLIST);

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _bannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _searchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _sortCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    Future.microtask(() async {
      _headerCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 90));
      _bannerCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 90));
      _searchCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 90));
      _cardsCtrl.forward();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _bannerCtrl.dispose();
    _searchCtrl.dispose();
    _cardsCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  List<WishlistItem> get _filteredItems {
    List<WishlistItem> list = List.of(_items);

    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase().trim();
      list = list.where((it) {
        final inTitle = it.title.toLowerCase().contains(q);
        final inArea = it.area.toLowerCase().contains(q);
        final inTags = it.tags.any((t) => t.toLowerCase().contains(q));
        return inTitle || inArea || inTags;
      }).toList();
    }

    switch (_activeChip) {
      case "near":
        list = list.where((it) => _parseKm(it.distance) <= 1.5).toList();
        break;
      case "verified":
        list = list.where((it) => it.verified).toList();
        break;
      case "budget":
        list = list.where((it) => it.price <= 12000).toList();
        break;
      case "studio":
        list = list.where((it) {
          final tags = it.tags.map((e) => e.toLowerCase()).toList();
          return tags.any((t) => t.contains("studio") || t.contains("loft"));
        }).toList();
        break;
      case "available":
        list = list.where((it) => it.available).toList();
        break;
      default:
        break;
    }

    switch (_sortBy) {
      case "priceAsc":
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case "priceDesc":
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case "ratingDesc":
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case "distance":
        list.sort(
          (a, b) => _parseKm(a.distance).compareTo(_parseKm(b.distance)),
        );
        break;
      default:
        break;
    }

    return list;
  }

  double _parseKm(String s) {
    final v = s.toLowerCase().replaceAll("km", "").trim();
    return double.tryParse(v) ?? 999;
  }

  IconData _sortIcon() {
    switch (_sortBy) {
      case "priceAsc":
        return MdiIcons.arrowUp;
      case "priceDesc":
        return MdiIcons.arrowDown;
      case "ratingDesc":
        return MdiIcons.star;
      case "distance":
        return MdiIcons.mapMarkerDistance;
      default:
        return MdiIcons.clockOutline;
    }
  }

  String _sortLabel() {
    switch (_sortBy) {
      case "priceAsc":
        return "Price: Low to High";
      case "priceDesc":
        return "Price: High to Low";
      case "ratingDesc":
        return "Highest Rated";
      case "distance":
        return "Nearest First";
      default:
        return "Recently Added";
    }
  }

  Future<void> _removeFromWishlist(WishlistItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Property"),
        content: Text('Remove "${item.title}" from your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _items.removeWhere((x) => x.id == item.id));
    }
  }

  void _toggleSortDropdown() {
    setState(() => _showSort = !_showSort);
    if (_showSort) {
      _sortCtrl.forward(from: 0);
    } else {
      _sortCtrl.reverse(from: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final r = R(mq.size.width, mq.size.height);
    final T = Toks.fromTheme(context);

    final tabBarSpace = r.vs(_TAB_BAR_SPACE_BASE);

    final filtered = _filteredItems;
    final firstGroup = filtered.take(4).toList();
    final remaining = filtered.skip(4).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: T.background,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: T.background,
          body: Column(
            children: [
              _buildHeader(r, T, filtered.length),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    r.s(16),
                    r.vs(0),
                    r.s(16),
                    r.vs(20),
                  ),
                  child: Column(
                    children: [
                      _buildSearch(r, T),
                      SizedBox(height: r.vs(10)),
                      _buildChips(r, T),
                      SizedBox(height: r.vs(10)),
                      _buildTopPromoBanner(r, T),
                      SizedBox(height: r.vs(12)),

                      if (filtered.isEmpty) ...[
                        _buildEmptyState(r, T),
                        SizedBox(height: tabBarSpace),
                      ] else ...[
                        if (firstGroup.isNotEmpty)
                          _buildPropertyGrid(r, T, firstGroup),
                        SizedBox(height: r.vs(14)),
                        _buildOfferSection(r, T),
                        SizedBox(height: r.vs(14)),
                        _buildAdsSection(r, T),
                        SizedBox(height: r.vs(14)),
                        _buildDiscoverSection(r, T),
                        if (remaining.isNotEmpty) ...[
                          SizedBox(height: r.vs(14)),
                          _sectionHeader(
                            r: r,
                            T: T,
                            title: "More from your Wishlist",
                            subtitle: "Continue exploring your saved rooms",
                          ),
                          SizedBox(height: r.vs(10)),
                          _buildPropertyGrid(r, T, remaining),
                        ],
                        SizedBox(height: tabBarSpace),
                      ],
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

  /* -------------------- Header (with sort dropdown overlay) -------------------- */
  Widget _buildHeader(R r, Toks T, int count) {
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(16), r.vs(10), r.s(16), r.vs(6)),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut),
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, -0.18),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut),
              ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "My Wishlist",
                          style: TextStyle(
                            fontSize: r.ms(24),
                            fontWeight: FontWeight.w800,
                            color: T.onBackground,
                          ),
                        ),
                        SizedBox(height: r.vs(2)),
                        Text(
                          "$count saved properties",
                          style: TextStyle(
                            fontSize: r.ms(12),
                            fontWeight: FontWeight.w500,
                            color: T.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleSortDropdown,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: r.s(12),
                        vertical: r.vs(8),
                      ),
                      decoration: BoxDecoration(
                        color: T.elevated,
                        borderRadius: BorderRadius.circular(r.s(12)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(_sortIcon(), size: r.ms(16), color: T.primary),
                          SizedBox(width: r.s(6)),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: r.s(160)),
                            child: Text(
                              _sortLabel(),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: r.ms(12),
                                fontWeight: FontWeight.w600,
                                color: T.onBackground,
                              ),
                            ),
                          ),
                          SizedBox(width: r.s(6)),
                          Icon(
                            _showSort
                                ? MdiIcons.chevronUp
                                : MdiIcons.chevronDown,
                            size: r.ms(16),
                            color: T.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // dropdown
              Positioned(
                right: 0,
                top: r.vs(54),
                child: IgnorePointer(
                  ignoring: !_showSort,
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _sortCtrl,
                      curve: Curves.easeOut,
                    ),
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, -0.10),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _sortCtrl,
                              curve: Curves.easeOut,
                            ),
                          ),
                      child: Container(
                        width: r.s(190),
                        constraints: BoxConstraints(maxHeight: r.vs(220)),
                        decoration: BoxDecoration(
                          color: T.elevated,
                          borderRadius: BorderRadius.circular(r.s(12)),
                          border: Border.all(color: T.border, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(r.s(12)),
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(vertical: r.vs(6)),
                            shrinkWrap: true,
                            itemCount: SORT_OPTIONS.length,
                            itemBuilder: (ctx, i) {
                              final opt = SORT_OPTIONS[i];
                              final active = _sortBy == opt.id;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _sortBy = opt.id;
                                    _showSort = false;
                                  });
                                  _sortCtrl.reverse(from: 1);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: r.s(12),
                                    vertical: r.vs(10),
                                  ),
                                  color: active ? T.ripple : Colors.transparent,
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: r.s(22),
                                        child: Icon(
                                          opt.icon,
                                          size: r.ms(16),
                                          color: active
                                              ? T.primary
                                              : T.onBackground,
                                        ),
                                      ),
                                      SizedBox(width: r.s(8)),
                                      Expanded(
                                        child: Text(
                                          opt.label,
                                          style: TextStyle(
                                            fontSize: r.ms(13),
                                            fontWeight: FontWeight.w500,
                                            color: active
                                                ? T.primary
                                                : T.onBackground,
                                          ),
                                        ),
                                      ),
                                      if (active)
                                        Icon(
                                          MdiIcons.check,
                                          size: r.ms(16),
                                          color: T.primary,
                                        ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* -------------------- Search -------------------- */
  Widget _buildSearch(R r, Toks T) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _searchCtrl, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.10),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _searchCtrl, curve: Curves.easeOut)),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: r.s(12),
            vertical: r.vs(10),
          ),
          decoration: BoxDecoration(
            color: T.surface,
            borderRadius: BorderRadius.circular(r.s(12)),
            border: Border.all(color: T.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(MdiIcons.magnify, size: r.ms(20), color: T.muted),
              SizedBox(width: r.s(10)),
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  controller: TextEditingController(
                    text: _query,
                  )..selection = TextSelection.collapsed(offset: _query.length),
                  style: TextStyle(
                    fontSize: r.ms(14),
                    color: T.onBackground,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search your saved properties...",
                    hintStyle: TextStyle(color: T.muted),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (_query.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _query = ""),
                  child: Padding(
                    padding: EdgeInsets.all(r.s(4)),
                    child: Icon(
                      MdiIcons.closeCircle,
                      size: r.ms(18),
                      color: T.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /* -------------------- Chips -------------------- */
  Widget _buildChips(R r, Toks T) {
    return SizedBox(
      height: r.vs(44),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: CHIP_PRESETS.length,
        separatorBuilder: (_, __) => SizedBox(width: r.s(8)),
        itemBuilder: (ctx, i) {
          final c = CHIP_PRESETS[i];
          final active = _activeChip == c.id;
          return GestureDetector(
            onTap: () => setState(() => _activeChip = c.id),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: r.s(14),
                vertical: r.vs(10),
              ),
              decoration: BoxDecoration(
                color: active ? T.primary : T.surface,
                borderRadius: BorderRadius.circular(r.s(20)),
                border: Border.all(
                  color: active ? T.primary : T.border,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(active ? 0.12 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    c.icon,
                    size: r.ms(14),
                    color: active ? T.onPrimary : T.onBackground,
                  ),
                  SizedBox(width: r.s(6)),
                  Text(
                    c.label,
                    style: TextStyle(
                      fontSize: r.ms(12),
                      fontWeight: FontWeight.w600,
                      color: active ? T.onPrimary : T.onBackground,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /* -------------------- Top Promo Banner -------------------- */
  Widget _buildTopPromoBanner(R r, Toks T) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _bannerCtrl, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _bannerCtrl, curve: Curves.easeOut)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r.s(18)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4F46E5), Color(0xFFEC4899)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(r.s(18)),
            child: Padding(
              padding: EdgeInsets.all(r.s(14)),
              child: Row(
                children: [
                  Expanded(
                    flex: 13,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.s(10),
                            vertical: r.vs(4),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFACC15),
                            borderRadius: BorderRadius.circular(r.s(20)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                MdiIcons.bullhornOutline,
                                size: r.ms(14),
                                color: Colors.black,
                              ),
                              SizedBox(width: r.s(6)),
                              Text(
                                "Partner Brands",
                                style: TextStyle(
                                  fontSize: r.ms(10),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: r.vs(6)),
                        Text(
                          "Shift hona easy,\njab partners ho strong.",
                          style: TextStyle(
                            fontSize: r.ms(16),
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        SizedBox(height: r.vs(4)),
                        Text(
                          "Packers & movers, WiFi, furniture rental aur cleaning — sab ek hi jagah discover karo.",
                          style: TextStyle(
                            fontSize: r.ms(11),
                            color: Colors.white.withOpacity(0.92),
                          ),
                        ),
                        SizedBox(height: r.vs(10)),
                        GestureDetector(
                          onTap: () {
                            // TODO: Navigator.pushNamed(context, "AdvertiseWithUsScreen");
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: r.s(12),
                              vertical: r.vs(6),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(r.s(20)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "See all partner brands",
                                  style: TextStyle(
                                    fontSize: r.ms(11),
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
                  ),
                  SizedBox(width: r.s(10)),
                  Expanded(
                    flex: 10,
                    child: SizedBox(
                      height: r.vs(140),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(right: r.s(6)),
                        itemCount: AD_IMAGES.length,
                        separatorBuilder: (_, __) => SizedBox(width: r.s(10)),
                        itemBuilder: (ctx, i) {
                          final b = AD_IMAGES[i];

                          return Container(
                            width: r.s(96),
                            height: double.infinity,
                            padding: EdgeInsets.all(r.s(8)),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(15, 23, 42, 0.65),
                              borderRadius: BorderRadius.circular(r.s(14)),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // LOGO
                                Container(
                                  width: r.s(44),
                                  height: r.s(44),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.10),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.35),
                                      width: 1,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.asset(
                                    b.asset,
                                    fit: BoxFit
                                        .cover, // agar logo crop ho raha ho to BoxFit.contain kar do
                                  ),
                                ),

                                SizedBox(height: r.vs(8)),

                                // BRAND
                                Text(
                                  b.brand,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: r.ms(10.5),
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),

                                SizedBox(height: r.vs(4)),

                                // BADGE
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: r.s(8),
                                    vertical: r.vs(3),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(
                                      r.s(999),
                                    ),
                                  ),
                                  child: Text(
                                    b.badge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: r.ms(8),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withOpacity(0.85),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyGrid(R r, Toks T, List<WishlistItem> data) {
    final gap = r.s(12);
    final imgH = r.vs(140);

    return LayoutBuilder(
      builder: (context, c) {
        final maxW = c.maxWidth; // already inside parent padding
        final itemW = ((maxW - gap) / 2).clamp(r.s(150), r.s(420));

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: data.map((it) {
            return SizedBox(
              width: itemW,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _cardsCtrl,
                  curve: Curves.easeOut,
                ),
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _cardsCtrl,
                          curve: Curves.easeOut,
                        ),
                      ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(r.s(18)),
                      onTap: () {
                        // TODO: Navigator.pushNamed(context, "PropertyDetail", arguments: it.id);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: T.elevated,
                          borderRadius: BorderRadius.circular(r.s(18)),
                          border: Border.all(color: T.border, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // IMAGE AREA
                            SizedBox(
                              height: imgH,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(it.asset, fit: BoxFit.cover),

                                  // soft top vignette (premium look)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      height: r.vs(46),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.30),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // BOOKED overlay
                                  if (!it.available)
                                    Container(
                                      color: Colors.black.withOpacity(0.68),
                                      alignment: Alignment.center,
                                      child: Text(
                                        "BOOKED",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: r.ms(14),
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),

                                  // Verified badge
                                  if (it.verified)
                                    Positioned(
                                      top: r.s(10),
                                      left: r.s(10),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: r.s(10),
                                          vertical: r.vs(5),
                                        ),
                                        decoration: BoxDecoration(
                                          color: T.success,
                                          borderRadius: BorderRadius.circular(
                                            r.s(14),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.16,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              MdiIcons.shieldCheck,
                                              size: r.ms(12),
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: r.s(5)),
                                            Text(
                                              "Verified",
                                              style: TextStyle(
                                                fontSize: r.ms(10),
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // Heart remove
                                  Positioned(
                                    top: r.s(10),
                                    right: r.s(10),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(
                                        r.s(18),
                                      ),
                                      onTap: () => _removeFromWishlist(it),
                                      child: Container(
                                        width: r.s(34),
                                        height: r.s(34),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.42),
                                          borderRadius: BorderRadius.circular(
                                            r.s(18),
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.18,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          MdiIcons.heart,
                                          size: r.ms(18),
                                          color: const Color(0xFFFF4757),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // bottom price/rating bar
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: r.s(12),
                                        vertical: r.vs(10),
                                      ),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Color(0xD9000000),
                                          ],
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                it.priceText,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: r.ms(16),
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              SizedBox(width: r.s(3)),
                                              Text(
                                                it.perMonth,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.90),
                                                  fontSize: r.ms(10),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: r.vs(6)),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    MdiIcons.star,
                                                    size: r.ms(12),
                                                    color: const Color(
                                                      0xFFFFD166,
                                                    ),
                                                  ),
                                                  SizedBox(width: r.s(4)),
                                                  Text(
                                                    it.rating.toStringAsFixed(
                                                      1,
                                                    ),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: r.ms(12),
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Icon(
                                                    MdiIcons.mapMarker,
                                                    size: r.ms(12),
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: r.s(4)),
                                                  Text(
                                                    it.distance,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: r.ms(12),
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
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

                            // DETAILS AREA
                            Padding(
                              padding: EdgeInsets.all(r.s(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    it.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: r.ms(14),
                                      fontWeight: FontWeight.w900,
                                      color: T.onBackground,
                                    ),
                                  ),
                                  SizedBox(height: r.vs(4)),
                                  Row(
                                    children: [
                                      Icon(
                                        MdiIcons.mapMarkerOutline,
                                        size: r.ms(12),
                                        color: T.muted,
                                      ),
                                      SizedBox(width: r.s(4)),
                                      Expanded(
                                        child: Text(
                                          it.area,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: r.ms(11),
                                            fontWeight: FontWeight.w600,
                                            color: T.muted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: r.vs(10)),

                                  // tags
                                  Wrap(
                                    spacing: r.s(6),
                                    runSpacing: r.vs(6),
                                    children: it.tags.map((t) {
                                      return Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: r.s(10),
                                          vertical: r.vs(5),
                                        ),
                                        decoration: BoxDecoration(
                                          color: T.ripple,
                                          borderRadius: BorderRadius.circular(
                                            r.s(999),
                                          ),
                                          border: Border.all(
                                            color: T.border,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          t,
                                          style: TextStyle(
                                            fontSize: r.ms(10),
                                            fontWeight: FontWeight.w700,
                                            color: T.onBackground,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),

                                  SizedBox(height: r.vs(10)),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            MdiIcons.homeVariant,
                                            size: r.ms(12),
                                            color: T.primary,
                                          ),
                                          SizedBox(width: r.s(4)),
                                          Text(
                                            "${it.amenities} amenities",
                                            style: TextStyle(
                                              fontSize: r.ms(10),
                                              fontWeight: FontWeight.w600,
                                              color: T.onBackground,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            MdiIcons.accountGroup,
                                            size: r.ms(12),
                                            color: T.primary,
                                          ),
                                          SizedBox(width: r.s(4)),
                                          Text(
                                            "${it.booked} booked",
                                            style: TextStyle(
                                              fontSize: r.ms(10),
                                              fontWeight: FontWeight.w600,
                                              color: T.onBackground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: r.vs(12)),

                                  // CTA
                                  SizedBox(
                                    height: r.vs(36),
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: it.available
                                          ? () {
                                              // TODO: Navigator.pushNamed(context, "BookingScreen", arguments: it.id);
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        backgroundColor: it.available
                                            ? T.primary
                                            : T.disabled,
                                        disabledBackgroundColor: T.disabled,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            r.s(12),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            it.available
                                                ? "Book Now"
                                                : "Booked",
                                            style: TextStyle(
                                              fontSize: r.ms(12),
                                              fontWeight: FontWeight.w900,
                                              color: it.available
                                                  ? T.onPrimary
                                                  : T.onBackground,
                                            ),
                                          ),
                                          if (it.available) ...[
                                            SizedBox(width: r.s(6)),
                                            Icon(
                                              MdiIcons.arrowRight,
                                              size: r.ms(14),
                                              color: T.onPrimary,
                                            ),
                                          ],
                                        ],
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
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /* -------------------- Sections -------------------- */
  Widget _sectionHeader({
    required R r,
    required Toks T,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: r.ms(18),
                  fontWeight: FontWeight.w800,
                  color: T.onBackground,
                ),
              ),
              SizedBox(height: r.vs(2)),
              Text(
                subtitle,
                style: TextStyle(fontSize: r.ms(12), color: T.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfferSection(R r, Toks T) {
    final w = MediaQuery.of(context).size.width;
    final cardW = (w * 0.70).clamp(
      r.s(240),
      r.s(320),
    ); // same as RN: SCREEN_WIDTH * 0.7

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          r: r,
          T: T,
          title: "Special Offers",
          subtitle: "Extra benefits on your favourite stays",
        ),
        SizedBox(height: r.vs(10)),
        SizedBox(
          height: r.vs(160),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: OFFER_CARDS.length,
            separatorBuilder: (_, __) => SizedBox(width: r.s(12)),
            itemBuilder: (ctx, i) {
              final o = OFFER_CARDS[i];
              return Container(
                width: cardW,
                padding: EdgeInsets.all(r.s(14)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(r.s(18)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: o.gradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: r.s(8),
                        vertical: r.vs(4),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(r.s(14)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(o.icon, size: r.ms(12), color: Colors.white),
                          SizedBox(width: r.s(4)),
                          Text(
                            o.badge,
                            style: TextStyle(
                              fontSize: r.ms(10),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: r.vs(10)),
                    Text(
                      o.title,
                      style: TextStyle(
                        fontSize: r.ms(16),
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: r.vs(6)),
                    Text(
                      o.description,
                      style: TextStyle(
                        fontSize: r.ms(12),
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigator.pushNamed(context, "OffersScreen");
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: r.s(12),
                          vertical: r.vs(6),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(r.s(14)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "View Details",
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdsSection(R r, Toks T) {
    final w = MediaQuery.of(context).size.width;
    final gap = r.s(12);
    final cardW = (w - (r.s(16) * 2) - gap) / 2;
    final cardH = r.vs(140);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          r: r,
          T: T,
          title: "Sponsored Services",
          subtitle: "Helpful services for shifting & setup",
        ),
        SizedBox(height: r.vs(10)),
        Wrap(
          spacing: gap,
          runSpacing: gap,
          children: AD_IMAGES.map((ad) {
            return GestureDetector(
              onTap: () {
                // TODO: Navigator.pushNamed(context, "AdvertiseWithUsScreen");
              },
              child: Container(
                width: cardW,
                height: cardH,
                decoration: BoxDecoration(
                  color: T.elevated,
                  borderRadius: BorderRadius.circular(r.s(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(ad.asset, fit: BoxFit.cover),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: r.s(8),
                          vertical: r.vs(8),
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xD9000000)],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: r.s(6),
                                vertical: r.vs(2),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.60),
                                borderRadius: BorderRadius.circular(r.s(10)),
                              ),
                              child: Text(
                                ad.badge,
                                style: TextStyle(
                                  fontSize: r.ms(8),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: r.vs(4)),
                            Text(
                              ad.brand,
                              style: TextStyle(
                                fontSize: r.ms(12),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: r.vs(2)),
                            Text(
                              ad.tagline,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: r.ms(10),
                                color: Colors.white.withOpacity(0.90),
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
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDiscoverSection(R r, Toks T) {
    final w = MediaQuery.of(context).size.width;
    final cardW = (w * 0.55).clamp(r.s(200), r.s(280));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          r: r,
          T: T,
          title: "Discover Something New",
          subtitle: "Ideas to improve your stay & save more",
        ),
        SizedBox(height: r.vs(10)),
        SizedBox(
          height: r.vs(140),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: DISCOVER_ITEMS.length,
            separatorBuilder: (_, __) => SizedBox(width: r.s(12)),
            itemBuilder: (ctx, i) {
              final d = DISCOVER_ITEMS[i];
              return Container(
                width: cardW,
                padding: EdgeInsets.all(r.s(12)),
                decoration: BoxDecoration(
                  color: T.elevated,
                  borderRadius: BorderRadius.circular(r.s(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: r.s(32),
                      height: r.s(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(r.s(16)),
                      ),
                      alignment: Alignment.center,
                      child: Icon(d.icon, size: r.ms(20), color: Colors.white),
                    ),
                    SizedBox(height: r.vs(8)),
                    Text(
                      d.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: r.ms(13),
                        fontWeight: FontWeight.w800,
                        color: T.onBackground,
                      ),
                    ),
                    SizedBox(height: r.vs(4)),
                    Text(
                      d.sub,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: r.ms(11),
                        height: 1.3,
                        color: T.muted,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /* -------------------- Empty state -------------------- */
  Widget _buildEmptyState(R r, Toks T) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _cardsCtrl, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.10),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _cardsCtrl, curve: Curves.easeOut)),
        child: Padding(
          padding: EdgeInsets.only(top: r.vs(40)),
          child: Column(
            children: [
              Container(
                width: r.s(100),
                height: r.s(100),
                decoration: BoxDecoration(
                  color: T.elevated,
                  borderRadius: BorderRadius.circular(r.s(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  MdiIcons.heartOutline,
                  size: r.ms(48),
                  color: T.muted,
                ),
              ),
              SizedBox(height: r.vs(16)),
              Text(
                "No saved properties yet",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.ms(18),
                  fontWeight: FontWeight.w800,
                  color: T.onBackground,
                ),
              ),
              SizedBox(height: r.vs(8)),
              Text(
                "Start building your wishlist by tapping the heart icon on properties you like",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.ms(14),
                  height: 1.4,
                  color: T.muted,
                ),
              ),
              SizedBox(height: r.vs(18)),
              GestureDetector(
                onTap: () {
                  // TODO: Navigator.pushNamed(context, "Home");
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: r.s(20),
                    vertical: r.vs(12),
                  ),
                  decoration: BoxDecoration(
                    color: T.primary,
                    borderRadius: BorderRadius.circular(r.s(12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    "Explore Properties",
                    style: TextStyle(
                      fontSize: r.ms(14),
                      fontWeight: FontWeight.w800,
                      color: T.onPrimary,
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
