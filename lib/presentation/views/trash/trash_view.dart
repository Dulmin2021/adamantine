import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../state/gallery_provider.dart';
import '../../common/media_thumbnail.dart';

class TrashView extends StatelessWidget {
  const TrashView({super.key});

  @override
  Widget build(BuildContext context) {
    final gallery = context.watch<GalleryProvider>();
    final trashItems = gallery.trash;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          if (trashItems.isNotEmpty)
            TextButton(
              onPressed: () => _confirmEmptyTrash(context, gallery),
              child: const Text('Empty Trash', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: trashItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_sweep_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('Trash is empty', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Deleted photos remain here for 30 days before permanent removal', style: TextStyle(color: AppColors.textMuted, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemCount: trashItems.length,
              itemBuilder: (context, index) {
                final item = trashItems[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: MediaThumbnail(item: item, fit: BoxFit.cover),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        ),
                        child: Text(
                          '${item.daysUntilPermanentDelete}d left',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.restore_from_trash_rounded, color: Colors.white, size: 20),
                        tooltip: 'Restore',
                        onPressed: () {
                          gallery.restoreFromTrash(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Photo restored')),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  void _confirmEmptyTrash(BuildContext context, GalleryProvider gallery) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text('All items in trash will be permanently deleted. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              for (final item in gallery.trash) {
                gallery.permanentlyDelete(item.id);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Empty All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
