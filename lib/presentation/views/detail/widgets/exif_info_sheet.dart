import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/media_item.dart';
import '../../../../core/theme/app_colors.dart';

class ExifInfoSheet extends StatelessWidget {
  final MediaItem item;

  const ExifInfoSheet({
    super.key,
    required this.item,
  });

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes == 0) return 'Unknown';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final exif = item.exif;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
          const SizedBox(height: 18),

          // Title & Filename
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date & Time
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            title: DateFormat('EEEE, MMMM d, yyyy').format(item.createDate),
            subtitle: DateFormat('h:mm:ss a').format(item.createDate),
          ),

          // Camera & Lens
          if (exif.cameraMake != null || exif.cameraModel != null)
            _buildInfoRow(
              icon: Icons.camera_alt_outlined,
              title: '${exif.cameraMake ?? ''} ${exif.cameraModel ?? ''}',
              subtitle: exif.lens ?? 'Standard Lens',
            ),

          // Shooting parameters (Aperture, Shutter, ISO, Focal)
          if (exif.aperture != null || exif.iso != null || exif.focalLength != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _buildExifChip('f-stop', exif.aperture ?? 'f/1.8'),
                  const SizedBox(width: 8),
                  _buildExifChip('Shutter', exif.shutterSpeed ?? '1/500s'),
                  const SizedBox(width: 8),
                  _buildExifChip('ISO', exif.iso ?? '100'),
                  const SizedBox(width: 8),
                  _buildExifChip('Focal', exif.focalLength ?? '24mm'),
                ],
              ),
            ),

          // Resolution & File size
          _buildInfoRow(
            icon: Icons.aspect_ratio_rounded,
            title: '${exif.width ?? 4000} × ${exif.height ?? 3000}',
            subtitle: _formatFileSize(exif.fileSize),
          ),

          // Location GPS Info
          if (exif.hasLocation) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              title: exif.locationName ?? 'Geotagged Location',
              subtitle: '${exif.latitude!.toStringAsFixed(4)}, ${exif.longitude!.toStringAsFixed(4)}',
            ),
          ],

          // Tags & People
          if (item.tags.isNotEmpty || item.people.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...item.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder, width: 1),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                )),
                ...item.people.map((person) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, color: AppColors.secondary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        person,
                        style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExifChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
