// lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _db = FirebaseFirestore.instance;

  Future<int> _countUsers() async {
    try {
      final agg = await _db.collection('users').count().get();
      return agg.count ?? 0; //  บังคับ non-null
    } catch (_) {
      final q = await _db.collection('users').get();
      return q.size;
    }
  }

  Future<int> _countAllCalcs() async {
    try {
      final agg = await _db.collectionGroup('calculations').count().get();
      return agg.count ?? 0; //  บังคับ non-null
    } catch (_) {
      final q = await _db.collectionGroup('calculations').get();
      return q.size;
    }
  }

  Future<int> _countCalcsToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    try {
      final agg =
          await _db
              .collectionGroup('calculations')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .count()
              .get();
      return agg.count ?? 0; //  บังคับ non-null
    } catch (_) {
      final q =
          await _db
              .collectionGroup('calculations')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .get();
      return q.size;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _topUsersStream() {
    return _db
        .collection('users')
        .orderBy('calcCount', descending: true)
        .limit(10)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(title: 'Total Users', future: _countUsers()),
              _StatCard(title: 'Total Calculations', future: _countAllCalcs()),
              _StatCard(
                title: 'Today Calculations',
                future: _countCalcsToday(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Top Users (by calcCount)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _topUsersStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snap.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('โหลด Top Users ไม่ได้'),
                );
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('ไม่มีข้อมูล'),
                );
              }
              return Card(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    final email = (data['email'] as String?) ?? '-';
                    final count = (data['calcCount'] ?? 0).toString();
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          (email.isNotEmpty ? email[0] : '?').toUpperCase(),
                        ),
                      ),
                      title: Text(email),
                      trailing: Text(
                        count,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Future<int> future;
  const _StatCard({required this.title, required this.future});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<int>(
            future: future,
            builder: (context, snap) {
              final val =
                  snap.hasError
                      ? 'ERR'
                      : (snap.hasData ? snap.data.toString() : '...');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(val, style: Theme.of(context).textTheme.headlineSmall),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
