import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';

class SurahCard extends StatelessWidget {
  final int surahNumber;
  final bool isHorizontal;
  final VoidCallback? onTap;
  final bool isSelected;

  const SurahCard({
    Key? key,
    required this.surahNumber,
    this.isHorizontal = false,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final surahName = _getSurahName(surahNumber);
    final surahNameFrench = _getSurahNameFrench(surahNumber);
    final ayahCount = _getAyahCount(surahNumber);
    final revelationType = _getRevelationType(surahNumber);

    if (isHorizontal) {
      return _buildHorizontalCard(
        context,
        surahName,
        surahNameFrench,
        ayahCount,
        revelationType,
      );
    }

    return _buildVerticalCard(
      context,
      surahName,
      surahNameFrench,
      ayahCount,
      revelationType,
    );
  }

  Widget _buildHorizontalCard(
    BuildContext context,
    String surahName,
    String surahNameFrench,
    int ayahCount,
    String revelationType,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.primaryColor,
              AppConstants.primaryColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 24.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Center(
                      child: Text(
                        '$surahNumber',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    revelationType == 'Meccan' ? Icons.location_on : Icons.location_city,
                    color: Colors.white.withOpacity(0.7),
                    size: 16.sp,
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                surahName,
                style: AppTheme.arabicTextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Text(
                surahNameFrench,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                '$ayahCount versets',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalCard(
    BuildContext context,
    String surahName,
    String surahNameFrench,
    int ayahCount,
    String revelationType,
  ) {
    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? AppConstants.primaryColor.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: isSelected
            ? BorderSide(color: AppConstants.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Numéro de sourate
              Container(
                width: 50.w,
                height: 50.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppConstants.primaryColor,
                      AppConstants.accentColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    '$surahNumber',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 16.w),
              
              // Informations de la sourate
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surahName,
                      style: AppTheme.arabicTextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isSelected 
                            ? AppConstants.primaryColor 
                            : AppConstants.textColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      surahNameFrench,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected 
                            ? AppConstants.primaryColor 
                            : AppConstants.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          revelationType == 'Meccan' 
                              ? Icons.location_on 
                              : Icons.location_city,
                          size: 14.sp,
                          color: AppConstants.secondaryTextColor,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '$ayahCount versets • $revelationType',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Icône de navigation
              Icon(
                Icons.arrow_forward_ios,
                color: isSelected 
                    ? AppConstants.primaryColor 
                    : AppConstants.secondaryTextColor,
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSurahName(int number) {
    // Noms des sourates en arabe (échantillon)
    const surahNames = [
      'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة',
      'الأنعام', 'الأعراف', 'الأنفال', 'التوبة', 'يونس',
      'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر',
      'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه',
    ];
    
    if (number <= surahNames.length) {
      return surahNames[number - 1];
    }
    return 'السورة $number';
  }

  String _getSurahNameFrench(int number) {
    if (number <= AppConstants.surahNamesFrench.length) {
      return AppConstants.surahNamesFrench[number - 1];
    }
    return 'Sourate $number';
  }

  int _getAyahCount(int number) {
    // Nombre d'ayahs par sourate (échantillon)
    const ayahCounts = [
      7, 286, 200, 176, 120, 165, 206, 75, 129, 109,
      123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    ];
    
    if (number <= ayahCounts.length) {
      return ayahCounts[number - 1];
    }
    return 0; // Valeur par défaut
  }

  String _getRevelationType(int number) {
    // Type de révélation par sourate (échantillon)
    const revelationTypes = [
      'Meccan', 'Medinan', 'Medinan', 'Medinan', 'Medinan',
      'Meccan', 'Meccan', 'Medinan', 'Medinan', 'Meccan',
      'Meccan', 'Meccan', 'Medinan', 'Meccan', 'Meccan',
      'Meccan', 'Meccan', 'Meccan', 'Meccan', 'Meccan',
    ];
    
    if (number <= revelationTypes.length) {
      return revelationTypes[number - 1];
    }
    return 'Meccan'; // Valeur par défaut
  }
}
