import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _obscurePass = true, _obscureConfirm = true, _loading = false;
  String _errorText = '';

  double get _passwordStrength {
    final p = _password.text;
    int s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'\d').hasMatch(p)) s++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(p)) s++;
    return (s / 5).clamp(0, 1).toDouble();
  }

  String get _passwordLabel {
    final s = _passwordStrength;
    if (s <= 0.2) return 'อ่อนมาก';
    if (s <= 0.4) return 'อ่อน';
    if (s <= 0.6) return 'ปานกลาง';
    if (s <= 0.8) return 'ค่อนข้างดี';
    return 'แข็งแรง';
  }

  Color _strengthColor() {
    final s = _passwordStrength;
    if (s <= 0.2) return Colors.redAccent;
    if (s <= 0.4) return Colors.orange;
    if (s <= 0.6) return Colors.amber;
    if (s <= 0.8) return Colors.lightGreen;
    return Colors.green;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _errorText = '';
      _loading = true;
    });
    try {
      await _auth.setLanguageCode('th');
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      await cred.user?.sendEmailVerification(); // ส่งเมลจริง
      await FirestoreService().ensureUserDoc(); // สร้าง users/{uid}
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'weak-password')
          _errorText = 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
        else if (e.code == 'email-already-in-use')
          _errorText = 'อีเมลนี้ถูกใช้แล้ว';
        else if (e.code == 'invalid-email')
          _errorText = 'รูปแบบอีเมลไม่ถูกต้อง';
        else
          _errorText = 'สมัครไม่สำเร็จ: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorText = 'เกิดข้อผิดพลาดที่ไม่คาดคิด: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xfff5f7fa), Color(0xffc3cfe2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 10,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.black12),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.wifi_tethering,
                            size: 36,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'สมัครสมาชิก FiberFlow',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'สร้างบัญชีเพื่อเริ่มใช้งานการคำนวณสีคอร์ไฟเบอร์ และบันทึกประวัติการทำงานของคุณ',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'อีเมล',
                          hintText: 'name@example.com',
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Colors.black,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'กรุณากรอกอีเมล';
                          final ok = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(value);
                          if (!ok) return 'รูปแบบอีเมลไม่ถูกต้อง';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      StatefulBuilder(
                        builder: (context, setSB) {
                          return Column(
                            children: [
                              TextFormField(
                                controller: _password,
                                obscureText: _obscurePass,
                                onChanged: (_) => setSB(() {}),
                                decoration: InputDecoration(
                                  labelText: 'รหัสผ่าน',
                                  hintText:
                                      'อย่างน้อย 8 ตัว (แนะนำมี ตัวพิมพ์ใหญ่/ตัวเลข/สัญลักษณ์)',
                                  prefixIcon: const Icon(
                                    Icons.lock,
                                    color: Colors.black,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePass
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.black,
                                    ),
                                    onPressed:
                                        () => setSB(
                                          () => _obscurePass = !_obscurePass,
                                        ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (v) {
                                  final value = v ?? '';
                                  if (value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                                  if (value.length < 8)
                                    return 'รหัสผ่านควรมีอย่างน้อย 8 ตัวอักษร';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: _passwordStrength,
                                        minHeight: 8,
                                        color: _strengthColor(),
                                        backgroundColor: Colors.black12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _passwordLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _strengthColor(),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirm,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'ยืนยันรหัสผ่าน',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Colors.black,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.black,
                            ),
                            onPressed:
                                () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'กรุณายืนยันรหัสผ่าน';
                          if (v != _password.text) return 'รหัสผ่านไม่ตรงกัน';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      if (_errorText.isNotEmpty) ...[
                        Text(
                          _errorText,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 6),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_user,
                            size: 18,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'ข้อมูลของคุณจะถูกเก็บในระบบเพื่อให้ประสบการณ์ใช้งานต่อเนื่อง',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _register,
                          icon:
                              _loading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.person_add_alt_1),
                          label: Text(
                            _loading ? 'กำลังสมัคร...' : 'สมัครสมาชิก',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed:
                            _loading ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        label: const Text('ย้อนกลับไปหน้าเข้าสู่ระบบ'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
