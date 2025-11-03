import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/theme_notifier.dart';

class Tia598Screen extends StatelessWidget {
  const Tia598Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    return Scaffold(
      // AppBar แบบ “โล่ง” ไม่มี title ซ้ำ
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const SizedBox.shrink(),
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: cs.outlineVariant),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BrandHeader(title: 'TIA 598-C Standard'),
                  const SizedBox(height: 12),

                  _BigCardButton(
                    label: 'ข้อมูล',
                    icon: Icons.article_outlined,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _TiaInfoStub(),
                          ),
                        ),
                  ),
                  const SizedBox(height: 16),
                  _BigCardButton(
                    label: 'สัญลักษณ์',
                    icon: Icons.apps_outlined,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _TiaSymbolStub(),
                          ),
                        ),
                  ),

                  const SizedBox(height: 28),

                  // ปุ่มล่าง: Exit (Outlined), Back (Filled) ตามแบบ
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => SystemNavigator.pop(),
                          icon: Icon(
                            Icons.exit_to_app_rounded,
                            color: cs.primary,
                          ),
                          label: Text(
                            'Exit',
                            style: TextStyle(color: cs.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: const StadiumBorder(),
                            side: BorderSide(color: cs.outlineVariant),
                            foregroundColor: cs.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: const StadiumBorder(),
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
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

class _BrandHeader extends StatelessWidget {
  final String title;
  const _BrandHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        // โลโก้อย่างเดียว (ไม่มีคำว่า FiberFlow ใต้โลโก้)
        Image.asset('assets/images/logofiberflow.png', height: 64),

        const SizedBox(height: 12), // ระยะสวยๆ ระหว่างโลโก้กับชื่อหน้า
        // ชื่อหน้าจอ
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _BigCardButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _BigCardButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: cs.primary),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
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

/* ==== หน้าเปล่าวาง placeholder เนื้อหา ==== */
class _TiaInfoStub extends StatelessWidget {
  const _TiaInfoStub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ข้อมูล (TIA-598-C)')),
      body: const Center(child: Text('วางคอนเทนต์ “ข้อมูล” ที่นี่ภายหลัง')),
    );
  }
}

class _TiaSymbolStub extends StatelessWidget {
  const _TiaSymbolStub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สัญลักษณ์ (TIA-598-C)')),
      body: const Center(child: Text('วางคอนเทนต์ “สัญลักษณ์” ที่นี่ภายหลัง')),
    );
  }
}
