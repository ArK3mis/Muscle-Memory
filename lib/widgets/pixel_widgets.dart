import 'package:flutter/material.dart';

import '../theme/pixel_theme.dart';

/// Square box with a thick border and a hard (no blur) shadow.
/// The shadow sticks out [shadow] px to the right and bottom.
class PixelCard extends StatelessWidget {
  const PixelCard({
    super.key,
    required this.child,
    this.color = PX.white,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
    this.shadow = PX.shadow,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double shadow;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: PX.ink, width: PX.border),
        boxShadow: [BoxShadow(color: PX.ink, offset: Offset(shadow, shadow))],
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: box,
    );
  }
}

/// Chunky button that "presses down" into its shadow.
/// It reserves room for its own shadow, so no extra padding is needed.
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = PX.lime,
    this.icon,
    this.small = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final bool small;
  final bool expand;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final depth = widget.small ? 3.0 : 4.0;
    final pressed = _down ? depth : 0.0;

    return Padding(
      padding: EdgeInsets.only(right: depth, bottom: depth),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          transform: Matrix4.translationValues(pressed, pressed, 0),
          padding: EdgeInsets.symmetric(
            horizontal: widget.small ? 10 : 16,
            vertical: widget.small ? 8 : 14,
          ),
          decoration: BoxDecoration(
            color: widget.color,
            border: Border.all(color: PX.ink, width: PX.border),
            boxShadow: [
              BoxShadow(
                color: PX.ink,
                offset: Offset(depth - pressed, depth - pressed),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null)
                Icon(widget.icon, size: widget.small ? 14 : 18, color: PX.ink),
              if (widget.icon != null && widget.label.isNotEmpty)
                const SizedBox(width: 8),
              if (widget.label.isNotEmpty)
                Flexible(
                  child: Text(
                    widget.label.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: PX.title(widget.small ? 8 : 10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small label box, e.g. "4 x 10" or "Lats".
class PixelTag extends StatelessWidget {
  const PixelTag(this.text, {super.key, this.color = PX.yellow});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: PX.ink, width: 2),
      ),
      child: Text(text, style: PX.body(12, weight: FontWeight.w700)),
    );
  }
}

/// Filter / choice chip.
class PixelChip extends StatelessWidget {
  const PixelChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = PX.lime,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : PX.white,
          border: Border.all(color: PX.ink, width: PX.border),
          boxShadow: selected
              ? null
              : const [BoxShadow(color: PX.ink, offset: Offset(3, 3))],
        ),
        child: Text(label.toUpperCase(), style: PX.title(9)),
      ),
    );
  }
}

/// Row of little blocks that fill up as exercises get ticked.
class PixelProgress extends StatelessWidget {
  const PixelProgress({
    super.key,
    required this.done,
    required this.total,
    this.blocks = 10,
    this.color = PX.lime,
    this.expand = false,
  });

  final int done;
  final int total;
  final int blocks;
  final Color color;

  /// When true the blocks stretch to fill the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final filled = total == 0 ? 0 : (done / total * blocks).round();
    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: List.generate(blocks, (i) {
        final block = Container(
          width: expand ? null : 12,
          height: 14,
          margin: EdgeInsets.only(right: i == blocks - 1 ? 0 : 3),
          decoration: BoxDecoration(
            color: i < filled ? color : PX.white,
            border: Border.all(color: PX.ink, width: 2),
          ),
        );
        return expand ? Expanded(child: block) : block;
      }),
    );
  }
}

class PixelCheck extends StatelessWidget {
  const PixelCheck({super.key, required this.checked, required this.onTap});

  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: checked ? PX.lime : PX.white,
          border: Border.all(color: PX.ink, width: PX.border),
        ),
        child: checked
            ? const Icon(Icons.check, size: 20, color: PX.ink)
            : null,
      ),
    );
  }
}

OutlineInputBorder _pixelBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: color, width: PX.border),
    );

InputDecoration pixelInputDecoration({String? hint, Widget? prefixIcon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: PX.body(15, color: PX.grey),
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: PX.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: _pixelBorder(PX.ink),
    enabledBorder: _pixelBorder(PX.ink),
    focusedBorder: _pixelBorder(PX.blue),
    errorBorder: _pixelBorder(PX.pink),
    focusedErrorBorder: _pixelBorder(PX.pink),
  );
}

Future<T?> showPixelDialog<T>(BuildContext context, {required Widget child}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.only(right: PX.shadow, bottom: PX.shadow),
        child: PixelCard(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
}

Future<bool> showPixelConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Yes',
}) async {
  final result = await showPixelDialog<bool>(
    context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: PX.title(12)),
        const SizedBox(height: 12),
        Text(message, style: PX.body(15)),
        const SizedBox(height: 18),
        Builder(
          builder: (ctx) => Row(
            children: [
              Expanded(
                child: PixelButton(
                  label: 'Cancel',
                  color: PX.white,
                  expand: true,
                  onPressed: () => Navigator.pop(ctx, false),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: PixelButton(
                  label: confirmLabel,
                  color: PX.pink,
                  expand: true,
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showPixelSnack(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: PX.yellow,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: PX.ink, width: PX.border),
      ),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      content: Text(message, style: PX.body(15, weight: FontWeight.w700)),
      action: actionLabel == null
          ? null
          : SnackBarAction(
              label: actionLabel,
              textColor: PX.ink,
              onPressed: onAction ?? () {},
            ),
    ),
  );
}

/// Bottom navigation bar with pixel styling.
class PixelNavBar extends StatelessWidget {
  const PixelNavBar({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    ('Week', Icons.calendar_month),
    ('Muscle', Icons.fitness_center),
    ('Food', Icons.restaurant),
    ('Coach', Icons.forum),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PX.white,
        border: Border(top: BorderSide(color: PX.ink, width: PX.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: List.generate(_items.length, (i) {
              final selected = i == index;
              final item = _items[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? PX.lime : Colors.transparent,
                      border: Border.all(
                        color: selected ? PX.ink : Colors.transparent,
                        width: PX.border,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.$2, size: 22, color: PX.ink),
                        const SizedBox(height: 4),
                        Text(item.$1.toUpperCase(), style: PX.title(8)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
