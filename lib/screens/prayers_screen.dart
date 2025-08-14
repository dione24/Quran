import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_constants.dart';

class PrayersScreen extends StatefulWidget {
  const PrayersScreen({Key? key}) : super(key: key);

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  // Heures de prières mockées
  final Map<String, String> _prayerTimes = {
    'Fajr': '05:45',
    'Sunrise': '07:12',
    'Dhuhr': '12:58',
    'Asr': '15:45',
    'Maghrib': '18:23',
    'Isha': '19:45',
  };

  String _getNextPrayer() {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    for (var entry in _prayerTimes.entries) {
      if (entry.key != 'Sunrise' && entry.value.compareTo(currentTime) > 0) {
        return entry.key;
      }
    }
    return 'Fajr';
  }

  @override
  Widget build(BuildContext context) {
    final nextPrayer = _getNextPrayer();
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConstants.primaryColor,
              AppConstants.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    Text(
                      'Heures de Prières',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                    SizedBox(height: 8.h),
                    Text(
                      'Paris, France',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    SizedBox(height: 4.h),
                    Text(
                      DateTime.now().toString().split(' ')[0],
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),
              
              // Prochaine prière
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Prochaine prière',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      nextPrayer,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _prayerTimes[nextPrayer]!,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 36.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Dans 1h 23min',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(delay: 300.ms),
              
              SizedBox(height: 20.h),
              
              // Liste des prières
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.all(20.w),
                    itemCount: _prayerTimes.length,
                    itemBuilder: (context, index) {
                      final prayer = _prayerTimes.keys.elementAt(index);
                      final time = _prayerTimes[prayer]!;
                      final isPassed = prayer != nextPrayer && _prayerTimes.keys.toList().indexOf(prayer) < 
                          _prayerTimes.keys.toList().indexOf(nextPrayer);
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: prayer == nextPrayer 
                              ? AppConstants.primaryColor.withOpacity(0.1)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(15.r),
                          border: Border.all(
                            color: prayer == nextPrayer 
                                ? AppConstants.primaryColor 
                                : Colors.grey[200]!,
                            width: prayer == nextPrayer ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40.w,
                                  height: 40.w,
                                  decoration: BoxDecoration(
                                    color: prayer == nextPrayer 
                                        ? AppConstants.primaryColor 
                                        : isPassed ? Colors.green : Colors.grey[300],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    prayer == 'Sunrise' 
                                        ? Icons.wb_sunny 
                                        : isPassed 
                                            ? Icons.check 
                                            : Icons.access_time,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getPrayerNameInFrench(prayer),
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: prayer == nextPrayer 
                                            ? AppConstants.primaryColor 
                                            : Colors.black87,
                                      ),
                                    ),
                                    if (prayer == nextPrayer)
                                      Text(
                                        'Prochaine',
                                        style: TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 12.sp,
                                          color: AppConstants.primaryColor,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              time,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: prayer == nextPrayer 
                                    ? AppConstants.primaryColor 
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ).animate()
                          .fadeIn(delay: Duration(milliseconds: 100 * index))
                          .slideX(begin: 0.2, end: 0);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getPrayerNameInFrench(String prayer) {
    switch (prayer) {
      case 'Fajr':
        return 'Fajr (Aube)';
      case 'Sunrise':
        return 'Lever du soleil';
      case 'Dhuhr':
        return 'Dhuhr (Midi)';
      case 'Asr':
        return 'Asr (Après-midi)';
      case 'Maghrib':
        return 'Maghrib (Coucher)';
      case 'Isha':
        return 'Isha (Nuit)';
      default:
        return prayer;
    }
  }
}