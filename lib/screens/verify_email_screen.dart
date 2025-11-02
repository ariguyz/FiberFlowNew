// lib/screens/verify_email_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'dashboard_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _auth = FirebaseAuth.instance;

  Timer? _poll;
  bool _sending = false;
  bool _verified = false;

  // กันสแปมการส่งซ้ำ
  int _cooldown = 0; // วินาที
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _verified = _auth.currentUser?.emailVerified ?? false;
    _startPolling();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // เช็คทุก 3 วินาที
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _auth.currentUser?.reload();
      final v = _auth.currentUser?.emailVerified ?? false;
      if (v != _verified) {
        setState(() => _verified = v);
      }
      if (v) {
        _poll?.cancel();
        // อัปเดตเอกสารผู้ใช้ให้เรียบร้อย (ถ้าคุณมี ensureUserDoc)
        await FirestoreService().ensureUserDoc();
        if (!mounted) return;
        // ไปหน้า Dashboard ทันที
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (_) => false,
        );
      }
    });
  }

  Future<void> _sendVerification() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _sending = true;
      _cooldown = 30; // รอ 30 วินาทีก่อนส่งซ้ำ
    });

    try {
      await user.sendEmailVerification();
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งอีเมลยืนยันแล้ว กรุณาตรวจกล่องจดหมาย'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ส่งอีเมลไม่สำเร็จ: $e')));
      }
      // ถ้าส่งไม่สำเร็จ ไม่ต้องเริ่ม cooldown
      _cooldown = 0;
      _cooldownTimer?.cancel();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _cooldown -= 1;
        if (_cooldown <= 0) {
          _cooldown = 0;
          t.cancel();
        }
      });
    });
  }

  Future<void> _checkNow() async {
    await _auth.currentUser?.reload();
    final v = _auth.currentUser?.emailVerified ?? false;
    if (mounted) setState(() => _verified = v);

    if (v) {
      _poll?.cancel();
      await FirestoreService().ensureUserDoc();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ยังไม่ได้ยืนยันอีเมล กรุณาตรวจสอบอีเมลอีกครั้ง'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = _auth.currentUser?.email ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('ยืนยันอีเมล')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _verified
                              ? Icons.verified
                              : Icons.mark_email_unread_outlined,
                          color:
                              _verified
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _verified ? 'ยืนยันอีเมลแล้ว' : 'กรุณายืนยันอีเมล',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'เราได้ส่งลิงก์ยืนยันไปที่: $email\n'
                      'เปิดอีเมลของคุณและกดลิงก์เพื่อยืนยัน จากนั้นกลับมาที่หน้านี้',
                    ),
                    const SizedBox(height: 16),

                    // ปุ่มส่งอีเมลยืนยัน
                    FilledButton.icon(
                      onPressed:
                          (_sending || _cooldown > 0)
                              ? null
                              : _sendVerification,
                      icon:
                          _sending
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.email_outlined),
                      label: Text(
                        (_cooldown > 0)
                            ? 'ส่งอีกครั้งใน $_cooldown วิ'
                            : 'ส่งอีเมลยืนยันอีกครั้ง',
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ปุ่มตรวจสอบทันที
                    OutlinedButton.icon(
                      onPressed: _checkNow,
                      icon: const Icon(Icons.refresh),
                      label: const Text('ตรวจสอบอีกครั้ง'),
                    ),
                    const SizedBox(height: 10),

                    // ปุ่มไปต่อ (จะกดได้เมื่อ verified = true)
                    ElevatedButton.icon(
                      onPressed:
                          _verified
                              ? () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const DashboardScreen(),
                                  ),
                                  (_) => false,
                                );
                              }
                              : null,
                      icon: const Icon(Icons.arrow_forward_ios),
                      label: const Text('ไปต่อ'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // สถานะย่อย
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child:
                          _verified
                              ? const Text(
                                'สถานะ: ยืนยันแล้ว',
                                key: ValueKey('ok'),
                              )
                              : const Text(
                                'สถานะ: ยังไม่ยืนยัน',
                                key: ValueKey('no'),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
