import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/glass_container.dart';

class SelectionBottomBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onShare;
  final VoidCallback onFavorite;
  final VoidCallback onAddToAlbum;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const SelectionBottomBar({
    super.key,
    required this.selectedCount,
    required this.onShare,
    required this.onFavorite,
    required this.onAddToAlbum,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: GlassContainer(
        borderRadius: 24,
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
              tooltip: 'Cancel selection',
              onPressed: onCancel,
            ),
            Text(
              '$selectedCount selected',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 20),
                  tooltip: 'Share',
                  onPressed: onShare,
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border_rounded, color: AppColors.textPrimary, size: 20),
                  tooltip: 'Favorite',
                  onPressed: onFavorite,
                ),
                IconButton(
                  icon: const Icon(Icons.create_new_folder_outlined, color: AppColors.textPrimary, size: 20),
                  tooltip: 'Add to album',
                  onPressed: onAddToAlbum,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
