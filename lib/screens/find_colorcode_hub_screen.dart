// lib/screens/find_colorcode_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/theme_notifier.dart';
import 'home_screen.dart';

class FindColorCodeHubScreen extends StatefulWidget {
  const FindColorCodeHubScreen({super.key});
  @override
  State<FindColorCodeHubScreen> createState() => _FindColorCodeHubScreenState();
}

class _FindColorCodeHubScreenState extends State<FindColorCodeHubScreen> {
  _JacketItem? _selected;

  // สีแจ็กเก็ตตาม TIA-598-C ที่ใช้บ่อย
  final List<_JacketItem> _jackets = const [
    _JacketItem('OS1', Color(0xFFF7E300), 'Single-mode (OS1) — Yellow'),
    _JacketItem('OS2', Color(0xFFF7E300), 'Single-mode (OS2) — Yellow'),
    _JacketItem('OM1', Color(0xFFF08A00), 'Multi-mode (OM1) — Orange'),
    _JacketItem('OM2', Color(0xFFFFA040), 'Multi-mode (OM2) — Orange'),
    _JacketItem('OM3', Color(0xFF00B8D4), 'Multi-mode (OM3) — Aqua'),
    _JacketItem('OM4', Color(0xFF7E57C2), 'Multi-mode (OM4) — Violet'),
    _JacketItem('OM5', Color(0xFF9CCC00), 'Wideband MMF (OM5) — Lime Green'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            tooltip: 'สลับธีม',
            icon: Icon(
              themeNotifier.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () => themeNotifier.toggleTheme(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: cs.outlineVariant),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // โลโก้
                  Image.asset('assets/images/logofiberflow.png', height: 64),
                  const SizedBox(height: 8),

                  // ===== กลุ่มท่อ/คอร์ =====
                  _Title('Find Color Code of Tube and Fiber'),
                  const SizedBox(height: 12),
                  _BigCardButton(
                    label: 'Single Loose Tube',
                    icon: Icons.radio_button_checked_outlined,
                    onTap:
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Single Loose Tube (เร็วๆ นี้)'),
                          ),
                        ),
                  ),
                  const SizedBox(height: 14),
                  _BigCardButton(
                    label: 'Multi Loose Tube',
                    icon: Icons.blur_circular_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ===== กลุ่มสีสายแจ็กเก็ต =====
                  _Title('Find Cable Color of outer Jacket Cable'),
                  const SizedBox(height: 10),

                  // ชิป 2 คอลัมน์ + จุดสีบนชิป
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        _jackets.map((item) {
                          final selected = _selected?.name == item.name;
                          return _JacketChip(
                            item: item,
                            selected: selected,
                            onTap: () => setState(() => _selected = item),
                          );
                        }).toList(),
                  ),

                  // แถบพรีวิวเต็มความกว้าง
                  if (_selected != null) ...[
                    const SizedBox(height: 14),
                    _PreviewBar(item: _selected!),
                  ],

                  const SizedBox(height: 28),

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

/* ===== Widgets ===== */

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: cs.onSurface,
      ),
    );
  }
}

class _BigCardButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _BigCardButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      elevation: 1.5,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black.withOpacity(.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 108,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: cs.primary),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JacketChip extends StatelessWidget {
  final _JacketItem item;
  final bool selected;
  final VoidCallback onTap;
  const _JacketChip({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // ทำให้กว้างพอสำหรับ 2 คอลัมน์
    final double w = (MediaQuery.of(context).size.width - 20 * 2 - 10) / 2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w, // ช่วยจัดเป็น 2 คอลัมน์พอดี ๆ
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // จุดสี
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.black12),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.name,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? cs.primary : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewBar extends StatelessWidget {
  final _JacketItem item;
  const _PreviewBar({required this.item});

  Color _on(Color bg) =>
      bg.computeLuminance() > 0.7 ? Colors.black : Colors.white;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showBorder = item.color.computeLuminance() > 0.7;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(14),
        border: showBorder ? Border.all(color: cs.outline) : null,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _on(item.color),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.note,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: _on(item.color),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ===== Model ===== */
class _JacketItem {
  final String name;
  final Color color;
  final String note;
  const _JacketItem(this.name, this.color, this.note);
}
