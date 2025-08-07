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
                    context.push('/surah/1');
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
                  icon: Icons.search,
                  label: 'Recherche\nAvancée',
                  color: AppConstants.infoColor,
                  onTap: () {
                    showSearchDialog(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher'),
        content: const Text('La recherche avancée arrive bientôt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
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
}
