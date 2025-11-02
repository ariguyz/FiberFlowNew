import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../repositories/fiber_repository.dart';
import 'core_visualization_screen.dart';
import 'route_measure_screen.dart';
import 'tube_planner_screen.dart';

class CableDetailScreen extends StatelessWidget {
  final String cableId;
  const CableDetailScreen({super.key, required this.cableId});

  @override
  Widget build(BuildContext context) {
    final repo = FiberRepository();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Cable: $cableId')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: repo.watchFiberByCableId(cableId),
        builder: (context, snap) {
          final data = (snap.data?.data()) ?? {};
          final distance = (data['distance'] as num?)?.toDouble() ?? 0.0;
          final start = data['startPoint'];
          final end = data['endPoint'];

          final tubesCount = (data['tubesCount'] as int?) ?? 0;
          final coresPerTube = (data['coresPerTube'] as int?) ?? 0;
          final totalFromField = (data['totalCores'] as int?) ?? 0;
          final hasStructure = tubesCount > 0 && coresPerTube > 0;
          final totalCores =
              totalFromField > 0
                  ? totalFromField
                  : (hasStructure ? tubesCount * coresPerTube : 24);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _InfoCard(
                title: 'สรุปสาย',
                subtitle: 'ข้อมูลล่าสุดของสาย $cableId',
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${distance.toStringAsFixed(2)} m',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (hasStructure)
                      Text(
                        '$tubesCount ท่อ × $coresPerTube คอร์ = $totalCores คอร์',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ระยะที่บันทึก',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (start != null && end != null)
                      Text(
                        'A: (${start['lat']}, ${start['lng']})  •  B: (${end['lat']}, ${end['lng']})',
                        style: theme.textTheme.bodySmall,
                      )
                    else
                      Text(
                        'ยังไม่มีพิกัดที่บันทึก',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Text('เครื่องมือ', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),

              _ActionTile(
                icon: Icons.view_column_rounded,
                title: 'กำหนดโครงสร้างสาย (Tube Planner)',
                subtitle:
                    'ระบุจำนวนท่อ และจำนวนคอร์/ท่อ แล้วบันทึกลง Firestore',
                outlined: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TubePlannerScreen(cableId: cableId),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              _ActionTile(
                icon: Icons.grid_view_rounded,
                title: 'จัดการคอร์ (ตามโครงสร้าง)',
                subtitle:
                    'จะแสดง $totalCores คอร์'
                    '${hasStructure ? " • จาก $tubesCount ท่อ × $coresPerTube" : " • (ค่าเริ่มต้น 24)"}',
                outlined: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CoreVisualizationScreen(cableId: cableId),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              _ActionTile(
                icon: Icons.straighten_rounded,
                title: 'วัดระยะสาย A → B (GPS)',
                subtitle: 'ตั้งพิกัด A/B แล้วบันทึกระยะลง Firestore',
                outlined: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteMeasureScreen(cableId: cableId),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget? body;

  const _InfoCard({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.show_chart_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สรุปสาย',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (body != null) ...[const SizedBox(height: 12), body!],
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final radius = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    final content = Row(
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    );

    if (outlined) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          shape: radius,
          side: BorderSide(color: cs.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          foregroundColor: cs.onSurface,
        ),
        onPressed: onTap,
        child: content,
      );
    }

    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        shape: radius,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        elevation: 0,
      ),
      onPressed: onTap,
      child: content,
    );
  }
}
