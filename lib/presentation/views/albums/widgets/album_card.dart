import 'package:flutter/material.dart';
import '../../../../core/models/album.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/glass_container.dart';
import '../../../common/animated_pressable.dart';
import '../../../common/media_thumbnail.dart';

class AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const AlbumCard({
    super.key,
    required this.album,
    required this.onTap,
  });

  IconData _getAlbumIcon(AlbumType type) {
    switch (type) {
      case AlbumType.camera:
        return Icons.camera_alt_outlined;
      case AlbumType.screenshots:
        return Icons.smartphone_outlined;
      case AlbumType.downloads:
        return Icons.download_rounded;
      case AlbumType.whatsApp:
        return Icons.chat_bubble_outline_rounded;
      case AlbumType.userCreated:
        return Icons.folder_outlined;
      case AlbumType.other:
        return Icons.photo_library_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 20,
        backgroundColor: AppColors.surfaceElevated,
        borderColor: AppColors.cardBorder,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Cover Image with Stitch 3D layered stack effect
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Bottom layer in stack
                  Positioned(
                    top: 2,
                    left: 12,
                    right: 12,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder, width: 0.8),
                      ),
                    ),
                  ),
                  // Middle layer in stack
                  Positioned(
                    top: 6,
                    left: 6,
                    right: 6,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder, width: 0.8),
                      ),
                    ),
                  ),
                  // Top main photo card
                  Positioned.fill(
                    top: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (album.coverItem != null)
                            MediaThumbnail(
                              item: album.coverItem!,
                              fit: BoxFit.cover,
                            )
                          else if (album.coverPhotoUrl != null && album.coverPhotoUrl!.isNotEmpty)
                            Image.network(
                              album.coverPhotoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildPlaceholder(),
                            )
                          else
                            _buildPlaceholder(),

                          // Subtle gradient overlay for depth
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.6),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // System Album Type Icon badge top right
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.cardBorder, width: 0.8),
                              ),
                              child: Icon(
                                _getAlbumIcon(album.type),
                                color: AppColors.primary,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Album Title
            Text(
              album.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            // Count
            Text(
              '${album.count} photos',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Icon(
          _getAlbumIcon(album.type),
          color: AppColors.textMuted,
          size: 32,
        ),
      ),
    );
  }
}
