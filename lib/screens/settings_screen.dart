import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/app_constants.dart';
import '../providers/app_providers.dart';
import '../services/prayer_times_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  PackageInfo? packageInfo;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();

    // Animations pour l'entrée
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    // Démarrer les animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = info;
    });
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
              AppConstants.primaryColor.withOpacity(0.05),
              AppConstants.secondaryColor.withOpacity(0.03),
              Colors.white,
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // AppBar personnalisée avec gradient
            SliverAppBar(
              expandedHeight: 120.h,
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
                        AppConstants.primaryColor,
                        AppConstants.secondaryColor,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 20.h),
                        Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 32.sp,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Paramètres',
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
            ),

            // Contenu principal
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      children: [
                        SizedBox(height: 20.h),

                        // Section Heures de Prière - Design moderne
                        _buildModernSection(
                          icon: Icons.access_time,
                          title: 'Heures de Prière',
                          color: AppConstants.primaryColor,
                          children: [
                            _buildPrayerTimesSettings(),
                          ],
                        ),

                        SizedBox(height: 20.h),

                        // Section Application - Design coloré
                        _buildModernSection(
                          icon: Icons.smartphone,
                          title: 'Application',
                          color: const Color(0xFF6C63FF),
                          children: [
                            _buildAppSettings(),
                          ],
                        ),

                        SizedBox(height: 20.h),

                        // Section Données - Design avec icône
                        _buildModernSection(
                          icon: Icons.storage,
                          title: 'Données',
                          color: const Color(0xFF26A69A),
                          children: [
                            _buildDataSettings(),
                          ],
                        ),

                        SizedBox(height: 20.h),

                        // Section À Propos - Design élégant
                        _buildModernSection(
                          icon: Icons.info,
                          title: 'À Propos',
                          color: const Color(0xFFFF7043),
                          children: [
                            _buildAboutSettings(),
                          ],
                        ),

                        SizedBox(height: 40.h),

                        // Footer avec citation
                        _buildFooter(),
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

  Widget _buildModernSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
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
              top: BorderSide(color: color, width: 4),
            ),
          ),
          child: Column(
            children: [
              // En-tête de section avec gradient
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      color.withOpacity(0.1),
                      color.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Text(
                        title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenu de la section
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerTimesSettings() {
    final prayerService = PrayerTimesService();

    return Column(
      children: [
        // Toggle moderne avec animation
        StreamBuilder<bool>(
          stream: prayerService.visibilityStream,
          initialData: false,
          builder: (context, snapshot) {
            final isVisible = snapshot.data ?? false;

            return Container(
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: isVisible
                    ? AppConstants.primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isVisible
                      ? AppConstants.primaryColor.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color:
                          isVisible ? AppConstants.primaryColor : Colors.grey,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Afficher les heures de prière',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          isVisible
                              ? 'Heures affichées sur l\'accueil'
                              : 'Heures masquées pour plus de simplicité',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Switch(
                      key: ValueKey(isVisible),
                      value: isVisible,
                      onChanged: (_) => prayerService.toggleVisibility(),
                      activeColor: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Options avancées
        _buildModernListTile(
          icon: Icons.calculate,
          title: 'Méthode de calcul',
          subtitle: 'Choisir selon votre région',
          onTap: () => _showCalculationMethodDialog(),
          color: AppConstants.primaryColor,
        ),

        _buildModernListTile(
          icon: Icons.my_location,
          title: 'Actualiser la position',
          subtitle: 'Recharger selon votre localisation',
          onTap: () => _updatePrayerTimes(),
          color: AppConstants.primaryColor,
        ),
      ],
    );
  }

  Widget _buildAppSettings() {
    return Column(
      children: [
        _buildModernListTile(
          icon: Icons.palette,
          title: 'Thème de l\'application',
          subtitle: 'Clair • Sombre à venir',
          onTap: () => _showThemeDialog(),
          color: const Color(0xFF6C63FF),
        ),
        _buildModernListTile(
          icon: Icons.text_fields,
          title: 'Taille du texte',
          subtitle: 'Ajuster pour votre confort',
          onTap: () => _showFontSizeDialog(),
          color: const Color(0xFF6C63FF),
        ),
        _buildModernListTile(
          icon: Icons.language,
          title: 'Langue',
          subtitle: 'Français • Arabe à venir',
          onTap: () => _showLanguageDialog(),
          color: const Color(0xFF6C63FF),
        ),
      ],
    );
  }

  Widget _buildDataSettings() {
    return Column(
      children: [
        _buildModernListTile(
          icon: Icons.cloud_download,
          title: 'Recharger le Coran',
          subtitle: 'Télécharger les dernières données',
          onTap: () => _showReloadDataDialog(),
          color: const Color(0xFF26A69A),
        ),
        _buildModernListTile(
          icon: Icons.favorite,
          title: 'Sauvegarder les favoris',
          subtitle: 'Exporter vers le cloud',
          onTap: () => _showBackupDialog(),
          color: const Color(0xFF26A69A),
        ),
        _buildModernListTile(
          icon: Icons.cleaning_services,
          title: 'Nettoyer l\'historique',
          subtitle: 'Supprimer les traces de lecture',
          onTap: () => _showClearHistoryDialog(),
          color: const Color(0xFF26A69A),
        ),
      ],
    );
  }

  Widget _buildAboutSettings() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFF7043).withOpacity(0.1),
                const Color(0xFFFF7043).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mosque,
                  color: Colors.white,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Coran Intelligent',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFFFF7043),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 8.h),
              Text(
                packageInfo != null
                    ? 'Version ${packageInfo!.version} (${packageInfo!.buildNumber})'
                    : 'Chargement...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Développé avec ❤️ pour la communauté musulmane',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        _buildModernListTile(
          icon: Icons.help_outline,
          title: 'Guide d\'utilisation',
          subtitle: 'Apprendre à utiliser l\'application',
          onTap: () => _showUserGuideDialog(),
          color: const Color(0xFFFF7043),
        ),
        _buildModernListTile(
          icon: Icons.feedback,
          title: 'Nous contacter',
          subtitle: 'Suggestions et commentaires',
          onTap: () => _showFeedbackDialog(),
          color: const Color(0xFFFF7043),
        ),
      ],
    );
  }

  Widget _buildModernListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: color.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color.withOpacity(0.5),
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor.withOpacity(0.1),
            AppConstants.secondaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Text(
            '🤲',
            style: TextStyle(fontSize: 32.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            '"وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا"',
            style: TextStyle(
              fontSize: 18.sp,
              fontFamily: 'Amiri',
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Et quiconque craint Allah, Il lui donnera une issue favorable',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            '(Coran 65:2)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  // Méthodes pour les dialogs (versions améliorées)
  void _showCalculationMethodDialog() {
    final prayerService = PrayerTimesService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppConstants.primaryColor,
                    AppConstants.secondaryColor
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calculate, color: Colors.white, size: 24.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Méthodes de calcul',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: prayerService.calculationMethods.length,
                itemBuilder: (context, index) {
                  final methods = prayerService.calculationMethods;
                  final methodId = methods.keys.elementAt(index);
                  final methodName = methods[methodId]!;

                  return Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          prayerService.setCalculationMethod(methodId);
                          Navigator.pop(context);
                          _showSuccessSnackBar('Méthode changée: $methodName');
                        },
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.grey.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            methodName,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updatePrayerTimes() async {
    _showLoadingSnackBar('🔄 Actualisation des heures de prière...');

    try {
      final prayerService = PrayerTimesService();
      await prayerService.forceUpdate();
      _showSuccessSnackBar('✅ Heures de prière mises à jour !');
    } catch (e) {
      _showErrorSnackBar('❌ Erreur: $e');
    }
  }

  void _showThemeDialog() {
    _showInfoSnackBar('🎨 Mode sombre à venir dans une prochaine version');
  }

  void _showFontSizeDialog() {
    _showInfoSnackBar('🔤 Personnalisation des polices à venir');
  }

  void _showLanguageDialog() {
    _showInfoSnackBar('🌍 Support multilingue à venir');
  }

  void _showReloadDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.cloud_download, color: AppConstants.primaryColor),
            SizedBox(width: 8.w),
            const Text('Recharger les données'),
          ],
        ),
        content: const Text(
          'Cette action va télécharger à nouveau toutes les données du Coran. '
          'Cela peut prendre quelques minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showLoadingSnackBar('🔄 Rechargement des données...');

              try {
                final db = ref.read(quranDBProvider);
                await db.clearAndReload();
                ref.invalidate(quranDataProvider);
                _showSuccessSnackBar('✅ Données rechargées avec succès !');
              } catch (e) {
                _showErrorSnackBar('❌ Erreur: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('Recharger'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    _showInfoSnackBar('☁️ Sauvegarde cloud à venir');
  }

  void _showClearHistoryDialog() {
    _showInfoSnackBar('🗑️ Nettoyage de l\'historique à venir');
  }

  void _showUserGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: const Text('Guide d\'utilisation'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideItem('🏠', 'Accueil',
                  'Salutations, heures de prière et actions rapides'),
              _buildGuideItem(
                  '📖', 'Lecture', 'Parcourez les 114 sourates avec audio'),
              _buildGuideItem('🎙️', 'Écoute',
                  'Reconnaissance vocale pour identifier les versets'),
              _buildGuideItem('⭐', 'Favoris', 'Gérez vos versets préférés'),
              _buildGuideItem(
                  '🕌', 'Heures de Prière', 'Activez le toggle pour les voir'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    _showInfoSnackBar('📧 Système de feedback à venir');
  }

  Widget _buildGuideItem(String icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: TextStyle(fontSize: 20.sp)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes pour les snackbars améliorées
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.infoColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }
}
