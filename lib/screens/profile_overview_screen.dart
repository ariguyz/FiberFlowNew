// lib/screens/profile_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class ProfileOverviewScreen extends StatefulWidget {
  const ProfileOverviewScreen({super.key});

  @override
  State<ProfileOverviewScreen> createState() => _ProfileOverviewScreenState();
}

class _ProfileOverviewScreenState extends State<ProfileOverviewScreen> {
  // ===== controllers - ข้อมูลบุคคล =====
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _orgCtl = TextEditingController();
  final _positionCtl = TextEditingController();

  // ===== controllers - ข้อมูลสถานที่ =====
  final _siteCtl = TextEditingController(); // สถานที่ทำงาน/ไซต์งาน
  final _addrCtl = TextEditingController(); // ที่อยู่ (ย่อ)
  final _provinceCtl = TextEditingController(); // จังหวัด
  final _districtCtl = TextEditingController(); // อำเภอ/เขต

  // state
  bool _loading = true;
  bool _savingPersonal = false;
  bool _savingPlace = false;
  bool _editingPersonal = false;
  bool _editingPlace = false;

  String _email = '';
  String _uid = ''; // เก็บไว้ใช้เขียนอ่าน Firestore แต่ **ไม่แสดงบน UI**
  String? _role;
  String? _photoUrl;

  // เพื่อคืนค่าเมื่อกดยกเลิก
  late Map<String, String> _originalPersonal;
  late Map<String, String> _originalPlace;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    // personal
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _orgCtl.dispose();
    _positionCtl.dispose();
    // place
    _siteCtl.dispose();
    _addrCtl.dispose();
    _provinceCtl.dispose();
    _districtCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _email = u.email ?? '';
    _uid = u.uid;
    _photoUrl = u.photoURL;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(_uid).get();
    final d = doc.data() ?? {};

    // personal
    _nameCtl.text = (u.displayName ?? d['name'] ?? '').toString();
    _phoneCtl.text = (d['phone'] ?? '').toString();
    _orgCtl.text = (d['org'] ?? '').toString();
    _positionCtl.text = (d['position'] ?? '').toString();
    _role = (d['role'] ?? '').toString().isEmpty ? null : d['role'];

    // place
    _siteCtl.text = (d['site'] ?? '').toString();
    _addrCtl.text = (d['address'] ?? '').toString();
    _provinceCtl.text = (d['province'] ?? '').toString();
    _districtCtl.text = (d['district'] ?? '').toString();

    _originalPersonal = {
      'name': _nameCtl.text,
      'phone': _phoneCtl.text,
      'org': _orgCtl.text,
      'position': _positionCtl.text,
    };
    _originalPlace = {
      'site': _siteCtl.text,
      'address': _addrCtl.text,
      'province': _provinceCtl.text,
      'district': _districtCtl.text,
    };

