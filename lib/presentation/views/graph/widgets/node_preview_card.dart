import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/graph_node.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/glass_container.dart';
import '../../../common/media_thumbnail.dart';

class NodePreviewCard extends StatelessWidget {
  final GraphNode node;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  const NodePreviewCard({
    super.key,
    required this.node,
    required this.onOpen,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final item = node.mediaItem;
    if (item == null) return const SizedBox.shrink();

    return GlassContainer(
      width: 280,
      borderRadius: 20,
      backgroundColor: AppColors.surface.withValues(alpha: 0.95),
      borderColor: AppColors.primaryLight.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.albumName,
                  style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Thumbnail Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: MediaThumbnail(item: item, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 10),

          // Photo Title & Date
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('MMMM d, yyyy • h:mm a').format(item.createDate),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),

          if (item.exif.locationName != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.earthPin, size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.exif.locationName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // 'Open' Fullscreen Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_full_rounded, size: 14),
              label: const Text('Open Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
