// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // ส่วนตัว
  final _displayName = TextEditingController();
  final _phone = TextEditingController();

  // บริษัท
  final _companyName = TextEditingController();
  final _department = TextEditingController();
  final _position = TextEditingController();
  final _employeeId = TextEditingController();
  final _site = TextEditingController();
  final _supervisorName = TextEditingController();
  final _supervisorPhone = TextEditingController();
  final _lineId = TextEditingController();

  bool _saving = false;
  String? _photoUrl;

  @override
  void dispose() {
    _displayName.dispose();
    _phone.dispose();
    _companyName.dispose();
    _department.dispose();
    _position.dispose();
    _employeeId.dispose();
    _site.dispose();
    _supervisorName.dispose();
    _supervisorPhone.dispose();
    _lineId.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _saving = true);

      final url = await FirestoreService().uploadAvatar(
        fileName: picked.name,
        file: kIsWeb ? null : File(picked.path),
        bytes: kIsWeb ? await picked.readAsBytes() : null,
        contentType: 'image/jpeg',
      );

      await FirestoreService().updateProfile(photoUrl: url);
      if (!mounted) return;
      setState(() => _photoUrl = url);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('อัปเดตรูปโปรไฟล์แล้ว')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('อัปโหลดรูปไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      // อัปเดตข้อมูลส่วนตัว (Auth + users/{uid})
      await FirestoreService().updateProfile(
        displayName:
            _displayName.text.trim().isEmpty ? null : _displayName.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      );

      // อัปเดตข้อมูลบริษัท (users/{uid} merge)
      await FirestoreService().updateCompanyInfo(
        companyName: _companyName.text.trim(),
        department: _department.text.trim(),
        position: _position.text.trim(),
        employeeId: _employeeId.text.trim(),
        site: _site.text.trim(),
        supervisorName: _supervisorName.text.trim(),
        supervisorPhone: _supervisorPhone.text.trim(),
        lineId: _lineId.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อย')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์ของฉัน')),
      body: StreamBuilder(
        stream: FirestoreService().currentUserDocStream(),
        builder: (context, snap) {
          final data = snap.data?.data() ?? {};

          // เติมค่าเริ่มต้น (ทำครั้งเดียวตอนมีข้อมูล)
          if (_photoUrl == null)
            _photoUrl = (data['photoUrl'] as String?) ?? user?.photoURL;

          void _initOnce(TextEditingController c, String key) {
            if (c.text.isEmpty && data[key] != null) c.text = '${data[key]}';
          }

          _initOnce(_displayName, 'displayName');
          _initOnce(_phone, 'phone');

          // กลุ่ม company.*
          final company = (data['company'] as Map<String, dynamic>?) ?? {};
          void _initCompany(TextEditingController c, String key) {
            if (c.text.isEmpty && company[key] != null)
              c.text = '${company[key]}';
          }

          _initCompany(_companyName, 'companyName');
          _initCompany(_department, 'department');
          _initCompany(_position, 'position');
          _initCompany(_employeeId, 'employeeId');
          _initCompany(_site, 'site');
          _initCompany(_supervisorName, 'supervisorName');
          _initCompany(_supervisorPhone, 'supervisorPhone');
          _initCompany(_lineId, 'lineId');

          return AbsorbPointer(
            absorbing: _saving,
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 48,
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          backgroundImage:
                              (_photoUrl != null && _photoUrl!.isNotEmpty)
                                  ? NetworkImage(_photoUrl!)
                                  : null,
                          child:
                              (_photoUrl == null || _photoUrl!.isEmpty)
                                  ? Icon(
                                    Icons.person,
                                    size: 48,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                  )
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _pickAvatar,
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('เปลี่ยนรูปโปรไฟล์'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                        const SizedBox(height: 24),

                        // -------- ข้อมูลส่วนตัว --------
                        _SectionHeader(title: 'ข้อมูลส่วนตัว'),
                        const SizedBox(height: 8),
                        _Input(
                          controller: _displayName,
                          label: 'ชื่อที่แสดง',
                          prefix: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 10),
                        _Input(
                          controller: _phone,
                          label: 'เบอร์โทร',
                          prefix: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 24),
                        // -------- ข้อมูลบริษัท --------
                        _SectionHeader(title: 'ข้อมูลบริษัท'),
                        const SizedBox(height: 8),
                        _Input(
                          controller: _companyName,
                          label: 'ชื่อบริษัท',
                          prefix: Icons.apartment_outlined,
                          validator:
                              (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'กรอกชื่อบริษัท'
                                      : null,
                        ),
                        const SizedBox(height: 10),
                        _Input(
                          controller: _department,
                          label: 'แผนก',
                          prefix: Icons.group_outlined,
                        ),
                        const SizedBox(height: 10),
                        _Input(
                          controller: _position,
                          label: 'ตำแหน่ง',
                          prefix: Icons.workspace_premium_outlined,
                        ),
                        const SizedBox(height: 10),
                        _Input(
                          controller: _employeeId,
                          label: 'รหัสพนักงาน',
                          prefix: Icons.credit_card_outlined,
                        ),
                        const SizedBox(height: 10),
                        _Input(
                          controller: _site,
                          label: 'ไซต์งาน/พื้นที่รับผิดชอบ',
                          prefix: Icons.place_outlined,
                        ),
                        const SizedBox(height: 10),
                        _Input(
                          controller: _supervisorName,
                          label: 'ชื่อหัวหน้างาน',
                          prefix: Icons.person_outline,
                        ),
                        const SizedBox(height: 10),
                        _Input(
                          controller: _supervisorPhone,
                          label: 'เบอร์หัวหน้างาน',
                          prefix: Icons.call_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 10),
                        _Input(
                          controller: _lineId,
                          label: 'LINE ID (ถ้ามี)',
                          prefix: Icons.chat_bubble_outline,
                        ),
                      ],
                    ),
                  ),
                ),

                // ปุ่มบันทึกติดขอบล่าง
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon:
                          _saving
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'กำลังบันทึก...' : 'บันทึกข้อมูล'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.folder_shared_outlined,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? prefix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Input({
    required this.controller,
    required this.label,
    this.prefix,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefix == null ? null : Icon(prefix),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
    );
  }
}
