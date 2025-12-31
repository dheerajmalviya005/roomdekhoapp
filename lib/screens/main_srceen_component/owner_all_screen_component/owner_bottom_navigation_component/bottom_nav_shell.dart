import "dart:ui";
import "package:flutter/material.dart";
import "package:material_design_icons_flutter/material_design_icons_flutter.dart";

void main() {
  runApp(const MyApp());
}

/* ---------------- Theme tokens (same as RN) ---------------- */
class T {
  static const primary = Color(0xFF667EEA);
  static const primaryLight = Color(0xFF764BA2);
  static const secondary = Color(0xFFF093FB);
  static const accent = Color(0xFF43E97B);

  static const white = Color(0xFFFFFFFF);
  static const lightGray = Color(0xFFF8F9FA);
  static const darkGray = Color(0xFF6B7280);
  static const black = Color(0xFF1F2937);

  // shadow: "#00000010" => 0x10000000 (alpha 0x10)
  static const shadow = Color(0x10000000);

  static const success = Color(0xFF10B981);
  static const info = Color(0xFF3B82F6);
  static const warning = Color(0xFFF59E0B);
}

/* ---------------- Responsive scale helpers (RN-like) ---------------- */
class S {
  // Base width similar to common mobile design base
  static const double _baseWidth = 375.0;
  static const double _baseHeight = 812.0;

  static double _w(BuildContext c) => MediaQuery.of(c).size.width;
  static double _h(BuildContext c) => MediaQuery.of(c).size.height;

  static double scale(BuildContext c, double v) => v * (_w(c) / _baseWidth);
  static double verticalScale(BuildContext c, double v) =>
      v * (_h(c) / _baseHeight);

  // moderateScale ~ blend of scale + original value
  static double moderateScale(BuildContext c, double v, {double factor = 0.5}) {
    final s = scale(c, v);
    return v + (s - v) * factor;
  }
}

/* ---------------- Tab config (same as RN) ---------------- */
class TabItemConfig {
  final String name;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final List<Color> gradient;

  const TabItemConfig({
    required this.name,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.gradient,
  });
}

// ❌ const List<TabItemConfig> TAB_CONFIG = [ ... ];
// ✅ change to:
final List<TabItemConfig> TAB_CONFIG = [
  TabItemConfig(
    name: "Home",
    label: "Home",
    icon: MdiIcons.homeOutline,
    activeIcon: MdiIcons.home,
    gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
  ),
  TabItemConfig(
    name: "Support",
    label: "Support",
    icon: MdiIcons.headset,
    activeIcon: MdiIcons.headset,
    gradient: const [Color(0xFF43E97B), Color(0xFF38F9D7)],
  ),
  TabItemConfig(
    name: "Chat",
    label: "Chat",
    icon: MdiIcons.messageText,
    activeIcon: MdiIcons.messageText,
    gradient: const [Color(0xFFF093FB), Color(0xFFF5576C)],
  ),
  TabItemConfig(
    name: "Profile",
    label: "Profile",
    icon: MdiIcons.account,
    activeIcon: MdiIcons.account,
    gradient: const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
  ),
];

/* ---------------- App ---------------- */
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const RenterTabs(),
    );
  }
}

/* ---------------- Screens (replace with your actual screens) ---------------- */
// Replace these with:
// import '.../renter_home.dart';
// import '.../create_room_screen.dart';
// import '.../support_screen.dart';
// import '.../profile_screen.dart';
// import '.../chat_list_screen.dart';

class RenterHome extends StatelessWidget {
  const RenterHome({super.key});
  @override
  Widget build(BuildContext context) => const _DemoScreen(title: "Home");
}

class RentalSupportScreen extends StatelessWidget {
  const RentalSupportScreen({super.key});
  @override
  Widget build(BuildContext context) => const _DemoScreen(title: "Support");
}

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});
  @override
  Widget build(BuildContext context) => const _DemoScreen(title: "Chat");
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => const _DemoScreen(title: "Profile");
}

class CreateRoomScreen extends StatelessWidget {
  const CreateRoomScreen({super.key});
  @override
  Widget build(BuildContext context) => const _DemoScreen(title: "Create Room");
}

