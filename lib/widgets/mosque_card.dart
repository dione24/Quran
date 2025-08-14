import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/mosque.dart';
import '../utils/app_constants.dart';

class MosqueCard extends StatelessWidget {
  final Mosque mosque;
  final VoidCallback? onTap;
  final VoidCallback? onNavigate;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;
  final bool showActions;

  const MosqueCard({
    Key? key,
    required this.mosque,
    this.onTap,
    this.onNavigate,
    this.onFavoriteToggle,
    this.isFavorite = false,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image et badges
            if (mosque.photos != null && mosque.photos!.isNotEmpty)
              _buildImageSection(),
            
            // Informations principales
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom et type
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mosque.name,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            _buildTypeBadge(),
                          ],
                        ),
                      ),
                      // Bouton favori
                      if (showActions)
                        IconButton(
                          onPressed: onFavoriteToggle,
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey,
                            size: 24.sp,
                          ),
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // Adresse
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18.sp,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          mosque.address,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // Distance et temps
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.directions_walk,
                        mosque.formattedDistance,
                        Colors.blue,
                      ),
                      SizedBox(width: 8.w),
                      _buildInfoChip(
                        Icons.access_time,
                        mosque.estimatedWalkingTime,
                        Colors.orange,
                      ),
                      if (mosque.isOpen != null) ...[
                        SizedBox(width: 8.w),
                        _buildInfoChip(
                          Icons.schedule,
                          mosque.isOpen! ? 'Ouvert' : 'Fermé',
                          mosque.isOpen! ? Colors.green : Colors.red,
                        ),
                      ],
                    ],
                  ),
                  
                  // Note et avis
                  if (mosque.rating != null) ...[
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 20.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          mosque.rating!.toStringAsFixed(1),
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (mosque.totalRatings != null) ...[
                          SizedBox(width: 4.w),
                          Text(
                            '(${mosque.totalRatings} avis)',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  
                  // Services disponibles
                  if (mosque.services != null && mosque.services!.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _buildServiceChips(),
                    ),
                  ],
                  
                  // Actions
                  if (showActions) ...[
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.navigation,
                            label: 'Itinéraire',
                            onTap: onNavigate,
                            isPrimary: true,
                          ),
                        ),
                        if (mosque.phoneNumber != null) ...[
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.phone,
                              label: 'Appeler',
                              onTap: () => _makePhoneCall(mosque.phoneNumber!),
                              isPrimary: false,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          child: CachedNetworkImage(
            imageUrl: mosque.photos!.first,
            height: 150.h,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 150.h,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  color: AppConstants.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 150.h,
              color: Colors.grey[200],
              child: Icon(
                Icons.mosque,
                size: 50.sp,
                color: Colors.grey[400],
              ),
            ),
          ),
        ),
        
        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    String typeText;
    Color badgeColor;
    
    switch (mosque.type) {
      case MosqueType.grand:
        typeText = 'Grande Mosquée';
        badgeColor = Colors.purple;
        break;
      case MosqueType.historical:
        typeText = 'Historique';
        badgeColor = Colors.brown;
        break;
      case MosqueType.educational:
        typeText = 'École Coranique';
        badgeColor = Colors.blue;
        break;
      case MosqueType.community:
        typeText = 'Centre Communautaire';
        badgeColor = Colors.green;
        break;
      default:
        typeText = 'Mosquée';
        badgeColor = AppConstants.primaryColor;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        typeText,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12.sp,
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildServiceChips() {
    final services = <Widget>[];
    
    if (mosque.hasParking) {
      services.add(_buildServiceChip('Parking', Icons.local_parking));
    }
    if (mosque.hasWudu) {
      services.add(_buildServiceChip('Ablutions', Icons.water_drop));
    }
    if (mosque.hasWomenSection) {
      services.add(_buildServiceChip('Section Femmes', Icons.woman));
    }
    if (mosque.hasSchool) {
      services.add(_buildServiceChip('École', Icons.school));
    }
    if (mosque.hasLibrary) {
      services.add(_buildServiceChip('Bibliothèque', Icons.menu_book));
    }
    if (mosque.hasAirConditioning) {
      services.add(_buildServiceChip('Climatisation', Icons.ac_unit));
    }
    if (mosque.hasWheelchairAccess) {
      services.add(_buildServiceChip('Accès PMR', Icons.accessible));
    }
    
    return services;
  }

  Widget _buildServiceChip(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: Colors.grey[700],
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11.sp,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary ? AppConstants.primaryColor : Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: isPrimary ? null : Border.all(
              color: AppConstants.primaryColor,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18.sp,
                color: isPrimary ? Colors.white : AppConstants.primaryColor,
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? Colors.white : AppConstants.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}

// Version compacte pour les listes
class MosqueListTile extends StatelessWidget {
  final Mosque mosque;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const MosqueListTile({
    Key? key,
    required this.mosque,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      leading: Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          Icons.mosque,
          color: AppConstants.primaryColor,
          size: 24.sp,
        ),
      ),
      title: Text(
        mosque.name,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mosque.address,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(
                Icons.directions_walk,
                size: 14.sp,
                color: Colors.grey,
              ),
              SizedBox(width: 4.w),
              Text(
                mosque.formattedDistance,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
              ),
              if (mosque.rating != null) ...[
                SizedBox(width: 12.w),
                Icon(
                  Icons.star,
                  size: 14.sp,
                  color: Colors.amber,
                ),
                SizedBox(width: 4.w),
                Text(
                  mosque.rating!.toStringAsFixed(1),
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: IconButton(
        onPressed: onFavoriteToggle,
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : Colors.grey,
          size: 20.sp,
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }
}