import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';

enum ButtonType { primary, secondary, outline, text }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;
  final double? elevation;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.width,
    this.height,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.elevation,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Color getBackgroundColor() {
    if (widget.backgroundColor != null) return widget.backgroundColor!;
    switch (widget.type) {
      case ButtonType.primary:
        return AppColors.primary;
      case ButtonType.secondary:
        return AppColors.secondary;
      case ButtonType.outline:
        return Colors.transparent;
      case ButtonType.text:
        return Colors.transparent;
    }
  }

  Color getTextColor() {
    if (widget.textColor != null) return widget.textColor!;
    switch (widget.type) {
      case ButtonType.primary:
      case ButtonType.secondary:
        return AppColors.textOnPrimary;
      case ButtonType.outline:
      case ButtonType.text:
        return AppColors.primary;
    }
  }

  Color getBorderColor() {
    switch (widget.type) {
      case ButtonType.primary:
      case ButtonType.secondary:
      case ButtonType.text:
        return Colors.transparent;
      case ButtonType.outline:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(getTextColor()),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: getTextColor()),
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: AppStyles.button.copyWith(color: getTextColor()),
        ),
      ],
    );

    if (_controller == null || _scaleAnimation == null) {
      // Return a simple container if animations aren't initialized yet
      return Container(
        width: widget.isFullWidth ? double.infinity : widget.width,
        height: widget.height ?? 48,
        padding: widget.padding ?? const EdgeInsets.symmetric(
          horizontal: AppStyles.spacing24,
          vertical: AppStyles.spacing12,
        ),
        decoration: BoxDecoration(
          color: getBackgroundColor(),
          borderRadius: BorderRadius.circular(widget.borderRadius ?? AppStyles.radius8),
          border: Border.all(
            color: getBorderColor(),
            width: widget.type == ButtonType.outline ? 1.5 : 0,
          ),
        ),
        child: Center(child: buttonChild),
      );
    }

    Widget button = AnimatedBuilder(
      animation: _scaleAnimation!,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation!.value,
          child: Container(
            width: widget.isFullWidth ? double.infinity : widget.width,
            height: widget.height ?? 48,
            padding: widget.padding ?? const EdgeInsets.symmetric(
              horizontal: AppStyles.spacing24,
              vertical: AppStyles.spacing12,
            ),
            decoration: BoxDecoration(
              color: getBackgroundColor(),
              borderRadius: BorderRadius.circular(widget.borderRadius ?? AppStyles.radius8),
              border: Border.all(
                color: getBorderColor(),
                width: widget.type == ButtonType.outline ? 1.5 : 0,
              ),
              boxShadow: widget.elevation != null && widget.elevation! > 0
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: _isPressed ? 0.15 : 0.1),
                        offset: Offset(0, _isPressed ? 1 : 2),
                        blurRadius: widget.elevation!,
                        spreadRadius: _isPressed ? -1 : 0,
                      ),
                    ]
                  : widget.type == ButtonType.primary || widget.type == ButtonType.secondary
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: _isPressed ? 0.2 : 0.12),
                            offset: Offset(0, _isPressed ? 2 : 4),
                            blurRadius: 8,
                            spreadRadius: _isPressed ? -1 : 0,
                          ),
                        ]
                      : null,
            ),
            child: Center(child: buttonChild),
          ),
        );
      },
    );

    if (widget.onPressed != null && !widget.isLoading) {
      return GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller?.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller?.reverse();
          widget.onPressed?.call();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller?.reverse();
        },
        child: button,
      );
    }

    return button;
  }
}

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final double? iconSize;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.iconSize,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Container(
      width: size ?? 40,
      height: size ?? 40,
      padding: padding ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(borderRadius ?? AppStyles.radius8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: iconSize ?? 20,
        color: iconColor ?? AppColors.textPrimary,
      ),
    );

    if (onPressed != null) {
      return GestureDetector(
        onTap: onPressed,
        child: button,
      );
    }

    return button;
  }
}

class CustomFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;

  const CustomFloatingActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: iconColor ?? AppColors.textOnPrimary,
      elevation: 4,
      child: Icon(icon, size: size ?? 24),
    );
  }
}
