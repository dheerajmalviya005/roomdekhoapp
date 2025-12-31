import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../home_screen_component/home_screen.dart';
import '../wishlist_screen_component/wishlist_screen.dart';
import '../profile_screen_component/tenant_profile_screen.dart';
import '../chat_screen_componenet/chats_list_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Demo(label: "Support");
}


class _Demo extends StatelessWidget {
  final String label;
  const _Demo({required this.label});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label, style: const TextStyle(fontSize: 18)));
  }
}

// ---------------- COLORS (same) ----------------
class T {
  static const primary = Color(0xFF667EEA);
  static const primaryLight = Color(0xFF764BA2);
  static const secondary = Color(0xFFF093FB);
  static const accent = Color(0xFF43E97B);

  static const white = Color(0xFFFFFFFF);
  static const lightGray = Color(0xFFF8F9FA);
  static const darkGray = Color(0xFF6B7280);
  static const black = Color(0xFF1F2937);
  static const shadow = Color(0x1A000000);
  static const success = Color(0xFF10B981);
  static const info = Color(0xFF3B82F6);
  static const warning = Color(0xFFF59E0B);
}

// ---------------- TAB CONFIG (same) ----------------
class TabItemConfig {
  final String name;
  final IconData icon;
  final IconData activeIcon;
  final List<Color> gradient;
  final String label;

  const TabItemConfig({
    required this.name,
    required this.icon,
    required this.activeIcon,
    required this.gradient,
    required this.label,
  });
}

final List<TabItemConfig> TAB_CONFIG = [
  TabItemConfig(
    name: "Home",
    icon: MdiIcons.layersOutline,
    activeIcon: MdiIcons.layers,
    gradient: [Color(0xFF667EEA), Color(0xFF764BA2)],
    label: "Home",
  ),
  TabItemConfig(
    name: "WishList",
    icon: MdiIcons.heartOutline,
    activeIcon: MdiIcons.heart,
    gradient: [Color(0xFFF97373), Color(0xFFF43F5E)],
    label: "Wishlist",
  ),
  TabItemConfig(
    name: "Support",
    icon: MdiIcons.headset,
    activeIcon: MdiIcons.headset,
    gradient: [Color(0xFF43E97B), Color(0xFF38F9D7)],
    label: "Support",
  ),
  TabItemConfig(
    name: "Chat",
    icon: MdiIcons.messageOutline,
    activeIcon: MdiIcons.message,
    gradient: [Color(0xFFF093FB), Color(0xFFF5576C)],
    label: "Chat",
  ),
  TabItemConfig(
    name: "Profile",
    icon: MdiIcons.accountOutline,
    activeIcon: MdiIcons.account,
    gradient: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    label: "Profile",
  ),
];

class BottomNavShell extends StatefulWidget {
  const BottomNavShell({super.key});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell>
    with WidgetsBindingObserver {
  int _index = 0;
  bool _keyboardVisible = false;

  final _pages = const [
    HomeScreen(),
    WishListScreen(),
    SupportScreen(),
    ChatListScreen(),
    TenantProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding
        .instance
        .platformDispatcher
        .views
        .first
        .viewInsets
        .bottom;
    final visible = bottomInset > 0;
    if (visible != _keyboardVisible) {
      setState(() => _keyboardVisible = visible);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      extendBody: true,
      bottomNavigationBar: _keyboardVisible
          ? null
          : _CustomGlassTabBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
            ),
    );
  }
}

class _CustomGlassTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CustomGlassTabBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return SafeArea(
      top: false,
      child: Stack(
        children: [
          Positioned(
            left: 35,
            right: 35,
            top: 0,
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(0.75),
                gradient: LinearGradient(
                  colors: [
                    T.primary.withOpacity(0.10),
                    T.primaryLight.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(
              left: 10,
              right: 10,
              bottom: isIOS ? 8 : 4,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.44),
                borderRadius: BorderRadius.circular(26),
              ),
              child: SizedBox(
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(TAB_CONFIG.length, (i) {
                    final cfg = TAB_CONFIG[i];
                    final focused = currentIndex == i;

                    return Expanded(
                      child: InkWell(
                        onTap: () => onTap(i),
                        borderRadius: BorderRadius.circular(26),
                        child: _TabItem(cfg: cfg, focused: focused),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final TabItemConfig cfg;
  final bool focused;

  const _TabItem({required this.cfg, required this.focused});

  @override
  Widget build(BuildContext context) {
    final labelColor = focused ? cfg.gradient[0] : T.darkGray;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.translate(
          offset: Offset(0, focused ? -5 : 0),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: T.primary.withOpacity(0.30),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: focused
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: cfg.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(cfg.activeIcon, size: 22, color: T.white),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: T.lightGray,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(cfg.icon, size: 20, color: T.darkGray),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 60, maxWidth: 80),
          child: Text(
            cfg.label,
            maxLines: 1,
            overflow: TextOverflow.clip,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: focused ? 12 : 11,
              fontWeight: focused ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.1,
              color: labelColor,
            ),
          ),
        ),
      ],
    );
  }
}
