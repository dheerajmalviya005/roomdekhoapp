import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:go_router/go_router.dart';

class SignUpAuthenticationScreen extends StatefulWidget {
  const SignUpAuthenticationScreen({super.key});

  @override
  State<SignUpAuthenticationScreen> createState() =>
      _SignUpAuthenticationScreenState();
}

class _SignUpAuthenticationScreenState extends State<SignUpAuthenticationScreen>
    with TickerProviderStateMixin {
  // --------- controllers ----------
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // ---------- focus nodes ----------
  final _firstFocus = FocusNode();
  final _lastFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  // ---------- focus flags for underline animation ----------
  bool _firstFocused = false;
  bool _lastFocused = false;
  bool _phoneFocused = false;
  bool _emailFocused = false;
  bool _passFocused = false;
  bool _confirmFocused = false;
  bool _roleFocused = false;

  // --------- form state ----------
  bool _showPass = false;
  bool _showConfirm = false;
  bool _accept = true;
  bool _loading = false;

  String _role = '';
  bool _roleOpen = false;

  // --------- errors ----------
  String? _firstNameError;
  String? _lastNameError;
  String? _phoneError;
  String? _emailError;
  String? _passError;
  String? _confirmError;
  String? _roleError;
  String? _termsError;

  // --------- animations ----------
  late final AnimationController _bgController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  late final AnimationController _entranceController;

  final List<String> _roles = const ['TENANT (Renter)', 'OWNER'];

  @override
  void initState() {
    super.initState();

    // background pulse (bubbles)
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));
    _pulseOpacity = Tween<double>(
      begin: 0.12,
      end: 0.20,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    // entrance animation (hero, card, social)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    // start entrance after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceController.forward();
    });

    _firstFocus.addListener(() {
      setState(() => _firstFocused = _firstFocus.hasFocus);
    });
    _lastFocus.addListener(() {
      setState(() => _lastFocused = _lastFocus.hasFocus);
    });
    _phoneFocus.addListener(() {
      setState(() => _phoneFocused = _phoneFocus.hasFocus);
    });
    _emailFocus.addListener(() {
      setState(() => _emailFocused = _emailFocus.hasFocus);
    });
    _passFocus.addListener(() {
      setState(() => _passFocused = _passFocus.hasFocus);
    });
    _confirmFocus.addListener(() {
      setState(() => _confirmFocused = _confirmFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entranceController.dispose();

    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();

    _firstFocus.dispose();
    _lastFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();

    super.dispose();
  }

  // ---------- helpers ----------

  String? _nullIfEmpty(String? v) {
    if (v == null) return null;
    final s = v.trim();
    return s.isEmpty ? null : s;
  }

  String? _normalizeRole(String? label) {
    if (label == null) return null;
    final L = label.toUpperCase();
    if (L.contains('OWNER')) return 'OWNER';
    if (L.startsWith('TENANT')) return 'TENANT';
    return null;
  }

  bool _validate() {
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _phoneError = null;
      _emailError = null;
      _passError = null;
      _confirmError = null;
      _roleError = null;
      _termsError = null;
    });

    bool ok = true;

    if (_firstNameCtrl.text.trim().isEmpty) {
      _firstNameError = 'First name is required';
      ok = false;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      _phoneError = 'Phone is required';
      ok = false;
    }
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _emailError = 'Email is required';
      ok = false;
    } else {
      final emailReg = RegExp(r'^\S+@\S+\.\S+$');
      if (!emailReg.hasMatch(email)) {
        _emailError = 'Enter a valid email';
        ok = false;
      }
    }

    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (pass.trim().isEmpty) {
      _passError = 'Password is required';
      ok = false;
    } else if (pass.length < 6) {
      _passError = 'Minimum 6 characters';
      ok = false;
    }

    if (confirm.trim().isEmpty) {
      _confirmError = 'Please confirm password';
      ok = false;
    } else if (confirm != pass) {
      _confirmError = 'Passwords do not match';
      ok = false;
    }

    if (_role.isEmpty) {
      _roleError = 'Please select a role';
      ok = false;
    }

    if (!_accept) {
      _termsError = 'Please accept Terms & Privacy';
      ok = false;
    }

    if (!ok) {
      setState(() {});
    }
    return ok;
  }

  Future<void> _onSignup() async {
    if (!_validate()) return;

    setState(() => _loading = true);

    final normalizedRole = _normalizeRole(_role);

    // yahi payload aap API ko bhej sakte ho
    final payload = {
      'first_name': _nullIfEmpty(_firstNameCtrl.text),
      'last_name': _nullIfEmpty(_lastNameCtrl.text),
      'phone': _nullIfEmpty(_phoneCtrl.text),
      'email': _nullIfEmpty(_emailCtrl.text),
      'password': _passCtrl.text,
      'role': normalizedRole,
    };

    try {
      await Future.delayed(const Duration(seconds: 1)); // fake delay

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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

    // React Native ke T.* mapping
    final background = cs.surface;
    final surface = cs.surface;
    final primary = cs.primary;
    final onPrimary = cs.onPrimary;
    final onSurface = cs.onSurface;
    final onBackground = cs.onSurface;
    final border = cs.outlineVariant;
    final elevated = cs.surfaceContainerHighest;
    final accent = cs.secondary;
    final muted = onSurface.withOpacity(0.7);
    final disabled = onSurface.withOpacity(0.4);
    final link = cs.primary;
    final shadow = Colors.black.withOpacity(0.15);

    final heroSlide =
        Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
          ),
        );

    final heroScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    final cardSlide =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    final cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.7),
      ),
    );

    final socialSlide =
        Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            // top bubble
            Positioned(
              top: -40,
              left: -80,
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (_, child) {
                  return FadeTransition(
                    opacity: _pulseOpacity,
                    child: ScaleTransition(scale: _pulseScale, child: child),
                  );
                },
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // bottom bubble
            Positioned(
              bottom: -60,
              right: -40,
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (_, child) {
                  return FadeTransition(
                    opacity: _pulseOpacity,
                    child: ScaleTransition(scale: _pulseScale, child: child),
                  );
                },
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            // main content
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50, bottom: 24),
                        child: Column(
                          children: [
                            // hero
                            SlideTransition(
                              position: heroSlide,
                              child: ScaleTransition(
                                scale: heroScale,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: elevated,
                                        borderRadius: BorderRadius.circular(14),
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
                                            MdiIcons.homeCity,
                                            color: accent,
                                            size: 26,
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
                                      'Join PropRental to find your next home',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // card
                            SlideTransition(
                              position: cardSlide,
                              child: FadeTransition(
                                opacity: cardOpacity,
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
                                        color: shadow.withOpacity(0.08),
                                        offset: const Offset(0, 8),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: onSurface,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // First Name
                                      _buildLabel('First Name', muted),
                                      TapRow(
                                        focused: _firstFocused,
                                        baseColor: border,
                                        highlightColor: primary,
                                        onTap: () => _firstFocus.requestFocus(),
                                        child: Row(
                                          children: [
                                            Icon(
                                              MdiIcons.accountOutline,
                                              color: muted,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                controller: _firstNameCtrl,
                                                focusNode: _firstFocus,
                                                textInputAction:
                                                    TextInputAction.next,
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  border: InputBorder.none,
                                                  hintText: 'John',
                                                  hintStyle: TextStyle(
                                                    color: disabled,
                                                  ),
                                                ),
                                                style: TextStyle(
                                                  color: onSurface,
                                                  fontSize: 14,
                                                ),
                                                onSubmitted: (_) =>
                                                    _lastFocus.requestFocus(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_firstNameError != null)
                                        _buildError(_firstNameError!),

                                      const SizedBox(height: 12),

                                      // Last Name
                                      _buildLabel(
                                        'Last Name (optional)',
                                        muted,
                                      ),
                                      TapRow(
                                        focused: _lastFocused,
                                        baseColor: border,
                                        highlightColor: primary,
                                        onTap: () => _lastFocus.requestFocus(),
                                        child: Row(
                                          children: [
                                            Icon(
                                              MdiIcons.accountOutline,
                                              color: muted,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                controller: _lastNameCtrl,
                                                focusNode: _lastFocus,
                                                textInputAction:
                                                    TextInputAction.next,
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  border: InputBorder.none,
                                                  hintText: 'Doe',
                                                  hintStyle: TextStyle(
                                                    color: disabled,
                                                  ),
                                                ),
                                                style: TextStyle(
                                                  color: onSurface,
                                                  fontSize: 14,
                                                ),
                                                onSubmitted: (_) =>
                                                    _phoneFocus.requestFocus(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_lastNameError != null)
                                        _buildError(_lastNameError!),

                                      const SizedBox(height: 12),

                                      // Phone
                                      _buildLabel('Phone', muted),
                                      TapRow(
                                        focused: _phoneFocused,
                                        baseColor: border,
                                        highlightColor: primary,
                                        onTap: () => _phoneFocus.requestFocus(),
                                        child: Row(
                                          children: [
                                            Icon(
                                              MdiIcons.phoneOutline,
                                              color: muted,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                controller: _phoneCtrl,
                                                focusNode: _phoneFocus,
                                                keyboardType:
                                                    TextInputType.phone,
                                                textInputAction:
                                                    TextInputAction.next,
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  border: InputBorder.none,
                                                  hintText: '+91 98765 43210',
                                                  hintStyle: TextStyle(
                                                    color: disabled,
                                                  ),
                                                ),
                                                style: TextStyle(
                                                  color: onSurface,
                                                  fontSize: 14,
                                                ),
                                                onSubmitted: (_) =>
                                                    _emailFocus.requestFocus(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_phoneError != null)
                                        _buildError(_phoneError!),

                                      const SizedBox(height: 12),

                                      // Email
                                      _buildLabel('Email', muted),
                                      TapRow(
                                        focused: _emailFocused,
                                        baseColor: border,
                                        highlightColor: primary,
                                        onTap: () => _emailFocus.requestFocus(),
                                        child: Row(
                                          children: [
                                            Icon(
                                              MdiIcons.emailOutline,
                                              color: muted,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                controller: _emailCtrl,
                                                focusNode: _emailFocus,
                                                keyboardType:
                                                    TextInputType.emailAddress,
                                                textInputAction:
                                                    TextInputAction.next,
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  border: InputBorder.none,
                                                  hintText: 'user@mail.com',
                                                  hintStyle: TextStyle(
                                                    color: disabled,
                                                  ),
                                                ),
                                                style: TextStyle(
                                                  color: onSurface,
                                                  fontSize: 14,
                                                ),
                                                onSubmitted: (_) =>
                                                    _passFocus.requestFocus(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_emailError != null)
                                        _buildError(_emailError!),

                                      const SizedBox(height: 12),

                                      // Password
                                      _buildLabel('Password', muted),
                                      TapRow(
                                        focused: _passFocused,
                                        baseColor: border,
                                        highlightColor: primary,
                                        onTap: () => _passFocus.requestFocus(),
                                        child: Row(
                                          children: [
                                            Icon(
                                              MdiIcons.lockOutline,
                                              color: muted,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                controller: _passCtrl,
                                                focusNode: _passFocus,
                                                obscureText: !_showPass,
                                                textInputAction:
                                                    TextInputAction.next,
                                                decoration:
                                                    const InputDecoration(
                                                      isDense: true,
                                                      border: InputBorder.none,
                                                      hintText:
                                                          'Enter password',
                                                    ),
                                                style: TextStyle(
                                                  color: onSurface,
                                                  fontSize: 14,
                                                ),
                                                onSubmitted: (_) =>
                                                    _confirmFocus
                                                        .requestFocus(),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _showPass = !_showPass;
                                                });
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 8.0,
                                                ),
                                                child: Icon(
                                                  _showPass
                                                      ? MdiIcons.eyeOffOutline
                                                      : MdiIcons.eyeOutline,
                                                  color: muted,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_passError != null)
                                        _buildError(_passError!),

                                      const SizedBox(height: 12),

                                      // Confirm Password
                                      _buildLabel('Confirm Password', muted),
                                      TapRow(
                                        focused: _confirmFocused,
                                        baseColor: border,
                                        highlightColor: primary,
                                        onTap: () =>
                                            _confirmFocus.requestFocus(),
                                        child: Row(
                                          children: [
                                            Icon(
                                              MdiIcons.lockCheckOutline,
                                              color: muted,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                controller: _confirmCtrl,
                                                focusNode: _confirmFocus,
                                                obscureText: !_showConfirm,
                                                textInputAction:
                                                    TextInputAction.done,
                                                decoration:
                                                    const InputDecoration(
                                                      isDense: true,
                                                      border: InputBorder.none,
                                                      hintText:
                                                          'Re-enter password',
                                                    ),
                                                style: TextStyle(
                                                  color: onSurface,
                                                  fontSize: 14,
                                                ),
                                                onSubmitted: (_) => _onSignup(),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _showConfirm = !_showConfirm;
                                                });
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 8.0,
                                                ),
                                                child: Icon(
                                                  _showConfirm
                                                      ? MdiIcons.eyeOffOutline
                                                      : MdiIcons.eyeOutline,
                                                  color: muted,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_confirmError != null)
                                        _buildError(_confirmError!),

                                      const SizedBox(height: 12),

                                      // Role dropdown
                                      _buildLabel('Role', muted),

                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          TapRow(
                                            focused: _roleFocused,
                                            baseColor: border,
                                            highlightColor: primary,
                                            onTap: () {
                                              setState(() {
                                                _roleOpen = !_roleOpen;
                                                _roleFocused = _roleOpen;
                                              });
                                            },
                                            child: Row(
                                              children: [
                                                Icon(
                                                  MdiIcons.accountSwitchOutline,
                                                  color: muted,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        _roleOpen = !_roleOpen;
                                                        _roleFocused =
                                                            _roleOpen;
                                                      });
                                                    },
                                                    child: Container(
                                                      height: 42,
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                        _role.isEmpty
                                                            ? 'Select role'
                                                            : _role,
                                                        style: TextStyle(
                                                          color: onSurface,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  _roleOpen
                                                      ? MdiIcons.chevronUp
                                                      : MdiIcons.chevronDown,
                                                  color: muted,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),

                                          if (_roleError != null)
                                            _buildError(_roleError!),

                                          // 👇 yahi pe dropdown dikhayenge – ab sab kuch neeche push hoga, hide nahi karega
                                          if (_roleOpen)
                                            const SizedBox(height: 6),

                                          if (_roleOpen)
                                            Material(
                                              elevation: 4,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: elevated,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: border,
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: _roles.map((opt) {
                                                    final selected =
                                                        _role == opt;
                                                    return InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          _role = opt;
                                                          _roleOpen = false;
                                                          _roleFocused = false;
                                                        });
                                                      },
                                                      child: Container(
                                                        height: 36,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                            ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              opt,
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    selected
                                                                    ? FontWeight
                                                                          .w700
                                                                    : FontWeight
                                                                          .w500,
                                                                color: selected
                                                                    ? primary
                                                                    : onSurface,
                                                              ),
                                                            ),
                                                            if (selected)
                                                              Icon(
                                                                Icons.check,
                                                                size: 16,
                                                                color: primary,
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      // Terms / checkbox
                                      Row(
                                        children: [
                                          BouncyCheckbox(
                                            value: _accept,
                                            onChanged: (v) {
                                              setState(() => _accept = v);
                                            },
                                            border: border,
                                            elevated: elevated,
                                            primary: primary,
                                            onPrimary: onPrimary,
                                            onBackground: onBackground,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'I accept Terms & Privacy',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: onBackground,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_termsError != null)
                                        _buildError(_termsError!),

                                      const SizedBox(height: 16),

                                      // Button
                                      SizedBox(
                                        height: 46,
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            elevation: 0,
                                          ),
                                          onPressed: _loading
                                              ? null
                                              : () => _onSignup(),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              if (_loading)
                                                const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                ),
                                              AnimatedOpacity(
                                                duration: const Duration(
                                                  milliseconds: 150,
                                                ),
                                                opacity: _loading ? 0 : 1,
                                                child: Text(
                                                  'Create Account',
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

                                      const SizedBox(height: 14),

                                      Center(
                                        child: Text(
                                          'Or continue with',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: muted,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // social row
                                      SlideTransition(
                                        position: socialSlide,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _SocialButton(
                                                label: 'Google',
                                                icon: MdiIcons.google,
                                                iconColor: const Color(
                                                  0xFFDB4437,
                                                ),
                                                elevated: elevated,
                                                border: border,
                                                textColor: onSurface,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _SocialButton(
                                                label: 'Facebook',
                                                icon: MdiIcons.facebook,
                                                iconColor: const Color(
                                                  0xFF1877F2,
                                                ),
                                                elevated: elevated,
                                                border: border,
                                                textColor: onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 14),

                                      Center(
                                        child: GestureDetector(
                                          onTap: () {
                                            context.go('/login');
                                          },
                                          child: RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: muted,
                                              ),
                                              children: [
                                                const TextSpan(
                                                  text:
                                                      'Already have an account? ',
                                                ),
                                                TextSpan(
                                                  text: 'Sign In',
                                                  style: TextStyle(
                                                    color: link,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  recognizer: null,
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: TextStyle(fontSize: 12, color: color)),
    );
  }

  Widget _buildError(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.red),
      ),
    );
  }
}

// ------------- TapRow (underline input row) ----------------

class TapRow extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color baseColor;
  final Color highlightColor;
  final bool focused;

  const TapRow({
    super.key,
    required this.child,
    this.onTap,
    required this.baseColor,
    required this.highlightColor,
    required this.focused,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 1,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              AnimatedAlign(
                alignment: Alignment.centerLeft,
                duration: const Duration(milliseconds: 200),
                child: FractionallySizedBox(
                  widthFactor: focused ? 1.0 : 0.0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------- Bouncy Checkbox ----------------

class BouncyCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color border;
  final Color elevated;
  final Color primary;
  final Color onPrimary;
  final Color onBackground;

  const BouncyCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.border,
    required this.elevated,
    required this.primary,
    required this.onPrimary,
    required this.onBackground,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = value ? primary : elevated;
    final borderColor = value ? primary : border;

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Center(
              child: AnimatedScale(
                scale: value ? 1.0 : 0.01,
                duration: const Duration(milliseconds: 180),
                curve: Curves.elasticOut,
                child: value
                    ? Icon(Icons.check, size: 12, color: onPrimary)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------- Social button ----------------

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color elevated;
  final Color border;
  final Color textColor;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.elevated,
    required this.border,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
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
