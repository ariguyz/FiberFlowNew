// lib/screens/tube_planner_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../repositories/fiber_repository.dart';

class TubePlannerScreen extends StatefulWidget {
  final String cableId;
  const TubePlannerScreen({super.key, required this.cableId});

  @override
  State<TubePlannerScreen> createState() => _TubePlannerScreenState();
}

class _TubePlannerScreenState extends State<TubePlannerScreen> {
  final _repo = FiberRepository();
  final _tubesCtrl = TextEditingController(text: '12');
  final _coresCtrl = TextEditingController(text: '12');

  bool _loading = false;
  String? _error;
  int get _tubes => int.tryParse(_tubesCtrl.text.trim()) ?? 0;
  int get _cores => int.tryParse(_coresCtrl.text.trim()) ?? 0;
  int get _total => _tubes * _cores;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    setState(() => _loading = true);
    try {
      final structure = await _repo.getCableStructure(widget.cableId);
      if (structure != null) {
        final tubesCount = (structure['tubesCount'] ?? 0) as int;
        final coresPerTube = (structure['coresPerTube'] ?? 0) as int;
        if (tubesCount > 0) _tubesCtrl.text = tubesCount.toString();
        if (coresPerTube > 0) _coresCtrl.text = coresPerTube.toString();
      }
    } catch (e) {
      _error = 'โหลดข้อมูลเดิมไม่สำเร็จ: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final tubes = _tubes;
    final cores = _cores;

    if (tubes <= 0 || cores <= 0) {
      setState(
        () => _error = 'กรุณาระบุจำนวนท่อและจำนวนคอร์/ท่อให้ถูกต้อง (> 0)',
      );
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      await _repo.setCableStructure(
        cableId: widget.cableId,
        tubesCount: tubes,
        coresPerTube: cores,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกโครงสร้างสายสำเร็จ')));
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'บันทึกไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tubesCtrl.dispose();
    _coresCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('โครงสร้างสาย • ${widget.cableId}')),
      body: AbsorbPointer(
        absorbing: _loading,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: cs.onErrorContainer),
                ),
              ),
              const SizedBox(height: 12),
            ],

            _numberField(
              context,
              controller: _tubesCtrl,
              label: 'จำนวนท่อ (Tubes)',
              hint: 'เช่น 6, 12, 24...',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _numberField(
              context,
              controller: _coresCtrl,
              label: 'จำนวนคอร์/ท่อ (Cores per Tube)',
              hint: 'เช่น 12',
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: ListTile(
                leading: Icon(Icons.calculate_rounded, color: cs.primary),
                title: Text('รวมคอร์ทั้งหมด'),
                subtitle: Text('$_tubes ท่อ × $_cores คอร์/ท่อ'),
                trailing: Text(
                  _total.toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              'ตัวอย่างรายท่อ',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _tubePreview(context),

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon:
                  _loading
                      ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.save_rounded),
              label: const Text('บันทึกโครงสร้างสาย'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    String? hint,
    ValueChanged<String>? onChanged,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.numbers_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: onChanged,
      style: theme.textTheme.bodyLarge,
    );
  }

  Widget _tubePreview(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tubes = _tubes.clamp(0, 50); // Limit เพื่อกัน UI ย้วย
    if (tubes == 0 || _cores == 0) {
      return Text(
        'ใส่จำนวนท่อและคอร์/ท่อ เพื่อดูตัวอย่าง',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      );
    }
    return Column(
      children: List.generate(tubes, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(color: cs.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('Tube ${i + 1}')),
              Text('${_cores} cores'),
            ],
          ),
        );
      }),
    );
  }
}
