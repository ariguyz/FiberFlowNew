// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/theme_notifier.dart';
import '../services/firestore_service.dart';
import '../utils/role_helper.dart';

import 'home_screen.dart';
import 'settings_screen.dart';
import 'admin_mode_screen.dart';
import 'cable_enter_screen.dart';
import 'scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // ✅ ส่ง embedded: true ให้เพจที่อยู่ในแท็บ
  final List<Widget> _tabs = const <Widget>[
    HomeScreen(), // (ถ้า Home มี AppBar ให้ปรับเป็น embedded เช่นกัน)
    SizedBox(), // แท็บสแกนจะ push แยก
    CableEnterScreen(embedded: true),
    SettingsScreen(embedded: true),
  ];

  @override
  void initState() {
    super.initState();
    FirestoreService().ensureUserDoc();
  }

  Future<void> _onItemTapped(int index) async {
    if (index == 1) {
      final code = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const ScannerScreen()),
      );
      if (!mounted) return;
      if (code != null && code.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('สแกนได้: $code')));
      }
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          _getAppBarTitle(_selectedIndex),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          FutureBuilder<String?>(
            future: fetchCurrentUserRole(),
            builder: (context, snap) {
              if (snap.data == 'admin') {
                return IconButton(
                  tooltip: 'โหมดแอดมิน',
                  icon: const Icon(Icons.admin_panel_settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminModeScreen(),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            tooltip: 'สลับธีม',
            icon: Icon(
              themeNotifier.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () => themeNotifier.toggleTheme(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: cs.outlineVariant),
        ),
      ),

      body: IndexedStack(index: _selectedIndex, children: _tabs),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedItemColor: cs.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'หน้าแรก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'สแกน',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.straighten), label: 'GPS'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'ฉัน',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'เครื่องมือค้นหา Core';
      case 2:
        return 'จัดการสาย/วัดระยะ (GPS)';
      case 3:
        return 'โปรไฟล์';
      default:
        return '';
    }
  }
}