class _DemoScreen extends StatelessWidget {
  final String title;
  const _DemoScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/* ---------------- Main Tabs (custom bottom bar) ---------------- */
class RenterTabs extends StatefulWidget {
  const RenterTabs({super.key});

  @override
  State<RenterTabs> createState() => _RenterTabsState();
}

class _RenterTabsState extends State<RenterTabs> {
  int index = 0;

  final List<Widget> pages = const [
    RenterHome(),
    RentalSupportScreen(),
    ChatsListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: Stack(
        children: [
          // keep state alive like tab navigator
          IndexedStack(index: index, children: pages),

          // Custom tab bar overlay
          if (!keyboardVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _CustomTabBar(
                currentIndex: index,
                onChange: (i) => setState(() => index = i),
              ),
            ),
        ],
      ),
    );
  }
}

/* ---------------- Custom Tab Bar (same style) ---------------- */
class _CustomTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChange;

  const _CustomTabBar({required this.currentIndex, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final pb = MediaQuery.of(context).padding.bottom;

    final containerPaddingBottom =
        (Theme.of(context).platform == TargetPlatform.iOS)
        ? S.verticalScale(context, 8)
        : S.verticalScale(context, 4);

    return IgnorePointer(
      ignoring: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: S.scale(context, 12),
          right: S.scale(context, 12),
          bottom: containerPaddingBottom + (pb > 0 ? (pb * 0.15) : 0),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Floating glass card wrapper
            Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.44), // glass
                borderRadius: BorderRadius.circular(S.scale(context, 26)),
              ),
              child: SizedBox(
                height: S.verticalScale(context, 64),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(TAB_CONFIG.length, (i) {
                    final cfg = TAB_CONFIG[i];
                    final isFocused = i == currentIndex;

                    return Expanded(
                      child: InkWell(
                        onTap: () => onChange(i),
                        borderRadius: BorderRadius.circular(
                          S.scale(context, 26),
                        ),
                        child: SizedBox(
                          height: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.translate(
                                offset: Offset(0, isFocused ? -5 : 0),
                                child: Container(
                                  width: S.scale(context, 40),
                                  height: S.scale(context, 40),
                                  margin: EdgeInsets.only(
                                    bottom: S.verticalScale(context, 4),
                                  ),
                                  decoration: BoxDecoration(
                                    color: isFocused
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(
                                      S.scale(context, 20),
                                    ),
                                    boxShadow: [
                                      if (isFocused)
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.25),
                                          offset: const Offset(0, 4),
                                          blurRadius: 8,
                                        )
                                      else
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.12),
                                          offset: const Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                    ],
                                  ),
                                  child: isFocused
                                      ? _GradientIcon(
                                          colors: cfg.gradient,
                                          child: Icon(
                                            cfg.activeIcon,
                                            size: S.moderateScale(context, 22),
                                            color: T.white,
                                          ),
                                        )
                                      : Center(
                                          child: Icon(
                                            cfg.icon,
                                            size: S.moderateScale(context, 20),
                                            color: T.darkGray,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(
                                width: S.scale(context, 80),
                                child: Text(
                                  cfg.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isFocused
                                        ? S.moderateScale(context, 12)
                                        : S.moderateScale(context, 11),
                                    fontWeight: isFocused
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    letterSpacing: 0.1,
                                    color: isFocused
                                        ? (cfg.gradient.isNotEmpty
                                              ? cfg.gradient[0]
                                              : T.primary)
                                        : T.darkGray,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // subtle top glow line
            Positioned(
              top: 0,
              left: S.scale(context, 40),
              right: S.scale(context, 40),
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(0.75),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      T.primary.withOpacity(0.10),
                      T.primaryLight.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- Gradient icon wrapper ---------------- */
class _GradientIcon extends StatelessWidget {
  final List<Color> colors;
  final Widget child;

  const _GradientIcon({required this.colors, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(S.scale(context, 20)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.isNotEmpty
              ? colors
              : const [T.primary, T.primaryLight],
        ),
      ),
      child: Center(child: child),
    );
  }
}
