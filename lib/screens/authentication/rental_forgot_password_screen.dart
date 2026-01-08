import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class RentalForgotPasswordScreen extends StatefulWidget {
  const RentalForgotPasswordScreen({super.key});

  @override
  State<RentalForgotPasswordScreen> createState() =>
      _RentalForgotPasswordScreenState();
}

class _RentalForgotPasswordScreenState extends State<RentalForgotPasswordScreen>
    with TickerProviderStateMixin {
  // --- form state ---
  final TextEditingController _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  // ✅ OTP focus nodes (auto-next)
  late final List<FocusNode> _otpTextNodes = List.generate(
    6,
    (_) => FocusNode(),
  );

  bool _sending = false;
  bool _isOtpSent = false;

  // --- animations ---
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

  late final AnimationController _emailFocusController;

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

    _emailFocusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _emailController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final n in _otpTextNodes) {
      n.dispose();
    }
    _introController.dispose();
    _pulseController.dispose();
    _btnController.dispose();
    _emailFocusController.dispose();
    super.dispose();
  }

  Color _mutedColor(Color onSurface) => onSurface.withOpacity(0.7);

  String get _primaryLabel {
    if (!_isOtpSent) return _sending ? 'Sending...' : 'Send OTP';
    return 'Verify & Continue';
  }

  bool get _primaryDisabled {
    if (!_isOtpSent) return _sending || _emailController.text.trim().isEmpty;
    final code = _otpControllers.map((c) => c.text).join();
    return code.length != 6;
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.trim().isEmpty) return;
    setState(() => _sending = true);

    try {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      setState(() => _isOtpSent = true);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_otpTextNodes[0]);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _verifyOtp() {
    final email = _emailController.text.trim();
    final code = _otpControllers.map((c) => c.text).join();
    if (email.isEmpty || code.length != 6) return;

    // ✅ go_router navigation (FIX)
    context.push('/createnewpassword');
  }

  void _onPrimaryPressed() {
    if (_primaryDisabled) return;

    _btnController
      ..reset()
      ..forward().whenComplete(() {
        if (!_isOtpSent) {
          _sendOtp();
        } else {
          _verifyOtp();
        }
      });
  }

  // ✅ auto-next + paste support
  void _onOtpChanged(String text, int index) {
    final cleaned = text.replaceAll(RegExp(r'\D'), '');

    // paste 6 digits
    if (cleaned.length == 6) {
      for (int i = 0; i < 6; i++) {
        _otpControllers[i].text = cleaned[i];
      }
      FocusScope.of(context).unfocus();
      setState(() {});
      return;
    }

    final char = cleaned.isEmpty ? '' : cleaned.substring(cleaned.length - 1);
    _otpControllers[index].text = char;

    if (char.isNotEmpty) {
      if (index < 5) {
        FocusScope.of(context).requestFocus(_otpTextNodes[index + 1]);
      } else {
        FocusScope.of(context).unfocus();
      }
    }
    setState(() {});
  }

  void _onOtpBackspace(RawKeyEvent event, int index) {
    if (event is! RawKeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpControllers[index].text.isEmpty && index > 0) {
        _otpControllers[index - 1].clear();
        FocusScope.of(context).requestFocus(_otpTextNodes[index - 1]);
      } else {
        _otpControllers[index].clear();
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final background = scheme.surface;
    final primary = scheme.primary;
    final accent = scheme.secondary;
    final surface = scheme.surface;
    final onSurface = scheme.onSurface;
    // final onBackground = scheme.onSurface;
    final onPrimary = scheme.onPrimary;

    final border = scheme.outlineVariant;
    final shadow = Colors.black.withOpacity(0.18);
    final muted = _mutedColor(onSurface);
    final link = Colors.blue;
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
                  // top-left bubble
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

                  // bottom-right bubble
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
                                child: Image.asset(
                                  'assets/icon/png-transparent-reset-password-illustration-removebg-preview.png',
                                  fit: BoxFit.contain,
                                ),
                              ),

                              // PropRental chip (primary bg + white)
                              Container(
                                decoration: BoxDecoration(
                                  color: primary,
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
                                    const Icon(
                                      Icons.location_city_rounded,
                                      size: 26,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'PropRental',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),
                              Text(
                                !_isOtpSent
                                    ? 'Enter your email to receive an OTP'
                                    : 'Enter the 6-digit OTP sent to your email',
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
                                  !_isOtpSent ? 'Send OTP' : 'Verify Account',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: onSurface,
                                  ),
                                ),

                                if (!_isOtpSent) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Email',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: muted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  AnimatedBuilder(
                                    animation: _emailFocusController,
                                    builder: (context, child) {
                                      final underline =
                                          Color.lerp(
                                            border,
                                            primary,
                                            _emailFocusController.value,
                                          ) ??
                                          border;

                                      return Container(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
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
                                          Icons.email_outlined,
                                          size: 18,
                                          color: muted,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Focus(
                                            onFocusChange: (hasFocus) {
                                              if (hasFocus) {
                                                _emailFocusController.forward();
                                              } else {
                                                _emailFocusController.reverse();
                                              }
                                            },
                                            child: TextField(
                                              controller: _emailController,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                border: InputBorder.none,
                                                hintText: 'ex: user@mail.com',
                                                hintStyle: TextStyle(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                              ),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: onSurface,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                if (_isOtpSent) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    '6-digit OTP',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: muted,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(6, (i) {
                                      return SizedBox(
                                        width: 40,
                                        child: RawKeyboardListener(
                                          focusNode: FocusNode(),
                                          onKey: (e) => _onOtpBackspace(e, i),
                                          child: TextField(
                                            focusNode: _otpTextNodes[i],
                                            controller: _otpControllers[i],
                                            textAlign: TextAlign.center,
                                            maxLength: 1,
                                            keyboardType: TextInputType.number,
                                            textInputAction: i == 5
                                                ? TextInputAction.done
                                                : TextInputAction.next,
                                            decoration: InputDecoration(
                                              counterText: '',
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color:
                                                      _otpControllers[i]
                                                          .text
                                                          .isNotEmpty
                                                      ? primary
                                                      : border,
                                                ),
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: onSurface,
                                            ),
                                            onChanged: (text) =>
                                                _onOtpChanged(text, i),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),

                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: _sendOtp,
                                        child: Text(
                                          'Resend OTP',
                                          style: TextStyle(
                                            color: link,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isOtpSent = false;
                                            for (final c in _otpControllers) {
                                              c.clear();
                                            }
                                          });
                                        },
                                        child: Text(
                                          'Change email',
                                          style: TextStyle(
                                            color: link,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 18),

                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _primaryDisabled
                                      ? null
                                      : _onPrimaryPressed,
                                  child: Opacity(
                                    opacity: _primaryDisabled ? 0.7 : 1.0,
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
                                              _primaryLabel,
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
