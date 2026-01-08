import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:material_design_icons_flutter/material_design_icons_flutter.dart";

/* ---------------- score + label (same logic) ---------------- */

int scorePassword(String pwd) {
  var score = 0;
  if (pwd.length >= 8) score++;
  if (RegExp(r"[A-Z]").hasMatch(pwd)) score++;
  if (RegExp(r"[a-z]").hasMatch(pwd)) score++;
  if (RegExp(r"\d").hasMatch(pwd)) score++;
  if (RegExp(r"[^A-Za-z0-9]").hasMatch(pwd)) score++;
  return score > 5 ? 5 : score;
}

String strengthLabel(int n) {
  final labels = ["Very weak", "Weak", "Okay", "Good", "Strong"];
  final idx = (n - 1).clamp(0, 4);
  return labels[idx];
}

/* ---------------- Theme Tokens (match your RN T keys) ---------------- */

class Tokens {
  final Color background;
  final Color elevated;
  final Color surface;
  final Color border;

  final Color primary;
  final Color accent;
  final Color onPrimary;

  final Color onBackground;
  final Color muted;

  final Color disabled;
  final Color error;

  final Color success;
  final Color info;
  final Color warning;

  const Tokens({
    required this.background,
    required this.elevated,
    required this.surface,
    required this.border,
    required this.primary,
    required this.accent,
    required this.onPrimary,
    required this.onBackground,
    required this.muted,
    required this.disabled,
    required this.error,
    required this.success,
    required this.info,
    required this.warning,
  });

  factory Tokens.light() => const Tokens(
    background: Color(0xFFFFFFFF),
    elevated: Color(0xFFFFFFFF),
    surface: Color(0xFFF6F7FB),
    border: Color(0xFFE5E7EB),
    primary: Color(0xFF667EEA),
    accent: Color(0xFF764BA2),
    onPrimary: Color(0xFFFFFFFF),
    onBackground: Color(0xFF0F172A),
    muted: Color(0xFF64748B),
    disabled: Color(0xFFCBD5E1),
    error: Color(0xFFEF4444),
    success: Color(0xFF10B981),
    info: Color(0xFF3B82F6),
    warning: Color(0xFFF59E0B),
  );
}

/* ---------------- Responsive scale (like RN size-matters) ---------------- */

class S {
  static const double _baseW = 375.0;
  static const double _baseH = 812.0;

  static double w(BuildContext c) => MediaQuery.of(c).size.width;
  static double h(BuildContext c) => MediaQuery.of(c).size.height;

  static double scale(BuildContext c, double v) => v * (w(c) / _baseW);
  static double verticalScale(BuildContext c, double v) => v * (h(c) / _baseH);

  static double moderateScale(BuildContext c, double v, {double factor = 0.5}) {
    final s = scale(c, v);
    return v + (s - v) * factor;
  }
}

/* ---------------- Screen ---------------- */

class ChangePasswordScreenFlutter extends StatefulWidget {
  const ChangePasswordScreenFlutter({super.key, this.T, this.themeName});

  final Tokens? T;
  final String? themeName; // "dark"/"light" (optional)

  @override
  State<ChangePasswordScreenFlutter> createState() =>
      _ChangePasswordScreenFlutterState();
}

