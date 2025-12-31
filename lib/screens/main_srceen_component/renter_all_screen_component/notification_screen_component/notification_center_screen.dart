import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/* ---------------- Responsive helpers ---------------- */
class R {
  final Size s;
  R(this.s);

  double scale(double v) => (s.width / 375) * v;
  double vScale(double v) => (s.height / 812) * v;
  double ms(double v) => v + (scale(v) - v) * .4;
}

/* ---------------- Data model ---------------- */
class NotificationItem {
  final String id;
  final String type; // ticket, payment, task, chat, alert...
  final String title;
  final String body;
  final DateTime at;
  bool unread;
  bool pinned;
  final String actor;
  final String badge;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.at,
    required this.unread,
    required this.pinned,
    required this.actor,
    required this.badge,
  });
}

/* ---------------- Utils ---------------- */
IconData iconByType(String t) {
  switch (t) {
    case 'ticket':
      return MdiIcons.lifebuoy;
    case 'payment':
      return MdiIcons.cashMultiple;
    case 'task':
      return MdiIcons.checkCircleOutline;
    case 'chat':
      return MdiIcons.messageTextOutline;
    case 'alert':
      return MdiIcons.alertDecagramOutline;
    default:
      return MdiIcons.bellOutline;
  }
}

Color tintByType(String t) {
  switch (t) {
    case 'ticket':
      return const Color(0xFF7C3AED); // purple
    case 'payment':
      return const Color(0xFF16A34A); // green
    case 'task':
      return const Color(0xFF2563EB); // blue
    case 'chat':
      return const Color(0xFF0EA5E9); // sky
    case 'alert':
      return const Color(0xFFEF4444); // red
    default:
      return const Color(0xFF111827); // slate
  }
}

bool isToday(DateTime d) {
  final n = DateTime.now();
  return d.year == n.year && d.month == n.month && d.day == n.day;
}

bool isYesterday(DateTime d) {
  final y = DateTime.now().subtract(const Duration(days: 1));
  return d.year == y.year && d.month == y.month && d.day == y.day;
}

String fmtTime(DateTime d) {
  final h = d.hour;
  final m = d.minute.toString().padLeft(2, '0');
  final ap = h >= 12 ? 'PM' : 'AM';
  final hh = h % 12 == 0 ? 12 : h % 12;
  return '$hh:$m $ap';
}

