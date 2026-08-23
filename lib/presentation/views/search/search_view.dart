import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/media_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../state/gallery_provider.dart';
import '../../state/settings_provider.dart';
import '../timeline/widgets/photo_grid_tile.dart';
import '../detail/photo_viewer_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilterChip = '';
  final List<String> _recentSearches = ['Tokyo', 'Sri Lanka', 'Camera', 'Nature', 'Europe'];

  final List<Map<String, dynamic>> _filterChips = [
    {'label': 'Places', 'icon': Icons.location_on_outlined},
    {'label': 'People', 'icon': Icons.people_outline_rounded},
    {'label': 'Favorites', 'icon': Icons.favorite_border_rounded},
    {'label': 'Screenshots', 'icon': Icons.smartphone_outlined},
    {'label': 'Videos', 'icon': Icons.videocam_outlined},
    {'label': 'This Month', 'icon': Icons.calendar_today_outlined},
  ];

  List<MediaItem> _filterPhotos(List<MediaItem> photos) {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();

    return photos.where((item) {
      // 1. Check quick filter chip
      if (_selectedFilterChip == 'Places' && !item.hasLocation) return false;
      if (_selectedFilterChip == 'People' && item.people.isEmpty) return false;
      if (_selectedFilterChip == 'Favorites' && !item.isFavorite) return false;
      if (_selectedFilterChip == 'Screenshots' && !item.albumName.toLowerCase().contains('screenshot')) return false;
      if (_selectedFilterChip == 'Videos' && !item.isVideo) return false;
      if (_selectedFilterChip == 'This Month' && (item.createDate.month != now.month || item.createDate.year != now.year)) return false;

      // 2. Check search query text
      if (query.isEmpty) return true;

      final matchTitle = item.title.toLowerCase().contains(query);
      final matchAlbum = item.albumName.toLowerCase().contains(query);
      final matchLocation = item.exif.locationName?.toLowerCase().contains(query) ?? false;
      final matchTags = item.tags.any((t) => t.toLowerCase().contains(query));
      final matchPeople = item.people.any((p) => p.toLowerCase().contains(query));

      return matchTitle || matchAlbum || matchLocation || matchTags || matchPeople;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gallery = context.watch<GalleryProvider>();
    final settings = context.watch<SettingsProvider>();
    final allPhotos = gallery.allItems;
    final filteredPhotos = _filterPhotos(allPhotos);
    final isSearching = _searchController.text.isNotEmpty || _selectedFilterChip.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            autofocus: false,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search photos, places, tags, albums...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryLight, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Filter Chips Row
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: _filterChips.map((chip) {
                  final label = chip['label'] as String;
                  final icon = chip['icon'] as IconData;
                  final isSelected = _selectedFilterChip == label;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(icon, size: 14, color: isSelected ? AppColors.primaryLight : AppColors.textMuted),
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.25),
                      backgroundColor: AppColors.surfaceElevated,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.cardBorder,
                        width: 1,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _selectedFilterChip = val ? label : '';
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Recent Searches & Suggestions (When not querying)
          if (!isSearching) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Searches', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => setState(() => _recentSearches.clear()),
                      child: const Text('Clear', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _recentSearches.map((term) => ActionChip(
                    label: Text(term),
                    backgroundColor: AppColors.surfaceElevated,
                    side: const BorderSide(color: AppColors.cardBorder),
                    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    onPressed: () {
                      _searchController.text = term;
                      setState(() {});
                    },
                  )).toList(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],

          // Search Results Header
          if (isSearching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  '${filteredPhotos.length} results found',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),

          // Photo Grid Results
          if (filteredPhotos.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text('No photos matching your search', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: settings.gridColumns,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filteredPhotos[index];
                    return PhotoGridTile(
                      item: item,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PhotoViewerView(
                              initialPhotoId: item.id,
                              photoList: filteredPhotos,
                            ),
                          ),
                        );
                      },
                      onLongPress: () {},
                    );
                  },
                  childCount: filteredPhotos.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
