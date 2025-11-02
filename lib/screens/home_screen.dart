// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
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

  Map<String, dynamic>? _lookup(int n) {
    if (n <= 0) return null;
    final tubeIndex = ((n - 1) ~/ _coresPerTube) + 1;
    final coreIndex = ((n - 1) % _coresPerTube) + 1;
    final tubeColor = _colorOrder[(tubeIndex - 1) % 12];
    final coreColor = _colorOrder[(coreIndex - 1) % 12];
    return {
      'tubeIndex': tubeIndex,
      'coreIndex': coreIndex,
      'tubeColor': tubeColor,
      'coreColor': coreColor,
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
    }); // 👉 แค่คำนวณ แต่อย่าเซฟอัตโนมัติ
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
      body: ListView(
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
                  Text('ค้นหาเลขคอร์', style: theme.textTheme.labelLarge),
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
                      Text('เลื่อนคอร์', style: theme.textTheme.bodyMedium),
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
              // ปุ่ม “บันทึกผล” (กดเองเท่านั้น)
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
    );
  }
}

class _ResultCard extends StatelessWidget {
  final int n;
  final int tubeIndex;
  final int coreIndex;
  final String tubeColorName;
  final String coreColorName;
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: tubeBg,
                      borderRadius: BorderRadius.circular(12),
                      border: _borderIfBright(tubeBg),
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
                        Icon(Icons.circle, size: 18, color: tubeOn),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tube $tubeIndex\nสี $tubeColorName',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tubeOn,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: coreBg,
                      borderRadius: BorderRadius.circular(12),
                      border: _borderIfBright(coreBg),
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
                        Icon(Icons.circle, size: 18, color: coreOn),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Core $coreIndex\nสี $coreColorName',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: coreOn,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ปุ่มบันทึก (กดเองเท่านั้น)
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
              '• ท่อที่ $tubeIndex (สี $tubeColorName)  •  คอร์ที่ $coreIndex (สี $coreColorName)',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
