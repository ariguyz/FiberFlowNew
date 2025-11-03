import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// หน้าที่มีอยู่แล้วในโปรเจกต์
import 'profile_overview_screen.dart';
import 'scanner_screen.dart';
import 'cable_enter_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart'; // หน้าเครื่องมือคำนวณเดิมของคุณ

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    final items = <_HubItem>[
      _HubItem(
        icon: Icons.calculate_outlined,
        label: 'คำนวณคอร์',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
      ),
      _HubItem(
        icon: Icons.qr_code_scanner,
        label: 'สแกน',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScannerScreen()),
            ),
      ),
      _HubItem(
        icon: Icons.straighten_rounded,
        label: 'GPS/จัดการสาย',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CableEnterScreen()),
            ),
      ),
      _HubItem(
        icon: Icons.history,
        label: 'ประวัติของฉัน',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
      ),
      // เพิ่มปุ่มอื่น ๆ ตรงนี้ได้ตามต้องการ
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ส่วนหัว: โลโก้กลาง + ปุ่มโปรไฟล์ขวาบน
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Image.asset(
                            'assets/images/logofiberflow.png',
                            height: 72,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'FiberFlow',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'เมนูหลัก',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        tooltip: 'โปรไฟล์ของฉัน',
                        iconSize: 32,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileOverviewScreen(),
                            ),
                          );
                        },
                        icon: CircleAvatar(
                          radius: 16,
                          backgroundColor: cs.primary.withOpacity(.15),
                          child: const Icon(Icons.person, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // กริดเมนู
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _HubCard(item: items[i]),
                  childCount: items.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _HubItem({required this.icon, required this.label, required this.onTap});
}

class _HubCard extends StatelessWidget {
  const _HubCard({required this.item});
  final _HubItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: item.onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: cs.primary),
              ),
              const Spacer(),
              Text(
                item.label,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
