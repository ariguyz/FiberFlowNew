import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../repositories/fiber_repository.dart';
import '../models/core_status.dart';

class CoreVisualizationScreen extends StatelessWidget {
  final String cableId;
  const CoreVisualizationScreen({super.key, required this.cableId});

  @override
  Widget build(BuildContext context) {
    // กัน text scale ใหญ่เกินจน layout ล้น
    final media = MediaQuery.of(context);
    final clampedMedia = media.copyWith(
      textScaler: media.textScaler.clamp(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.1,
      ),
    );

    final repo = FiberRepository();

    return MediaQuery(
      data: clampedMedia,
      child: Scaffold(
        appBar: AppBar(title: Text('Core Visualization • $cableId')),
        body: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: repo.watchFiberByCableId(cableId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData || !snap.data!.exists) {
                return const Center(child: Text('กำลังเตรียมข้อมูล...'));
              }

              final doc = snap.data!;
              final data = doc.data()!;
              final cores = (data['cores'] ?? {}) as Map<String, dynamic>;
              final docId = doc.id;

              // 👇 จำนวนคอร์จริงจาก Firestore; ถ้าไม่มีให้ fallback เป็น 24
              final tubesCount = (data['tubesCount'] as int?) ?? 0;
              final coresPerTube = (data['coresPerTube'] as int?) ?? 0;
              final totalFromField = (data['totalCores'] as int?) ?? 0;
              final totalCores =
                  totalFromField > 0
                      ? totalFromField
                      : (tubesCount > 0 && coresPerTube > 0
                          ? tubesCount * coresPerTube
                          : 24);

              return LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  int cross = 4;
                  if (w >= 420) cross = 6;
                  if (w >= 720) cross = 8;

                  return CustomScrollView(
                    slivers: [
                      // แถบคำอธิบาย
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: _Legend(),
                        ),
                      ),

                      // แจ้งถ้ายังไม่ได้ตั้งโครงสร้าง (กำลังใช้ 24 ชั่วคราว)
                      if (tubesCount <= 0 || coresPerTube <= 0)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Card(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  'ยังไม่ได้ตั้งโครงสร้างสายใน Tube Planner — แสดง $totalCores คอร์เป็นค่าเริ่มต้น',
                                  style: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // กริดคอร์ (จำนวนตามจริง)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cross,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: .95,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final n = index + 1;
                              final raw = cores['$n']?.toString();
                              final s = parseCoreStatus(raw);

                              return _CoreTile(
                                number: n,
                                status: s,
                                onPick: () async {
                                  final picked = await _pickStatus(context, s);
                                  if (picked != null) {
                                    await repo.setCoreStatus(
                                      docId: docId,
                                      coreNumber: n,
                                      status: coreStatusToString(picked),
                                    );
                                  }
                                },
                              );
                            },
                            childCount: totalCores, // 👈 ใช้จำนวนคอร์ตามจริง
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<CoreStatus?> _pickStatus(BuildContext context, CoreStatus current) {
    return showModalBottomSheet<CoreStatus>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  CoreStatus.values.map((s) {
                    final selected = s == current;
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 10,
                        backgroundColor: coreColor(s),
                      ),
                      title: Text(
                        _prettyLabel(s),
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      trailing: selected ? const Icon(Icons.check) : null,
                      onTap: () => Navigator.pop(ctx, s),
                    );
                  }).toList(),
            ),
          ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget chip(Color c, String t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(.16),
        border: Border.all(color: c.withOpacity(.5)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          Text(t, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            chip(coreColor(CoreStatus.free), _prettyLabel(CoreStatus.free)),
            chip(coreColor(CoreStatus.used), _prettyLabel(CoreStatus.used)),
            chip(coreColor(CoreStatus.fault), _prettyLabel(CoreStatus.fault)),
          ],
        ),
      ),
    );
  }
}

class _CoreTile extends StatefulWidget {
  final int number;
  final CoreStatus status;
  final Future<void> Function() onPick;

  const _CoreTile({
    required this.number,
    required this.status,
    required this.onPick,
  });

  @override
  State<_CoreTile> createState() => _CoreTileState();
}

class _CoreTileState extends State<_CoreTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dot = coreColor(widget.status);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () async {
        await widget.onPick();
        if (mounted) setState(() => _pressed = false);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(.6),
          ),
          boxShadow:
              _pressed
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dot.withOpacity(.12),
                border: Border.all(color: dot, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '${widget.number}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: dot.withOpacity(.10),
                border: Border.all(color: dot.withOpacity(.55)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _prettyLabel(widget.status),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _prettyLabel(CoreStatus s) {
  switch (s) {
    case CoreStatus.used:
      return 'ใช้งานอยู่';
    case CoreStatus.fault:
      return 'เสีย/ขัดข้อง';
    case CoreStatus.free:
      return 'ว่าง';
  }
}
