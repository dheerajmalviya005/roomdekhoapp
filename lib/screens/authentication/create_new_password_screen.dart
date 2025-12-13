import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen>
    with TickerProviderStateMixin {
  // --- form state ---
  final TextEditingController _newPass = TextEditingController();
  final TextEditingController _confirmPass = TextEditingController();

  bool _showNew = false;
  bool _showConfirm = false;

  // --- animations (same as RN) ---
  late final AnimationController _introController;
  late final Animation<double> _heroTranslateY;
  late final Animation<double> _heroScale;
  late final Animation<double> _cardTranslateY;
  late final Animation<double> _cardOpacity;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  late final AnimationController _btnController;
  late final Animation<double> _btnFill;

  late final AnimationController _newFocusController;
  late final AnimationController _confirmFocusController;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _heroTranslateY = Tween<double>(begin: -40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _heroScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _cardTranslateY = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    _introController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutQuad),
    );

    _pulseOpacity = Tween<double>(begin: 0.12, end: 0.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutQuad),
    );

    _pulseController.repeat(reverse: true);

    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _btnFill = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.easeOutCubic),
    );

    _newFocusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _confirmFocusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _newPass.dispose();
    _confirmPass.dispose();

    _introController.dispose();
    _pulseController.dispose();
    _btnController.dispose();
    _newFocusController.dispose();
    _confirmFocusController.dispose();
    super.dispose();
  }

  void _submit() {
    final a = _newPass.text.trim();
    final b = _confirmPass.text.trim();

    if (a.isEmpty || b.isEmpty) return;
    if (a != b) return;

    _btnController
      ..reset()
      ..forward().whenComplete(() {
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/sign-authentication', (r) => false);
      });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final background = scheme.surface;
    final primary = scheme.primary;
    final accent = scheme.secondary;
    final surface = scheme.surface;
    final elevated = theme.cardColor;

    final onSurface = scheme.onSurface;
    final onBackground = scheme.onSurface;
    final onPrimary = scheme.onPrimary;

    final border = scheme.outlineVariant;
    final shadow = Colors.black.withOpacity(0.18);
    final muted = onSurface.withOpacity(0.7);

    final info = scheme.tertiary;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: scheme.brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;

              return Stack(
                children: [
                  // bubble top-left
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Positioned(
                        top: -100,
                        left: -50,
                        child: Opacity(
                          opacity: _pulseOpacity.value,
                          child: Transform.scale(
                            scale: _pulseScale.value,
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(110),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // bubble bottom-right
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Positioned(
                        bottom: -30,
                        right: -20,
                        child: Opacity(
                          opacity: _pulseOpacity.value,
                          child: Transform.scale(
                            scale: _pulseScale.value,
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(110),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SizedBox(height: height * 0.11),

                        // HERO
                        AnimatedBuilder(
                          animation: _introController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _heroTranslateY.value),
                              child: Transform.scale(
                                scale: _heroScale.value,
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 250,
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Center(
                                  child: Transform.scale(
                                    scale: 1.25,
                                    child: Image.asset(
                                      'assets/icon/pngtree-worries-before-exams-isolated-cartoon-vector-illustrations-picture-image_8710545.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),

                              Container(
                                decoration: BoxDecoration(
                                  color: elevated,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: shadow,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_city_rounded,
                                      size: 26,
                                      color: accent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'PropRental',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: onBackground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),
                              Text(
                                'Set a new password to continue',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: muted),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // CARD
                        AnimatedBuilder(
                          animation: _introController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _cardOpacity.value,
                              child: Transform.translate(
                                offset: Offset(0, _cardTranslateY.value),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 18),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: shadow,
                                  blurRadius: 12,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create New Password',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: onSurface,
                                  ),
                                ),

                                const SizedBox(height: 8),
                                Text(
                                  'New Password',
                                  style: TextStyle(fontSize: 12, color: muted),
                                ),
                                const SizedBox(height: 6),
                                AnimatedBuilder(
                                  animation: _newFocusController,
                                  builder: (context, child) {
                                    final underline =
                                        Color.lerp(
                                          border,
                                          primary,
                                          _newFocusController.value,
                                        ) ??
                                        border;
                                    return Container(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: underline,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: child,
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        size: 18,
                                        color: muted,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Focus(
                                          onFocusChange: (hasFocus) {
                                            if (hasFocus) {
                                              _newFocusController.forward();
                                            } else {
                                              _newFocusController.reverse();
                                            }
                                          },
                                          child: TextField(
                                            controller: _newPass,
                                            obscureText: !_showNew,
                                            textInputAction:
                                                TextInputAction.next,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              border: InputBorder.none,
                                              hintText: 'Enter new password',
                                              hintStyle: TextStyle(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: onSurface,
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _showNew = !_showNew,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          child: Icon(
                                            _showNew
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 18,
                                            color: muted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),
                                Text(
                                  'Confirm Password',
                                  style: TextStyle(fontSize: 12, color: muted),
                                ),
                                const SizedBox(height: 6),
                                AnimatedBuilder(
                                  animation: _confirmFocusController,
                                  builder: (context, child) {
                                    final underline =
                                        Color.lerp(
                                          border,
                                          primary,
                                          _confirmFocusController.value,
                                        ) ??
                                        border;
                                    return Container(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: underline,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: child,
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        size: 18,
                                        color: muted,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Focus(
                                          onFocusChange: (hasFocus) {
                                            if (hasFocus) {
                                              _confirmFocusController.forward();
                                            } else {
                                              _confirmFocusController.reverse();
                                            }
                                          },
                                          child: TextField(
                                            controller: _confirmPass,
                                            obscureText: !_showConfirm,
                                            textInputAction:
                                                TextInputAction.done,
                                            onSubmitted: (_) => _submit(),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              border: InputBorder.none,
                                              hintText: 'Re-enter new password',
                                              hintStyle: TextStyle(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: onSurface,
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _showConfirm = !_showConfirm,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          child: Icon(
                                            _showConfirm
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 18,
                                            color: muted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // BUTTON
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _submit,
                                  child: Container(
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      children: [
                                        AnimatedBuilder(
                                          animation: _btnController,
                                          builder: (context, child) {
                                            return Align(
                                              alignment: Alignment.centerLeft,
                                              child: FractionallySizedBox(
                                                widthFactor: _btnFill.value,
                                                child: Container(color: info),
                                              ),
                                            );
                                          },
                                        ),
                                        Center(
                                          child: Text(
                                            'Update Password',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: onPrimary,
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
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
