import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/surah_selector.dart';
import '../widgets/ayah_tile.dart';
import '../models/surah.dart';
import '../services/recitation_service.dart';

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
  bool useRecitation = true; // prefer recorded recitation when available

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
    final reciter = ref.watch(recitationServiceProvider).currentReciter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lire le Coran'),
        actions: [
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
          IconButton(
            icon: Icon(useRecitation ? Icons.record_voice_over : Icons.spatial_audio_off),
            onPressed: () {
              setState(() {
                useRecitation = !useRecitation;
              });
            },
            tooltip: useRecitation ? 'Utiliser synthèse vocale' : 'Utiliser récitation enregistrée',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _showReciterDialog,
            tooltip: 'Récitant: ${reciter.name}',
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () {
              _showFontSizeDialog();
            },
            tooltip: 'Taille de police',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
            tooltip: 'Rechercher',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            child: SurahSelector(
              selectedSurahNumber: selectedSurahNumber,
              onSurahSelected: (surahNumber) {
                setState(() {
                  selectedSurahNumber = surahNumber == 0 ? null : surahNumber;
                });
                ref.read(currentSurahProvider.notifier).state = surahNumber == 0 ? null : surahNumber;
              },
            ),
          ),

          Expanded(
            child: quranDataAsync.when(
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

                return _buildSurahContent(surah, currentAyah, isSpeaking);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: selectedSurahNumber != null
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
        // En-tête de la sourate
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          margin: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppConstants.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                surah.name,
                style: AppTheme.arabicTextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                surah.englishNameTranslation,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppConstants.primaryColor,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${surah.numberOfAyahs} versets • ${surah.revelationType}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        // Basmalah (sauf pour At-Tawbah)
        if (surah.number != 9)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              style: AppTheme.arabicTextStyle(
                fontSize: 20.sp,
                color: AppConstants.secondaryColor,
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
                onTap: () async {
                  ref.read(currentAyahProvider.notifier).state = ayah.number;
                  await ref.read(readingHistoryProvider.notifier).addToHistory('${surah.number}_${ayah.number}');
                },
                onPlay: () async {
                  if (useRecitation) {
                    await ref.read(recitationServiceProvider).playAyahAndAwait(surah.number, ayah.numberInSurah);
                  } else {
                    await _playAyah(ayah, surah.number);
                  }
                },
                onFavorite: () async {
                  await _toggleFavorite(surah.number, ayah.number);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _playAyah(ayah, [int? surahNumber]) async {
    ref.read(currentAyahProvider.notifier).state = ayah.number;
    await ref.read(ttsServiceProvider).speak(ayah.text);
    if (surahNumber != null) {
      await ref.read(readingHistoryProvider.notifier).addToHistory('${surahNumber}_${ayah.number}');
    }
  }

  Future<void> _toggleFavorite(int surahNumber, int ayahNumber) async {
    final favorites = ref.read(favoritesProvider.notifier);
    final ayahId = '${surahNumber}_$ayahNumber';
    
    if (ref.read(favoritesProvider).contains(ayahId)) {
      await favorites.removeFavorite(ayahId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retiré des favoris')),
      );
    } else {
      await favorites.addFavorite(ayahId);
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

  Future<void> _startContinuousReading() async {
    if (selectedSurahNumber == null) return;
    
    final quranData = await ref.read(quranDataProvider.future);
    final surah = quranData.getSurahByNumber(selectedSurahNumber!);
    if (surah == null) return;

    for (final ayah in surah.ayahs) {
      if (!ref.read(isSpeakingProvider)) break;
      ref.read(currentAyahProvider.notifier).state = ayah.number;

      if (useRecitation) {
        // play recorded if available, else fallback to TTS
        final played = await ref.read(recitationServiceProvider).playAyah(surah.number, ayah.numberInSurah);
        if (!played) {
          await ref.read(ttsServiceProvider).speak(ayah.text);
        } else {
          await ref.read(recitationServiceProvider).playerStateStream
              .firstWhere((s) => s.processingState == ProcessingState.completed);
        }
      } else {
        await ref.read(ttsServiceProvider).speak(ayah.text);
      }

      await ref.read(readingHistoryProvider.notifier).addToHistory('${surah.number}_${ayah.number}');
      await Future.delayed(const Duration(milliseconds: 200));
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

  void _showReciterDialog() {
    final service = ref.read(recitationServiceProvider);
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choisir un récitant'),
        children: service.availableReciters.map((r) {
          final isCurrent = r.id == service.currentReciter.id;
          return SimpleDialogOption(
            onPressed: () async {
              await service.setReciter(r);
              if (mounted) Navigator.pop(context);
              setState(() {});
            },
            child: Row(
              children: [
                Icon(isCurrent ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: AppConstants.primaryColor),
                const SizedBox(width: 8),
                Text(r.name),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
