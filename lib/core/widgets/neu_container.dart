import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/neumorphic_theme.dart';
import '../constants/app_sizes.dart';

class NeuContainer extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isPressed;
  final double? width;
  final double? height;

  const NeuContainer({
    super.key,
    required this.child,
    this.borderRadius = AppSizes.radiusMd,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.onLongPress,
    this.isPressed = false,
    this.width,
    this.height,
  });

  @override
  State<NeuContainer> createState() => _NeuContainerState();
}

class _NeuContainerState extends State<NeuContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isTapDown = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isTapDown = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isTapDown = false);
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isTapDown = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNeon = AppColors.isNeonTheme(context);
    final isActive = _isTapDown || widget.isPressed;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.width,
          height: widget.height,
          padding: widget.padding ?? const EdgeInsets.all(AppSizes.md),
          margin: widget.margin,
          decoration: isActive
              ? NeumorphicDecoration.pressed(
                  isDark: isDark,
                  isNeon: isNeon,
                  borderRadius: widget.borderRadius,
                  color: widget.color,
                )
              : NeumorphicDecoration.raised(
                  isDark: isDark,
                  isNeon: isNeon,
                  borderRadius: widget.borderRadius,
                  color: widget.color,
                ),
          child: widget.child,
        ),
      ),
    );
  }
}
