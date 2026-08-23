import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/glass_container.dart';

class EarthSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;

  const EarthSearchBar({
    super.key,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<EarthSearchBar> createState() => _EarthSearchBarState();
}

class _EarthSearchBarState extends State<EarthSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassContainer(
        borderRadius: 24,
        backgroundColor: AppColors.surface.withValues(alpha: 0.85),
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.primaryLight, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search a place on the globe...',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  filled: false,
                ),
                onSubmitted: widget.onSearch,
              ),
            ),
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                onPressed: () {
                  _controller.clear();
                  widget.onClear();
                  setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }
}
