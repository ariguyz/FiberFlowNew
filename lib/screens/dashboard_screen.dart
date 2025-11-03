// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../utils/role_helper.dart';
import '../utils/theme_notifier.dart';

import 'scanner_screen.dart';
import 'cable_enter_screen.dart';
import 'profile_overview_screen.dart';
import 'admin_mode_screen.dart';
import 'find_colorcode_hub_screen.dart';
import 'tia598_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    FirestoreService().ensureUserDoc();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      // AppBar แบบ “โล่ง” ให้พื้นที่กับโลโก้ด้านบนของ body
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const SizedBox.shrink(), // ← ไม่ใส่โลโก้ใน AppBar แล้ว
        actions: [
          IconButton(
            tooltip: 'สลับธีม',
            icon: Icon(
              themeNotifier.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () => themeNotifier.toggleTheme(),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileOverviewScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: cs.primary.withOpacity(.18),
                backgroundImage:
                    (user?.photoURL?.isNotEmpty ?? false)
                        ? NetworkImage(user!.photoURL!)
                        : null,
                child:
                    (user?.photoURL?.isEmpty ?? true)
                        ? Icon(Icons.person, size: 20, color: cs.primary)
                        : null,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: cs.outlineVariant),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ===== โลโก้กึ่งกลางแบบเดียวกับหน้า TIA =====
                  const _BrandHeader(),
                  const SizedBox(height: 16),

                  // ===== รายการปุ่มหลัก =====
                  _HubBigButton(
                    icon: Icons.library_books_outlined,
                    label: 'TIA-598-C Standard',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Tia598Screen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  _HubBigButton(
                    icon: Icons.palette_outlined,
                    label: 'Find ColorCode',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FindColorCodeHubScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  _HubBigButton(
                    icon: Icons.straighten_rounded,
                    label: 'จัดการสาย / วัดระยะ (GPS)',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CableEnterScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  _HubBigButton(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan QR',
                    onTap: () async {
                      final code = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScannerScreen(),
                        ),
                      );
                      if (!mounted) return;
                      if (code != null && code.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('สแกนได้: $code')),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 22),

                  FutureBuilder<String?>(
                    future: fetchCurrentUserRole(),
                    builder: (context, snap) {
                      if (snap.data == 'admin') {
                        return Column(
                          children: [
                            _HubBigButton(
                              icon: Icons.admin_panel_settings_outlined,
                              label: 'โหมดแอดมิน',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AdminModeScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  _HubBigButton(
                    danger: true,
                    icon: Icons.exit_to_app_rounded,
                    label: 'Exit',
                    onTap: () => SystemNavigator.pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// โลโก้กึ่งกลาง + ข้อความ “FiberFlow” (เหมือนหน้า TIA)
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Image.asset('assets/images/logofiberflow.png', height: 64),
        const SizedBox(height: 6),
        Text(
          'FiberFlow',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// ปุ่มใหญ่แนวตั้ง
class _HubBigButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _HubBigButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: (danger ? cs.error : cs.primary).withOpacity(
                  .15,
                ),
                child: Icon(icon, color: danger ? cs.error : cs.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: danger ? cs.error : cs.onSurface,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
