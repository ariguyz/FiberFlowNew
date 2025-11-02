// lib/screens/cable_enter_screen.dart
import 'package:flutter/material.dart';
import 'cable_detail_screen.dart';

class CableEnterScreen extends StatefulWidget {
  final bool embedded; // ✅ เพิ่ม
  const CableEnterScreen({super.key, this.embedded = false});

  @override
  State<CableEnterScreen> createState() => _CableEnterScreenState();
}

class _CableEnterScreenState extends State<CableEnterScreen> {
  final _id = TextEditingController();
  String? _err;
  bool _submitting = false;

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final v = _id.text.trim();
    if (v.isEmpty) {
      setState(() => _err = 'กรุณากรอก Cable ID');
      return;
    }
    setState(() {
      _err = null;
      _submitting = true;
    });
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CableDetailScreen(cableId: v)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    // ✅ เนื้อหาหลัก แยกเป็นตัวแปร
    final content = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            elevation: 3,
            color: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: onSurface.withOpacity(.06)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cable, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'ระบุ Cable ID',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _id,
                    decoration: InputDecoration(
                      hintText: 'เช่น 0001, 007, A-12',
                      labelText: 'Cable ID',
                      prefixIcon: const Icon(Icons.tag),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: _err,
                      filled: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() => _err = null),
                    onSubmitted: (_) => _go(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _go,
                    icon:
                        _submitting
                            ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.chevron_right_rounded),
                    label: Text(_submitting ? 'กำลังไป…' : 'ต่อไป'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child:
                        _err == null
                            ? const SizedBox.shrink()
                            : Padding(
                              key: ValueKey(_err),
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _err!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // ✅ ถ้าฝังใน Dashboard → ไม่สร้าง AppBar/Scaffold ซ้ำ
    if (widget.embedded) return content;

    // ใช้เดี่ยว ๆ (push มาเอง) → มี AppBar ตามปกติ
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการสาย/วัดระยะ (GPS)')),
      body: content,
    );
  }
}
