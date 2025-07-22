import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_constants.dart';
import '../providers/app_providers.dart';

class StatsWidget extends StatelessWidget {
  final UserStats stats;

  const StatsWidget({
    Key? key,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppConstants.primaryColor,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Mes statistiques',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.book,
                    label: 'Sourates lues',
                    value: '${stats.surahsRead}',
                    color: AppConstants.primaryColor,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.memory,
                    label: 'Versets mémorisés',
                    value: '${stats.ayahsMemorized}',
                    color: AppConstants.successColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.local_fire_department,
                    label: 'Série de jours',
                    value: '${stats.daysStreak}',
                    color: AppConstants.warningColor,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.star,
                    label: 'Score total',
                    value: '${stats.totalScore.toInt()}',
                    color: AppConstants.secondaryColor,
                  ),
                ),
              ],
            ),
            if (stats.badges.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Text(
                'Badges récents',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                children: stats.badges.take(3).map((badge) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppConstants.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppConstants.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20.sp,
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
