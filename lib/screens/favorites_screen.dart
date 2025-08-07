import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/ayah_tile.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final readingHistory = ref.watch(readingHistoryProvider);
    final quranDataAsync = ref.watch(quranDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoris & Historique'),
        bottom: TabBar(
          controller: _tabController,
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
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear_favorites':
                  _showClearDialog('favoris', () async {
                    await ref.read(favoritesProvider.notifier).clearAll();
                  });
                  break;
                case 'clear_history':
                  _showClearDialog('historique', () async {
                    await ref.read(readingHistoryProvider.notifier).clearAll();
                  });
                  break;
                case 'export':
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
                    Text('Effacer favoris'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_history',
                child: Row(
                  children: [
                    Icon(Icons.history_toggle_off),
                    SizedBox(width: 8),
                    Text('Effacer historique'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Exporter'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Favoris
          _buildFavoritesTab(favorites, quranDataAsync),
          
          // Onglet Historique
          _buildHistoryTab(readingHistory, quranDataAsync),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(List<String> favorites, AsyncValue<dynamic> quranDataAsync) {
    if (favorites.isEmpty) {
      return _buildEmptyState(
        Icons.favorite_border,
        'Aucun favori',
        'Ajoutez des versets à vos favoris en appuyant sur l\'icône cœur lors de la lecture.',
      );
    }

    return quranDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
      data: (quranData) {
        final favoriteAyahs = _getAyahsFromIds(favorites, quranData);
        
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: favoriteAyahs.length,
          itemBuilder: (context, index) {
            final item = favoriteAyahs[index];
            return Card(
              margin: EdgeInsets.only(bottom: 12.h),
              child: Column(
                children: [
                  // En-tête avec info de la sourate
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12.r),
                        topRight: Radius.circular(12.r),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: AppConstants.favoriteColor,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${item['surah'].name} - Verset ${item['ayah'].numberInSurah}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item['surah'].englishNameTranslation,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  
                  // Contenu de l'ayah
                  AyahTile(
                    ayah: item['ayah'],
                    surahNumber: item['surah'].number,
                    showTranslation: true,
                    isHighlighted: false,
                    isPlaying: false,
                    showFavoriteButton: false, // Déjà dans les favoris
                    onTap: () {
                      // Naviguer vers cet ayah
                      _navigateToAyah(item['surah'].number, item['ayah'].number);
                      context.push('/surah/${item['surah'].number}');
                    },
                    onPlay: () {
                      ref.read(ttsServiceProvider).speak(item['ayah'].text);
                    },
                    onFavorite: () async {
                      // Retirer des favoris
                      final ayahId = '${item['surah'].number}_${item['ayah'].number}';
                      await ref.read(favoritesProvider.notifier).removeFavorite(ayahId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Retiré des favoris')),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab(List<String> history, AsyncValue<dynamic> quranDataAsync) {
    if (history.isEmpty) {
      return _buildEmptyState(
        Icons.history,
        'Aucun historique',
        'Votre historique de lecture apparaîtra ici au fur et à mesure de votre utilisation.',
      );
    }

    return quranDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
      data: (quranData) {
        final historyAyahs = _getAyahsFromIds(history.take(50).toList(), quranData);
        
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: historyAyahs.length,
          itemBuilder: (context, index) {
            final item = historyAyahs[index];
            final isRecent = index < 5; // Les 5 derniers sont marqués comme récents
            
            return Card(
              margin: EdgeInsets.only(bottom: 12.h),
              child: ListTile(
                leading: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: isRecent 
                        ? AppConstants.primaryColor 
                        : Colors.grey[400],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Text(
                      '${item['surah'].number}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  '${item['surah'].name} - Verset ${item['ayah'].numberInSurah}',
                  style: AppTheme.arabicTextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['surah'].englishNameTranslation,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (isRecent)
                      Container(
                        margin: EdgeInsets.only(top: 4.h),
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'Récent',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        ref.read(ttsServiceProvider).speak(item['ayah'].text);
                      },
                      icon: const Icon(Icons.play_arrow),
                      color: AppConstants.primaryColor,
                    ),
                    IconButton(
                      onPressed: () async {
                        final ayahId = '${item['surah'].number}_${item['ayah'].number}';
                        final favorites = ref.read(favoritesProvider);
                        
                        if (favorites.contains(ayahId)) {
                          await ref.read(favoritesProvider.notifier).removeFavorite(ayahId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Retiré des favoris')),
                          );
                        } else {
                          await ref.read(favoritesProvider.notifier).addFavorite(ayahId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ajouté aux favoris')),
                          );
                        }
                      },
                      icon: Icon(
                        ref.watch(favoritesProvider).contains(
                          '${item['surah'].number}_${item['ayah'].number}'
                        ) ? Icons.favorite : Icons.favorite_border,
                      ),
                      color: AppConstants.favoriteColor,
                    ),
                  ],
                ),
                onTap: () {
                  _navigateToAyah(item['surah'].number, item['ayah'].number);
                  context.push('/surah/${item['surah'].number}');
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppConstants.errorColor,
          ),
          SizedBox(height: 16.h),
          Text(
            'Erreur de chargement',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 8.h),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAyahsFromIds(List<String> ids, dynamic quranData) {
    final result = <Map<String, dynamic>>[];
    
    for (final id in ids) {
      final parts = id.split('_');
      if (parts.length != 2) continue;
      
      final surahNumber = int.tryParse(parts[0]);
      final ayahNumber = int.tryParse(parts[1]);
      
      if (surahNumber == null || ayahNumber == null) continue;
      
      final surah = quranData.getSurahByNumber(surahNumber);
      if (surah == null) continue;
      
      final ayah = () {
        try {
          return surah.ayahs.firstWhere((a) => a.number == ayahNumber);
        } catch (_) {
          return null;
        }
      }();
      
      if (ayah != null) {
        result.add({
          'surah': surah,
          'ayah': ayah,
        });
      }
    }
    
    return result;
  }

  void _navigateToAyah(int surahNumber, int ayahNumber) {
    ref.read(currentSurahProvider.notifier).state = surahNumber;
    ref.read(currentAyahProvider.notifier).state = ayahNumber;
    
    // Naviguer vers l'écran de lecture
    // (Ceci nécessiterait une communication avec le widget parent pour changer d'onglet)
  }

  void _showClearDialog(String type, Future<void> Function() onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Effacer $type'),
        content: Text('Êtes-vous sûr de vouloir effacer tous les $type ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await onConfirm();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${type.capitalize()} effacés')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
            ),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    // Export simple: afficher un JSON minimal des favoris et historique
    final favorites = ref.read(favoritesProvider);
    final history = ref.read(readingHistoryProvider);
    final json = '{\n  "favorites": ${favorites.toString()},\n  "history": ${history.toString()}\n}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export des données'),
        content: SingleChildScrollView(child: Text(json)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
