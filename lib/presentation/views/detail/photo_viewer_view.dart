import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/models/media_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../state/gallery_provider.dart';
import '../../common/media_thumbnail.dart';
import 'widgets/exif_info_sheet.dart';
import 'photo_editor_view.dart';

class PhotoViewerView extends StatefulWidget {
  final String initialPhotoId;
  final List<MediaItem> photoList;

  const PhotoViewerView({
    super.key,
    required this.initialPhotoId,
    required this.photoList,
  });

  @override
  State<PhotoViewerView> createState() => _PhotoViewerViewState();
}

class _PhotoViewerViewState extends State<PhotoViewerView> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showUiOverlays = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.photoList.indexWhere((p) => p.id == widget.initialPhotoId);
    if (_currentIndex == -1) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    setState(() {
      _showUiOverlays = !_showUiOverlays;
    });
  }

  void _showExif(MediaItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExifInfoSheet(item: item),
    );
  }

  void _shareItem(MediaItem item) {
    if (item.path != null) {
      Share.shareXFiles([XFile(item.path!)], text: item.title);
    } else {
      Share.share('Check out this photo: ${item.title}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gallery = context.watch<GalleryProvider>();
    final currentList = widget.photoList;

    if (currentList.isEmpty || _currentIndex >= currentList.length) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('No photo available', style: TextStyle(color: Colors.white))),
      );
    }

    final currentPhoto = currentList[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Photo Swipe PageView with InteractiveViewer
          GestureDetector(
            onTap: _toggleOverlay,
            child: PageView.builder(
              controller: _pageController,
              itemCount: currentList.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final photo = currentList[index];
                return Hero(
                  tag: 'photo_${photo.id}',
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.5,
                    child: Center(
                      child: MediaThumbnail(
                        item: photo,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Top Translucent Navigation Bar
          if (_showUiOverlays)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentPhoto.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_currentIndex + 1} of ${currentList.length}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, color: Colors.white),
                          onPressed: () => _shareItem(currentPhoto),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Translucent Actions Bar
          if (_showUiOverlays)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Favorite
                        IconButton(
                          icon: Icon(
                            currentPhoto.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: currentPhoto.isFavorite ? AppColors.favorite : Colors.white,
                          ),
                          tooltip: 'Favorite',
                          onPressed: () => gallery.toggleFavorite(currentPhoto.id),
                        ),

                        // Edit
                        IconButton(
                          icon: const Icon(Icons.tune_rounded, color: Colors.white),
                          tooltip: 'Edit',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PhotoEditorView(item: currentPhoto),
                              ),
                            );
                          },
                        ),

                        // Share
                        IconButton(
                          icon: const Icon(Icons.share_outlined, color: Colors.white),
                          tooltip: 'Share',
                          onPressed: () => _shareItem(currentPhoto),
                        ),

                        // Delete
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                          tooltip: 'Delete',
                          onPressed: () {
                            gallery.moveToTrash(currentPhoto.id);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Moved to trash'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),

                        // Info / EXIF
                        IconButton(
                          icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                          tooltip: 'Info',
                          onPressed: () => _showExif(currentPhoto),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
