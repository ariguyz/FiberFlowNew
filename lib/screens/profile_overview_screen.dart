// lib/screens/profile_overview_screen.dart
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../services/firestore_service.dart';
import 'profile_screen.dart'; // หน้าแก้ไขเดิม

class ProfileOverviewScreen extends StatefulWidget {
  const ProfileOverviewScreen({super.key});

  @override
  State<ProfileOverviewScreen> createState() => _ProfileOverviewScreenState();
}

class _ProfileOverviewScreenState extends State<ProfileOverviewScreen> {
  final _fs = FirestoreService();
  bool _busy = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> _pickAndUploadAvatar() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (x == null) {
        setState(() => _busy = false);
        return;
      }

      // ลบรูปเดิมถ้ามี
      final oldUrl = _user?.photoURL ?? '';
      if (oldUrl.isNotEmpty) {
        await _fs.deleteAvatarByUrl(oldUrl);
      }

      // อัปโหลดขึ้น Storage
      String url;
      if (kIsWeb) {
        final bytes = await x.readAsBytes();
        url = await _fs.uploadAvatar(
          fileName: x.name,
          bytes: bytes,
          contentType: 'image/jpeg',
        );
      } else {
        url = await _fs.uploadAvatar(
          fileName: x.name,
          file: File(x.path),
          contentType: 'image/jpeg',
        );
      }

      // sync โปรไฟล์ (Firestore + FirebaseAuth)
      await _fs.updateProfile(photoUrl: url);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปเดตรูปโปรไฟล์เรียบร้อย')),
      );
      setState(() {}); // refresh
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('อัปโหลดไม่สำเร็จ: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('โปรไฟล์ของฉัน'),
        actions: [
          IconButton(
            tooltip: 'แก้ไขโปรไฟล์',
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _fs.currentUserDocStream(),
        builder: (context, snap) {
          final data = (snap.data?.data()) ?? {};
          final user = _user;

          final displayName = (data['displayName'] as String?)?.trim();
          final email = user?.email ?? '';
          final phone = (data['phone'] as String?)?.trim() ?? '';
          final photoUrl = (data['photoUrl'] as String?) ?? '';
          final emailVerified =
              (data['emailVerified'] as bool?) ?? user?.emailVerified ?? false;
          final createdAt = (data['createdAt'] as Timestamp?);
          final calcCount = (data['calcCount'] as int?) ?? 0;

          // company fields
          final company = (data['company'] as Map?) ?? {};
          final companyName = (company['companyName'] as String?) ?? '';
          final department = (company['department'] as String?) ?? '';
          final position = (company['position'] as String?) ?? '';
          final employeeId = (company['employeeId'] as String?) ?? '';
          final site = (company['site'] as String?) ?? '';
          final supervisor = (company['supervisor'] as Map?) ?? {};
          final supName = (supervisor['name'] as String?) ?? '';
          final supPhone = (supervisor['phone'] as String?) ?? '';
          final lineId = (company['lineId'] as String?) ?? '';

          final headerName =
              (displayName?.isNotEmpty ?? false) ? displayName! : email;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          backgroundImage:
                              (photoUrl.isNotEmpty)
                                  ? NetworkImage(photoUrl)
                                  : null,
                          child:
                              (photoUrl.isEmpty)
                                  ? Icon(
                                    Icons.person,
                                    size: 48,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  )
                                  : null,
                        ),
                        Material(
                          color: theme.colorScheme.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _busy ? null : _pickAndUploadAvatar,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child:
                                  _busy
                                      ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Icon(
                                        Icons.photo_camera_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      headerName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((displayName?.isNotEmpty ?? false))
                      Text(
                        email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            emailVerified
                                ? 'ยืนยันอีเมลแล้ว'
                                : 'ยังไม่ยืนยันอีเมล',
                          ),
                          avatar: Icon(
                            emailVerified
                                ? Icons.verified
                                : Icons.mark_email_unread,
                            size: 18,
                            color:
                                emailVerified
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.error,
                          ),
                          side: BorderSide(
                            color:
                                emailVerified
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.error,
                          ),
                        ),
                        Chip(
                          label: Text('ประวัติการคำนวณ: $calcCount ครั้ง'),
                          avatar: const Icon(Icons.history, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Contact
              _Section(
                title: 'ข้อมูลติดต่อ',
                children: [
                  _Tile(icon: Icons.mail, title: 'อีเมล', value: email),
                  _Tile(
                    icon: Icons.phone,
                    title: 'โทรศัพท์',
                    value: _dash(phone),
                  ),
                  if (createdAt != null)
                    _Tile(
                      icon: Icons.calendar_month,
                      title: 'เริ่มใช้งาน',
                      value: _fmtDate(createdAt),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // Company
              _Section(
                title: 'ข้อมูลบริษัท',
                children: [
                  _Tile(
                    icon: Icons.business,
                    title: 'บริษัท',
                    value: _dash(companyName),
                  ),
                  _Tile(
                    icon: Icons.apartment,
                    title: 'แผนก',
                    value: _dash(department),
                  ),
                  _Tile(
                    icon: Icons.workspace_premium,
                    title: 'ตำแหน่ง',
                    value: _dash(position),
                  ),
                  _Tile(
                    icon: Icons.badge,
                    title: 'รหัสพนักงาน',
                    value: _dash(employeeId),
                  ),
                  _Tile(
                    icon: Icons.location_on,
                    title: 'ไซต์/พื้นที่',
                    value: _dash(site),
                  ),
                  _Tile(
                    icon: Icons.perm_contact_calendar,
                    title: 'หัวหน้างาน',
                    value: _dash(supName),
                  ),
                  _Tile(
                    icon: Icons.call,
                    title: 'เบอร์หัวหน้า',
                    value: _dash(supPhone),
                  ),
                  _Tile(
                    icon: Icons.chat,
                    title: 'LINE ID',
                    value: _dash(lineId),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('แก้ไขโปรไฟล์'),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _fmtDate(Timestamp ts) {
    final d = ts.toDate();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  static String _dash(String v) => v.trim().isEmpty ? '-' : v.trim();
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _Tile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: theme.textTheme.bodyMedium),
      trailing: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
