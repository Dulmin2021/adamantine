import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/location_cluster.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/media_thumbnail.dart';
import '../../detail/photo_viewer_view.dart';

class ClusterBottomSheet extends StatelessWidget {
  final LocationCluster cluster;
  final VoidCallback onClose;

  const ClusterBottomSheet({
    super.key,
    required this.cluster,
    required this.onClose,
  });

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return '';
    if (end == null || start.year == end.year && start.month == end.month && start.day == end.day) {
      return DateFormat('MMMM d, yyyy').format(start);
    }
    return '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, yyyy').format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.glassBorder, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Location Title & Close button
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.earthPin, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cluster.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${cluster.count} photos • ${_formatDateRange(cluster.startDate, cluster.endDate)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal Photo Thumbnail Strip
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cluster.items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final photo = cluster.items[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoViewerView(
                          initialPhotoId: photo.id,
                          photoList: cluster.items,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 110,
                      height: 110,
                      child: MediaThumbnail(item: photo, fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
