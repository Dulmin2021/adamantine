import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/album.dart';
import '../../../core/theme/app_colors.dart';
import '../../state/gallery_provider.dart';
import '../../state/settings_provider.dart';
import '../timeline/widgets/photo_grid_tile.dart';
import '../detail/photo_viewer_view.dart';

class AlbumDetailView extends StatelessWidget {
  final Album album;

  const AlbumDetailView({
    super.key,
    required this.album,
  });

  @override
  Widget build(BuildContext context) {
    final gallery = context.watch<GalleryProvider>();
    final settings = context.watch<SettingsProvider>();

    final albumPhotos = gallery.allItems.where((item) => item.albumId == album.id).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(album.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: albumPhotos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('No photos in this album', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: settings.gridColumns,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.0,
              ),
              itemCount: albumPhotos.length,
              itemBuilder: (context, index) {
                final item = albumPhotos[index];
                return PhotoGridTile(
                  item: item,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoViewerView(
                          initialPhotoId: item.id,
                          photoList: albumPhotos,
                        ),
                      ),
                    );
                  },
                  onLongPress: () {},
                );
              },
            ),
    );
  }
}
