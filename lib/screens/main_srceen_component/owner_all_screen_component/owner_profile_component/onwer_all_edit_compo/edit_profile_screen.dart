import "dart:io";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:material_design_icons_flutter/material_design_icons_flutter.dart";

ImageProvider? toImageProvider(dynamic val) {
  if (val == null) return null;

  // asset (already ImageProvider)
  if (val is ImageProvider) return val;

  // Flutter assets are usually strings too
  if (val is String) {
    final s = val.trim();
    if (s.isEmpty) return null;

    if (s.startsWith("http://") || s.startsWith("https://")) {
      return NetworkImage(s);
    }

    if (s.startsWith("file://")) {
      return FileImage(File(s.replaceFirst("file://", "")));
    }

    if (s.startsWith("/")) {
      return FileImage(File(s));
    }

    // treat as asset path
    return AssetImage(s);
  }

  return null;
}

final RegExp emailRx = RegExp(
  r"^[^\s@]+@[^\s@]+\.[^\s@]{2,}$",
  caseSensitive: false,
);
final RegExp phoneRx = RegExp(r"^[0-9+\s()-]{8,}$");

// ---------------- Theme bridge (use your own theme) ----------------

class Tokens {
  final Color background;
  final Color elevated;
  final Color surface;
  final Color border;

  final Color primary;
  final Color onPrimary;

  final Color onBackground;
  final Color muted;

  final Color disabled;
  final Color error;

  final Color success;
  final Color warning;
  final Color accent;

  const Tokens({
    required this.background,
    required this.elevated,
    required this.surface,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.onBackground,
    required this.muted,
    required this.disabled,
    required this.error,

    // ✅ yahan fix
    required this.success,
    required this.warning,
    required this.accent,
  });

  factory Tokens.light() => const Tokens(
    background: Color(0xFFF6F7FB),
    elevated: Colors.white,
    surface: Color(0xFFF1F5F9),
    border: Color(0xFFE5E7EB),
    primary: Color(0xFF667EEA),
    onPrimary: Colors.white,
    onBackground: Color(0xFF0F172A),
    muted: Color(0xFF64748B),
    disabled: Color(0xFFCBD5E1),
    error: Color(0xFFEF4444),

    // ✅ yahan bhi match
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    accent: Color(0xFF667EEA),
  );
}

// ---------------- Screen ----------------

class EditProfileScreenFlutter extends StatefulWidget {
  const EditProfileScreenFlutter({
    super.key,
    this.user,
    this.themeName = "light",
    this.T,
  });

  // like route?.params?.user
  final Map<String, dynamic>? user;

  // "dark"/"light" (for status bar style)
  final String themeName;

  // pass Tokens if you want, else uses light()
  final Tokens? T;

  @override
  State<EditProfileScreenFlutter> createState() =>
      _EditProfileScreenFlutterState();
}

class _EditProfileScreenFlutterState extends State<EditProfileScreenFlutter> {
  late final Tokens T;
  late final String themeName;

  late Map<String, dynamic> form;
  Map<String, String> errors = {};

  bool dirty = false;
  bool saving = false;

  final _scrollController = ScrollController();

  // controllers (so same feel as RN TextInput)
  late final TextEditingController nameC;
  late final TextEditingController roleC;
  late final TextEditingController orgC;
  late final TextEditingController emailC;
  late final TextEditingController phoneC;
  late final TextEditingController aboutC;

  @override
  void initState() {
    super.initState();
    T = widget.T ?? Tokens.light();
    themeName = widget.themeName;

    final initialUser =
        widget.user ??
        {
          "name": "Aarav Mehta",
          "role": "Admin",
          "email": "aarav.mehta@example.com",
          "phone": "+91 98765 43210",
          "avatar": const AssetImage("assets/icon/images.jpg"),
          "about": "I manage property listings and support operations.",
          "org": "University Living",
        };

    form = Map<String, dynamic>.from(initialUser);

    nameC = TextEditingController(text: (form["name"] ?? "").toString());
    roleC = TextEditingController(text: (form["role"] ?? "").toString());
    orgC = TextEditingController(text: (form["org"] ?? "").toString());
    emailC = TextEditingController(text: (form["email"] ?? "").toString());
    phoneC = TextEditingController(text: (form["phone"] ?? "").toString());
    aboutC = TextEditingController(text: (form["about"] ?? "").toString());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    nameC.dispose();
    roleC.dispose();
    orgC.dispose();
    emailC.dispose();
    phoneC.dispose();
    aboutC.dispose();
    super.dispose();
  }

