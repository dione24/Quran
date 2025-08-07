import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppConstants.backgroundColor,
      fontFamily: 'Tajawal',
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppConstants.textColor,
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
        ),
        iconTheme: IconThemeData(
          color: AppConstants.primaryColor,
          size: 24.sp,
        ),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32.sp,
          fontWeight: FontWeight.bold,
          color: AppConstants.textColor,
          fontFamily: 'Tajawal',
        ),
        displayMedium: TextStyle(
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
          color: AppConstants.textColor,
          fontFamily: 'Tajawal',
        ),
        headlineLarge: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: AppConstants.textColor,
          fontFamily: 'Tajawal',
        ),
        headlineMedium: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: AppConstants.textColor,
          fontFamily: 'Tajawal',
        ),
        bodyLarge: TextStyle(
          fontSize: 16.sp,
          color: AppConstants.textColor,
          fontFamily: 'Tajawal',
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.sp,
          color: AppConstants.textColor,
          fontFamily: 'Tajawal',
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12.sp,
          color: AppConstants.secondaryTextColor,
          fontFamily: 'Tajawal',
        ),
      ),

      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          textStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Tajawal',
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppConstants.darkBackgroundColor,
      fontFamily: 'Tajawal',
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppConstants.darkTextColor,
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
        ),
        iconTheme: IconThemeData(
          color: AppConstants.primaryColor,
          size: 24.sp,
        ),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32.sp,
          fontWeight: FontWeight.bold,
          color: AppConstants.darkTextColor,
          fontFamily: 'Tajawal',
        ),
        headlineLarge: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: AppConstants.darkTextColor,
          fontFamily: 'Tajawal',
        ),
        bodyLarge: TextStyle(
          fontSize: 16.sp,
          color: AppConstants.darkTextColor,
          fontFamily: 'Tajawal',
          height: 1.5,
        ),
      ),

      cardTheme: CardTheme(
        color: AppConstants.darkCardColor,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  static TextStyle arabicTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'AmiriQuran',
      fontSize: fontSize ?? 18.sp,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? AppConstants.textColor,
      height: height ?? 2.0,
    );
  }
}
