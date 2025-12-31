import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/* ---------------- Responsive scaler ---------------- */
class R {
  final double w;
  final double h;
  R(this.w, this.h);

  double s(double v) => (w / 375.0) * v;
  double vs(double v) => (h / 812.0) * v;
  double ms(double v, [double f = 0.5]) => v + (s(v) - v) * f;
}

/* ---------------- Soft / premium shadow ---------------- */
List<BoxShadow> softShadow(
  R r, {
  double blur = 18,
  double y = 10,
  double op = 0.10,
}) {
  return [
    BoxShadow(
      color: Colors.black.withOpacity(op),
      blurRadius: r.s(blur),
      offset: Offset(0, r.vs(y)),
    ),
  ];
}

/* ---------------- Dummy Data ---------------- */
class PropertyItem {
  final String id;
  final String title;
  final String price;
  final String distance;
  final String locality;
  final double rating;
  final String image;
  final List<String> tags;
  final String type;
  final int beds;
  final int baths;
  final String area;

  PropertyItem({
    required this.id,
    required this.title,
    required this.price,
    required this.distance,
    required this.locality,
    required this.rating,
    required this.image,
    required this.tags,
    required this.type,
    required this.beds,
    required this.baths,
    required this.area,
  });
}

final PROPERTIES = <PropertyItem>[
  PropertyItem(
    id: "p1",
    title: "City View Residency",
    price: "₹11,500/mo",
    distance: "1.2 km",
    locality: "Near ABC University",
    rating: 4.8,
    image: "https://images.pexels.com/photos/106399/pexels-photo-106399.jpeg",
    tags: ["AC", "WiFi", "Laundry", "Parking", "Gym"],
    type: "Apartment",
    beds: 2,
    baths: 1,
    area: "900 sq ft",
  ),
  PropertyItem(
    id: "p2",
    title: "Palm Beach Villa",
    price: "₹14,000/mo",
    distance: "2.5 km",
    locality: "Lakeview Road",
    rating: 4.6,
    image: "https://images.pexels.com/photos/261102/pexels-photo-261102.jpeg",
    tags: ["Furnished", "Parking", "Balcony", "Pool"],
    type: "Villa",
    beds: 3,
    baths: 2,
    area: "1200 sq ft",
  ),
  PropertyItem(
    id: "p3",
    title: "Campus Heights",
    price: "₹12,800/mo",
    distance: "500 m",
    locality: "Walking distance to college",
    rating: 4.9,
    image: "https://images.pexels.com/photos/439391/pexels-photo-439391.jpeg",
    tags: ["Study Room", "Cafeteria", "Power"],
    type: "Apartment",
    beds: 2,
    baths: 2,
    area: "980 sq ft",
  ),
  PropertyItem(
    id: "p4",
    title: "Riverside PG",
    price: "₹9,500/mo",
    distance: "2.1 km",
    locality: "Downtown Location",
    rating: 4.4,
    image: "https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg",
    tags: ["Food", "Security", "Cleaning"],
    type: "PG",
    beds: 1,
    baths: 1,
    area: "650 sq ft",
  ),
  PropertyItem(
    id: "p5",
    title: "Green Park Studios",
    price: "₹14,000/mo",
    distance: "800 m",
    locality: "5 min from campus",
    rating: 4.6,
    image: "https://images.pexels.com/photos/271618/pexels-photo-271618.jpeg",
    tags: ["Furnished", "Gym", "Parking"],
    type: "Studio",
    beds: 1,
    baths: 1,
    area: "520 sq ft",
  ),
];

/* ---------------- Screen (3 cards per screen) ---------------- */
class AllPropertiesScreenFlutter extends StatefulWidget {
  const AllPropertiesScreenFlutter({super.key});

  @override
  State<AllPropertiesScreenFlutter> createState() =>
      _AllPropertiesScreenFlutterState();
}

