// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <- สำหรับ SystemNavigator.pop()
import '../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _coresPerTube = 12;
  final _nCtrl = TextEditingController();
  final _fs = FirestoreService();

  int? _n;
  String? _err;
  bool _saving = false;

  @override
  void dispose() {
    _nCtrl.dispose();
    super.dispose();
  }

  static const List<String> _colorOrder = [
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
  ];

  Color _uiColorFor(String name, ColorScheme cs) {
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
        return cs.primary;
    }
  }

  Color _onColorForBackground(Color bg) =>
      bg.computeLuminance() > 0.7 ? Colors.black : Colors.white;

  /// Multi-loose-tube: ท่อวนสีทุก 12, คอร์วนสีทุก 12
  Map<String, dynamic>? _lookup(int n) {
    if (n <= 0) return null;

    final tubeIndex = ((n - 1) ~/ _coresPerTube) + 1; // 1..∞
    final coreIndex = ((n - 1) % _coresPerTube) + 1; // 1..12

    final tubeColor = _colorOrder[(tubeIndex - 1) % 12];
    final coreColor = _colorOrder[(coreIndex - 1) % 12];

    final tubeColorCycle = ((tubeIndex - 1) ~/ 12) + 1;
    final coreColorCycle = ((coreIndex - 1) ~/ 12) + 1; // จะเป็น 1 เสมอ

    return {
      'tubeIndex': tubeIndex,
      'coreIndex': coreIndex,
      'tubeColor': tubeColor,
      'coreColor': coreColor,
      'tubeColorCycle': tubeColorCycle,
      'coreColorCycle': coreColorCycle,
    };
  }

  Future<void> _saveHistory(int n, Map<String, dynamic> r) async {
    final resultStr =
        'Tube ${r['tubeIndex']} (${r['tubeColor']}) | Core ${r['coreIndex']} (${r['coreColor']})';
    setState(() => _saving = true);
    try {
      await _fs.saveCalculationHistory(inputValue: n, result: resultStr);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกประวัติเรียบร้อย')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onSearch() {
    final raw = _nCtrl.text.trim();
    final value = int.tryParse(raw);
    if (value == null || value <= 0) {
      setState(() {
        _n = null;
        _err = 'ใส่เลขคอร์ให้ถูกต้อง (> 0)';
      });
      return;
    }
    setState(() {
      _n = value;
      _err = null;
    });
  }

  void _step(int delta) {
    final now = _n ?? 0;
    final next = now + delta;
    if (next <= 0) return;
    _nCtrl.text = next.toString();
    _onSearch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final result = (_n != null) ? _lookup(_n!) : null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ===== เนื้อหาหลัก (เหมือนเดิม) =====
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Text(
                    'Fiber Calculation',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ค้นหาเลขคอร์',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'เช่น 1, 12, 48, 96...',
                                    prefixIcon: const Icon(Icons.tag),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    errorText: _err,
                                  ),
                                  onSubmitted: (_) => _onSearch(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: _onSearch,
                                icon: const Icon(Icons.search),
                                label: const Text('ค้นหา'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.swap_horiz, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'เลื่อนคอร์',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'ก่อนหน้า',
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _step(-1),
                              ),
                              IconButton(
                                tooltip: 'ถัดไป',
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _step(1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (result != null)
                    _ResultCard(
                      n: _n!,
                      tubeIndex: result['tubeIndex'] as int,
                      coreIndex: result['coreIndex'] as int,
                      tubeColorName: result['tubeColor'] as String,
                      coreColorName: result['coreColor'] as String,
                      tubeColorCycle: result['tubeColorCycle'] as int,
                      coreColorCycle: result['coreColorCycle'] as int,
                      saving: _saving,
                      onSave: () => _saveHistory(_n!, result),
                      colorFor: (name) => _uiColorFor(name, cs),
                      onColorFor: (bg) => _onColorForBackground(bg),
                    )
                  else
                    Text(
                      'พิมพ์เลขคอร์แล้วกดค้นหา เพื่อดูผลลำดับสีของท่อ/คอร์',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),

            // ===== ปุ่ม Exit / Back ด้านล่าง =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => SystemNavigator.pop(),
                      icon: Icon(Icons.exit_to_app_rounded, color: cs.primary),
                      label: Text('Exit', style: TextStyle(color: cs.primary)),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final int n;
  final int tubeIndex;
  final int coreIndex;
  final String tubeColorName;
  final String coreColorName;
  final int tubeColorCycle;
  final int coreColorCycle;
  final bool saving;
  final VoidCallback onSave;
  final Color Function(String name) colorFor;
  final Color Function(Color bg) onColorFor;

  const _ResultCard({
    required this.n,
    required this.tubeIndex,
    required this.coreIndex,
    required this.tubeColorName,
    required this.coreColorName,
    required this.tubeColorCycle,
    required this.coreColorCycle,
    required this.saving,
    required this.onSave,
    required this.colorFor,
    required this.onColorFor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final tubeBg = colorFor(tubeColorName);
    final coreBg = colorFor(coreColorName);
    final tubeOn = onColorFor(tubeBg);
    final coreOn = onColorFor(coreBg);

    Border? _borderIfBright(Color bg) =>
        bg.computeLuminance() > 0.7 ? Border.all(color: cs.outline) : null;

    Widget _cornerBadge(int cycle) =>
        cycle <= 1
            ? const SizedBox.shrink()
            : Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.repeat, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'x$cycle',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            );

    Widget _colorTile({
      required Color bg,
      required Color fg,
      required String line1,
      required String line2,
      int cycleForBadge = 1,
    }) {
      return Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: _borderIfBright(bg),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 18, color: fg),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$line1\n$line2',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          _cornerBadge(cycleForBadge),
        ],
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Core #$n',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'ผลลัพธ์',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _colorTile(
                    bg: tubeBg,
                    fg: tubeOn,
                    line1: 'Tube $tubeIndex',
                    line2: 'สี $tubeColorName',
                    cycleForBadge: tubeColorCycle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _colorTile(
                    bg: coreBg,
                    fg: coreOn,
                    line1: 'Core $coreIndex',
                    line2: 'สี $coreColorName',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon:
                    saving
                        ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save_alt_rounded),
                label: const Text('บันทึกผล'),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ความหมาย:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '• ท่อที่ $tubeIndex (สี $tubeColorName'
              '${tubeColorCycle > 1 ? ', รอบสีที่ $tubeColorCycle' : ''})'
              '  •  คอร์ที่ $coreIndex (สี $coreColorName)',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
