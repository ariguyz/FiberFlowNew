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
                  const SizedBox(height: 16),

                  // ===== การ์ด "ข้อมูล" (แสดงบนหน้านี้เลย / ไม่กด) =====
                  _SectionCard(
                    leadingIcon: Icons.article_outlined,
                    title: 'ข้อมูล',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bullet(
                          'มาตรฐานการระบุสีเส้นใย (Fiber) และท่อ (Tube) สำหรับสายใยแก้วนำแสง',
                        ),
                        _Bullet(
                          'ชุดสีมาตรฐานมี 12 สี และจะ “วนซ้ำเป็นรอบ (Group)” เมื่อเกิน 12',
                        ),
                        _Bullet(
                          'ใช้ได้กับหลายโครงสร้าง เช่น loose-tube, tight-buffered, ribbon',
                        ),
                        _Bullet(
                          'จุดประสงค์เพื่อลดความผิดพลาดในการเข้าหัว/เชื่อมต่อ และการบำรุงรักษาหน้างาน',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'เคล็ดลับ: ในภาคสนาม หากจำนวนท่อเกิน 12 มักทำแถบ/ริ้วสีดำหรือสัญลักษณ์เสริมเพื่อบอกว่าเป็นรอบสีถัดไป (Group x2, x3, ...)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== การ์ด "สัญลักษณ์" (แสดงบนหน้านี้เลย / ไม่กด) =====
                  _SectionCard(
                    leadingIcon: Icons.apps_outlined,
                    title: 'สัญลักษณ์',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ลำดับสีมาตรฐาน 12 สี (วนซ้ำ):',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        _ColorChipsRow(
                          colors: const [
                            'Blue',
                            'Orange',
                            'Green',
                            'Brown',
                            'Slate',
                            'White',
                            'Red',
                            'Black',
                            'Yellow',
                            'Violet',
                            'Rose',
                            'Aqua',
                          ],
                        ),
                        const SizedBox(height: 12),
                        _Bullet(
                          'สัญลักษณ์พบบ่อย: จุด/ขีด/ปลอกหด (marker) เพื่อบอกตำแหน่ง/รอบสี',
                        ),
                        _Bullet('งาน Ribbon อาจระบุสี + เลขแถบริบบอนเพิ่ม'),
                        const SizedBox(height: 8),
                        Text(
                          'ส่วนรายละเอียดเชิงรูปภาพ/แผนผังจะเพิ่มให้ภายหลัง เพื่อให้เปิดดูประกอบก่อนคำนวณได้สะดวก',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ปุ่มล่างเหมือนเดิม
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
        Image.asset('assets/images/logofiberflow.png', height: 64),
        const SizedBox(height: 12),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData leadingIcon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.leadingIcon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(.06),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(leadingIcon, color: cs.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 6, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ColorChipsRow extends StatelessWidget {
  final List<String> colors;
  const _ColorChipsRow({required this.colors});

  Color _uiColorFor(String name) {
    switch (name) {
      case 'Blue':
        return const Color(0xFF1E88E5);
      case 'Orange':
        return const Color(0xFFF39C12);
      case 'Green':
        return const Color(0xFF43A047);
      case 'Brown':
        return const Color(0xFF795548);
      case 'Slate':
        return const Color(0xFF9E9E9E);
      case 'White':
        return const Color(0xFFFFFFFF);
      case 'Red':
        return const Color(0xFFE53935);
      case 'Black':
        return const Color(0xFF000000);
      case 'Yellow':
        return const Color(0xFFFDD835);
      case 'Violet':
        return const Color(0xFF8E24AA);
      case 'Rose':
        return const Color(0xFFE91E63);
      case 'Aqua':
        return const Color(0xFF26C6DA);
      default:
        return Colors.blueGrey;
    }
  }

  Color _onColor(Color bg) =>
      bg.computeLuminance() > 0.7 ? Colors.black : Colors.white;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          colors.map((name) {
            final bg = _uiColorFor(name);
            final fg = _onColor(bg);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border:
                    bg.computeLuminance() > 0.7
                        ? Border.all(color: cs.outline)
                        : null,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                name,
                style: TextStyle(color: fg, fontWeight: FontWeight.w700),
              ),
            );
          }).toList(),
    );
  }
}
