// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    this.typeFilter, // 'multi' | 'single' | null = แสดงทั้งหมด
  });

  final String? typeFilter;

  bool _matchType(Map<String, dynamic> data) {
    if (typeFilter == null) return true;

    // ถ้ามี calcType ก็ใช้เลย
    final type = (data['calcType'] as String?)?.toLowerCase();
    if (type != null) return type == typeFilter;

    // ถ้า record เก่าไม่มี calcType → เดาตามรูปแบบข้อความ
    final result = (data['result'] as String? ?? '').toLowerCase();
    final looksMulti = result.startsWith('tube ') && result.contains('| core ');
    final looksSingle = result.startsWith('single tube | core');

    if (typeFilter == 'multi') return looksMulti && !looksSingle;
    if (typeFilter == 'single') return looksSingle && !looksMulti;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final svc = FirestoreService();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          typeFilter == null
              ? 'Calculation History'
              : 'Calculation History (${typeFilter!})',
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // ดึงทั้งหมดแล้วกรองฝั่ง client เพื่อครอบคลุมเรคคอร์ดเก่า
        stream: svc.getUserHistoryStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Error loading history'));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snap.data?.docs ?? [];
          final docs = all.where((d) => _matchType(d.data())).toList();

          if (docs.isEmpty) {
            return Center(
              child: Text(
                'ยังไม่มีข้อมูลที่บันทึก',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final inputValue = data['inputValue'];
              final result = data['result'] as String? ?? '';
              final ts = data['timestamp'] as Timestamp?;
              final when =
                  ts != null ? ts.toDate().toString().substring(0, 16) : '';

              return ListTile(
                leading: Icon(Icons.history, color: cs.primary),
                title: Text('Core: $inputValue'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result),
                    const SizedBox(height: 4),
                    if (when.isNotEmpty)
                      Text(when, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
