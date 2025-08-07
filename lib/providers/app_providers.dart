import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/audio_matcher.dart';
import '../data/quran_db.dart';
import '../models/quran_data.dart';
// Services avancés (stubs pour compilation)
import '../services/firebase_service.dart';
import '../services/tajwid_service.dart';
import '../services/tafsir_service.dart';
import '../services/qibla_service.dart';
import '../services/prayer_times_service.dart';

// Services principaux
final sttServiceProvider = Provider<STTService>((ref) => STTService());
final ttsServiceProvider = Provider<TTSService>((ref) => TTSService());
final audioMatcherProvider = Provider<AudioMatcher>((ref) => AudioMatcher());
final quranDBProvider = Provider<QuranDB>((ref) => QuranDB());
// Services avancés (stubs pour compilation)
final firebaseServiceProvider = Provider<FirebaseService>((ref) => FirebaseService());
final tajwidServiceProvider = Provider<TajwidService>((ref) => TajwidService());
final tafsirServiceProvider = Provider<TafsirService>((ref) => TafsirService());
final qiblaServiceProvider = Provider<QiblaService>((ref) => QiblaService());
final prayerTimesServiceProvider = Provider<PrayerTimesService>((ref) => PrayerTimesService());

// Données du Coran
final quranDataProvider = FutureProvider<QuranData>((ref) async {
  final db = ref.read(quranDBProvider);
  await db.initializeWithQuranData();
  return await db.getQuranData();
});

// État de l'application
final currentSurahProvider = StateProvider<int?>((ref) => null);
final currentAyahProvider = StateProvider<int?>((ref) => null);
final isListeningProvider = StateProvider<bool>((ref) => false);
final isSpeakingProvider = StateProvider<bool>((ref) => false);
final currentThemeProvider = StateProvider<String>((ref) => 'light');
final selectedLanguageProvider = StateProvider<String>((ref) => 'fr');

// Apprentissage et récitation
final tajwidModeProvider = StateProvider<bool>((ref) => false);
final syllableModeProvider = StateProvider<bool>((ref) => false);
final recitationScoreProvider = StateProvider<double>((ref) => 0.0);

// Recherche
final searchQueryProvider = StateProvider<String>((ref) => '');
final searchResultsProvider = FutureProvider<List<dynamic>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  
  // final quranData = await ref.read(quranDataProvider.future);
  // Implémentation de la recherche à venir
  return [];
});

// Favoris et historique persistants
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
  return FavoritesNotifier(ref.read);
});

final readingHistoryProvider = StateNotifierProvider<ReadingHistoryNotifier, List<String>>((ref) {
  return ReadingHistoryNotifier(ref.read);
});

class FavoritesNotifier extends StateNotifier<List<String>> {
  final Reader read;
  FavoritesNotifier(this.read) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final db = read(quranDBProvider);
    state = await db.getFavorites();
  }

  Future<void> addFavorite(String ayahId) async {
    final parts = ayahId.split('_');
    if (parts.length != 2) return;
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null || ayah == null) return;

    final db = read(quranDBProvider);
    await db.addToFavorites(surah, ayah);
    if (!state.contains(ayahId)) {
      state = [ayahId, ...state];
    }
  }

  Future<void> removeFavorite(String ayahId) async {
    final parts = ayahId.split('_');
    if (parts.length != 2) return;
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null || ayah == null) return;

    final db = read(quranDBProvider);
    await db.removeFromFavorites(surah, ayah);
    state = state.where((id) => id != ayahId).toList();
  }

  Future<void> clearAll() async {
    final db = read(quranDBProvider);
    await db.clearFavorites();
    state = [];
  }
}

class ReadingHistoryNotifier extends StateNotifier<List<String>> {
  final Reader read;
  ReadingHistoryNotifier(this.read) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final db = read(quranDBProvider);
    state = await db.getReadingHistory(limit: 50);
  }

  Future<void> addToHistory(String ayahId) async {
    final parts = ayahId.split('_');
    if (parts.length != 2) return;
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null || ayah == null) return;

    final db = read(quranDBProvider);
    await db.addToReadingHistory(surah, ayah);
    state = [ayahId, ...state.where((id) => id != ayahId)].take(50).toList();
  }

  Future<void> clearAll() async {
    final db = read(quranDBProvider);
    await db.clearReadingHistory();
    state = [];
  }
}

// Gamification
final userStatsProvider = StateNotifierProvider<UserStatsNotifier, UserStats>((ref) {
  return UserStatsNotifier();
});

class UserStats {
  final int surahsRead;
  final int ayahsMemorized;
  final int daysStreak;
  final List<String> badges;
  final double totalScore;

  const UserStats({
    this.surahsRead = 0,
    this.ayahsMemorized = 0,
    this.daysStreak = 0,
    this.badges = const [],
    this.totalScore = 0.0,
  });

  UserStats copyWith({
    int? surahsRead,
    int? ayahsMemorized,
    int? daysStreak,
    List<String>? badges,
    double? totalScore,
  }) {
    return UserStats(
      surahsRead: surahsRead ?? this.surahsRead,
      ayahsMemorized: ayahsMemorized ?? this.ayahsMemorized,
      daysStreak: daysStreak ?? this.daysStreak,
      badges: badges ?? this.badges,
      totalScore: totalScore ?? this.totalScore,
    );
  }
}

class UserStatsNotifier extends StateNotifier<UserStats> {
  UserStatsNotifier() : super(const UserStats());

  void updateSurahsRead(int count) {
    state = state.copyWith(surahsRead: count);
  }

  void addBadge(String badge) {
    if (!state.badges.contains(badge)) {
      state = state.copyWith(badges: [...state.badges, badge]);
    }
  }

  void updateScore(double score) {
    state = state.copyWith(totalScore: state.totalScore + score);
  }
}
