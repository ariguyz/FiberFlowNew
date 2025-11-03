// lib/screens/cable_enter_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'cable_detail_screen.dart';

class CableEnterScreen extends StatefulWidget {
  final bool embedded; // แสดงแบบฝังในแท็บหรือไม่
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

  /// การ์ดกรอก Cable ID (ใช้ได้ทั้ง embedded/standalone)
  Widget _card(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.cable, color: cs.primary),
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
            const SizedBox(height: 14),
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
                        child: Text(_err!, style: TextStyle(color: cs.error)),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  /// layout กลาง (ใช้ร่วมกัน)
  Widget _centeredBody(BuildContext context, {required Widget child}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // กรณี embedded (อยู่ในแท็บของ Dashboard): ไม่ใส่ AppBar/หัว/ปุ่มล่าง
    if (widget.embedded) {
      return _centeredBody(context, child: _card(context));
    }

    // Standalone (push มาเอง): มีหัวโลโก้ + ชื่อหน้า และปุ่ม Exit/Back สไตล์เดียวกับ FindColorCode
    return Scaffold(
      appBar: AppBar(
        title: null, // ไม่แสดงชื่อซ้ำ ให้หัวอยู่ใน body
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cs.surface,
      ),
      body: SafeArea(
        child: _centeredBody(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header โลโก้ + ชื่อหน้า
              Column(
                children: [
                  Image.asset('assets/images/logofiberflow.png', height: 64),
                  const SizedBox(height: 8),
                  Text(
                    'จัดการสาย / วัดระยะ (GPS)',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // การ์ดกรอก
              _card(context),

              const SizedBox(height: 28),

              // ปุ่มล่าง: Exit (outlined-pill) / Back (filled-pill)
              Row(
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
            ],
          ),
        ),
      ),
    );
  }
}