class _AllPropertiesScreenFlutterState
    extends State<AllPropertiesScreenFlutter> {
  final Set<String> _liked = {};

  void _toggleLike(String id) {
    setState(() {
      if (_liked.contains(id)) {
        _liked.remove(id);
      } else {
        _liked.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final r = R(mq.size.width, mq.size.height);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              "All Properties",
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: r.ms(20),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: r.vs(2)),
            Text(
              "${PROPERTIES.length} listings available",
              style: TextStyle(
                fontSize: r.ms(12),
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),

      // ✅ Fixed height cards => gap control + ~3 cards visible
      body: LayoutBuilder(
        builder: (context, c) {
          final gap = r.vs(12);
          final itemH = (c.maxHeight - gap * 4) / 3.05; // ~3 cards

          return ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: r.s(14),
              vertical: r.vs(12),
            ),
            itemCount: PROPERTIES.length,
            separatorBuilder: (_, __) => SizedBox(height: gap),
            itemBuilder: (_, i) {
              final p = PROPERTIES[i];
              return SizedBox(
                height: itemH,
                child: _CompactPropertyCard(
                  r: r,
                  item: p,
                  liked: _liked.contains(p.id),
                  onToggleLike: () => _toggleLike(p.id),
                  onView: () {},
                  onBook: () {},
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(r.s(28)),
          boxShadow: softShadow(r, blur: 22, y: 12, op: 0.18),
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {},
          icon: const Icon(Icons.tune, color: Colors.white),
          label: Text(
            "Filter & Sort",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: r.ms(14),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------- Compact Card (tight + classy + Book Now) ---------------- */
class _CompactPropertyCard extends StatelessWidget {
  final R r;
  final PropertyItem item;
  final bool liked;
  final VoidCallback onToggleLike;
  final VoidCallback onView;
  final VoidCallback onBook;

  const _CompactPropertyCard({
    required this.r,
    required this.item,
    required this.liked,
    required this.onToggleLike,
    required this.onView,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.s(18)),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: softShadow(r, blur: 14, y: 8, op: 0.10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // LEFT: image
          SizedBox(
            width: r.s(118),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: item.image,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: const Color(0xFFF3F4F6),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: r.s(16),
                      height: r.s(16),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFF3F4F6),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: r.vs(52),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xAA000000)],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: r.s(8),
                  bottom: r.vs(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: r.s(8),
                      vertical: r.vs(3),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.60),
                      borderRadius: BorderRadius.circular(r.s(12)),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 13,
                          color: Color(0xFFFFD700),
                        ),
                        SizedBox(width: r.s(3)),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: r.ms(10),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // RIGHT: content (NO Spacer -> no big gap)
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.s(12), r.vs(8), r.s(12), r.vs(8)),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // ✅ fills height
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- TOP BLOCK ----------
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // title + heart
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: r.ms(14),
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onToggleLike,
                              borderRadius: BorderRadius.circular(r.s(18)),
                              child: Container(
                                width: r.s(34),
                                height: r.s(34),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(r.s(18)),
                                ),
                                alignment: Alignment.center,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 160),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(
                                        scale: anim,
                                        child: child,
                                      ),
                                  child: Icon(
                                    liked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    key: ValueKey(liked),
                                    size: r.ms(18),
                                    color: liked
                                        ? const Color(0xFFFF4B6E)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: r.vs(4)),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Color(0xFFFF4B6E),
                          ),
                          SizedBox(width: r.s(4)),
                          Expanded(
                            child: Text(
                              item.locality,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: r.ms(11),
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: r.vs(6)),

                      Row(
                        children: [
                          Flexible(
                            child: _Pill(
                              r: r,
                              bg: const Color(0xFFFFEEF2),
                              fg: const Color(0xFFFF4B6E),
                              text: item.price,
                            ),
                          ),
                          SizedBox(width: r.s(8)),
                          _Pill(
                            r: r,
                            bg: const Color(0xFFF3F4F6),
                            fg: const Color(0xFF111827),
                            text: item.distance,
                          ),
                        ],
                      ),

                      SizedBox(height: r.vs(6)),

                      Text(
                        "${item.beds} Beds • ${item.baths} Bath • ${item.area}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: r.ms(10.5),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF6B7280),
                        ),
                      ),

                      // ✅ OPTIONAL tiny line (fills nicely, looks premium)
                      SizedBox(height: r.vs(6)),
                      Row(
                        children: [
                          _TinyChip(r: r, text: "Verified"),
                          SizedBox(width: r.s(6)),
                          _TinyChip(r: r, text: "Free Visit"),
                        ],
                      ),
                    ],
                  ),

                  // ---------- BOTTOM BUTTONS (always sticks to bottom) ----------
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onView,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(r.s(12)),
                            ),
                            padding: EdgeInsets.symmetric(vertical: r.vs(10)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "View",
                            style: TextStyle(
                              fontSize: r.ms(11.5),
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: r.s(10)),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onBook,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4B6E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(r.s(12)),
                            ),
                            padding: EdgeInsets.symmetric(vertical: r.vs(10)),
                            elevation: 0,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "Book Now",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: r.ms(11.5),
                              fontWeight: FontWeight.w900,
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
    );
  }
}

class _Pill extends StatelessWidget {
  final R r;
  final Color bg;
  final Color fg;
  final String text;

  const _Pill({
    required this.r,
    required this.bg,
    required this.fg,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.s(10), vertical: r.vs(5)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(r.s(999)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: r.ms(10.5),
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }
}

class _TinyChip extends StatelessWidget {
  final R r;
  final String text;

  const _TinyChip({required this.r, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.s(8), vertical: r.vs(4)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(r.s(999)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: r.ms(10),
          fontWeight: FontWeight.w900,
          color: const Color(0xFF111827),
        ),
      ),
    );
  }
}
