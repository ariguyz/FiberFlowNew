// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _svc = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calculation History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {}, // ให้ AppBar อยู่สวย ๆ / ใช้ Hot Reload แทน
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        //  ดึงเฉพาะของผู้ใช้ปัจจุบันเท่านั้น
        stream: _svc.getUserHistoryStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text("Error loading history"));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("ยังไม่มีข้อมูลที่บันทึก"));
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
              );
            },
          );
        },
      ),
    );
  }
}
