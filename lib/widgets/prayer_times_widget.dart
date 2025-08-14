import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_constants.dart';
import '../services/prayer_times_service.dart';

final prayerTimesServiceProvider = Provider<PrayerTimesService>((ref) {
  return PrayerTimesService();
});

class PrayerTimesWidget extends ConsumerStatefulWidget {
  const PrayerTimesWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<PrayerTimesWidget> createState() => _PrayerTimesWidgetState();
}

class _PrayerTimesWidgetState extends ConsumerState<PrayerTimesWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(prayerTimesServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prayerService = ref.watch(prayerTimesServiceProvider);

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.primaryColor.withOpacity(0.1),
              AppConstants.secondaryColor.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // En-tête avec toggle
              _buildHeader(prayerService),

              // Contenu des heures de prière (conditionnel)
              StreamBuilder<bool>(
                stream: prayerService.visibilityStream,
                initialData: false,
                builder: (context, snapshot) {
                  final isVisible = snapshot.data ?? false;

                  if (!isVisible) {
                    return _buildHiddenState();
                  }

                  return _buildPrayerTimesContent(prayerService);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(PrayerTimesService prayerService) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.access_time,
            color: AppConstants.primaryColor,
            size: 20.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            'Heures de Prière',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        // Toggle switch
        StreamBuilder<bool>(
          stream: prayerService.visibilityStream,
          initialData: false,
          builder: (context, snapshot) {
            final isVisible = snapshot.data ?? false;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppConstants.primaryColor.withOpacity(0.7),
                  size: 16.sp,
                ),
                SizedBox(width: 4.w),
                Switch(
                  value: isVisible,
                  onChanged: (_) => prayerService.toggleVisibility(),
                  activeColor: AppConstants.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHiddenState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        children: [
          Icon(
            Icons.visibility_off,
            size: 32.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 8.h),
          Text(
            'Heures de prière masquées',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Activez le toggle pour afficher',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesContent(PrayerTimesService prayerService) {
    return Column(
      children: [
        SizedBox(height: 16.h),

        // Prochaine prière
        StreamBuilder<PrayerTime>(
          stream: prayerService.nextPrayerStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _buildLoadingState();
            }

            return _buildNextPrayerCard(snapshot.data!);
          },
        ),

        SizedBox(height: 16.h),

        // Toutes les prières d'aujourd'hui
        StreamBuilder<List<PrayerTime>>(
          stream: prayerService.allPrayersStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            return _buildTodayPrayers(snapshot.data!);
          },
        ),

        SizedBox(height: 12.h),

        // Actions
        _buildActions(prayerService),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 12.h),
          Text(
            'Chargement des heures de prière...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.primaryColor,
                ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Obtention de votre localisation',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPrayerCard(PrayerTime nextPrayer) {
    final isNow = nextPrayer.timeUntil == Duration.zero;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isNow
            ? AppConstants.successColor.withOpacity(0.1)
            : AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isNow ? AppConstants.successColor : AppConstants.primaryColor,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                nextPrayer.icon,
                style: TextStyle(fontSize: 24.sp),
              ),
              SizedBox(width: 8.w),
              Text(
                isNow ? 'C\'est l\'heure de' : 'Prochaine prière',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isNow
                          ? AppConstants.successColor
                          : AppConstants.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Nom de la prière en arabe et français
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                nextPrayer.nameAr,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                  fontFamily: 'Amiri',
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                nextPrayer.nameEn,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Heure et temps restant
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Icon(
                    Icons.schedule,
                    color: AppConstants.secondaryColor,
                    size: 20.sp,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    nextPrayer.formattedTime,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppConstants.secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Heure',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 60.h,
                color: AppConstants.primaryColor.withOpacity(0.3),
              ),
              Column(
                children: [
                  Icon(
                    isNow ? Icons.notifications_active : Icons.timer,
                    color: isNow
                        ? AppConstants.successColor
                        : AppConstants.warningColor,
                    size: 20.sp,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    nextPrayer.timeUntilFormatted,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: isNow
                              ? AppConstants.successColor
                              : AppConstants.warningColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    isNow ? 'Maintenant' : 'Restant',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPrayers(List<PrayerTime> prayers) {
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.today,
              color: AppConstants.primaryColor,
              size: 16.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Aujourd\'hui',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ...prayers.map((prayer) {
          final isPassed = prayer.time.isBefore(now);
          final isCurrent =
              prayer.time.isAfter(now.subtract(const Duration(minutes: 30))) &&
                  prayer.time.isBefore(now.add(const Duration(minutes: 30)));

          return Container(
            margin: EdgeInsets.only(bottom: 4.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppConstants.successColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Text(
                  prayer.icon,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: isPassed ? Colors.grey[400] : null,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    '${prayer.nameAr} - ${prayer.nameEn}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isPassed
                              ? AppConstants.primaryColor.withOpacity(0.6)
                              : AppConstants.primaryColor,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                  ),
                ),
                Text(
                  prayer.formattedTime,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isPassed
                            ? AppConstants.primaryColor.withOpacity(0.6)
                            : AppConstants.secondaryColor,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildActions(PrayerTimesService prayerService) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showCalculationMethodDialog(prayerService),
            icon: Icon(Icons.settings, size: 16.sp),
            label: const Text('Méthode'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
              side:
                  BorderSide(color: AppConstants.primaryColor.withOpacity(0.3)),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => prayerService.forceUpdate(),
            icon: Icon(Icons.refresh, size: 16.sp),
            label: const Text('Actualiser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
              side:
                  BorderSide(color: AppConstants.primaryColor.withOpacity(0.3)),
            ),
          ),
        ),
      ],
    );
  }

  void _showCalculationMethodDialog(PrayerTimesService prayerService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.calculate,
                color: AppConstants.primaryColor,
              ),
              SizedBox(width: 8.w),
              const Text('Méthode de calcul'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: prayerService.calculationMethods.length,
              itemBuilder: (context, index) {
                final methods = prayerService.calculationMethods;
                final methodId = methods.keys.elementAt(index);
                final methodName = methods[methodId]!;

                return ListTile(
                  title: Text(
                    methodName,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  onTap: () {
                    prayerService.setCalculationMethod(methodId);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Méthode changée: $methodName'),
                        backgroundColor: AppConstants.successColor,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}
