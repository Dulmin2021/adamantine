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
            // Album Cover Image with stacked photo illusion
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
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
                              Colors.black.withValues(alpha: 0.5),
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
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getAlbumIcon(album.type),
                          color: Colors.white70,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
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
