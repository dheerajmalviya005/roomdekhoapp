import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:material_design_icons_flutter/material_design_icons_flutter.dart";

import "../../services/support_service.dart";

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
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
      final d = await SupportService.getPublicFaq(); // ✅ /faq/public
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

  List _safeList(dynamic v) => (v is List) ? v : const [];

  String _safeStr(dynamic v) => (v ?? "").toString();

  IconData _categoryIcon(String title) {
    final t = title.toLowerCase().trim();
    if (t.contains("general")) return MdiIcons.helpCircleOutline;
    if (t.contains("listing")) return MdiIcons.homeOutline;
    if (t.contains("payment")) return MdiIcons.creditCardOutline;
    if (t.contains("account")) return MdiIcons.accountOutline;
    return MdiIcons.folderOutline;
  }

  Color _categoryTint(String title) {
    final t = title.toLowerCase().trim();
    if (t.contains("general")) return const Color(0xFF667EEA);
    if (t.contains("listing")) return const Color(0xFF10B981);
    if (t.contains("payment")) return const Color(0xFF3B82F6);
    return const Color(0xFF0EA5E9);
  }

  @override
  Widget build(BuildContext context) {
    final data = _data ?? {};
    final updatedAt = _safeStr(data["updated_at"]);
    final categories = _safeList(data["categories"]);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.white),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          centerTitle: true,
          title: const Text(
            "FAQ",
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: _loading
            ? const _FaqSkeleton()
            : (_err.isNotEmpty
                  ? _ErrorState(message: _err, onRetry: _load)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      children: [
                        _TopInfo(updatedAt: updatedAt),
                        const SizedBox(height: 12),

                        const Text(
                          "Categories",
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),

                        ...categories.map((c) {
                          final cat = _safeMap(c);
                          final title = _safeStr(cat["title"]);
                          final items = _safeList(cat["items"]);

                          // ✅ sort by sort_order
                          final sortedItems =
                              items.map((x) => _safeMap(x)).toList()..sort((
                                a,
                                b,
                              ) {
                                final sa = (a["sort_order"] is int)
                                    ? a["sort_order"] as int
                                    : int.tryParse(_safeStr(a["sort_order"])) ??
                                          999999;
                                final sb = (b["sort_order"] is int)
                                    ? b["sort_order"] as int
                                    : int.tryParse(_safeStr(b["sort_order"])) ??
                                          999999;
                                return sa.compareTo(sb);
                              });

                          final tint = _categoryTint(title);
                          final icon = _categoryIcon(title);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CategoryCard(
                              title: title,
                              icon: icon,
                              tint: tint,
                              items: sortedItems,
                            ),
                          );
                        }),
                      ],
                    )),
      ),
    );
  }
}

/* ---------------- Top Info ---------------- */

class _TopInfo extends StatelessWidget {
  const _TopInfo({required this.updatedAt});
  final String updatedAt;

  String _formatDate(String iso) {
    final s = iso.trim();
    if (s.isEmpty) return "-";
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ), // ✅ compact
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Icon(
              MdiIcons.frequentlyAskedQuestions,
              color: const Color(0xFF0EA5E9),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Help & FAQs",
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Updated: ${_formatDate(updatedAt)}",
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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

/* ---------------- Category Card ---------------- */

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.tint,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color tint;
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ), // ✅ compact
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Icon(icon, color: tint, size: 22),
          ),
          title: Text(
            title.isEmpty ? "Category" : title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            "${items.length} questions",
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          trailing: Icon(MdiIcons.chevronDown, color: const Color(0xFF94A3B8)),
          children: [
            ...items.map((it) {
              final q = (it["q"] ?? "").toString();
              final a = (it["a"] ?? "").toString();
              return _FaqAccordionItem(question: q, answer: a);
            }),
          ],
        ),
      ),
    );
  }
}

/* ---------------- FAQ Item ---------------- */

class _FaqAccordionItem extends StatelessWidget {
  const _FaqAccordionItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8), // ✅ compact
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ), // ✅ compact
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Icon(
            MdiIcons.helpCircleOutline,
            color: const Color(0xFF0EA5E9),
            size: 20,
          ),
          title: Text(
            question.isEmpty ? "Question" : question,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 13,
              height: 1.2,
            ),
          ),
          trailing: Icon(MdiIcons.plus, color: const Color(0xFF94A3B8)),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer.isEmpty ? "-" : answer,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- Loading + Error ---------------- */

class _FaqSkeleton extends StatelessWidget {
  const _FaqSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: const [
        _SkelBox(h: 72),
        SizedBox(height: 12),
        _SkelLine(w: 120),
        SizedBox(height: 10),
        _SkelBox(h: 78),
        SizedBox(height: 12),
        _SkelBox(h: 78),
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
        color: Color(0xFFF1F5F9),
        borderRadius: BorderRadius.all(Radius.circular(14)),
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
        color: Color(0xFFF1F5F9),
        borderRadius: BorderRadius.all(Radius.circular(10)),
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
              color: Color(0xFFEF4444),
              size: 28,
            ),
            const SizedBox(height: 10),
            const Text(
              "Failed to load FAQs",
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
