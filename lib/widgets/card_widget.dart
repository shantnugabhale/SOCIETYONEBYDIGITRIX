import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import '../constants/colors.dart';
import '../constants/styles.dart';

class CustomCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final double? borderRadius;
  final Color? borderColor;
  final double? borderWidth;
  final VoidCallback? onTap;
  final bool isClickable;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    this.onTap,
    this.isClickable = false,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _scaleAnimation == null) {
      // Return a simple container if animations aren't initialized yet
      return Container(
        margin: widget.margin ?? const EdgeInsets.all(AppStyles.spacing8),
        padding: widget.padding ?? const EdgeInsets.all(AppStyles.spacing16),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? AppColors.surface,
          borderRadius: BorderRadius.circular(widget.borderRadius ?? AppStyles.radius16),
          border: widget.borderColor != null
              ? Border.all(color: widget.borderColor!, width: widget.borderWidth ?? 1)
              : null,
          boxShadow: widget.elevation != null && widget.elevation! > 0
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06), // Softer shadow
                    offset: const Offset(0, 2),
                    blurRadius: widget.elevation! * 2, // Larger blur for diffused look
                    spreadRadius: -1, // Negative spread for softer edge
                  ),
                ]
              : AppStyles.shadowSmall,
        ),
        child: widget.child,
      );
    }

    Widget card = AnimatedBuilder(
      animation: _scaleAnimation!,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation!.value,
          child: Container(
            margin: widget.margin ?? const EdgeInsets.all(AppStyles.spacing8),
            padding: widget.padding ?? const EdgeInsets.all(AppStyles.spacing16),
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? AppColors.surface,
              borderRadius: BorderRadius.circular(widget.borderRadius ?? AppStyles.radius16),
              border: widget.borderColor != null
                  ? Border.all(color: widget.borderColor!, width: widget.borderWidth ?? 1)
                  : null,
              boxShadow: widget.elevation != null && widget.elevation! > 0
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: _isPressed ? 0.08 : 0.06),
                        offset: Offset(0, _isPressed ? 1 : 4),
                        blurRadius: widget.elevation! * 3,
                        spreadRadius: _isPressed ? -2 : 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : widget.isClickable
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: _isPressed ? 0.06 : 0.04),
                            offset: Offset(0, _isPressed ? 2 : 4),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            offset: const Offset(0, 1),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
            ),
            child: widget.child,
          ),
        );
      },
    );

    if (widget.isClickable && widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller?.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller?.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller?.reverse();
        },
        child: card,
      );
    }

    return card;
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;
  final VoidCallback? onTap;
  final bool isClickable;
  final double? iconSize;
  final double? textScaleFactor;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.onTap,
    this.isClickable = false,
    this.iconSize,
    this.textScaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = iconSize ?? 20.0;
    final effectiveTextScale = textScaleFactor ?? 1.0;
    
    return CustomCard(
      onTap: onTap,
      isClickable: isClickable || onTap != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: effectiveIconSize,
                  color: iconColor ?? AppColors.primary,
                ),
                SizedBox(width: AppStyles.spacing8 * effectiveTextScale),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppStyles.bodySmall.copyWith(
                    color: const Color.fromARGB(255, 106, 109, 116),
                    fontSize: AppStyles.bodySmall.fontSize! * effectiveTextScale,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppStyles.spacing8 * effectiveTextScale),
          Text(
            value,
            style: AppStyles.heading5.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: AppStyles.heading5.fontSize! * effectiveTextScale,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: AppStyles.spacing4 * effectiveTextScale),
            Text(
              subtitle!,
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textHint,
                fontSize: AppStyles.bodySmall.fontSize! * effectiveTextScale,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PaymentCard extends StatelessWidget {
  final String title;
  final String amount;
  final String status;
  final String dueDate;
  final Color? statusColor;
  final VoidCallback? onTap;
  final bool isClickable;

  const PaymentCard({
    super.key,
    required this.title,
    required this.amount,
    required this.status,
    required this.dueDate,
    this.statusColor,
    this.onTap,
    this.isClickable = true,
  });

  @override
  Widget build(BuildContext context) {
    Color getStatusColor() {
      if (statusColor != null) return statusColor!;
      switch (status.toLowerCase()) {
        case 'paid':
          return AppColors.success;
        case 'pending':
          return AppColors.warning;
        case 'overdue':
          return AppColors.error;
        default:
          return AppColors.textSecondary;
      }
    }

    return CustomCard(
      onTap: onTap,
      isClickable: isClickable,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacing8,
                  vertical: AppStyles.spacing4,
                ),
                decoration: BoxDecoration(
                  color: getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radius4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppStyles.caption.copyWith(
                    color: getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount',
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                amount,
                style: AppStyles.heading6.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Due Date',
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                dueDate,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NoticeCard extends StatelessWidget {
  final String title;
  final String content;
  final String category;
  final String priority;
  final String publishDate;
  final String? expiryDate;
  final bool isRead;
  final bool requiresAcknowledgment;
  final List<String> attachments;
  final Function(String)? onImageTap;
  final Function(String)? onPdfTap;
  final VoidCallback? onTap;
  final bool isClickable;

  const NoticeCard({
    super.key,
    required this.title,
    required this.content,
    required this.category,
    required this.priority,
    required this.publishDate,
    this.expiryDate,
    this.isRead = false,
    this.requiresAcknowledgment = false,
    this.attachments = const [],
    this.onImageTap,
    this.onPdfTap,
    this.onTap,
    this.isClickable = true,
  });

  bool _isImageUrl(String url) {
    final extension = url.split('.').last.toLowerCase().split('?').first;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  bool _isPdfUrl(String url) {
    final extension = url.split('.').last.toLowerCase().split('?').first;
    return extension == 'pdf';
  }

  List<String> get _imageAttachments => 
      attachments.where((url) => _isImageUrl(url)).toList();
  
  List<String> get _pdfAttachments => 
      attachments.where((url) => _isPdfUrl(url)).toList();

  @override
  Widget build(BuildContext context) {
    Color getPriorityColor() {
      switch (priority.toLowerCase()) {
        case 'urgent':
          return AppColors.error;
        case 'high':
          return AppColors.warning;
        case 'medium':
          return AppColors.info;
        case 'low':
          return AppColors.success;
        default:
          return AppColors.textSecondary;
      }
    }

    return CustomCard(
      onTap: onTap,
      isClickable: isClickable,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isRead ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
              ),
              if (priority.toLowerCase() == 'urgent' || priority.toLowerCase() == 'high')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyles.spacing8,
                    vertical: AppStyles.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: getPriorityColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppStyles.radius4),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: AppStyles.caption.copyWith(
                      color: getPriorityColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppStyles.spacing8),
          Text(
            content,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          // Images gallery - post-like display
          if (_imageAttachments.isNotEmpty) ...[
            const SizedBox(height: AppStyles.spacing12),
            _buildImageGallery(context),
          ],
          // PDF attachments - direct display like images
          if (_pdfAttachments.isNotEmpty) ...[
            const SizedBox(height: AppStyles.spacing12),
            _buildPdfDirectDisplay(context),
          ],
          const SizedBox(height: AppStyles.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.toUpperCase(),
                style: AppStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                publishDate,
                style: AppStyles.caption.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          if (requiresAcknowledgment) ...[
            const SizedBox(height: AppStyles.spacing8),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppStyles.spacing4),
                Text(
                  'Acknowledgment Required',
                  style: AppStyles.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    final images = _imageAttachments;
    if (images.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppStyles.radius12),
      child: images.length == 1
          ? _buildSingleImage(images[0], context)
          : images.length == 2
              ? _buildTwoImages(images, context)
              : images.length == 3
                  ? _buildThreeImages(images, context)
                  : _buildMultipleImages(images, context),
    );
  }

  Widget _buildSingleImage(String url, BuildContext context) {
    return GestureDetector(
      onTap: () => onImageTap?.call(url),
      child: Image.network(
        url,
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 250,
            color: AppColors.background,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 250,
            color: AppColors.background,
            child: const Center(
              child: Icon(Icons.broken_image, size: 48),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTwoImages(List<String> images, BuildContext context) {
    return Row(
      children: images.asMap().entries.map((entry) {
        final index = entry.key;
        final url = entry.value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onImageTap?.call(url),
            child: Container(
              height: 200,
              margin: EdgeInsets.only(
                right: index == 0 ? AppStyles.spacing4 : 0,
                left: index == 1 ? AppStyles.spacing4 : 0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppStyles.radius8),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.background,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.background,
                      child: const Center(
                        child: Icon(Icons.broken_image),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThreeImages(List<String> images, BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onImageTap?.call(images[0]),
                child: Container(
                  height: 150,
                  margin: const EdgeInsets.only(right: AppStyles.spacing4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppStyles.radius8),
                    child: Image.network(
                      images[0],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.background,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.background,
                          child: const Center(
                            child: Icon(Icons.broken_image),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onImageTap?.call(images[1]),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppStyles.spacing4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppStyles.radius8),
                          child: Image.network(
                            images[1],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: AppColors.background,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.background,
                                child: const Center(
                                  child: Icon(Icons.broken_image),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onImageTap?.call(images[2]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppStyles.radius8),
                        child: Image.network(
                          images[2],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppColors.background,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.background,
                              child: const Center(
                                child: Icon(Icons.broken_image),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMultipleImages(List<String> images, BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onImageTap?.call(images[0]),
                child: Container(
                  height: 150,
                  margin: const EdgeInsets.only(right: AppStyles.spacing4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppStyles.radius8),
                    child: Image.network(
                      images[0],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.background,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.background,
                          child: const Center(
                            child: Icon(Icons.broken_image),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onImageTap?.call(images[1]),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppStyles.spacing4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppStyles.radius8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                images[1],
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: AppColors.background,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.background,
                                    child: const Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  );
                                },
                              ),
                              if (images.length > 4)
                                Container(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  child: Center(
                                    child: Text(
                                      '+${images.length - 4}',
                                      style: AppStyles.heading6.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onImageTap?.call(images[2]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppStyles.radius8),
                        child: Image.network(
                          images[2],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppColors.background,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.background,
                              child: const Center(
                                child: Icon(Icons.broken_image),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPdfDirectDisplay(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _pdfAttachments.map((url) {
        return GestureDetector(
          onTap: () => onPdfTap?.call(url),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppStyles.spacing8),
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppStyles.radius12),
              border: Border.all(
                color: AppColors.grey300,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppStyles.radius12),
              child: Stack(
                children: [
                  // PDF Preview
                  FutureBuilder<Uint8List>(
                    future: _loadPdfBytes(url),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          color: AppColors.background,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Container(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  size: 64,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: AppStyles.spacing8),
                                Text(
                                  _getFileNameFromUrl(url),
                                  style: AppStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppStyles.spacing4),
                                Text(
                                  'Tap to view PDF',
                                  style: AppStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasData) {
                        try {
                          return Container(
                            color: Colors.white,
                            child: PdfView(
                              controller: PdfController(
                                document: PdfDocument.openData(snapshot.data!),
                              ),
                            ),
                          );
                        } catch (e) {
                          return Container(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf,
                                    size: 64,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: AppStyles.spacing8),
                                  Text(
                                    _getFileNameFromUrl(url),
                                    style: AppStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      }
                      return Container(
                        color: AppColors.background,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                  // Overlay with PDF icon and tap indicator
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onPdfTap?.call(url),
                        borderRadius: BorderRadius.circular(AppStyles.radius12),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.3),
                              ],
                              stops: const [0.7, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(AppStyles.radius12),
                          ),
                          child: Stack(
                            children: [
                              // PDF label at bottom
                              Positioned(
                                bottom: 8,
                                left: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppStyles.spacing8,
                                    vertical: AppStyles.spacing4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(AppStyles.radius8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.picture_as_pdf,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: AppStyles.spacing4),
                                      Flexible(
                                        child: Text(
                                          _getFileNameFromUrl(url),
                                          style: AppStyles.caption.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Tap indicator
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(AppStyles.spacing8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<Uint8List> _loadPdfBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to load PDF: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load PDF: $e');
    }
  }

  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
      return 'Attachment';
    } catch (e) {
      return 'Attachment';
    }
  }
}

class MaintenanceCard extends StatelessWidget {
  final String title;
  final String description;
  final String status;
  final String priority;
  final String requestedDate;
  final String? assignedTo;
  final VoidCallback? onTap;
  final bool isClickable;

  const MaintenanceCard({
    super.key,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.requestedDate,
    this.assignedTo,
    this.onTap,
    this.isClickable = true,
  });

  @override
  Widget build(BuildContext context) {
    Color getStatusColor() {
      switch (status.toLowerCase()) {
        case 'completed':
          return AppColors.success;
        case 'in progress':
          return AppColors.info;
        case 'open':
          return AppColors.warning;
        case 'closed':
          return AppColors.textSecondary;
        default:
          return AppColors.textSecondary;
      }
    }

    Color getPriorityColor() {
      switch (priority.toLowerCase()) {
        case 'high':
          return AppColors.error;
        case 'medium':
          return AppColors.warning;
        case 'low':
          return AppColors.success;
        default:
          return AppColors.textSecondary;
      }
    }

    return CustomCard(
      onTap: onTap,
      isClickable: isClickable,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacing8,
                  vertical: AppStyles.spacing4,
                ),
                decoration: BoxDecoration(
                  color: getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radius4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppStyles.caption.copyWith(
                    color: getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacing8),
          Text(
            description,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppStyles.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.priority_high,
                    size: 16,
                    color: getPriorityColor(),
                  ),
                  const SizedBox(width: AppStyles.spacing4),
                  Text(
                    priority.toUpperCase(),
                    style: AppStyles.caption.copyWith(
                      color: getPriorityColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                requestedDate,
                style: AppStyles.caption.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          if (assignedTo != null) ...[
            const SizedBox(height: AppStyles.spacing8),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppStyles.spacing4),
                Text(
                  'Assigned to: $assignedTo',
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
