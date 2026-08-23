import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../state/settings_provider.dart';
import '../../state/gallery_provider.dart';
import '../../state/graph_provider.dart';
import '../../state/earth_provider.dart';
import '../favorites/favorites_view.dart';
import '../trash/trash_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final gallery = context.watch<GalleryProvider>();
    final graph = context.watch<GraphProvider>();
    final earth = context.watch<EarthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Section: Library & Quick Shortcuts
          _buildSectionHeader('Library & Shortcuts'),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.favorite_rounded, color: AppColors.favorite),
              title: const Text('Favorites', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text('${gallery.favorites.length} photos', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesView())),
            ),
            const Divider(color: AppColors.divider, height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              title: const Text('Trash', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text('${gallery.trash.length} items (30-day recovery)', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashView())),
            ),
            const Divider(color: AppColors.divider, height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.sync_rounded, color: AppColors.primaryLight),
              title: const Text('Re-index MediaStore', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Scan device storage and refresh EXIF GPS tags', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              trailing: ElevatedButton(
                onPressed: () {
                  gallery.loadGallery();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Re-indexing media store...')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  foregroundColor: AppColors.primaryLight,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('Scan', style: TextStyle(fontSize: 12)),
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // Section: Appearance
          _buildSectionHeader('Appearance'),
          _buildSettingsCard([
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Timeline Grid Columns', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [2, 3, 4, 5].map((cols) {
                      final isSelected = settings.gridColumns == cols;
                      return ChoiceChip(
                        label: Text('$cols Columns'),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.25),
                        backgroundColor: AppColors.surfaceVariant,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) => settings.setGridColumns(cols),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // Section: Graph View (Obsidian Engine)
          _buildSectionHeader('Graph View (Obsidian Physics)'),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.hub_outlined, color: AppColors.primaryLight),
              title: const Text('Link Distance', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Slider(
                value: graph.linkDistance,
                min: 40,
                max: 180,
                activeColor: AppColors.primary,
                onChanged: (v) => graph.setPhysics(linkDistance: v),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.grain_rounded, color: AppColors.primaryLight),
              title: const Text('Repulsion Force', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Slider(
                value: graph.repulsionForce,
                min: 500,
                max: 3000,
                activeColor: AppColors.primary,
                onChanged: (v) => graph.setPhysics(repulsionForce: v),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.waves_rounded, color: AppColors.primaryLight),
              title: const Text('Idle Breathing Drift', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Simulates subtle continuous kinetic movement', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              value: graph.isIdleDriftEnabled,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => graph.setPhysics(idleDrift: v),
            ),
          ]),

          const SizedBox(height: 20),

          // Section: Earth View (3D Globe)
          _buildSectionHeader('Earth View (3D Globe)'),
          _buildSettingsCard([
            SwitchListTile(
              secondary: const Icon(Icons.public_rounded, color: AppColors.earthPin),
              title: const Text('Flat Satellite Map Fallback', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Use flat 2D tile map for low-power performance', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              value: earth.useFlatMap,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => earth.setRenderMode(v),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.rotate_90_degrees_ccw_rounded, color: AppColors.primaryLight),
              title: const Text('Auto-Rotate Globe', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Slow smooth celestial rotation when idle', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              value: earth.isAutoRotate,
              activeThumbColor: AppColors.primary,
              onChanged: (_) => earth.toggleAutoRotate(),
            ),
          ]),

          const SizedBox(height: 20),

          // Section: Privacy & EXIF
          _buildSectionHeader('Privacy'),
          _buildSettingsCard([
            SwitchListTile(
              secondary: const Icon(Icons.location_off_outlined, color: AppColors.textMuted),
              title: const Text('Strip GPS Location on Share', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Removes geotag EXIF metadata when sharing photos', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              value: settings.stripExifLocationOnExport,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => settings.toggleStripExif(v),
            ),
          ]),

          const SizedBox(height: 20),

          // Section: About
          _buildSectionHeader('About'),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.diamond_outlined, color: AppColors.primaryLight),
              title: const Text('Adamantine Gallery', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              subtitle: const Text('v1.0.0 • Obsidian Graph & 3D Earth Globe', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
          ]),

          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primaryLight,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