    if (mounted) setState(() => _loading = false);
  }

  // ===== บันทึกข้อมูลบุคคล =====
  Future<void> _savePersonal() async {
    if (_savingPersonal) return;
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    setState(() => _savingPersonal = true);
    try {
      final newName = _nameCtl.text.trim();
      if (newName.isNotEmpty && newName != (u.displayName ?? '')) {
        await u.updateDisplayName(newName);
      }
      await FirebaseFirestore.instance.collection('users').doc(_uid).set({
        'name': newName,
        'phone': _phoneCtl.text.trim(),
        'org': _orgCtl.text.trim(),
        'position': _positionCtl.text.trim(),
        if (_role != null) 'role': _role,
        'email': _email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _originalPersonal = {
        'name': _nameCtl.text,
        'phone': _phoneCtl.text,
        'org': _orgCtl.text,
        'position': _positionCtl.text,
      };
      if (mounted) {
        setState(() => _editingPersonal = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลบุคคลเรียบร้อย')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกข้อมูลบุคคลไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPersonal = false);
    }
  }

  // ===== บันทึกข้อมูลสถานที่ =====
  Future<void> _savePlace() async {
    if (_savingPlace) return;
    setState(() => _savingPlace = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).set({
        'site': _siteCtl.text.trim(),
        'address': _addrCtl.text.trim(),
        'province': _provinceCtl.text.trim(),
        'district': _districtCtl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _originalPlace = {
        'site': _siteCtl.text,
        'address': _addrCtl.text,
        'province': _provinceCtl.text,
        'district': _districtCtl.text,
      };
      if (mounted) {
        setState(() => _editingPlace = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลสถานที่เรียบร้อย')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกข้อมูลสถานที่ไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPlace = false);
    }
  }

  void _toggleEditPersonal() {
    if (_editingPersonal) {
      _nameCtl.text = _originalPersonal['name'] ?? '';
      _phoneCtl.text = _originalPersonal['phone'] ?? '';
      _orgCtl.text = _originalPersonal['org'] ?? '';
      _positionCtl.text = _originalPersonal['position'] ?? '';
      setState(() => _editingPersonal = false);
    } else {
      setState(() => _editingPersonal = true);
    }
  }

  void _toggleEditPlace() {
    if (_editingPlace) {
      _siteCtl.text = _originalPlace['site'] ?? '';
      _addrCtl.text = _originalPlace['address'] ?? '';
      _provinceCtl.text = _originalPlace['province'] ?? '';
      _districtCtl.text = _originalPlace['district'] ?? '';
      setState(() => _editingPlace = false);
    } else {
      setState(() => _editingPlace = true);
    }
  }

  // ===== ออกจากระบบ =====
  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('ยืนยันการออกจากระบบ'),
            content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
            actions: [
              TextButton(
                child: const Text('ยกเลิก'),
                onPressed: () => Navigator.pop(context, false),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ออกจากระบบ'),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pop(); // ให้ Auth Gate นำไปหน้า Login เอง
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ออกจากระบบแล้ว')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ออกจากระบบไม่สำเร็จ: $e')));
    }
  }

  // ====== UI Helpers ======
  Card _section(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: child,
      ),
    );
  }

  InputDecoration _dec(BuildContext ctx, String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('โปรไฟล์'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: cs.outlineVariant),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ===== รูปโปรไฟล์ด้านบน =====
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: cs.primary.withOpacity(.15),
                        backgroundImage:
                            (_photoUrl != null && _photoUrl!.isNotEmpty)
                                ? NetworkImage(_photoUrl!)
                                : null,
                        child:
                            (_photoUrl == null || _photoUrl!.isEmpty)
                                ? Icon(
                                  Icons.person,
                                  color: cs.primary,
                                  size: 34,
                                )
                                : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _nameCtl.text.isEmpty ? 'ผู้ใช้' : _nameCtl.text,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),

                  // ===== กล่อง “ข้อมูลบุคคล” =====
                  _section(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ข้อมูลบุคคล',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // อีเมล / สิทธิ์ผู้ใช้
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.alternate_email),
                          title: Text(_email.isEmpty ? '—' : _email),
                          subtitle: const Text('อีเมล'),
                        ),
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.verified_user_outlined),
                          title: Text(_role ?? '—'),
                          subtitle: const Text('สิทธิ์ผู้ใช้ (role)'),
                        ),

                        // **ตัด User ID ออกจาก UI ตามคำขอ**
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameCtl,
                          readOnly: !_editingPersonal,
                          decoration: _dec(
                            context,
                            'ชื่อที่แสดง',
                            icon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _phoneCtl,
                          readOnly: !_editingPersonal,
                          keyboardType: TextInputType.phone,
                          decoration: _dec(
                            context,
                            'เบอร์โทร',
                            icon: Icons.phone_outlined,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _orgCtl,
                          readOnly: !_editingPersonal,
                          decoration: _dec(
                            context,
                            'หน่วยงาน/บริษัท',
                            icon: Icons.apartment_outlined,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _positionCtl,
                          readOnly: !_editingPersonal,
                          decoration: _dec(
                            context,
                            'ตำแหน่งงาน',
                            icon: Icons.work_outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    _savingPersonal
                                        ? null
                                        : _toggleEditPersonal,
                                icon: Icon(
                                  _editingPersonal ? Icons.close : Icons.edit,
                                ),
                                label: Text(
                                  _editingPersonal ? 'ยกเลิก' : 'แก้ไข',
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  shape: const StadiumBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed:
                                    (!_editingPersonal || _savingPersonal)
                                        ? null
                                        : _savePersonal,
                                icon:
                                    _savingPersonal
                                        ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(Icons.save_outlined),
                                label: const Text('บันทึก'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  shape: const StadiumBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== กล่อง “ข้อมูลสถานที่” =====
                  _section(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ข้อมูลสถานที่',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _siteCtl,
                          readOnly: !_editingPlace,
                          decoration: _dec(
                            context,
                            'สถานที่ทำงาน/ไซต์งาน',
                            icon: Icons.place_outlined,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _addrCtl,
                          readOnly: !_editingPlace,
                          decoration: _dec(
                            context,
                            'ที่อยู่ (ย่อ)',
                            icon: Icons.home_outlined,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _provinceCtl,
                          readOnly: !_editingPlace,
                          decoration: _dec(
                            context,
                            'จังหวัด',
                            icon: Icons.map_outlined,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _districtCtl,
                          readOnly: !_editingPlace,
                          decoration: _dec(
                            context,
                            'อำเภอ/เขต',
                            icon: Icons.location_city_outlined,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    _savingPlace ? null : _toggleEditPlace,
                                icon: Icon(
                                  _editingPlace ? Icons.close : Icons.edit,
                                ),
                                label: Text(_editingPlace ? 'ยกเลิก' : 'แก้ไข'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  shape: const StadiumBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed:
                                    (!_editingPlace || _savingPlace)
                                        ? null
                                        : _savePlace,
                                icon:
                                    _savingPlace
                                        ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(Icons.save_outlined),
                                label: const Text('บันทึก'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  shape: const StadiumBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ===== ปุ่มออกจากระบบ (สไตล์ปกติ ไม่แดง) =====
                  OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: Icon(Icons.logout_rounded, color: cs.primary),
                    label: Text(
                      'ออกจากระบบ',
                      style: TextStyle(color: cs.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: const StadiumBorder(),
                      side: BorderSide(color: cs.outlineVariant),
                      foregroundColor: cs.primary,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ===== ปุ่ม Back / Exit ด้านล่าง =====
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => SystemNavigator.pop(),
                          icon: Icon(
                            Icons.exit_to_app_rounded,
                            color: cs.primary,
                          ),
                          label: Text(
                            'Exit',
                            style: TextStyle(color: cs.primary),
                          ),
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
        ),
      ),
    );
  }
}
