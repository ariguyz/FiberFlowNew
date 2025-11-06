// lib/screens/single_loose_tube_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';
import 'history_screen.dart';

class SingleLooseTubeScreen extends StatefulWidget {
  const SingleLooseTubeScreen({super.key});
  @override
  State<SingleLooseTubeScreen> createState() => _SingleLooseTubeScreenState();
}

class _SingleLooseTubeScreenState extends State<SingleLooseTubeScreen> {
  static const int _colorsPerSet = 12;
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

  Color _onColor(Color bg) =>
      bg.computeLuminance() > 0.7 ? Colors.black : Colors.white;

  Map<String, dynamic>? _lookup(int n) {
    if (n <= 0) return null;
    final coreIndexInSet = ((n - 1) % _colorsPerSet) + 1; // 1..12
    final coreColor = _colorOrder[coreIndexInSet - 1];
    final colorCycle = ((n - 1) ~/ _colorsPerSet) + 1; // 1,2,3,...

    return {
      'tubeIndex': 1,
      'coreIndex': coreIndexInSet,
      'coreColor': coreColor,
      'colorCycle': colorCycle,
    };
  }

  Future<void> _saveHistory(int n, Map<String, dynamic> r) async {
    final resultStr =
        'Single Tube | Core ${r['coreIndex']} (${r['coreColor']})'
        '${(r['colorCycle'] as int) > 1 ? ' • Group ${r['colorCycle']}' : ' • Group 1'}';
    setState(() => _saving = true);
    try {
      await _fs.saveCalculationHistory(
        inputValue: n,
        result: resultStr,
        calcType: 'single', // <-- ใส่ชนิด Single
      );
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
    final v = int.tryParse(_nCtrl.text.trim());
    if (v == null || v <= 0) {
      setState(() {
        _n = null;
        _err = 'ใส่เลขคอร์ให้ถูกต้อง (> 0)';
      });
      return;
    }
    setState(() {
      _n = v;
      _err = null;
    });
  }

  void _step(int d) {
    final now = _n ?? 0;
    final next = now + d;
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
      appBar: AppBar(
        title: const Text('Fiber Calculation (Single)'),
        actions: [
          IconButton(
            tooltip: 'ประวัติ (Single เท่านั้น)',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoryScreen(typeFilter: 'single'),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
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
                            'ค้นหาลำดับของคอร์',
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
                                    hintText: 'เช่น 1, 13, 24, 25, 36...',
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
                                'เพิ่มหรือลดลำดับคอร์',
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
                    _SingleResultCard(
                      n: _n!,
                      coreIndex: result['coreIndex'] as int,
                      coreColorName: result['coreColor'] as String,
                      colorCycle: result['colorCycle'] as int,
                      saving: _saving,
                      onSave: () => _saveHistory(_n!, result),
                      colorFor: (name) => _uiColorFor(name, cs),
                      onColorFor: (bg) => _onColor(bg),
                    )
                  else
                    Text(
                      'พิมพ์เลขคอร์แล้วกดค้นหา เพื่อดูสีคอร์ (ท่อเดียว แบบ Single-loose-tube)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),

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

class _SingleResultCard extends StatelessWidget {
  final int n;
  final int coreIndex;
  final String coreColorName;
  final int colorCycle; // Group 1=คอร์ 1..12, Group 2=13..24, ...
  final bool saving;
  final VoidCallback onSave;
  final Color Function(String name) colorFor;
  final Color Function(Color bg) onColorFor;

  const _SingleResultCard({
    required this.n,
    required this.coreIndex,
    required this.coreColorName,
    required this.colorCycle,
    required this.saving,
    required this.onSave,
    required this.colorFor,
    required this.onColorFor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final coreBg = colorFor(coreColorName);
    final coreOn = onColorFor(coreBg);

    Border? _borderIfBright(Color bg) =>
        bg.computeLuminance() > 0.7 ? Border.all(color: cs.outline) : null;

    Widget _groupHeader() {
      return Row(
        children: [
          Text('Group ที่', style: theme.textTheme.labelLarge),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: cs.outlineVariant),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              '$colorCycle',
              style: TextStyle(
                color: cs.onSecondaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('Color Core', style: theme.textTheme.labelLarge),
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
            const SizedBox(height: 12),

            _groupHeader(),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                      'Single Tube • Core $coreIndex\nสี $coreColorName',
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
              '• โครงสร้าง Single-loose-tube มี 1 ท่อ (Tube 1) เท่านั้น\n'
              '• เลขคอร์ $n ⇒ เป็นคอร์ที่ $coreIndex ภายในชุดสีมาตรฐาน 12 สี (อยู่ใน Group ที่ $colorCycle)\n'
              '• สีคอร์ = $coreColorName (อ้างอิงลำดับสี TIA-598)',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
