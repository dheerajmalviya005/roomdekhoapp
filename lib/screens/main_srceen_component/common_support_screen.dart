import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:material_design_icons_flutter/material_design_icons_flutter.dart";
import "package:url_launcher/url_launcher.dart";
import "package:go_router/go_router.dart";

import "../../services/support_service.dart"; // ✅ make sure this path is correct

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  // ✅ ACTIONS MUST BE INSIDE CLASS (static)
  static Future<void> openUrl(BuildContext context, String url) async {
    final u = url.trim();
    if (u.isEmpty) return _toast(context, "Link not available");

    final uri = Uri.tryParse(u);
    if (uri == null) return _toast(context, "Invalid link");

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) _toast(context, "Could not open link");
  }

  static Future<void> openTel(BuildContext context, String phone) async {
    final p = phone.trim();
    if (p.isEmpty) return _toast(context, "Phone not available");

    final uri = Uri.parse("tel:$p");
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) _toast(context, "Could not open dialer");
  }

  static Future<void> openMail(BuildContext context, String email) async {
    final e = email.trim();
    if (e.isEmpty) return _toast(context, "Email not available");

    final uri = Uri.parse("mailto:$e");
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) _toast(context, "Could not open mail");
  }

  static Future<void> openWhatsApp(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r"[^\d]"), "");
    if (digits.isEmpty) return _toast(context, "WhatsApp number not available");

    final uri = Uri.parse("https://wa.me/$digits");
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) _toast(context, "Could not open WhatsApp");
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  bool _loading = true;
  String _err = "";

  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = "";
    });

    try {
      final d = await SupportService.getPublicSupport();
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e.toString();
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _safeMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  String _safeStr(dynamic v) => (v ?? "").toString();

  @override
  Widget build(BuildContext context) {
    final data = _data ?? {};
    final support = _safeMap(data["support"]);
    final links = _safeMap(support["links"]);

    final updatedAt = _safeStr(data["updated_at"]);
    final whatsapp = _safeStr(support["whatsapp"]);
    final call = _safeStr(support["call"]);
    final email = _safeStr(support["email"]);
    final hours = _safeStr(support["hours"]);
    final note = _safeStr(support["note"]);
    final instagram = _safeStr(links["instagram"]);
    final telegram = _safeStr(links["telegram"]);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.white),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          title: const Text(
            "Support",
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,

          actions: [
            IconButton(
              onPressed: () => context.go("/faq"),
              icon: Icon(
                MdiIcons.frequentlyAskedQuestions,
                color: const Color(0xFF0F172A),
              ),
              tooltip: "FAQ",
            ),
          ],
        ),
        body: _loading
            ? const _SupportSkeleton()
            : (_err.isNotEmpty
                  ? _ErrorState(message: _err, onRetry: _load)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TopInfo(hours: hours, updatedAt: updatedAt),
                          const SizedBox(height: 14),
                          const _SectionTitle("Quick contact"),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: _ActionCard(
                                  icon: MdiIcons.whatsapp,
                                  title: "WhatsApp",
                                  subtitle: whatsapp,
                                  tint: const Color(0xFF10B981),
                                  onTap: () => SupportScreen.openWhatsApp(
                                    context,
                                    whatsapp,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ActionCard(
                                  icon: MdiIcons.phone,
                                  title: "Call",
                                  subtitle: call,
                                  tint: const Color(0xFF3B82F6),
                                  onTap: () =>
                                      SupportScreen.openTel(context, call),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          _ActionCardWide(
                            icon: MdiIcons.emailOutline,
                            title: "Email",
                            subtitle: email,
                            tint: const Color(0xFF667EEA),
                            onTap: () => SupportScreen.openMail(context, email),
                          ),

                          const SizedBox(height: 18),
                          const _SectionTitle("Note"),
                          const SizedBox(height: 10),
                          _InfoBox(
                            icon: MdiIcons.informationOutline,
                            text: note,
                          ),

                          const SizedBox(height: 18),
                          const _SectionTitle("Social"),
                          const SizedBox(height: 10),

                          _LinkTile(
                            icon: MdiIcons.instagram,
                            title: "Instagram",
                            url: instagram,
                            onTap: () =>
                                SupportScreen.openUrl(context, instagram),
                          ),
                          const SizedBox(height: 10),
                          _LinkTile(
                            icon: MdiIcons.send,
                            title: "Telegram",
                            url: telegram,
                            onTap: () =>
                                SupportScreen.openUrl(context, telegram),
                          ),
                        ],
                      ),
                    )),
      ),
    );
  }
}

/* ---------------- UI Widgets ---------------- */

class _TopInfo extends StatelessWidget {
  const _TopInfo({required this.hours, required this.updatedAt});

  final String hours;
  final String updatedAt;

  String _formatDate(String iso) {
    final s = iso.trim();
    if (s.isEmpty) return "";
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Icon(MdiIcons.headset, color: const Color(0xFF667EEA)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "We’re here to help",
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Support hours: $hours",
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Updated: ${_formatDate(updatedAt)}",
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconBadge(icon: icon, tint: tint),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCardWide extends StatelessWidget {
  const _ActionCardWide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _IconBadge(icon: icon, tint: tint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(MdiIcons.chevronRight, color: const Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.tint});
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: tint.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Icon(icon, color: tint, size: 22),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.url,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Icon(icon, color: const Color(0xFF0EA5E9), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(MdiIcons.openInNew, color: const Color(0xFF94A3B8), size: 18),
          ],
        ),
      ),
    );
  }
}

/* ---------------- Loading + Error UI ---------------- */

class _SupportSkeleton extends StatelessWidget {
  const _SupportSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        _SkelBox(h: 86),
        const SizedBox(height: 14),
        _SkelLine(w: 140),
        const SizedBox(height: 10),
        Row(
          children: const [
            Expanded(child: _SkelBox(h: 120)),
            SizedBox(width: 10),
            Expanded(child: _SkelBox(h: 120)),
          ],
        ),
        const SizedBox(height: 10),
        _SkelBox(h: 76),
        const SizedBox(height: 18),
        _SkelLine(w: 90),
        const SizedBox(height: 10),
        _SkelBox(h: 68),
        const SizedBox(height: 18),
        _SkelLine(w: 70),
        const SizedBox(height: 10),
        _SkelBox(h: 64),
        const SizedBox(height: 10),
        _SkelBox(h: 64),
      ],
    );
  }
}

class _SkelBox extends StatelessWidget {
  const _SkelBox({required this.h});
  final double h;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
    );
  }
}

class _SkelLine extends StatelessWidget {
  const _SkelLine({required this.w});
  final double w;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              MdiIcons.alertCircleOutline,
              color: const Color(0xFFEF4444),
              size: 28,
            ),
            const SizedBox(height: 10),
            const Text(
              "Failed to load support info",
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}
