import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/album.dart';
import '../../../../core/theme/app_colors.dart';
import '../../state/gallery_provider.dart';
import 'widgets/album_card.dart';
import 'album_detail_view.dart';

class AlbumsView extends StatelessWidget {
  const AlbumsView({super.key});

  @override
  Widget build(BuildContext context) {
    final gallery = context.watch<GalleryProvider>();
    final albums = gallery.albums;

    final systemAlbums = albums.where((a) => a.isSystem).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Auto Albums Section Header
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Auto Albums',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),

        // Auto Albums Row
        SliverToBoxAdapter(
          child: SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: systemAlbums.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final album = systemAlbums[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AlbumDetailView(album: album)),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceElevated,
                          border: Border.all(color: AppColors.glassBorder, width: 1.5),
                        ),
                        child: Center(
                          child: Icon(
                            _getAutoAlbumIcon(album.type),
                            color: AppColors.primaryLight,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 65,
                        child: Text(
                          album.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // My Albums Section Header with '+ New Album' button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Albums',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showNewAlbumDialog(context, gallery),
                  icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primaryLight),
                  label: const Text(
                    'New Album',
                    style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Albums Grid (All Albums: System + User Created)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.88,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final album = albums[index];
                return AlbumCard(
                  album: album,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AlbumDetailView(album: album)),
                    );
                  },
                );
              },
              childCount: albums.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  IconData _getAutoAlbumIcon(AlbumType type) {
    switch (type) {
      case AlbumType.camera:
        return Icons.camera_alt_outlined;
      case AlbumType.screenshots:
        return Icons.smartphone_outlined;
      case AlbumType.downloads:
        return Icons.download_rounded;
      case AlbumType.whatsApp:
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.folder_outlined;
    }
  }

  void _showNewAlbumDialog(BuildContext context, GalleryProvider gallery) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Album'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Album name',
            prefixIcon: Icon(Icons.folder_outlined, color: AppColors.primary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                gallery.createCustomAlbum(name);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
