import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../state/graph_provider.dart';
import '../../../state/gallery_provider.dart';

class GraphSettingsSheet extends StatelessWidget {
  final GraphProvider graphProvider;

  const GraphSettingsSheet({
    super.key,
    required this.graphProvider,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: graphProvider,
      builder: (context, _) {
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Graph Physics Settings',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tune Obsidian spring & repulsion forces',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => graphProvider.resetPhysicsToDefaults(),
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primaryLight),
                    label: const Text('Reset', style: TextStyle(color: AppColors.primaryLight, fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      backgroundColor: AppColors.surfaceContainerHigh,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Link Distance Slider
              _buildSlider(
                title: 'Link Distance',
                value: graphProvider.linkDistance,
                min: 40.0,
                max: 180.0,
                onChanged: (val) => graphProvider.setPhysics(linkDistance: val),
              ),

              // Repulsion Force Slider
              _buildSlider(
                title: 'Repulsion Force',
                value: graphProvider.repulsionForce,
                min: 500.0,
                max: 3000.0,
                onChanged: (val) => graphProvider.setPhysics(repulsionForce: val),
              ),

              // Center Gravity Slider
              _buildSlider(
                title: 'Center Gravity',
                value: graphProvider.centerGravity,
                min: 0.01,
                max: 0.15,
                onChanged: (val) => graphProvider.setPhysics(centerGravity: val),
              ),

              // Idle Breathing Drift Toggle
              SwitchListTile(
                title: const Text('Idle Breathing Drift', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                subtitle: const Text('Gentle harmonic oscillation when idle', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                value: graphProvider.isIdleDriftEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => graphProvider.setPhysics(idleDrift: val),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 12),

              // Replay Formation Animation Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final gallery = context.read<GalleryProvider>();
                    Navigator.pop(context);
                    graphProvider.playFormationAnimation(
                      allItems: gallery.allItems,
                      allAlbums: gallery.albums,
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                  label: const Text(
                    'Replay Formation Animation',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
              Text(value.toStringAsFixed(1), style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.surfaceVariant,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
