import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/models/media_item.dart';
import '../../core/theme/app_colors.dart';

class MediaThumbnail extends StatelessWidget {
  final MediaItem item;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const MediaThumbnail({
    super.key,
    required this.item,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (item.path != null && File(item.path!).existsSync()) {
      imageWidget = Image.file(
        File(item.path!),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    } else if (item.thumbnailData != null) {
      imageWidget = Image.memory(
        item.thumbnailData!,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    } else if (item.placeholderUrl != null && item.placeholderUrl!.isNotEmpty) {
      imageWidget = Image.network(
        item.placeholderUrl!,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoading();
        },
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    } else {
      imageWidget = _buildPlaceholder();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceElevated,
      child: Center(
        child: Icon(
          item.isVideo ? Icons.play_circle_outline_rounded : Icons.image_outlined,
          color: AppColors.textMuted,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceElevated,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