  void setVal(String key, dynamic val) {
    setState(() {
      dirty = true;
      form[key] = val;
    });
  }

  bool validate() {
    final e = <String, String>{};

    final name = (form["name"] ?? "").toString().trim();
    final email = (form["email"] ?? "").toString();
    final phone = (form["phone"] ?? "").toString();
    final role = (form["role"] ?? "").toString().trim();

    if (name.isEmpty) e["name"] = "Name is required";
    if (!emailRx.hasMatch(email)) e["email"] = "Enter a valid email";
    if (!phoneRx.hasMatch(phone)) e["phone"] = "Enter a valid phone";
    if (role.isEmpty) e["role"] = "Role is required";

    setState(() => errors = e);
    return e.isEmpty;
  }

  bool get canSave {
    final quick =
        (form["name"] ?? "").toString().trim().isNotEmpty &&
        emailRx.hasMatch((form["email"] ?? "").toString()) &&
        phoneRx.hasMatch((form["phone"] ?? "").toString()) &&
        (form["role"] ?? "").toString().trim().isNotEmpty;

    return quick && dirty && !saving;
  }

  Future<void> onSave() async {
    if (!validate()) return;

    setState(() => saving = true);

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() {
      saving = false;
      dirty = false;
    });

    Navigator.of(context).maybePop();
  }

  void onPickAvatar() {
    // same logic as RN demo:
    // if current is "number" -> set url else placeholder asset
    // In Flutter we toggle between network + asset.
    final current = form["avatar"];
    final next = (current is String || current is NetworkImage)
        ? const AssetImage("assets/images/images.jpg")
        : "https://i.pravatar.cc/200?img=15";

    setVal("avatar", next);
  }

  Future<bool> _onWillPop() async {
    if (!dirty) return true;

    final discard = await _confirmDiscard();
    return discard == true;
  }

  Future<bool?> _confirmDiscard() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ConfirmSheet(
        T: T,
        title: "Discard changes?",
        message: "Your unsaved edits will be lost.",
        confirmText: "Discard",
        cancelText: "Stay",
        danger: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barStyle = themeName == "dark"
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    final avatar =
        toImageProvider(form["avatar"]) ??
        const AssetImage("assets/images/images.jpg");

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: barStyle.copyWith(statusBarColor: T.background),
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: T.background,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _Header(
                      T: T,
                      title: "Edit Profile",
                      onBack: () async {
                        final ok = await _onWillPop();
                        if (ok && mounted) Navigator.of(context).maybePop();
                      },
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ).copyWith(bottom: 120),
                        child: Column(
                          children: [
                            // avatar card
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(
                                12,
                              ).copyWith(top: 16, bottom: 16),
                              decoration: BoxDecoration(
                                color: T.elevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: T.border, width: 1),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 96,
                                  height: 96,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            border: Border.all(
                                              color: const Color(0x10000000),
                                              width: 2,
                                            ),
                                            image: DecorationImage(
                                              image: avatar,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // RN code has camera button commented; keep same behaviour:
                                      // Uncomment if you want:
                                      // Positioned(
                                      //   right: -4,
                                      //   bottom: -4,
                                      //   child: InkWell(
                                      //     onTap: onPickAvatar,
                                      //     borderRadius: BorderRadius.circular(10),
                                      //     child: Container(
                                      //       width: 32,
                                      //       height: 32,
                                      //       decoration: BoxDecoration(
                                      //         color: T.primary,
                                      //         borderRadius: BorderRadius.circular(10),
                                      //       ),
                                      //       child: Icon(Icons.camera_alt, size: 16, color: T.onPrimary),
                                      //     ),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            _Section(
                              title: "Basic information",
                              T: T,
                              child: Column(
                                children: [
                                  _Field(
                                    T: T,
                                    label: "Full name",
                                    controller: nameC,
                                    icon: MdiIcons.account,
                                    error: errors["name"],
                                    textInputAction: TextInputAction.next,
                                    onChanged: (t) => setVal("name", t),
                                    textCapitalization:
                                        TextCapitalization.words,
                                  ),
                                  _Field(
                                    T: T,
                                    label: "Role",
                                    controller: roleC,
                                    icon: MdiIcons.shieldAccount,
                                    error: errors["role"],
                                    hint: "Admin / Manager / Owner",

                                    readOnly: true,
                                    enabled: true,
                                    onTap: () =>
                                        FocusScope.of(context).unfocus(),
                                    onChanged: (_) {},
                                  ),

                                  _Field(
                                    T: T,
                                    label: "Organization",
                                    controller: orgC,
                                    icon: MdiIcons.officeBuildingOutline,
                                    hint: "Company / Team",
                                    last: true,
                                    onChanged: (t) => setVal("org", t),
                                  ),
                                ],
                              ),
                            ),

                            _Section(
                              title: "Contact",
                              T: T,
                              child: Column(
                                children: [
                                  _Field(
                                    T: T,
                                    label: "Email",
                                    controller: emailC,
                                    icon: MdiIcons.emailOutline,
                                    error: errors["email"],
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (t) => setVal("email", t),
                                  ),
                                  _Field(
                                    T: T,
                                    label: "Phone",
                                    controller: phoneC,
                                    icon: MdiIcons.phone,
                                    error: errors["phone"],
                                    keyboardType: TextInputType.phone,
                                    last: true,
                                    onChanged: (t) => setVal("phone", t),
                                  ),
                                ],
                              ),
                            ),

                            _Section(
                              title: "About",
                              T: T,
                              child: Column(
                                children: [
                                  _FieldMultiline(
                                    T: T,
                                    label: "Bio / About",
                                    controller: aboutC,
                                    icon: MdiIcons.textBoxOutline,
                                    hint:
                                        "Write a short bio that helps tenants and partners know you better.",
                                    numberOfLines: 4,
                                    last: true,
                                    onChanged: (t) => setVal("about", t),
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

                // sticky bottom bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: T.elevated,
                      border: Border(
                        top: BorderSide(color: T.border, width: 1),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: dirty ? T.warning : T.success,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dirty ? "Unsaved changes" : "All changes saved",
                              style: TextStyle(
                                color: T.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: canSave ? onSave : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: canSave ? T.primary : T.disabled,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  saving
                                      ? MdiIcons.loading
                                      : MdiIcons.contentSave,
                                  size: 16,
                                  color: T.onPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  saving ? "Saving…" : "Save",
                                  style: TextStyle(
                                    color: T.onPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
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
        ),
      ),
    );
  }
}

// ---------------- Widgets ----------------

class _Header extends StatelessWidget {
  const _Header({required this.T, required this.title, required this.onBack});

  final Tokens T;
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: T.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(MdiIcons.arrowLeft, size: 20, color: T.onPrimary),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: T.onBackground,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.T, required this.child});

  final String title;
  final Tokens T;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: T.onBackground,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: T.elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: T.border, width: 1),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.T,
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.error,
    this.last = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    required this.onChanged,

    // ✅ add these
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
  });

  final Tokens T;
  final String label;
  final TextEditingController controller;
  final IconData icon;

  final String? hint;
  final String? error;
  final bool last;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  final ValueChanged<String> onChanged;

  // ✅ new
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: last ? Colors.transparent : T.border,
            width: last ? 0 : 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: T.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: T.onBackground),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: T.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TextField(
                        controller: controller,
                        onChanged: enabled ? onChanged : null,
                        onTap: onTap,
                        enabled: enabled,
                        readOnly: readOnly,
                        keyboardType: keyboardType,
                        textInputAction: textInputAction,
                        textCapitalization: textCapitalization,
                        style: TextStyle(
                          color: enabled ? T.onBackground : T.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: hint,
                          hintStyle: TextStyle(
                            color: T.muted,
                            fontWeight: FontWeight.w600,
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if ((error ?? "").isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 56, right: 10, bottom: 8),
              child: Text(
                error!,
                style: TextStyle(
                  color: T.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FieldMultiline extends StatelessWidget {
  const _FieldMultiline({
    required this.T,
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.numberOfLines = 4,
    this.last = false,
    required this.onChanged,
  });

  final Tokens T;
  final String label;
  final TextEditingController controller;
  final IconData icon;

  final String? hint;
  final int numberOfLines;
  final bool last;

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: last ? Colors.transparent : T.border,
            width: last ? 0 : 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: T.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: T.onBackground),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: T.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: controller,
                    onChanged: onChanged,
                    maxLines: numberOfLines,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(
                      color: T.onBackground,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: T.muted,
                        fontWeight: FontWeight.w600,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- ConfirmSheet (for beforeRemove like RN) ----------------

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.T,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.danger,
  });

  final Tokens T;
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: T.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: T.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: T.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: T.border),
              ),
              child: Icon(
                MdiIcons.alertCircleOutline,
                color: danger ? T.error : T.warning,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: T.onBackground,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: T.muted,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: T.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: T.border),
                      ),
                      child: Center(
                        child: Text(
                          cancelText,
                          style: TextStyle(
                            color: T.onBackground,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: danger ? T.error : T.warning,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          confirmText,
                          style: TextStyle(
                            color: T.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
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
}
