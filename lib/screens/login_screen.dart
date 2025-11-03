// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../utils/theme_notifier.dart';
import '../services/firestore_service.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String _errorText = '';
  bool _rememberMe = false;
  bool _loading = false;

  // ใช้ควบคุมซ่อน/แสดงรหัสผ่าน (สำหรับปุ่มวางทับ)
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorText = '';
      _loading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = 'กรุณากรอกอีเมลและรหัสผ่าน';
        _loading = false;
      });
      return;
    }

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        setState(() => _errorText = 'ไม่สามารถเข้าสู่ระบบได้ กรุณาลองใหม่');
        return;
      }

      await FirestoreService().ensureUserDoc();
      if (!mounted) return;

      // ยังไม่ยืนยันอีเมล → พาไปหน้า Verify
      if (!user.emailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
        );
        return;
      }

      // สำเร็จ → เข้าหน้า Dashboard
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      final msg = _thaiAuthError(e);
      setState(() => _errorText = msg);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      const msg = 'เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองใหม่อีกครั้ง';
      setState(() => _errorText = msg);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorText = 'กรุณากรอกอีเมลเพื่อรีเซ็ตรหัสผ่าน');
      return;
    }
    try {
      await _auth.setLanguageCode('th');
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งอีเมลรีเซ็ตรหัสผ่านแล้ว')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = _thaiAuthError(e));
    } catch (_) {
      setState(() => _errorText = 'ไม่สามารถส่งอีเมลรีเซ็ตได้ กรุณาลองใหม่');
    }
  }

  String _thaiAuthError(FirebaseAuthException e) {
    // ครอบคลุมโค้ดยอดฮิตของ Email/Password
    switch (e.code) {
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'user-disabled':
        return 'บัญชีนี้ถูกปิดการใช้งาน';
      case 'user-not-found':
        return 'ไม่พบบัญชีผู้ใช้นี้';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'invalid-credential': // บ่อยมากเวลาพิมพ์รหัสผิด
      case 'invalid-login-credentials':
        return 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง';
      case 'too-many-requests':
        return 'พยายามเข้าสู่ระบบหลายครั้งเกินไป กรุณาลองใหม่ภายหลัง';
      case 'network-request-failed':
        return 'การเชื่อมต่ออินเทอร์เน็ตมีปัญหา';
      case 'operation-not-allowed':
        return 'ยังไม่ได้เปิดใช้งานการเข้าสู่ระบบด้วยอีเมล/รหัสผ่าน';
      case 'expired-action-code':
        return 'ลิงก์หรือโค้ดหมดอายุ กรุณาดำเนินการใหม่';
      default:
        return 'ไม่สามารถเข้าสู่ระบบได้ (${e.code})';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('เข้าสู่ระบบ'),
        actions: [
          IconButton(
            icon: Icon(
              themeNotifier.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () => themeNotifier.toggleTheme(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Image.asset('assets/images/logofiberflow.png', height: 120),
              const SizedBox(height: 32),

              // Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'อีเมล',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),
              const SizedBox(height: 16),

              // Password (แบบวางทับปุ่มตา)
              Stack(
                children: [
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่าน',
                      prefixIcon: const Icon(Icons.lock),
                      errorText: _errorText.isNotEmpty ? _errorText : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      // กันตัวอักษรไม่ให้ชน IconButton ที่วางทับด้านขวา
                      contentPadding: const EdgeInsets.fromLTRB(16, 16, 56, 16),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                        tooltip: _obscure ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  ),
                  const Text('จำฉันไว้'),
                  const Spacer(),
                  TextButton(
                    onPressed: _resetPassword,
                    child: const Text('ลืมรหัสผ่าน?'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _loading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text(
                            'เข้าสู่ระบบ',
                            style: TextStyle(fontSize: 18),
                          ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ยังไม่มีบัญชี?'),
                  TextButton(
                    onPressed:
                        _loading
                            ? null
                            : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                    style: TextButton.styleFrom(foregroundColor: cs.primary),
                    child: const Text('สมัครสมาชิก'),
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
