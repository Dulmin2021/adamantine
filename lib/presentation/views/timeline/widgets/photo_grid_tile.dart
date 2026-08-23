import 'package:flutter/material.dart';
import '../../../../core/models/media_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/media_thumbnail.dart';
import '../../../common/animated_pressable.dart';

class PhotoGridTile extends StatelessWidget {
  final MediaItem item;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const PhotoGridTile({
    super.key,
    required this.item,
    this.isSelected = false,
    this.isSelectionMode = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail Image
            Hero(
              tag: 'photo_${item.id}',
              child: MediaThumbnail(
                item: item,
                fit: BoxFit.cover,
              ),
            ),

            // Video Duration Badge
            if (item.isVideo)
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '${item.duration ~/ 60}:${(item.duration % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

            // Favorite Heart indicator
            if (item.isFavorite && !isSelectionMode)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.favorite,
                    size: 14,
                  ),
                ),
              ),

            // Selection Checkbox / Overlay
            if (isSelectionMode)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.15),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.primary : Colors.black.withValues(alpha: 0.5),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white70,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
