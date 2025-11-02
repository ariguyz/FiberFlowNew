// lib/screens/admin_user_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final String userId;
  final String userEmail;
  const AdminUserDetailScreen({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final _svc = FirestoreService();
  String _roleSaving = '';

  Future<void> _changeRole(String role) async {
    setState(() => _roleSaving = role);
    try {
      await _svc.updateUserRole(userId: widget.userId, role: role);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ปรับ role เป็น "$role" เรียบร้อย')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เปลี่ยน role ไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _roleSaving = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userEmail),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.security, color: Colors.black),
            onSelected: _changeRole,
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'user',
                    child: Text('ตั้งเป็น user'),
                  ),
                  const PopupMenuItem(
                    value: 'admin',
                    child: Text('ตั้งเป็น admin'),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_roleSaving.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.black12,
              padding: const EdgeInsets.all(8),
              child: Text(
                'กำลังบันทึก role: $_roleSaving',
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _svc.getUserCalculationsStream(widget.userId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return const Center(child: Text('โหลดประวัติไม่ได้'));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('ยังไม่มีประวัติของผู้ใช้นี้'),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data();
                    final inputValue = data['inputValue'];
                    final result = data['result'] as String? ?? '';
                    final ts = data['timestamp'] as Timestamp?;
                    final when =
                        ts != null
                            ? ts.toDate().toString().substring(0, 16)
                            : '';

                    return ListTile(
                      leading: const Icon(Icons.history, color: Colors.black),
                      title: Text("Core: $inputValue"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(result),
                          const SizedBox(height: 4),
                          if (when.isNotEmpty)
                            Text(when, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.black,
                        ),
                        onPressed: () async {
                          try {
                            await _svc.deleteHistory(
                              ownerUid: widget.userId,
                              docId: doc.id,
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
