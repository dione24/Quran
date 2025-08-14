import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_constants.dart';

class QuickActionsWidget extends ConsumerWidget {
  const QuickActionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions rapides',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppConstants.primaryColor,
                  ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAction(
                  context,
                  icon: Icons.menu_book,
                  label: 'Lire\nle Coran',
                  color: AppConstants.primaryColor,
                  onTap: () {
                    context.push('/read');
                  },
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.mic,
                  label: 'Écouter &\nReconnaître',
                  color: AppConstants.accentColor,
                  onTap: () {
                    context.push('/listen');
                  },
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.favorite,
                  label: 'Mes\nFavoris',
                  color: AppConstants.favoriteColor,
                  onTap: () {
                    context.push('/favorites');
                  },
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.access_time,
                  label: 'Horaires\nPrières',
                  color: AppConstants.infoColor,
                  onTap: () {
                    _showPrayerTimesDialog(context, ref);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 70.w,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Column(
          children: [
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: color.withOpacity(0.3),
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showPrayerTimesDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.access_time,
                color: AppConstants.primaryColor,
              ),
              SizedBox(width: 8.w),
              Text(
                'Horaires de Prière',
                style: TextStyle(color: AppConstants.primaryColor),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Consultez les horaires détaillés dans l\'écran principal',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // L'utilisateur peut voir les horaires sur l'écran principal
                  },
                  child: Text('Fermer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
