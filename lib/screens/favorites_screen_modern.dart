import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_constants.dart';

import '../providers/app_providers.dart';
import '../widgets/ayah_tile.dart';

class FavoritesScreenModern extends ConsumerStatefulWidget {
  const FavoritesScreenModern({Key? key}) : super(key: key);

  @override
  ConsumerState<FavoritesScreenModern> createState() =>
      _FavoritesScreenModernState();
}

class _FavoritesScreenModernState extends ConsumerState<FavoritesScreenModern>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

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
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final readingHistory = ref.watch(readingHistoryProvider);
    final quranDataAsync = ref.watch(quranDataProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.favoriteColor.withOpacity(0.05),
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
                        AppConstants.favoriteColor,
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
                          Icons.favorite,
                          color: Colors.white,
                          size: 32.sp,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Favoris & Historique',
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
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(48.h),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20.r)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppConstants.favoriteColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppConstants.favoriteColor,
                    indicatorWeight: 3,
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.favorite),
                        text: 'Favoris (${favorites.length})',
                      ),
                      Tab(
                        icon: const Icon(Icons.history),
                        text: 'Historique (${readingHistory.length})',
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    switch (value) {
                      case 'clear_favorites':
                        _showClearFavoritesDialog();
                        break;
                      case 'clear_history':
                        _showClearHistoryDialog();
                        break;
                      case 'export_data':
                        _exportData();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'clear_favorites',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all),
                          SizedBox(width: 8),
                          Text('Effacer les favoris'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_history',
                      child: Row(
                        children: [
                          Icon(Icons.history_toggle_off),
                          SizedBox(width: 8),
                          Text('Effacer l\'historique'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export_data',
                      child: Row(
                        children: [
                          Icon(Icons.file_download),
                          SizedBox(width: 8),
                          Text('Exporter les données'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Contenu des tabs avec animation
            SliverFillRemaining(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20.r)),
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFavoritesTab(quranDataAsync, favorites),
                      _buildHistoryTab(quranDataAsync, readingHistory),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesTab(
      AsyncValue<dynamic> quranDataAsync, List<String> favorites) {
    if (favorites.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: 'Aucun favori',
        subtitle:
            'Ajoutez vos versets préférés en appuyant sur ♡ lors de la lecture',
        color: AppConstants.favoriteColor,
      );
    }

    return quranDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          _buildErrorState('Erreur lors du chargement des favoris'),
      data: (quranData) {
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final favoriteId = favorites[index];
            final parts = favoriteId.split('_');

            if (parts.length != 2) return const SizedBox.shrink();

            final surahNumber = int.tryParse(parts[0]);
            final ayahNumber = int.tryParse(parts[1]);

            if (surahNumber == null || ayahNumber == null)
              return const SizedBox.shrink();

            final surah = quranData.getSurahByNumber(surahNumber);
            if (surah == null) return const SizedBox.shrink();

            final ayah = surah.ayahs.firstWhere(
              (a) => a.numberInSurah == ayahNumber,
              orElse: () => null,
            );

            if (ayah == null) return const SizedBox.shrink();

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.favoriteColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: AyahTile(
                ayah: ayah,
                surahNumber: surahNumber,
                showTranslation: true,
                onFavorite: () {
                  ref
                      .read(favoritesProvider.notifier)
                      .removeFavorite(favoriteId);
                  _showSnackBar(
                      'Retiré des favoris', AppConstants.favoriteColor);
                },
                onPlay: () {
                  ref.read(ttsServiceProvider).speak(ayah.text);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab(
      AsyncValue<dynamic> quranDataAsync, List<String> history) {
    if (history.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'Aucun historique',
        subtitle: 'Votre historique de lecture apparaîtra ici automatiquement',
        color: AppConstants.primaryColor,
      );
    }

    return quranDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          _buildErrorState('Erreur lors du chargement de l\'historique'),
      data: (quranData) {
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final historyId = history[index];
            final parts = historyId.split('_');

            if (parts.length != 2) return const SizedBox.shrink();

            final surahNumber = int.tryParse(parts[0]);
            final ayahNumber = int.tryParse(parts[1]);

            if (surahNumber == null || ayahNumber == null)
              return const SizedBox.shrink();

            final surah = quranData.getSurahByNumber(surahNumber);
            if (surah == null) return const SizedBox.shrink();

            final ayah = surah.ayahs.firstWhere(
              (a) => a.numberInSurah == ayahNumber,
              orElse: () => null,
            );

            if (ayah == null) return const SizedBox.shrink();

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: AyahTile(
                ayah: ayah,
                surahNumber: surahNumber,
                showTranslation: true,
                onPlay: () {
                  ref.read(ttsServiceProvider).speak(ayah.text);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64.sp,
                color: color.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 12.h),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: AppConstants.errorColor,
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppConstants.errorColor,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showClearFavoritesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.warning, color: AppConstants.warningColor),
            SizedBox(width: 8.w),
            const Text('Effacer les favoris'),
          ],
        ),
        content:
            const Text('Êtes-vous sûr de vouloir supprimer tous vos favoris ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final favorites = ref.read(favoritesProvider);
              for (final favorite in favorites) {
                ref.read(favoritesProvider.notifier).removeFavorite(favorite);
              }
              _showSnackBar('Tous les favoris ont été supprimés',
                  AppConstants.warningColor);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.warningColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.warning, color: AppConstants.warningColor),
            SizedBox(width: 8.w),
            const Text('Effacer l\'historique'),
          ],
        ),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer tout l\'historique ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implémenter l'effacement de l'historique
              _showSnackBar('Historique effacé (fonctionnalité à implémenter)',
                  AppConstants.warningColor);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.warningColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    _showSnackBar('Export des données (fonctionnalité à implémenter)',
        AppConstants.infoColor);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
