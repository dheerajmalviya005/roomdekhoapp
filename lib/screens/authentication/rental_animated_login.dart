import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart'; // Add this
import '../../widgets/error_toast.dart';

class RentalAnimatedLogin extends StatefulWidget {
  const RentalAnimatedLogin({super.key});

  @override
  State<RentalAnimatedLogin> createState() => _RentalAnimatedLoginState();
}

class _RentalAnimatedLoginState extends State<RentalAnimatedLogin>
    with TickerProviderStateMixin {
  // Text fields
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  String _emailError = '';
  String _passError = '';
  String _apiError = '';
  bool _loading = false;
  bool _showPass = false;
  bool _remember = true;
  bool _emailFocused = false;

  // Animations
  late final AnimationController _heroCtrl;
  late final Animation<double> _heroTranslateY;
  late final Animation<double> _heroScale;

  late final AnimationController _cardCtrl;
  late final Animation<double> _cardTranslateY;
  late final Animation<double> _cardOpacity;

  late final AnimationController _socialCtrl;
  late final Animation<double> _socialTranslateX;

  late final AnimationController _bgPulseCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  late final AnimationController _passFocusCtrl;
  late Animation<Color?> _passUnderlineColor;

  late final AnimationController _btnFillCtrl;
  late final Animation<double> _btnFillFactor;

  @override
  void initState() {
    super.initState();

    // Hero (logo + title)
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heroTranslateY = Tween<double>(
      begin: -40,
      end: 0,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutCubic));
    _heroScale = Tween<double>(
      begin: 0.9,
      end: 1,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutBack));

    // Card (login form)
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _cardTranslateY = Tween<double>(
      begin: 40,
      end: 0,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));

    // Social row
    _socialCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _socialTranslateX = Tween<double>(
      begin: 40,
      end: 0,
    ).animate(CurvedAnimation(parent: _socialCtrl, curve: Curves.easeOutCubic));

    // Background bubbles pulse
    _bgPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _pulseScale = Tween<double>(begin: 1, end: 1.06).animate(
      CurvedAnimation(parent: _bgPulseCtrl, curve: Curves.easeInOutQuad),
    );
    _pulseOpacity = Tween<double>(begin: 0.12, end: 0.2).animate(
      CurvedAnimation(parent: _bgPulseCtrl, curve: Curves.easeInOutQuad),
    );

    // Password underline focus
    _passFocusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    // Button fill
    _btnFillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _btnFillFactor = Tween<double>(begin: 0, end: 1).animate(_btnFillCtrl);

    // Start intro animations sequence
    _startIntroAnimations();
    _startBgPulse();
  }

  void _startIntroAnimations() async {
    await _heroCtrl.forward();
    await _cardCtrl.forward();
    await _socialCtrl.forward();
  }

  void _startBgPulse() {
    _bgPulseCtrl.forward();
    _bgPulseCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _bgPulseCtrl.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _bgPulseCtrl.forward();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Theme mapping similar to T object in RN
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final Color border = cs.outline;
    final Color primary = cs.primary;

    _passUnderlineColor = ColorTween(
      begin: border,
      end: primary,
    ).animate(_passFocusCtrl);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _heroCtrl.dispose();
    _cardCtrl.dispose();
    _socialCtrl.dispose();
    _bgPulseCtrl.dispose();
    _passFocusCtrl.dispose();
    _btnFillCtrl.dispose();
    super.dispose();
  }

  // Replace your current _onLogin() method with this
  Future<void> _onLogin() async {
    // Clear errors
    setState(() {
      _emailError = '';
      _passError = '';
      _apiError = '';
    });

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    // Validation
    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter email / phone');
      return;
    }
    if (pass.isEmpty) {
      setState(() => _passError = 'Please enter password');
      return;
    }

    setState(() => _loading = true);

    try {
      print('\n🔄 STARTING LOGIN PROCESS...');

      // Call AuthService
      final result = await AuthService.loginUser(email, pass);

      print('\n🔄 LOGIN RESULT RECEIVED');
      print('Success: ${result["success"]}');
      print('Role in payload: ${result["payload"]?["role"]}');

      if (result["success"] == true) {
        final token = result["token"];
        final role = result["payload"]?["role"] ?? "UNKNOWN";

        print('\n✅ LOGIN COMPLETE SUCCESSFULLY!');
        print('✅ Token: ${AuthService.maskToken(token)}');
        print('✅ User Role: $role');

        // Show role-based success message
        String welcomeMessage = "Welcome!";
        if (role == 'OWNER') {
          welcomeMessage = "Welcome Owner!";
        } else if (role == 'TENANT') {
          welcomeMessage = "Welcome Tenant!";
        }

        ErrorToast.show(
          context,
          message: "Login successful!\n$welcomeMessage",
          title: "Success",
          icon: Icons.check_circle,
          accent: Colors.green,
        );

        // Print current token from memory
        AuthService.printCurrentToken();

        // ✅ Get navigation path based on role
        final navigationPath = AuthService.getNavigationPath();
        print('\n📍 NAVIGATING TO: $navigationPath');

        // Show navigation info
        await Future.delayed(const Duration(seconds: 1));

        // Navigate based on role
        if (mounted) {
          // Show brief message about where user is going
          if (role == 'OWNER') {
            ErrorToast.show(
              context,
              message: "Redirecting to Owner Dashboard...",
              title: "Owner Access",
              icon: Icons.business,
              accent: Colors.blue,
              duration: const Duration(seconds: 1),
            );
          } else if (role == 'TENANT') {
            ErrorToast.show(
              context,
              message: "Redirecting to Tenant Dashboard...",
              title: "Tenant Access",
              icon: Icons.home,
              accent: Colors.green,
              duration: const Duration(seconds: 1),
            );
          }

          // Navigate after showing message
          await Future.delayed(const Duration(seconds: 1));
          context.go(navigationPath);
        }
      } else {
        print('\n❌ LOGIN FAILED');

        String errorMessage = result["message"] ?? "Login failed";
        setState(() => _apiError = errorMessage);

        ErrorToast.show(context, message: errorMessage, title: "Failed");
      }
    } catch (e) {
      print('\n❌ LOGIN EXCEPTION: $e');

      ErrorToast.show(context, message: "Something went wrong", title: "Error");

      setState(() => _apiError = "An error occurred");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final media = MediaQuery.of(context);
    final sw = media.size.width;
    final sh = media.size.height;
    final insets = media.viewInsets;

    // React Native size-matters like helpers
    double scale(double v) => v * sw / 375;
    double vScale(double v) => v * sh / 812;
    double mScale(double v) => v * (sw / 375 + sh / 812) / 2;

    // T mapping similar to RN useTheme()
    final background = theme.scaffoldBackgroundColor;
    final primary = cs.primary;
    final primaryVariant = cs.primaryContainer;
    final accent = cs.secondary;
    final elevated = cs.surfaceContainerHighest;
    final surface = cs.surface;
    final border = cs.outline;
    final onBackground = cs.onSurface;
    final onSurface = cs.onSurface;
    final onPrimary = cs.onPrimary;
    final shadow = Colors.black.withOpacity(0.25);
    final muted = cs.onSurface.withOpacity(0.7);
    final disabled = cs.onSurface.withOpacity(0.4);
    final link = Colors.blue;

    final barStyle = theme.brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;

    return SafeArea(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: barStyle == Brightness.dark
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: background,
          body: AnimatedBuilder(
            animation: Listenable.merge([
              _heroCtrl,
              _cardCtrl,
              _socialCtrl,
              _bgPulseCtrl,
              _passFocusCtrl,
              _btnFillCtrl,
            ]),
            builder: (context, _) {
              return GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Stack(
                  children: [
                    // 🔵 Background bubbles as full-screen layer
                    Positioned.fill(
                      child: PositionedBubbles(
                        scale: _pulseScale.value,
                        opacity: _pulseOpacity.value,
                        primary: primary,
                        accent: accent,
                        scaleFn: scale,
                        vScaleFn: vScale,
                      ),
                    ),

                    // Main scroll content
                    SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: scale(16),
                        right: scale(16),
                        bottom: insets.bottom + vScale(24),
                      ),
                      child: SizedBox(
                        height: sh,
                        child: Column(
                          children: [
                            SizedBox(height: vScale(90)),

                            // Hero section
                            Transform.translate(
                              offset: Offset(0, _heroTranslateY.value),
                              child: Transform.scale(
                                scale: _heroScale.value,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: scale(14),
                                        vertical: vScale(8),
                                      ),
                                      decoration: BoxDecoration(
                                        color: elevated,
                                        borderRadius: BorderRadius.circular(
                                          mScale(14),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: shadow.withOpacity(0.06),
                                            offset: const Offset(0, 4),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.location_city,
                                            size: mScale(26),
                                            color: accent,
                                          ),
                                          SizedBox(width: scale(8)),
                                          Text(
                                            'PropRental',
                                            style: TextStyle(
                                              fontSize: mScale(18),
                                              fontWeight: FontWeight.w700,
                                              color: onBackground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: vScale(8)),
                                    Text(
                                      'Find your next home — sign in to continue',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: mScale(12),
                                        color: muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: vScale(8)),

                            // Card
                            Opacity(
                              opacity: _cardOpacity.value,
                              child: Transform.translate(
                                offset: Offset(0, _cardTranslateY.value),
                                child: Container(
                                  width: double.infinity,
                                  margin: EdgeInsets.only(
                                    top: vScale(12),
                                    bottom: vScale(18),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: scale(18),
                                    vertical: vScale(16),
                                  ),
                                  decoration: BoxDecoration(
                                    color: surface,
                                    borderRadius: BorderRadius.circular(
                                      mScale(16),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: shadow.withOpacity(0.08),
                                        blurRadius: 12,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: mScale(20),
                                          fontWeight: FontWeight.w700,
                                          color: onSurface,
                                        ),
                                      ),

                                      // Email / phone
                                      SizedBox(height: vScale(4)),
                                      Text(
                                        'Email / Phone',
                                        style: TextStyle(
                                          fontSize: mScale(12),
                                          color: muted,
                                        ),
                                      ),
                                      SizedBox(height: vScale(6)),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.email_outlined,
                                            size: mScale(18),
                                            color: muted,
                                          ),
                                          SizedBox(width: scale(8)),
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: _emailFocused
                                                        ? primary
                                                        : border,
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                              child: TextField(
                                                controller: _emailCtrl,
                                                onChanged: (_) {
                                                  if (_emailError.isNotEmpty) {
                                                    setState(() {
                                                      _emailError = '';
                                                    });
                                                  }
                                                },
                                                onTap: () {
                                                  setState(() {
                                                    _emailFocused = true;
                                                  });
                                                },
                                                onEditingComplete: () {
                                                  setState(() {
                                                    _emailFocused = false;
                                                  });
                                                  FocusScope.of(
                                                    context,
                                                  ).nextFocus();
                                                },
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  border: InputBorder.none,
                                                  hintText:
                                                      'ex: user@mail.com or +91 98765 43210',
                                                  hintStyle: TextStyle(
                                                    color: disabled,
                                                    fontSize: mScale(14),
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                        bottom: vScale(6),
                                                      ),
                                                ),
                                                style: TextStyle(
                                                  color: onSurface,
                                                  fontSize: mScale(14),
                                                ),
                                                keyboardType:
                                                    TextInputType.emailAddress,
                                                textInputAction:
                                                    TextInputAction.next,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_emailError.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: vScale(4),
                                          ),
                                          child: Text(
                                            _emailError,
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: mScale(12),
                                            ),
                                          ),
                                        ),

                                      // Password
                                      SizedBox(height: vScale(14)),
                                      Text(
                                        'Password',
                                        style: TextStyle(
                                          fontSize: mScale(12),
                                          color: muted,
                                        ),
                                      ),
                                      SizedBox(height: vScale(6)),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color:
                                                  _passUnderlineColor.value ??
                                                  border,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.lock_outline,
                                              size: mScale(18),
                                              color: muted,
                                            ),
                                            SizedBox(width: scale(8)),
                                            Expanded(
                                              child: TextField(
                                                controller: _passCtrl,
                                                onTap: () {
                                                  _passFocusCtrl.forward();
                                                  if (_passError.isNotEmpty) {
                                                    setState(() {
                                                      _passError = '';
                                                    });
                                                  }
                                                },
                                                onEditingComplete: () {
                                                  _passFocusCtrl.reverse();
                                                },
                                                obscureText: !_showPass,
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  border: InputBorder.none,
                                                  hintText: 'Enter password',
                                                  hintStyle: TextStyle(
                                                    color: disabled,
                                                    fontSize: mScale(14),
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                        bottom: vScale(6),
                                                      ),
                                                ),
                                                style: TextStyle(
                                                  color: onSurface,
                                                  fontSize: mScale(14),
                                                ),
                                                textInputAction:
                                                    TextInputAction.done,
                                                onSubmitted: (_) => _onLogin(),
                                              ),
                                            ),
                                            GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {
                                                setState(() {
                                                  _showPass = !_showPass;
                                                });
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  left: scale(8),
                                                ),
                                                child: Icon(
                                                  _showPass
                                                      ? Icons
                                                            .visibility_off_outlined
                                                      : Icons
                                                            .visibility_outlined,
                                                  size: mScale(18),
                                                  color: muted,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_passError.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: vScale(4),
                                          ),
                                          child: Text(
                                            _passError,
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: mScale(12),
                                            ),
                                          ),
                                        ),

                                      // Remember + forgot
                                      SizedBox(height: vScale(12)),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _BouncyCheckbox(
                                            checked: _remember,
                                            onChanged: (v) {
                                              setState(() {
                                                _remember = v;
                                              });
                                            },
                                            border: border,
                                            elevated: elevated,
                                            primary: primary,
                                            onPrimary: onPrimary,
                                            textColor: onBackground,
                                            scaleFn: scale,
                                            mScaleFn: mScale,
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              context.go('/forgotpassword');
                                            },
                                            child: Text(
                                              'Forgot password?',
                                              style: TextStyle(
                                                fontSize: mScale(12),
                                                fontWeight: FontWeight.w600,
                                                color: link,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Login button
                                      SizedBox(height: vScale(16)),
                                      SizedBox(
                                        height: vScale(46),
                                        width: double.infinity,
                                        child: Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: primary,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      mScale(10),
                                                    ),
                                              ),
                                            ),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    mScale(10),
                                                  ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: FractionallySizedBox(
                                                  widthFactor:
                                                      _btnFillFactor.value,
                                                  child: Container(
                                                    color: primaryVariant
                                                        .withOpacity(0.9),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                minimumSize: Size.zero,
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        mScale(10),
                                                      ),
                                                ),
                                              ),
                                              onPressed: _loading
                                                  ? null
                                                  : _onLogin,
                                              child: Center(
                                                child: Text(
                                                  _loading
                                                      ? 'Signing In...'
                                                      : 'Sign In',
                                                  style: TextStyle(
                                                    fontSize: mScale(14),
                                                    fontWeight: FontWeight.w700,
                                                    color: onPrimary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (_apiError.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: vScale(6),
                                          ),
                                          child: Text(
                                            _apiError,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: mScale(13),
                                            ),
                                          ),
                                        ),

                                      // Or continue with
                                      SizedBox(height: vScale(14)),
                                      Center(
                                        child: Text(
                                          'Or continue with',
                                          style: TextStyle(
                                            fontSize: mScale(12),
                                            color: muted,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: vScale(8)),

                                      // Social buttons
                                      Transform.translate(
                                        offset: Offset(
                                          _socialTranslateX.value,
                                          0,
                                        ),
                                        child: Row(
                                          children: [
                                            // Expanded(
                                            //   child: _SocialButton(
                                            //     icon: Icons.g_mobiledata,
                                            //     iconColor: const Color(
                                            //       0xFFDB4437,
                                            //     ),
                                            //     label: 'Google',
                                            //     border: border,
                                            //     elevated: elevated,
                                            //     textColor: onSurface,
                                            //     vScale: vScale,
                                            //     mScale: mScale,
                                            //   ),
                                            // ),
                                            SizedBox(width: scale(8)),
                                            // Expanded(
                                            //   child: _SocialButton(
                                            //     icon: Icons.facebook,
                                            //     iconColor: const Color(
                                            //       0xFF1877F2,
                                            //     ),
                                            //     label: 'Facebook',
                                            //     border: border,
                                            //     elevated: elevated,
                                            //     textColor: onSurface,
                                            //     vScale: vScale,
                                            //     mScale: mScale,
                                            //   ),
                                            // ),
                                          ],
                                        ),
                                      ),

                                      // Bottom text
                                      SizedBox(height: vScale(14)),
                                      Center(
                                        child: GestureDetector(
                                          onTap: () {
                                            context.go('/signup');
                                          },
                                          child: RichText(
                                            text: TextSpan(
                                              text: "Don’t have an account? ",
                                              style: TextStyle(
                                                fontSize: mScale(12),
                                                color: muted,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: 'Sign Up',
                                                  style: TextStyle(
                                                    fontSize: mScale(12),
                                                    color: link,
                                                    fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

class PositionedBubbles extends StatelessWidget {
  final double scale;
  final double opacity;
  final Color primary;
  final Color accent;
  final double Function(double) scaleFn;
  final double Function(double) vScaleFn;

  const PositionedBubbles({
    super.key,
    required this.scale,
    required this.opacity,
    required this.primary,
    required this.accent,
    required this.scaleFn,
    required this.vScaleFn,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: vScaleFn(-100),
            left: -scaleFn(50),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: scaleFn(220),
                  height: scaleFn(220),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(scaleFn(220) / 2),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: vScaleFn(-30),
            right: -scaleFn(20),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: scaleFn(220),
                  height: scaleFn(220),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(scaleFn(220) / 2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BouncyCheckbox extends StatefulWidget {
  final bool checked;
  final ValueChanged<bool> onChanged;
  final Color border;
  final Color elevated;
  final Color primary;
  final Color onPrimary;
  final Color textColor;
  final double Function(double) scaleFn;
  final double Function(double) mScaleFn;

  const _BouncyCheckbox({
    required this.checked,
    required this.onChanged,
    required this.border,
    required this.elevated,
    required this.primary,
    required this.onPrimary,
    required this.textColor,
    required this.scaleFn,
    required this.mScaleFn,
  });

  @override
  State<_BouncyCheckbox> createState() => _BouncyCheckboxState();
}

class _BouncyCheckboxState extends State<_BouncyCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.01,
      upperBound: 1,
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);

    if (widget.checked) {
      _ctrl.value = 1;
    } else {
      _ctrl.value = 0.01;
    }
  }

  @override
  void didUpdateWidget(covariant _BouncyCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checked != widget.checked) {
      if (widget.checked) {
        _ctrl.animateTo(
          1,
          curve: Curves.elasticOut,
          duration: const Duration(milliseconds: 300),
        );
      } else {
        _ctrl.animateTo(
          0.01,
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 150),
        );
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boxSize = widget.scaleFn(16);
    return InkWell(
      onTap: () => widget.onChanged(!widget.checked),
      borderRadius: BorderRadius.circular(widget.scaleFn(3)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: boxSize,
            height: boxSize,
            margin: EdgeInsets.only(right: widget.scaleFn(8)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.scaleFn(3)),
              border: Border.all(
                color: widget.checked ? widget.primary : widget.border,
                width: 1,
              ),
              color: widget.checked ? widget.primary : widget.elevated,
            ),
            child: ScaleTransition(
              scale: _scaleAnim,
              child: widget.checked
                  ? Icon(
                      Icons.check,
                      size: widget.mScaleFn(12),
                      color: widget.onPrimary,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          Text(
            'Remember me',
            style: TextStyle(
              fontSize: widget.mScaleFn(12),
              color: widget.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color border;
  final Color elevated;
  final Color textColor;
  final double Function(double) vScale;
  final double Function(double) mScale;

  const _SocialButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.border,
    required this.elevated,
    required this.textColor,
    required this.vScale,
    required this.mScale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: vScale(40),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(mScale(10)),
        border: Border.all(color: border, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(mScale(10)),
        onTap: () {
          // TODO: social sign-in
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: mScale(18), color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: mScale(12),
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
