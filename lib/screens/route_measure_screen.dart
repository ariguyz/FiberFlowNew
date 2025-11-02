// lib/screens/route_measure_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../repositories/fiber_repository.dart';

class RouteMeasureScreen extends StatefulWidget {
  final String cableId;
  const RouteMeasureScreen({super.key, required this.cableId});

  @override
  State<RouteMeasureScreen> createState() => _RouteMeasureScreenState();
}

class _RouteMeasureScreenState extends State<RouteMeasureScreen> {
  final _loc = LocationService();
  final _repo = FiberRepository();

  Position? _start;
  Position? _end;
  bool _busy = false;
  String? _info;

  double? get _distanceM {
    if (_start == null || _end == null) return null;
    return Geolocator.distanceBetween(
      _start!.latitude,
      _start!.longitude,
      _end!.latitude,
      _end!.longitude,
    );
  }

  Future<void> _pickStart() async {
    setState(() {
      _busy = true;
      _info = null;
    });
    final p = await _loc.getCurrentPosition();
    setState(() {
      _busy = false;
      if (p == null) {
        _info =
            'ไม่ได้ตำแหน่ง A\n• โปรดเปิด Location และให้สิทธิ์แอป\n• หากใช้ Emulator ให้ตั้งพิกัดในแถบ “Location”';
      } else {
        _start = p;
        _end = null; // รีเซ็ต B เพื่อกันสับสน
        _info =
            'ตั้งจุดเริ่มแล้ว: (${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)})';
      }
    });
  }

  Future<void> _pickEndAndSave() async {
    if (_start == null) {
      setState(() => _info = 'กรุณาตั้งจุดเริ่ม (A) ก่อน');
      return;
    }
    setState(() {
      _busy = true;
      _info = null;
    });

    final p = await _loc.getCurrentPosition();
    if (p == null) {
      setState(() {
        _busy = false;
        _info =
            'ไม่ได้ตำแหน่ง B\n• โปรดเปิด Location และให้สิทธิ์แอป\n• หากใช้ Emulator ให้ตั้งพิกัดก่อน';
      });
      return;
    }
    _end = p;

    final d = Geolocator.distanceBetween(
      _start!.latitude,
      _start!.longitude,
      _end!.latitude,
      _end!.longitude,
    );

    final ref = await _repo.upsertFiber(cableId: widget.cableId);
    await _repo.saveRoute(
      docId: ref.id,
      latA: _start!.latitude,
      lngA: _start!.longitude,
      latB: _end!.latitude,
      lngB: _end!.longitude,
      distance: d,
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _info = 'บันทึกสำเร็จ: ${d.toStringAsFixed(2)} m';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('บันทึกระยะทางแล้ว: ${d.toStringAsFixed(2)} m')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('วัดระยะสาย • ${widget.cableId}')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // SUMMARY
                _SummaryCard(start: _start, end: _end, distanceM: _distanceM),
                const SizedBox(height: 14),

                // STEP A
                _StepCard(
                  step: 'ขั้นที่ 1',
                  icon: Icons.play_arrow_rounded,
                  title: 'จุดเริ่ม (A)',
                  subtitle:
                      _start == null
                          ? 'ยังไม่ได้ตั้ง'
                          : '(${_start!.latitude.toStringAsFixed(6)}, ${_start!.longitude.toStringAsFixed(6)})',
                  actionText: 'ตั้ง A',
                  onPressed: _pickStart,
                  accentColor: cs.primary,
                ),
                const SizedBox(height: 10),

                // STEP B
                _StepCard(
                  step: 'ขั้นที่ 2',
                  icon: Icons.flag_rounded,
                  title: 'จุดสิ้นสุด (B)',
                  subtitle:
                      _end == null
                          ? 'ยังไม่ได้ตั้ง'
                          : '(${_end!.latitude.toStringAsFixed(6)}, ${_end!.longitude.toStringAsFixed(6)})',
                  actionText: 'ตั้ง B & บันทึก',
                  onPressed: _start == null ? null : _pickEndAndSave,
                  accentColor: cs.secondary,
                  disabledHint: 'กรุณาตั้งจุดเริ่ม (A) ก่อน',
                ),

                if (_info != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Text(
                      _info!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ],
            ),

            if (_busy)
              const Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        ),
      ),
    );
  }
}

// ================== UI widgets ==================

class _SummaryCard extends StatelessWidget {
  final Position? start;
  final Position? end;
  final double? distanceM;
  const _SummaryCard({
    required this.start,
    required this.end,
    required this.distanceM,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasBoth = start != null && end != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('สรุปพิกัด', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _ChipStat(
                  label: 'A',
                  value:
                      start == null
                          ? 'ยังไม่ได้ตั้ง'
                          : '${start!.latitude.toStringAsFixed(5)}, ${start!.longitude.toStringAsFixed(5)}',
                  color: cs.primary,
                ),
                _ChipStat(
                  label: 'B',
                  value:
                      end == null
                          ? 'ยังไม่ได้ตั้ง'
                          : '${end!.latitude.toStringAsFixed(5)}, ${end!.longitude.toStringAsFixed(5)}',
                  color: cs.secondary,
                ),
                _ChipStat(
                  label: 'ระยะทาง',
                  value:
                      distanceM == null
                          ? '—'
                          : '${distanceM!.toStringAsFixed(2)} m',
                  color: hasBoth ? cs.tertiary : cs.outline,
                  icon: Icons.straighten,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;
  const _ChipStat({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color.withOpacity(.15),
            child: Icon(icon ?? Icons.place, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            '$label : ',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback? onPressed;
  final Color accentColor;
  final String? disabledHint;

  const _StepCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onPressed,
    required this.accentColor,
    this.disabledHint,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = onPressed == null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    step,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(icon, color: accentColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onPressed,
                    icon: Icon(
                      Icons.my_location,
                      color: disabled ? cs.onPrimary.withOpacity(.8) : null,
                    ),
                    label: Text(actionText),
                  ),
                ),
              ],
            ),
            if (disabled && (disabledHint?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Text(
                disabledHint!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