class _ChangePasswordScreenFlutterState
    extends State<ChangePasswordScreenFlutter> {
  late final Tokens T;
  late final String themeName;

  final currentCtrl = TextEditingController();
  final nextCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool showCur = false;
  bool showNew = false;
  bool showCon = false;

  bool submitting = false;
  Map<String, String> errors = {};

  @override
  void initState() {
    super.initState();
    T = widget.T ?? Tokens.light();
    themeName = widget.themeName ?? "light";

    currentCtrl.addListener(_rebuild);
    nextCtrl.addListener(_rebuild);
    confirmCtrl.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    currentCtrl.dispose();
    nextCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  int get score => scorePassword(nextCtrl.text);
  bool get canSubmit {
    final current = currentCtrl.text.trim();
    final next = nextCtrl.text.trim();
    final confirm = confirmCtrl.text.trim();

    final base =
        current.isNotEmpty &&
        next.length >= 8 &&
        confirm.isNotEmpty &&
        next == confirm &&
        score >= 3;

    return base && !submitting;
  }

  bool validate() {
    final e = <String, String>{};

    final current = currentCtrl.text.trim();
    final next = nextCtrl.text;
    final confirm = confirmCtrl.text;

    if (current.isEmpty) e["current"] = "Enter your current password";
    if (next.length < 8) e["next"] = "Minimum 8 characters";
    if (next.isNotEmpty && next == current) {
      e["next"] = "New password must be different";
    }
    if (next.isNotEmpty && confirm.isNotEmpty && next != confirm) {
      e["confirm"] = "Passwords do not match";
    }

    setState(() => errors = e);
    return e.isEmpty;
  }

  Future<void> onSubmit() async {
    if (!validate()) return;

    setState(() => submitting = true);

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() => submitting = false);

    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final barStyle = themeName == "dark"
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: barStyle.copyWith(statusBarColor: T.background),
      child: Scaffold(
        backgroundColor: T.background,
        body: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  _Header(
                    T: T,
                    title: "Change password",
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: S.scale(context, 16),
                      ).copyWith(bottom: S.verticalScale(context, 140)),
                      child: Column(
                        children: [
                          Container(
                            margin: EdgeInsets.only(
                              top: S.verticalScale(context, 70),
                            ),
                            padding: EdgeInsets.all(S.scale(context, 12)),
                            decoration: BoxDecoration(
                              color: T.elevated,
                              borderRadius: BorderRadius.circular(
                                S.scale(context, 12),
                              ),
                              border: Border.all(color: T.border, width: 1),
                            ),
                            child: Column(
                              children: [
                                FieldPassword(
                                  T: T,
                                  label: "Current password",
                                  controller: currentCtrl,
                                  placeholder: "Enter current password",
                                  visible: showCur,
                                  onToggle: () =>
                                      setState(() => showCur = !showCur),
                                  error: errors["current"],
                                  icon: MdiIcons.lockOutline,
                                ),
                                FieldPassword(
                                  T: T,
                                  label: "New password",
                                  controller: nextCtrl,
                                  placeholder: "Minimum 8 characters",
                                  visible: showNew,
                                  onToggle: () =>
                                      setState(() => showNew = !showNew),
                                  error: errors["next"],
                                  icon: MdiIcons.shieldLockOutline,
                                ),
                                StrengthMeter(T: T, score: score),
                                ReqRow(
                                  T: T,
                                  ok: nextCtrl.text.length >= 8,
                                  label: "At least 8 characters",
                                ),
                                ReqRow(
                                  T: T,
                                  ok: RegExp(r"[A-Z]").hasMatch(nextCtrl.text),
                                  label: "One uppercase letter (A–Z)",
                                ),
                                ReqRow(
                                  T: T,
                                  ok: RegExp(r"[a-z]").hasMatch(nextCtrl.text),
                                  label: "One lowercase letter (a–z)",
                                ),
                                ReqRow(
                                  T: T,
                                  ok: RegExp(r"\d").hasMatch(nextCtrl.text),
                                  label: "One number (0–9)",
                                ),
                                ReqRow(
                                  T: T,
                                  ok: RegExp(
                                    r"[^A-Za-z0-9]",
                                  ).hasMatch(nextCtrl.text),
                                  label: "One special character (!@#\$…)",
                                ),
                                FieldPassword(
                                  T: T,
                                  label: "Confirm new password",
                                  controller: confirmCtrl,
                                  placeholder: "Re-enter new password",
                                  visible: showCon,
                                  onToggle: () =>
                                      setState(() => showCon = !showCon),
                                  error: errors["confirm"],
                                  icon: MdiIcons.lockCheckOutline,
                                  last: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Sticky bottom bar (absolute)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: T.elevated,
                    border: Border(top: BorderSide(color: T.border)),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: S.scale(context, 16),
                    vertical: S.verticalScale(context, 10),
                  ).copyWith(bottom: S.verticalScale(context, 10)),
                  child: SizedBox(
                    height: S.verticalScale(context, 44),
                    child: ElevatedButton(
                      onPressed: canSubmit ? onSubmit : null,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: canSubmit ? T.primary : T.accent,
                        disabledBackgroundColor: T.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            S.scale(context, 12),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            submitting
                                ? MdiIcons.loading
                                : MdiIcons.contentSave,
                            size: S.moderateScale(context, 16),
                            color: T.onPrimary,
                          ),
                          SizedBox(width: S.scale(context, 8)),
                          Text(
                            submitting ? "Updating…" : "Update",
                            style: TextStyle(
                              color: T.onPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: S.moderateScale(context, 12),
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
    );
  }
}

/* ---------------- Widgets (same look) ---------------- */

class _Header extends StatelessWidget {
  const _Header({required this.T, required this.title, required this.onBack});

  final Tokens T;
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: S.scale(context, 16),
        vertical: S.verticalScale(context, 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(S.scale(context, 10)),
            onTap: onBack,
            child: Container(
              width: S.scale(context, 36),
              height: S.scale(context, 36),
              decoration: BoxDecoration(
                color: T.accent,
                borderRadius: BorderRadius.circular(S.scale(context, 10)),
              ),
              child: Center(
                child: Icon(
                  MdiIcons.arrowLeft,
                  size: S.moderateScale(context, 20),
                  color: T.onPrimary,
                ),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: S.moderateScale(context, 16),
              fontWeight: FontWeight.w800,
              color: T.onBackground,
            ),
          ),
          SizedBox(width: S.scale(context, 36)),
        ],
      ),
    );
  }
}

class FieldPassword extends StatelessWidget {
  const FieldPassword({
    super.key,
    required this.T,
    required this.label,
    required this.controller,
    required this.placeholder,
    required this.visible,
    required this.onToggle,
    required this.icon,
    this.error,
    this.last = false,
  });

  final Tokens T;
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final bool visible;
  final VoidCallback onToggle;
  final IconData icon;
  final String? error;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: last ? Colors.transparent : T.border),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: S.scale(context, 10),
              vertical: S.verticalScale(context, 10),
            ),
            child: Row(
              children: [
                Container(
                  width: S.scale(context, 36),
                  height: S.scale(context, 36),
                  decoration: BoxDecoration(
                    color: T.surface,
                    borderRadius: BorderRadius.circular(S.scale(context, 10)),
                  ),
                  child: Icon(
                    icon,
                    size: S.moderateScale(context, 18),
                    color: T.onBackground,
                  ),
                ),
                SizedBox(width: S.scale(context, 10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: S.moderateScale(context, 11),
                          fontWeight: FontWeight.w700,
                          color: T.muted,
                        ),
                      ),
                      SizedBox(height: S.verticalScale(context, 2)),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              obscureText: !visible,
                              autocorrect: false,
                              enableSuggestions: false,
                              textCapitalization: TextCapitalization.none,
                              style: TextStyle(
                                fontSize: S.moderateScale(context, 13),
                                fontWeight: FontWeight.w700,
                                color: T.onBackground,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: placeholder,
                                hintStyle: TextStyle(color: T.muted),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: onToggle,
                            borderRadius: BorderRadius.circular(
                              S.scale(context, 8),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(S.scale(context, 6)),
                              child: Icon(
                                visible
                                    ? MdiIcons.eyeOffOutline
                                    : MdiIcons.eyeOutline,
                                size: S.moderateScale(context, 18),
                                color: T.muted,
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
          if ((error ?? "").isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: S.scale(context, 56),
                bottom: S.verticalScale(context, 8),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  error!,
                  style: TextStyle(
                    fontSize: S.moderateScale(context, 11),
                    fontWeight: FontWeight.w700,
                    color: T.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StrengthMeter extends StatelessWidget {
  const StrengthMeter({super.key, required this.T, required this.score});

  final Tokens T;
  final int score;

  @override
  Widget build(BuildContext context) {
    const total = 5;
    final bars = List.generate(total, (i) => i < score);
    final label = strengthLabel(score);

    final Color tone = score >= 5
        ? T.success
        : score >= 4
        ? T.info
        : score >= 3
        ? T.warning
        : T.error;

    return Padding(
      padding: EdgeInsets.only(
        top: S.verticalScale(context, 6),
        bottom: S.verticalScale(context, 8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(total, (i) {
              return Expanded(
                child: Container(
                  height: S.verticalScale(context, 6),
                  margin: EdgeInsets.only(
                    right: i == total - 1 ? 0 : S.scale(context, 6),
                  ),
                  decoration: BoxDecoration(
                    color: bars[i] ? tone : T.disabled,
                    borderRadius: BorderRadius.circular(S.scale(context, 4)),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: S.verticalScale(context, 6)),
          RichText(
            text: TextSpan(
              style: TextStyle(color: T.muted, fontWeight: FontWeight.w700),
              children: [
                const TextSpan(text: "Strength: "),
                TextSpan(
                  text: label,
                  style: TextStyle(color: tone),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReqRow extends StatelessWidget {
  const ReqRow({
    super.key,
    required this.T,
    required this.ok,
    required this.label,
  });

  final Tokens T;
  final bool ok;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: S.verticalScale(context, 6)),
      child: Row(
        children: [
          Icon(
            ok ? MdiIcons.checkCircle : MdiIcons.checkboxBlankCircleOutline,
            size: S.moderateScale(context, 14),
            color: ok ? T.success : T.muted,
          ),
          SizedBox(width: S.scale(context, 8)),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: ok ? T.onBackground : T.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
