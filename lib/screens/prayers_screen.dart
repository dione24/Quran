import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_constants.dart';
import '../services/prayer_times_service.dart';
import '../widgets/prayer_times_widget.dart';

class PrayersScreen extends ConsumerStatefulWidget {
  const PrayersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends ConsumerState<PrayersScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation d'entrée
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.secondaryColor.withOpacity(0.05),
              AppConstants.primaryColor.withOpacity(0.03),
              Colors.white,
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // AppBar moderne avec gradient
            SliverAppBar(
              expandedHeight: 140.h,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppConstants.secondaryColor,
                        AppConstants.primaryColor,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 20.h),
                        Icon(
                          Icons.mosque,
                          color: Colors.white,
                          size: 32.sp,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Heures de Prières',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onSelected: (value) {
                    switch (value) {
                      case 'calculation_method':
                        _showCalculationMethodDialog();
                        break;
                      case 'location':
                        _showLocationDialog();
                        break;
                      case 'notifications':
                        _showNotificationsDialog();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'calculation_method',
                      child: Row(
                        children: [
                          Icon(Icons.calculate),
                          SizedBox(width: 8),
                          Text('Méthode de calcul'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'location',
                      child: Row(
                        children: [
                          Icon(Icons.location_on),
                          SizedBox(width: 8),
                          Text('Localisation'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'notifications',
                      child: Row(
                        children: [
                          Icon(Icons.notifications),
                          SizedBox(width: 8),
                          Text('Notifications'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Contenu principal avec animation
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20.r)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      children: [
                        // Widget des heures de prières principal
                        const PrayerTimesWidget(),

                        SizedBox(height: 24.h),

                        // Calendrier islamique
                        _buildIslamicCalendar(),

                        SizedBox(height: 24.h),

                        // Qibla et informations supplémentaires
                        _buildAdditionalInfo(),

                        SizedBox(height: 24.h),

                        // Conseils spirituels
                        _buildSpiritualTips(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIslamicCalendar() {
    return Container(
      margin: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppConstants.secondaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppConstants.secondaryColor, width: 4),
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppConstants.secondaryColor.withOpacity(0.1),
                  AppConstants.secondaryColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppConstants.secondaryColor,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.secondaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Text(
                        'Calendrier Islamique',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppConstants.secondaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Date actuelle en hijri
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppConstants.secondaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aujourd\'hui',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              Text(
                                _getCurrentHijriDate(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppConstants.secondaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.star_half,
                            color: AppConstants.secondaryColor.withOpacity(0.6),
                            size: 32.sp,
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Divider(color: Colors.grey[200]),
                      SizedBox(height: 12.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDateInfo('Jour', _getCurrentDayOfWeek()),
                          _buildDateInfo('Mois', _getCurrentHijriMonth()),
                          _buildDateInfo('Année', _getCurrentHijriYear()),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppConstants.secondaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      margin: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppConstants.primaryColor, width: 4),
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppConstants.primaryColor.withOpacity(0.1),
                  AppConstants.primaryColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.explore,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Text(
                        'Direction Qibla & Infos',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.navigation,
                        title: 'Direction Qibla',
                        value: '45°',
                        subtitle: 'Nord-Est',
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.location_on,
                        title: 'Distance Mecque',
                        value: '5,847 km',
                        subtitle: 'Kaaba',
                        color: AppConstants.accentColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpiritualTips() {
    return Container(
      margin: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppConstants.favoriteColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppConstants.favoriteColor, width: 4),
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppConstants.favoriteColor.withOpacity(0.1),
                  AppConstants.favoriteColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppConstants.favoriteColor,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.favoriteColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.lightbulb,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Text(
                        'Conseil Spirituel du Jour',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppConstants.favoriteColor,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppConstants.favoriteColor.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💫 La prière est le pilier de la religion',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppConstants.favoriteColor,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Accomplir ses prières à l\'heure est une source de paix intérieure et de connexion spirituelle. Prenez quelques minutes avant chaque prière pour vous recueillir.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: AppConstants.favoriteColor.withOpacity(0.6),
                            size: 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Prochaine prière dans : ',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                          StreamBuilder<PrayerTime>(
                            stream: PrayerTimesService().nextPrayerStream,
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data?.name ?? 'Chargement...',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppConstants.favoriteColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Méthodes utilitaires pour les dates
  String _getCurrentHijriDate() {
    // Implémentation simplifiée - à améliorer avec une vraie conversion
    return '15 Rajab 1446 H';
  }

  String _getCurrentDayOfWeek() {
    final days = [
      'Dimanche',
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi'
    ];
    return days[DateTime.now().weekday % 7];
  }

  String _getCurrentHijriMonth() {
    return 'Rajab';
  }

  String _getCurrentHijriYear() {
    return '1446 H';
  }

  // Dialogues de configuration
  void _showCalculationMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppConstants.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.calculate,
                color: AppConstants.secondaryColor,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            const Text('Méthode de Calcul'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Choisissez la méthode de calcul des heures de prières :'),
            SizedBox(height: 16.h),
            // Liste des méthodes - à implémenter
            ListTile(
              title: const Text('Ligue Islamique Mondiale'),
              leading: Radio(value: 1, groupValue: 1, onChanged: (v) {}),
            ),
            ListTile(
              title:
                  const Text('Université des Sciences Islamiques de Karachi'),
              leading: Radio(value: 2, groupValue: 1, onChanged: (v) {}),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Appliquer la méthode sélectionnée
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.secondaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.location_on,
                color: AppConstants.primaryColor,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            const Text('Localisation'),
          ],
        ),
        content: const Text(
          'L\'application utilise votre position GPS pour calculer les heures de prières avec précision.\n\n'
          'Assurez-vous d\'avoir activé la géolocalisation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Actualiser la localisation
              // PrayerTimesService().updateLocation(); // À implémenter
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('Actualiser'),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppConstants.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.notifications,
                color: AppConstants.accentColor,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            const Text('Notifications'),
          ],
        ),
        content: const Text(
          'Configurez les notifications pour être alerté avant chaque prière.\n\n'
          'Fonctionnalité à implémenter prochainement.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}
