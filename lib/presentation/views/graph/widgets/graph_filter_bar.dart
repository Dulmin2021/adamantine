import 'package:flutter/material.dart';
import '../../../../core/services/graph_service.dart';
import '../../../../core/theme/app_colors.dart';

class GraphFilterBar extends StatelessWidget {
  final Set<GraphFilter> activeFilters;
  final Function(GraphFilter) onToggleFilter;

  const GraphFilterBar({
    super.key,
    required this.activeFilters,
    required this.onToggleFilter,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('By Tag', GraphFilter.byTag, Icons.tag_rounded, AppColors.graphCrossLink),
          const SizedBox(width: 8),
          _buildFilterChip('By Location', GraphFilter.byLocation, Icons.location_on_outlined, AppColors.earthPin),
          const SizedBox(width: 8),
          _buildFilterChip('By Date', GraphFilter.byDate, Icons.calendar_month_outlined, AppColors.warning),
          const SizedBox(width: 8),
          _buildFilterChip('By Person', GraphFilter.byPerson, Icons.person_outline_rounded, AppColors.secondary),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, GraphFilter filter, IconData icon, Color activeColor) {
    final isSelected = activeFilters.contains(filter);
    return FilterChip(
      avatar: Icon(icon, size: 14, color: isSelected ? activeColor : AppColors.textMuted),
      label: Text(label),
      selected: isSelected,
      selectedColor: activeColor.withValues(alpha: 0.2),
      backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.9),
      side: BorderSide(
        color: isSelected ? activeColor : AppColors.cardBorder,
        width: 1.0,
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      onSelected: (_) => onToggleFilter(filter),
    );
  }
}