/* ---------------- Screen ---------------- */
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  late R r;

  String query = '';
  String tab = 'all'; // all, unread, tickets
  bool selectMode = false;
  final Set<String> selected = {};

  late List<NotificationItem> list;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    list = [
      NotificationItem(
        id: 'n1',
        type: 'ticket',
        title: 'New ticket assigned',
        body: 'Refund request • TKT-09218',
        at: now.subtract(const Duration(minutes: 2)),
        unread: true,
        pinned: true,
        actor: 'Support Bot',
        badge: 'High',
      ),
      NotificationItem(
        id: 'n2',
        type: 'payment',
        title: 'Payout processed',
        body: 'UL → LL-29811 • ₹38,500',
        at: now.subtract(const Duration(minutes: 9)),
        unread: false,
        pinned: false,
        actor: 'Finance',
        badge: 'Payout',
      ),
      NotificationItem(
        id: 'n3',
        type: 'chat',
        title: 'New message',
        body: '“Can we schedule a visit?”',
        at: now.subtract(const Duration(hours: 3)),
        unread: true,
        pinned: false,
        actor: 'Rohit',
        badge: 'Chat',
      ),
      NotificationItem(
        id: 'n4',
        type: 'alert',
        title: 'Listing expiring soon',
        body: 'Renew Riverside PG before midnight',
        at: now.subtract(const Duration(days: 1, hours: 2)),
        unread: false,
        pinned: false,
        actor: 'System',
        badge: 'Urgent',
      ),
    ];
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {});
  }

  void _exitSelectMode() {
    setState(() {
      selectMode = false;
      selected.clear();
    });
  }

  void _markAllRead() {
    setState(() {
      for (final n in list) {
        n.unread = false;
      }
    });
  }

  void _bulkMarkRead(bool unread) {
    setState(() {
      for (final id in selected) {
        final n = list.firstWhere((x) => x.id == id);
        n.unread = unread;
      }
      _exitSelectMode();
    });
  }

  void _bulkPin(bool pin) {
    setState(() {
      for (final id in selected) {
        final n = list.firstWhere((x) => x.id == id);
        n.pinned = pin;
      }
      _exitSelectMode();
    });
  }

  void _bulkDelete() {
    setState(() {
      list.removeWhere((n) => selected.contains(n.id));
      _exitSelectMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    r = R(MediaQuery.of(context).size);

    final filtered =
        list.where((n) {
          if (query.isNotEmpty &&
              !('${n.title} ${n.body} ${n.actor} ${n.badge}'
                  .toLowerCase()
                  .contains(query.toLowerCase()))) {
            return false;
          }
          if (tab == 'unread' && !n.unread) return false;
          if (tab == 'tickets' && n.type != 'ticket') return false;
          return true;
        }).toList()..sort((a, b) {
          if (a.pinned != b.pinned) return b.pinned ? 1 : -1;
          return b.at.compareTo(a.at);
        });

    final today = filtered.where((n) => isToday(n.at)).toList();
    final yday = filtered.where((n) => isYesterday(n.at)).toList();
    final earlier = filtered
        .where((n) => !isToday(n.at) && !isYesterday(n.at))
        .toList();

    final unreadCount = list.where((x) => x.unread).length;
    final ticketCount = list.where((x) => x.type == 'ticket').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F8FC),
        scrolledUnderElevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!selectMode)
            IconButton(
              tooltip: 'Mark all read',
              icon: const Icon(Icons.done_all, color: Color(0xFF111827)),
              onPressed: _markAllRead,
            ),
          IconButton(
            tooltip: selectMode ? 'Exit select' : 'Select',
            icon: Icon(
              selectMode ? Icons.close : Icons.select_all,
              color: const Color(0xFF111827),
            ),
            onPressed: () {
              setState(() {
                selectMode = !selectMode;
                selected.clear();
              });
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _searchBar(),
              _chips(unreadCount: unreadCount, ticketCount: ticketCount),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: EdgeInsets.all(r.scale(16)),
                    children: [
                      if (today.isNotEmpty) _section('Today', today),
                      if (yday.isNotEmpty) _section('Yesterday', yday),
                      if (earlier.isNotEmpty) _section('Earlier', earlier),
                      if (filtered.isEmpty) _emptyState(),
                      SizedBox(height: selectMode ? r.vScale(90) : 12),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom bulk actions (only in select mode)
          if (selectMode) _bulkBar(),
        ],
      ),
    );
  }

  Widget _section(String title, List<NotificationItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: r.scale(2), bottom: r.vScale(8)),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: r.ms(13),
              color: const Color(0xFF111827),
            ),
          ),
        ),
        ...items.map(_row),
        SizedBox(height: r.vScale(12)),
      ],
    );
  }

  Widget _row(NotificationItem item) {
    final isSel = selected.contains(item.id);
    final tint = tintByType(item.type);

    return Padding(
      padding: EdgeInsets.only(bottom: r.vScale(10)),
      child: Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.horizontal,
        background: _swipeLeftBg(item), // left → right
        secondaryBackground: _swipeRightBg(item), // right → left
        confirmDismiss: (dir) async {
          // left → right : toggle read
          if (dir == DismissDirection.startToEnd) {
            setState(() => item.unread = !item.unread);
            return false;
          }
          // right → left : delete (confirm)
          if (dir == DismissDirection.endToStart) {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Delete notification?'),
                content: const Text('This action cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            return ok == true;
          }
          return false;
        },
        onDismissed: (dir) {
          if (dir == DismissDirection.endToStart) {
            setState(() => list.removeWhere((x) => x.id == item.id));
          }
        },
        child: GestureDetector(
          onLongPress: () {
            setState(() {
              selectMode = true;
              selected.add(item.id);
            });
          },
          onTap: () {
            setState(() {
              if (selectMode) {
                isSel ? selected.remove(item.id) : selected.add(item.id);
              } else {
                item.unread = false; // open => mark read
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.all(r.scale(12)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(r.scale(16)),
              border: Border.all(
                color: isSel ? tint.withOpacity(0.35) : const Color(0xFFE5E7EB),
                width: isSel ? 1.2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: r.scale(16),
                  offset: Offset(0, r.vScale(10)),
                ),
              ],
            ),
            child: Row(
              children: [
                // icon tile
                Container(
                  width: r.scale(42),
                  height: r.scale(42),
                  decoration: BoxDecoration(
                    color: tint.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(r.scale(14)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        selectMode
                            ? (isSel
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked)
                            : iconByType(item.type),
                        size: r.ms(20),
                        color: selectMode
                            ? (isSel ? tint : const Color(0xFF9CA3AF))
                            : tint,
                      ),
                      if (item.unread && !selectMode)
                        Positioned(
                          right: r.scale(8),
                          top: r.scale(8),
                          child: Container(
                            width: r.scale(8),
                            height: r.scale(8),
                            decoration: BoxDecoration(
                              color: tint,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(width: r.scale(12)),

                // content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // title + pin
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: item.unread
                                    ? FontWeight.w900
                                    : FontWeight.w800,
                                fontSize: r.ms(13.5),
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ),
                          if (item.pinned)
                            Icon(Icons.push_pin, size: r.ms(14), color: tint),
                        ],
                      ),
                      SizedBox(height: r.vScale(2)),
                      Text(
                        item.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF6B7280),
                          fontSize: r.ms(11.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: r.vScale(8)),

                      // badge row
                      Row(
                        children: [
                          _MiniBadge(r: r, text: item.badge, tint: tint),
                          SizedBox(width: r.scale(8)),
                          Expanded(
                            child: Text(
                              '${item.actor} • ${fmtTime(item.at)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: r.ms(11),
                                color: const Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: r.scale(6)),

                // quick actions (pin)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => item.pinned = !item.pinned),
                  icon: Icon(
                    item.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: item.pinned ? tint : const Color(0xFF9CA3AF),
                    size: r.ms(18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _swipeLeftBg(NotificationItem item) {
    final tint = tintByType(item.type);
    return Container(
      decoration: BoxDecoration(
        color: tint.withOpacity(0.10),
        borderRadius: BorderRadius.circular(r.scale(16)),
      ),
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: r.scale(18)),
      child: Row(
        children: [
          Icon(
            item.unread ? Icons.mark_email_read : Icons.mark_email_unread,
            color: tint,
          ),
          SizedBox(width: r.scale(8)),
          Text(
            item.unread ? 'Mark read' : 'Mark unread',
            style: TextStyle(fontWeight: FontWeight.w900, color: tint),
          ),
        ],
      ),
    );
  }

  Widget _swipeRightBg(NotificationItem item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF2),
        borderRadius: BorderRadius.circular(r.scale(16)),
      ),
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: r.scale(18)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'Delete',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFFEF4444),
            ),
          ),
          SizedBox(width: r.scale(8)),
          const Icon(Icons.delete, color: Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: r.vScale(40)),
      child: Column(
        children: const [
          Icon(Icons.notifications_off, size: 54, color: Color(0xFF9CA3AF)),
          SizedBox(height: 10),
          Text(
            'Nothing here yet',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'We’ll notify you when something arrives.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() => Padding(
    padding: EdgeInsets.fromLTRB(r.scale(16), 6, r.scale(16), 10),
    child: TextField(
      onChanged: (v) => setState(() => query = v),
      decoration: InputDecoration(
        hintText: 'Search notifications…',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding: EdgeInsets.symmetric(
          horizontal: r.scale(12),
          vertical: r.vScale(12),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget _chips({required int unreadCount, required int ticketCount}) =>
      Padding(
        padding: EdgeInsets.fromLTRB(r.scale(16), 0, r.scale(16), 10),
        child: Row(
          children: [
            _chip('all', 'All', null),
            const SizedBox(width: 8),
            _chip('unread', 'Unread', unreadCount),
            const SizedBox(width: 8),
            _chip('tickets', 'Tickets', ticketCount),
          ],
        ),
      );

  Widget _chip(String id, String label, int? count) {
    final active = tab == id;
    return ChoiceChip(
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: active ? Colors.white : const Color(0xFF111827),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withOpacity(0.22)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: active ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ),
          ],
        ],
      ),
      selected: active,
      selectedColor: const Color(0xFF111827),
      backgroundColor: const Color(0xFFF3F4F6),
      onSelected: (_) => setState(() => tab = id),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

  Widget _bulkBar() {
    final count = selected.length;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.all(r.scale(14)),
        padding: EdgeInsets.symmetric(
          horizontal: r.scale(12),
          vertical: r.vScale(10),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: r.scale(24),
              offset: Offset(0, r.vScale(14)),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Text(
                '$count selected',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: r.ms(12.5),
                ),
              ),
              const Spacer(),
              _bulkBtn(
                icon: Icons.mark_email_read,
                label: 'Read',
                onTap: () => _bulkMarkRead(false),
              ),
              const SizedBox(width: 10),
              _bulkBtn(
                icon: Icons.push_pin,
                label: 'Pin',
                onTap: () => _bulkPin(true),
              ),
              const SizedBox(width: 10),
              _bulkBtn(
                icon: Icons.delete,
                label: 'Delete',
                danger: true,
                onTap: _bulkDelete,
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: _exitSelectMode,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bulkBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final c = danger ? const Color(0xFFEF4444) : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: r.scale(8), vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: c, size: r.ms(16)),
            SizedBox(width: r.scale(6)),
            Text(
              label,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.w900,
                fontSize: r.ms(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- Mini badge ---------------- */
class _MiniBadge extends StatelessWidget {
  final R r;
  final String text;
  final Color tint;

  const _MiniBadge({required this.r, required this.text, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.scale(10), vertical: 4),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withOpacity(0.20)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: r.ms(10.5),
          fontWeight: FontWeight.w900,
          color: tint,
        ),
      ),
    );
  }
}
