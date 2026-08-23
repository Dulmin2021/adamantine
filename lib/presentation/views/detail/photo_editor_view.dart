import 'package:flutter/material.dart';
import '../../../../core/models/media_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/edit_service.dart';
import '../../common/media_thumbnail.dart';

class PhotoEditorView extends StatefulWidget {
  final MediaItem item;

  const PhotoEditorView({
    super.key,
    required this.item,
  });

  @override
  State<PhotoEditorView> createState() => _PhotoEditorViewState();
}

class _PhotoEditorViewState extends State<PhotoEditorView> {
  int _rotationQuarterTurns = 0;
  double _brightness = 0.0;
  double _contrast = 1.0;
  PhotoFilterPreset _selectedPreset = PhotoFilterPreset.none;
  String _activeTab = 'Filters'; // 'Filters', 'Adjust', 'Crop'
  String _selectedAspectRatio = 'Original';

  void _rotateClockwise() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorFilter = EditService.getColorFilter(
      brightness: _brightness,
      contrast: _contrast,
      preset: _selectedPreset,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Photo',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_right_rounded, color: Colors.white),
            tooltip: 'Rotate 90°',
            onPressed: _rotateClockwise,
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edits saved successfully!'),
                  backgroundColor: AppColors.surfaceElevated,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Live Preview Area
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: RotatedBox(
                  quarterTurns: _rotationQuarterTurns,
                  child: ColorFiltered(
                    colorFilter: colorFilter,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: MediaThumbnail(
                        item: widget.item,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Editing Controls Panel
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sub-panel based on active tab
                if (_activeTab == 'Filters') _buildFiltersPanel(),
                if (_activeTab == 'Adjust') _buildAdjustPanel(),
                if (_activeTab == 'Crop') _buildCropPanel(),

                const SizedBox(height: 12),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 8),

                // Bottom Tab Switcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTabButton('Filters', Icons.auto_awesome_rounded),
                    _buildTabButton('Adjust', Icons.tune_rounded),
                    _buildTabButton('Crop', Icons.crop_rounded),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabName, IconData icon) {
    final isSelected = _activeTab == tabName;
    return InkWell(
      onTap: () => setState(() => _activeTab = tabName),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              tabName,
              style: TextStyle(
                color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: PhotoFilterPreset.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final preset = PhotoFilterPreset.values[index];
          final isSelected = _selectedPreset == preset;
          return GestureDetector(
            onTap: () => setState(() => _selectedPreset = preset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ColorFiltered(
                      colorFilter: EditService.getColorFilter(preset: preset),
                      child: MediaThumbnail(item: widget.item, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  preset.label,
                  style: TextStyle(
                    color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdjustPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.brightness_6_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              const SizedBox(width: 70, child: Text('Brightness', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
              Expanded(
                child: Slider(
                  value: _brightness,
                  min: -0.5,
                  max: 0.5,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.surfaceVariant,
                  onChanged: (v) => setState(() => _brightness = v),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.contrast_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              const SizedBox(width: 70, child: Text('Contrast', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
              Expanded(
                child: Slider(
                  value: _contrast,
                  min: 0.5,
                  max: 1.8,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.surfaceVariant,
                  onChanged: (v) => setState(() => _contrast = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCropPanel() {
    final ratios = ['Original', '1:1 Square', '4:3', '16:9', 'Free'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ratios.map((ratio) {
          final isSelected = _selectedAspectRatio == ratio;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(ratio),
              selected: isSelected,
              selectedColor: AppColors.primary.withValues(alpha: 0.25),
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => setState(() => _selectedAspectRatio = ratio),
            ),
          );
        }).toList(),
      ),
    );
  }
}
