// lib/widgets/multi_result_card.dart
import 'package:flutter/material.dart';

class MultiResultCard extends StatelessWidget {
  final int n;
  final int tubeIndex;
  final int coreIndex;
  final String tubeColorName;
  final String coreColorName;

  /// กลุ่มท่อ (12 ท่อ/กลุ่ม) เริ่มที่ 1
  final int groupIndex;

  /// เลขแถบ: groupIndex - 1  (0=ไม่มีแถบ, 1=แถบที่1, …)
  final int stripeIndex;

  final bool saving;
  final VoidCallback onSave;

  final Color Function(String name) colorFor;
  final Color Function(Color bg) onColorFor;

  const MultiResultCard({
    super.key,
    required this.n,
    required this.tubeIndex,
    required this.coreIndex,
    required this.tubeColorName,
    required this.coreColorName,
    required this.groupIndex,
    required this.stripeIndex,
    required this.saving,
    required this.onSave,
    required this.colorFor,
    required this.onColorFor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final tubeBg = colorFor(tubeColorName);
    final tubeOn = onColorFor(tubeBg);
    final coreBg = colorFor(coreColorName);
    final coreOn = onColorFor(coreBg);

    Border? _borderIfBright(Color bg) =>
        bg.computeLuminance() > 0.7 ? Border.all(color: cs.outline) : null;

    Widget _chip(String text, {IconData? icon}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: cs.onSecondaryContainer),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              color: cs.onSecondaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แถวหัวการ์ด
            Row(
              children: [
                _chip('Core #$n'),
                const Spacer(),
                Text(
                  'ผลลัพธ์',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ====== TUBE ======
            Text('Tube ที่', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: tubeBg,
                borderRadius: BorderRadius.circular(12),
                border: _borderIfBright(tubeBg),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 18, color: tubeOn),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tube $tubeIndex   •   สี $tubeColorName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tubeOn,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ====== แถบสี + Tube Group (ย้ายมาต่อท้ายแถบ) ======
            Row(
              children: [
                Text('แถบสี', style: theme.textTheme.labelLarge),
                const SizedBox(width: 8),
                // ไม่โชว์สี่เหลี่ยมสีดำอีกต่อไป — เหลือเฉพาะคำว่า "แถบที่ X"
                _chip(
                  stripeIndex == 0 ? 'ไม่มีแถบ' : 'แถบที่ $stripeIndex',
                  icon: Icons.info_outline,
                ),
                const SizedBox(width: 10),
                Text('•', style: theme.textTheme.labelLarge),
                const SizedBox(width: 10),
                Text(
                  'Tube Group $groupIndex',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ====== CORE ======
            Text('Core', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: coreBg,
                borderRadius: BorderRadius.circular(12),
                border: _borderIfBright(coreBg),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 18, color: coreOn),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Core $coreIndex   •   สี $coreColorName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: coreOn,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon:
                    saving
                        ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save_alt_rounded),
                label: const Text('บันทึกผล'),
              ),
            ),
            const SizedBox(height: 4),

            // หมายเหตุ
            Text(
              'ความหมาย:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '• ท่อที่ $tubeIndex (สี $tubeColorName, Group $groupIndex'
              '${stripeIndex == 0 ? ', ไม่มีแถบ' : ', แถบที่ $stripeIndex'})  '
              '• คอร์ที่ $coreIndex (สี $coreColorName)',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
