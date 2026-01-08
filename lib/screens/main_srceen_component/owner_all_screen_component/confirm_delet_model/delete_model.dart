import "package:flutter/material.dart";
import "package:material_design_icons_flutter/material_design_icons_flutter.dart";

/// ✅ Same-to-same ConfirmModal (React Native -> Flutter)
/// Usage:
/// ConfirmModal.show(
///   context,
///   title: "Are you sure?",
///   subtitle: "This action can't be undone.",
///   confirmText: "Confirm",
///   cancelText: "Cancel",
///   danger: true,
///   onConfirm: () { ... },
/// );

class ConfirmModal {
  static Future<void> show(
    BuildContext context, {
    String title = "Are you sure?",
    String subtitle = "",
    String confirmText = "Confirm",
    String cancelText = "Cancel",
    bool danger = false,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierLabel: "confirm_modal",
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.45), // RN overlay feel
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, a1, a2) {
        return _ConfirmModalWidget(
          title: title,
          subtitle: subtitle,
          confirmText: confirmText,
          cancelText: cancelText,
          danger: danger,
          onConfirm: onConfirm,
          onCancel: onCancel,
        );
      },
      transitionBuilder: (context, anim, secAnim, child) {
        // RN: fade + spring scale
        final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        final scale = Tween<double>(
          begin: 0.92,
          end: 1.0,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack));
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }
}

class _ConfirmModalWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String confirmText;
  final String cancelText;
  final bool danger;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const _ConfirmModalWidget({
    required this.title,
    required this.subtitle,
    required this.confirmText,
    required this.cancelText,
    required this.danger,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final c = _Tokens.of(context, danger: danger);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // backdrop tap
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                onCancel?.call();
              },
              child: const SizedBox(),
            ),
          ),

          // centered card
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.88,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.elevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // header row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c.iconBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            danger
                                ? MdiIcons.trashCanOutline
                                : MdiIcons.informationOutline,
                            size: 20,
                            color: c.iconColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: c.onBackground,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: c.muted,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Cancel (ghost)
                        _GhostButton(
                          text: cancelText,
                          borderColor: c.border,
                          bg: c.surface,
                          fg: c.onBackground,
                          onTap: () {
                            Navigator.of(context).pop();
                            onCancel?.call();
                          },
                        ),
                        const SizedBox(width: 8),

                        // Confirm (solid)
                        _SolidButton(
                          text: confirmText,
                          bg: danger ? c.error : c.primary,
                          fg: danger ? c.onError : c.onPrimary,
                          icon: danger
                              ? MdiIcons.deleteOutline
                              : MdiIcons.check,
                          onTap: () {
                            Navigator.of(context).pop();
                            onConfirm?.call();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- Buttons (same sizes as RN) ---------------- */

class _GhostButton extends StatelessWidget {
  final String text;
  final Color borderColor;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _GhostButton({
    required this.text,
    required this.borderColor,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _SolidButton extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final IconData icon;
  final VoidCallback onTap;

  const _SolidButton({
    required this.text,
    required this.bg,
    required this.fg,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- Tokens (replace with your theme later) ---------------- */
class _Tokens {
  final Color overlay;
  final Color elevated;
  final Color border;
  final Color surface;
  final Color onBackground;
  final Color muted;

  final Color primary;
  final Color onPrimary;

  final Color error;
  final Color onError;

  final Color info;
  final Color iconColor;
  final Color iconBg;

  _Tokens({
    required this.overlay,
    required this.elevated,
    required this.border,
    required this.surface,
    required this.onBackground,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.error,
    required this.onError,
    required this.info,
    required this.iconColor,
    required this.iconBg,
  });

  static _Tokens of(BuildContext context, {required bool danger}) {
    // ✅ default colors matching your RN intention
    final overlay = Colors.black.withOpacity(0.45);

    final elevated = Colors.white; // modal card
    final surface = const Color(0xFFF8F9FA);
    final border = const Color(0xFFE5E7EB);

    final onBackground = const Color(0xFF111827);
    final muted = const Color(0xFF6B7280);

    final primary = const Color(0xFF667EEA);
    final onPrimary = Colors.white;

    final error = const Color(0xFFEF4444);
    final onError = Colors.white;

    final info = const Color(0xFF3B82F6);

    final iconColor = danger ? error : info;
    final iconBg = (danger ? error : info).withOpacity(0.10); // + "1A" 느낌

    return _Tokens(
      overlay: overlay,
      elevated: elevated,
      surface: surface,
      border: border,
      onBackground: onBackground,
      muted: muted,
      primary: primary,
      onPrimary: onPrimary,
      error: error,
      onError: onError,
      info: info,
      iconColor: iconColor,
      iconBg: iconBg,
    );
  }
}
