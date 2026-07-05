import 'package:flutter/material.dart';

class HoverScaleWidget extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  final VoidCallback? onTap;

  const HoverScaleWidget({
    super.key,
    required this.child,
    this.scale = 1.03,
    this.duration = const Duration(milliseconds: 180),
    this.onTap,
  });

  @override
  State<HoverScaleWidget> createState() => _HoverScaleWidgetState();
}

class _HoverScaleWidgetState extends State<HoverScaleWidget> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = _isHovered || _isPressed;
    final double currentScale = active ? widget.scale : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..scale(currentScale),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    )
                  ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
