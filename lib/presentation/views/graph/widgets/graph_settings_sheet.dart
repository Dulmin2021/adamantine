import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../state/graph_provider.dart';

class GraphSettingsSheet extends StatelessWidget {
  final GraphProvider graphProvider;

  const GraphSettingsSheet({
    super.key,
    required this.graphProvider,
  });

  @override
  Widget build(BuildContext context) {
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

          const Text(
            'Graph Physics Settings',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tune the Obsidian-style spring and repulsion forces',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),

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
        ],
      ),
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
            value: value,
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
