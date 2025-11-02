// lib/screens/admin_mode_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';
import '../utils/role_helper.dart';
import 'admin_dashboard_screen.dart';
import 'admin_user_detail_screen.dart';

class AdminModeScreen extends StatefulWidget {
  const AdminModeScreen({super.key});

  @override
  State<AdminModeScreen> createState() => _AdminModeScreenState();
}

class _AdminModeScreenState extends State<AdminModeScreen> {
  final _svc = FirestoreService();
  final _search = TextEditingController();

  String _query = '';
  bool _normalizing = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> _userStream() {
    if (_query.isEmpty) return _svc.getAllUsersStream();
    return _svc.searchUsersByEmailPrefix(_query);
  }

  Future<void> _normalize() async {
    if (_normalizing) return;
    setState(() => _normalizing = true);
    try {
      final count = await _svc.normalizeUserDocs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปเดตข้อมูลมาตรฐาน $count ผู้ใช้')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Normalize ล้มเหลว: $e')));
    } finally {
      if (mounted) setState(() => _normalizing = false);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: fetchCurrentUserRole(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.data != 'admin') {
          return const Scaffold(
            body: Center(child: Text('คุณไม่มีสิทธิ์เข้าสู่โหมดแอดมิน')),
          );
        }

        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text('โหมดแอดมิน'),
            actions: [
              IconButton(
                tooltip: 'รีเฟรช',
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'เครื่องมือผู้ดูแล',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),

              // Tools row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ToolCard(
                          icon: Icons.dashboard_customize_outlined,
                          title: 'Admin Dashboard',
                          subtitle: 'ดูสถิติรวม, Top users',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminDashboardScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ToolCard(
                          icon: Icons.auto_fix_high_outlined,
                          title: 'Normalize Users',
                          subtitle:
                              _normalizing
                                  ? 'กำลังซ่อมแซมฟิลด์...'
                                  : 'ซ่อมแซมฟิลด์มาตรฐาน',
                          trailing:
                              _normalizing
                                  ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : null,
                          onTap: _normalize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'ค้นหาอีเมล...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              // Users list
              SliverFillRemaining(
                hasScrollBody: true,
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _userStream(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return const Center(
                        child: Text('โหลดรายชื่อผู้ใช้ไม่ได้'),
                      );
                    }
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(child: Text('ไม่พบผู้ใช้'));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final d = docs[i];
                        final data = d.data();
                        final uid = d.id;
                        final email = (data['email'] as String?) ?? '-';
                        final role = (data['role'] as String?) ?? 'user';
                        final calcCount = (data['calcCount'] as int?) ?? 0;

                        return Material(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => AdminUserDetailScreen(
                                        userId: uid,
                                        userEmail: email,
                                      ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: scheme.surfaceVariant,
                                    child: Text(
                                      (email.isNotEmpty ? email[0] : '?')
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          email,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyLarge,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            _Chip(
                                              text: 'role: $role',
                                              color:
                                                  role == 'admin'
                                                      ? scheme.primaryContainer
                                                      : scheme.surfaceVariant,
                                              fg:
                                                  role == 'admin'
                                                      ? scheme
                                                          .onPrimaryContainer
                                                      : null,
                                            ),
                                            const SizedBox(width: 8),
                                            _Chip(
                                              text: 'calcCount: $calcCount',
                                              color: scheme.surfaceVariant,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? fg;
  const _Chip({required this.text, this.color, this.fg});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg ?? scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
