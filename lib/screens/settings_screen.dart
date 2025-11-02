// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';
import 'scanner_screen.dart';
import 'history_screen.dart';
import 'admin_mode_screen.dart';
import '../utils/role_helper.dart';
import 'profile_overview_screen.dart';
import 'cable_enter_screen.dart';

class SettingsScreen extends StatelessWidget {
  final bool embedded; // ✅ เพิ่ม
  const SettingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final displayName = (user?.displayName ?? '').trim();
    final primaryText =
        displayName.isNotEmpty
            ? displayName
            : (user?.email ?? '.....................');

    // ✅ เนื้อหาแยกเป็นตัวแปร
    final body = ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileOverviewScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: cs.primary.withOpacity(.15),
                  child: Icon(Icons.person, size: 34, color: cs.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ดูโปรไฟล์',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 24, color: cs.onSurface.withOpacity(.12)),
        _item(
          context,
          icon: Icons.person_outline,
          title: 'โปรไฟล์ของฉัน',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileOverviewScreen()),
            );
          },
        ),
        _item(
          context,
          icon: Icons.history,
          title: 'ดูประวัติ (ของฉัน)',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
          },
        ),
        _item(
          context,
          icon: Icons.qr_code_scanner,
          title: 'สแกน',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScannerScreen()),
            );
          },
        ),
        _item(
          context,
          icon: Icons.straighten_rounded,
          title: 'จัดการสาย/วัดระยะ (GPS)',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CableEnterScreen()),
            );
          },
        ),
        _item(
          context,
          icon: Icons.help_outline,
          title: 'ศูนย์ช่วยเหลือ',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('หน้าศูนย์ช่วยเหลือ (เร็ว ๆ นี้)')),
            );
          },
        ),
        FutureBuilder<String?>(
          future: fetchCurrentUserRole(),
          builder: (context, snap) {
            final role = snap.data;
            if (role != 'admin') return const SizedBox.shrink();
            return _item(
              context,
              icon: Icons.admin_panel_settings_outlined,
              title: 'เข้าสู่โหมดแอดมิน',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminModeScreen()),
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('ออกจากระบบ'),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: cs.onSurface,
              side: BorderSide(color: cs.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );

    // ✅ โหมด embedded → ไม่สร้าง AppBar ซ้ำ
    if (embedded) return body;

    // ใช้เดี่ยว ๆ → มี AppBar
    return Scaffold(appBar: AppBar(title: const Text('โปรไฟล์')), body: body);
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 1,
        surfaceTintColor: cs.surface,
        shadowColor: cs.onSurface.withOpacity(.08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cs.outlineVariant, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: ListTile(
              leading: Icon(icon, color: cs.onSurface.withOpacity(.85)),
              title: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withOpacity(.6),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
