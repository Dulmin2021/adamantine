import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/media_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../state/gallery_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/date_section_header.dart';
import 'widgets/photo_grid_tile.dart';
import 'widgets/selection_bottom_bar.dart';
import '../detail/photo_viewer_view.dart';

class TimelineView extends StatefulWidget {
  const TimelineView({super.key});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  String _selectedDateFilter = 'All';

  final List<String> _dateFilters = ['All', 'Today', 'This Week', 'This Month'];

  Map<String, List<MediaItem>> _groupPhotosByDate(List<MediaItem> photos) {
    final Map<String, List<MediaItem>> groups = {};
    final now = DateTime.now();

    for (final photo in photos) {
      if (_selectedDateFilter == 'Today') {
        if (photo.createDate.year != now.year ||
            photo.createDate.month != now.month ||
            photo.createDate.day != now.day) {
          continue;
        }
      } else if (_selectedDateFilter == 'This Week') {
        if (now.difference(photo.createDate).inDays > 7) {
          continue;
        }
      } else if (_selectedDateFilter == 'This Month') {
        if (photo.createDate.year != now.year || photo.createDate.month != now.month) {
          continue;
        }
      }

      final dateKey = DateFormat('yyyy-MM-dd').format(photo.createDate);
      groups.putIfAbsent(dateKey, () => []).add(photo);
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final gallery = context.watch<GalleryProvider>();
    final settings = context.watch<SettingsProvider>();

    if (gallery.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final allPhotos = gallery.allItems;
    if (allPhotos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            const Text(
              'No photos found',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Photos taken on your device will appear here',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => gallery.loadGallery(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      );
    }

    final groupedPhotos = _groupPhotosByDate(allPhotos);
    final sortedDateKeys = groupedPhotos.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceElevated,
          onRefresh: () => gallery.loadGallery(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Horizontal Date Quick-Filter Row
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: _dateFilters.map((filter) {
                      final isSelected = _selectedDateFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withValues(alpha: 0.25),
                          backgroundColor: AppColors.surfaceElevated,
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.cardBorder,
                            width: 1,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedDateFilter = filter);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Grouped Photo Grids
              ...sortedDateKeys.expand((dateKey) {
                final photosInDate = groupedPhotos[dateKey]!;
                final firstPhoto = photosInDate.first;

                return [
                  SliverToBoxAdapter(
                    child: DateSectionHeader(
                      date: firstPhoto.createDate,
                      count: photosInDate.length,
                      location: firstPhoto.exif.locationName,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: settings.gridColumns,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 1.0,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = photosInDate[index];
                          final isSelected = gallery.selectedItemIds.contains(item.id);

                          return PhotoGridTile(
                            item: item,
                            isSelected: isSelected,
                            isSelectionMode: gallery.isSelectionMode,
                            onTap: () {
                              if (gallery.isSelectionMode) {
                                gallery.toggleItemSelection(item.id);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PhotoViewerView(
                                      initialPhotoId: item.id,
                                      photoList: allPhotos,
                                    ),
                                  ),
                                );
                              }
                            },
                            onLongPress: () {
                              if (!gallery.isSelectionMode) {
                                gallery.enterSelectionMode(item.id);
                              }
                            },
                          );
                        },
                        childCount: photosInDate.length,
                      ),
                    ),
                  ),
                ];
              }),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),

        // Multi-select Action Floating Toolbar
        if (gallery.isSelectionMode)
          SelectionBottomBar(
            selectedCount: gallery.selectedCount,
            onCancel: () => gallery.exitSelectionMode(),
            onFavorite: () => gallery.batchFavoriteSelected(),
            onDelete: () => _confirmBatchDelete(context, gallery),
            onShare: () {
              // Share selected
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sharing ${gallery.selectedCount} items...'),
                  backgroundColor: AppColors.surfaceElevated,
                ),
              );
              gallery.exitSelectionMode();
            },
            onAddToAlbum: () => _showAddToAlbumDialog(context, gallery),
          ),
      ],
    );
  }

  void _confirmBatchDelete(BuildContext context, GalleryProvider gallery) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Trash?'),
        content: Text('Move ${gallery.selectedCount} photos to trash? You can restore them within 30 days.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              gallery.batchDeleteSelected();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Move to Trash', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddToAlbumDialog(BuildContext context, GalleryProvider gallery) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add to Album', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...gallery.albums.map((album) => ListTile(
                leading: const Icon(Icons.photo_album_outlined, color: AppColors.primary),
                title: Text(album.name, style: const TextStyle(color: AppColors.textPrimary)),
                subtitle: Text('${album.count} photos', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  gallery.exitSelectionMode();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added to ${album.name}')),
                  );
                },
              )),
            ],
          ),
        );
      },
    );
  }
}
