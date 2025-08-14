import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/ayah_tile.dart';
import '../widgets/quran_audio_player.dart';
import '../models/surah.dart';

class ReadScreen extends ConsumerStatefulWidget {
  final int? surahNumber;

  const ReadScreen({Key? key, this.surahNumber}) : super(key: key);

  @override
  ConsumerState<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends ConsumerState<ReadScreen> {
  int? selectedSurahNumber;
  ScrollController _scrollController = ScrollController();
  bool showTranslation = true;
  bool isReadingMode = false; // Mode lecture concentrée
  double textSizeMultiplier = 1.0; // Multiplicateur de taille du texte
  bool showAudioPlayer = false; // Affichage du lecteur audio

  @override
  void initState() {
    super.initState();
    selectedSurahNumber = widget.surahNumber;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quranDataAsync = ref.watch(quranDataProvider);
    final currentAyah = ref.watch(currentAyahProvider);
    final isSpeaking = ref.watch(isSpeakingProvider);

    return Scaffold(
      appBar: AppBar(
        title: selectedSurahNumber != null
            ? GestureDetector(
                onTap: () => _showSurahSelector(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Sourate $selectedSurahNumber'),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              )
            : GestureDetector(
                onTap: () => _showSurahSelector(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Sélectionner une sourate'),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
        actions: [
          // Bouton audio
          if (selectedSurahNumber != null && !isReadingMode)
            IconButton(
              icon: Icon(
                showAudioPlayer ? Icons.headphones : Icons.headphones_outlined,
                color: showAudioPlayer ? AppConstants.accentColor : null,
              ),
              onPressed: () {
                setState(() {
                  showAudioPlayer = !showAudioPlayer;
                });
              },
              tooltip:
                  showAudioPlayer ? 'Masquer lecteur audio' : 'Lecteur audio',
            ),

          // Mode lecture concentrée
          IconButton(
            icon: Icon(
              isReadingMode ? Icons.fullscreen_exit : Icons.chrome_reader_mode,
              color: isReadingMode ? AppConstants.primaryColor : null,
            ),
            onPressed: () {
              setState(() {
                isReadingMode = !isReadingMode;
                if (isReadingMode) {
                  showAudioPlayer = false; // Masquer le lecteur en mode lecture
                }
              });
            },
            tooltip: isReadingMode
                ? 'Quitter mode lecture'
                : 'Mode lecture concentrée',
          ),

          // Toggle traduction (masqué en mode lecture)
          if (!isReadingMode)
            IconButton(
              icon: Icon(
                showTranslation ? Icons.translate : Icons.translate_outlined,
              ),
              onPressed: () {
                setState(() {
                  showTranslation = !showTranslation;
                });
              },
              tooltip: 'Afficher/Masquer la traduction',
            ),
          // Menu des options (masqué en mode lecture)
          if (!isReadingMode)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                switch (value) {
                  case 'font_size':
                    _showFontSizeDialog();
                    break;
                  case 'search':
                    _showSearchDialog();
                    break;
                  case 'settings':
                    _showSettingsDialog();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'font_size',
                  child: ListTile(
                    leading: Icon(Icons.text_fields),
                    title: Text('Taille de police'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'search',
                  child: ListTile(
                    leading: Icon(Icons.search),
                    title: Text('Rechercher'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Paramètres'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: quranDataAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
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
        ),
        data: (quranData) {
          if (selectedSurahNumber == null) {
            return _buildSurahList(quranData.surahs);
          }

          final surah = quranData.getSurahByNumber(selectedSurahNumber!);
          if (surah == null) {
            return const Center(
              child: Text('Sourate non trouvée'),
            );
          }

          return Column(
            children: [
              // Lecteur audio (si activé)
              if (showAudioPlayer)
                QuranAudioPlayer(
                  surahNumber: surah.number,
                  surahName: surah.name,
                  onClose: () {
                    setState(() {
                      showAudioPlayer = false;
                    });
                  },
                ),

              // Contenu de la sourate
              Expanded(
                child: _buildSurahContent(surah, currentAyah, isSpeaking),
              ),
            ],
          );
        },
      ),
      floatingActionButton: selectedSurahNumber != null && !isReadingMode
          ? FloatingActionButton(
              onPressed: () {
                _toggleContinuousReading();
              },
              child: Icon(
                isSpeaking ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }

  Widget _buildSurahList(List<Surah> surahs) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: surahs.length,
      itemBuilder: (context, index) {
        final surah = surahs[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8.h),
          child: ListTile(
            leading: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  '${surah.number}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
            title: Text(
              surah.name,
              style: AppTheme.arabicTextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surah.englishNameTranslation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${surah.numberOfAyahs} versets • ${surah.revelationType}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              setState(() {
                selectedSurahNumber = surah.number;
              });
              ref.read(currentSurahProvider.notifier).state = surah.number;
            },
          ),
        );
      },
    );
  }

  Widget _buildSurahContent(Surah surah, int? currentAyah, bool isSpeaking) {
    return Column(
      children: [
        // En-tête de la sourate - Adaptatif selon le mode
        if (!isReadingMode)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.r),
              border: Border(
                bottom: BorderSide(
                  color: AppConstants.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Nom arabe de la sourate - Taille réduite
                Text(
                  surah.name,
                  style: AppTheme.arabicTextStyle(
                    fontSize: 18.sp, // Réduit de 28.sp à 18.sp
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryColor,
                  ),
                ),
                SizedBox(height: 4.h),
                // Nom français - Plus discret
                Text(
                  surah.englishNameTranslation,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppConstants.primaryColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                SizedBox(height: 2.h),
                // Informations compactes
                Text(
                  '${surah.numberOfAyahs} versets • ${surah.revelationType}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 11.sp,
                      ),
                ),
              ],
            ),
          )
        else
          // Mode lecture concentrée - En-tête ultra-minimaliste
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            child: Text(
              surah.name,
              style: AppTheme.arabicTextStyle(
                fontSize: 14.sp, // Encore plus petit en mode lecture
                fontWeight: FontWeight.w500,
                color: AppConstants.primaryColor.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Basmalah (sauf pour At-Tawbah) - Adaptatif selon le mode
        if (surah.number != 9)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: isReadingMode ? 8.h : 12.h,
            ),
            margin: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: isReadingMode ? 4.h : 8.h,
            ),
            decoration: BoxDecoration(
              color: isReadingMode
                  ? Colors.transparent
                  : AppConstants.secondaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              style: AppTheme.arabicTextStyle(
                fontSize: isReadingMode ? 14.sp : 16.sp,
                color: isReadingMode
                    ? AppConstants.secondaryColor.withOpacity(0.6)
                    : AppConstants.secondaryColor.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Liste des ayahs
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: surah.ayahs.length,
            itemBuilder: (context, index) {
              final ayah = surah.ayahs[index];
              final isCurrentAyah = currentAyah == ayah.number;

              return AyahTile(
                ayah: ayah,
                surahNumber: surah.number,
                showTranslation: showTranslation,
                isHighlighted: isCurrentAyah,
                isPlaying: isSpeaking && isCurrentAyah,
                isReadingMode: isReadingMode, // Nouveau paramètre
                textSizeMultiplier: textSizeMultiplier, // Nouveau paramètre
                onTap: () {
                  ref.read(currentAyahProvider.notifier).state = ayah.number;
                },
                onPlay: () {
                  _playAyah(ayah);
                },
                onFavorite: () {
                  _toggleFavorite(surah.number, ayah.number);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _playAyah(ayah) {
    ref.read(currentAyahProvider.notifier).state = ayah.number;
    ref.read(ttsServiceProvider).speak(ayah.text);
  }

  void _toggleFavorite(int surahNumber, int ayahNumber) {
    final favorites = ref.read(favoritesProvider.notifier);
    final ayahId = '${surahNumber}_$ayahNumber';

    if (ref.read(favoritesProvider).contains(ayahId)) {
      favorites.removeFavorite(ayahId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retiré des favoris')),
      );
    } else {
      favorites.addFavorite(ayahId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajouté aux favoris')),
      );
    }
  }

  void _toggleContinuousReading() {
    final isSpeaking = ref.read(isSpeakingProvider);
    final ttsService = ref.read(ttsServiceProvider);

    if (isSpeaking) {
      ttsService.stop();
      ref.read(isSpeakingProvider.notifier).state = false;
    } else {
      // Commencer la lecture continue
      ref.read(isSpeakingProvider.notifier).state = true;
      _startContinuousReading();
    }
  }

  void _startContinuousReading() async {
    if (selectedSurahNumber == null) return;

    final quranData = await ref.read(quranDataProvider.future);
    final surah = quranData.getSurahByNumber(selectedSurahNumber!);
    if (surah == null) return;

    for (final ayah in surah.ayahs) {
      if (!ref.read(isSpeakingProvider)) break;

      ref.read(currentAyahProvider.notifier).state = ayah.number;
      ref.read(ttsServiceProvider).speak(ayah.text);

      // Attendre un peu entre les ayahs
      await Future.delayed(const Duration(milliseconds: 500));
    }

    ref.read(isSpeakingProvider.notifier).state = false;
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Taille de police'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Petite'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Normale'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Grande'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Très grande'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showSurahSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            color: Colors.white,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Sélectionner une sourate',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final quranDataAsync = ref.watch(quranDataProvider);
                    return quranDataAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) =>
                          Center(child: Text('Erreur: $error')),
                      data: (quranData) => ListView.builder(
                        controller: scrollController,
                        itemCount: quranData.surahs.length,
                        itemBuilder: (context, index) {
                          final surah = quranData.surahs[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppConstants.primaryColor,
                              child: Text(
                                '${surah.number}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              surah.name,
                              style: AppTheme.arabicTextStyle(),
                            ),
                            subtitle: Text(
                              '${surah.englishName} • ${surah.ayahs.length} versets',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              setState(() {
                                selectedSurahNumber = surah.number;
                              });
                              ref.read(currentSurahProvider.notifier).state =
                                  surah.number;
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Rechercher dans le Coran...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implémenter la recherche
            },
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paramètres'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Afficher la traduction'),
              value: showTranslation,
              onChanged: (value) {
                setState(() {
                  showTranslation = value;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Taille de police'),
              onTap: () {
                Navigator.pop(context);
                _showFontSizeDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Rechercher'),
              onTap: () {
                Navigator.pop(context);
                _showSearchDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Recharger les données'),
              onTap: () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🔄 Rechargement...')),
                );
                try {
                  final db = ref.read(quranDBProvider);
                  await db.clearAndReload();
                  ref.invalidate(quranDataProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Données rechargées !'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
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
