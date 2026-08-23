import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/glass_container.dart';
import '../../../common/media_thumbnail.dart';

class TripsCarousel extends StatelessWidget {
  final List<Trip> trips;
  final Function(Trip) onTripSelected;

  const TripsCarousel({
    super.key,
    required this.trips,
    required this.onTripSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.flight_takeoff_rounded, color: AppColors.primaryLight, size: 16),
              SizedBox(width: 6),
              Text(
                'My Trips',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: trips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final trip = trips[index];
              return GestureDetector(
                onTap: () => onTripSelected(trip),
                child: GlassContainer(
                  width: 220,
                  borderRadius: 16,
                  backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.9),
                  borderColor: AppColors.glassBorder,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      // Trip Cover Photo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 80,
                          height: double.infinity,
                          child: trip.coverPhoto != null
                              ? MediaThumbnail(item: trip.coverPhoto!, fit: BoxFit.cover)
                              : Container(color: AppColors.surfaceVariant),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Trip Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              trip.destination,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('MMM yyyy').format(trip.startDate),
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${trip.photoCount} photos',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
