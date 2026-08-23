import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../state/gallery_provider.dart';
import '../../state/settings_provider.dart';
import '../timeline/widgets/photo_grid_tile.dart';
import '../detail/photo_viewer_view.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final gallery = context.watch<GalleryProvider>();
    final settings = context.watch<SettingsProvider>();
    final favorites = gallery.favorites;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border_rounded, size: 64, color: AppColors.favorite),
                  const SizedBox(height: 16),
                  const Text('No favorite photos yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Tap the heart icon on any photo to add it here', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                return PhotoGridTile(
                  item: item,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoViewerView(
                          initialPhotoId: item.id,
                          photoList: favorites,
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
