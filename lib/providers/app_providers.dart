import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/quran_audio_service.dart';
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

// Provider pour Quran Audio Service
final quranAudioServiceProvider = Provider<QuranAudioService>((ref) {
  return QuranAudioService();
});
final audioMatcherProvider = Provider<AudioMatcher>((ref) => AudioMatcher());
final quranDBProvider = Provider<QuranDB>((ref) => QuranDB());
// Services avancés (stubs pour compilation)
final firebaseServiceProvider =
    Provider<FirebaseService>((ref) => FirebaseService());
final tajwidServiceProvider = Provider<TajwidService>((ref) => TajwidService());
final tafsirServiceProvider = Provider<TafsirService>((ref) => TafsirService());
final qiblaServiceProvider = Provider<QiblaService>((ref) => QiblaService());
final prayerTimesServiceProvider =
    Provider<PrayerTimesService>((ref) => PrayerTimesService());

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

// Favoris et historique
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
  return FavoritesNotifier();
});

final readingHistoryProvider =
    StateNotifierProvider<ReadingHistoryNotifier, List<String>>((ref) {
  return ReadingHistoryNotifier();
});

class FavoritesNotifier extends StateNotifier<List<String>> {
  FavoritesNotifier() : super([]);

  void addFavorite(String ayahId) {
    if (!state.contains(ayahId)) {
      state = [...state, ayahId];
    }
  }

  void removeFavorite(String ayahId) {
    state = state.where((id) => id != ayahId).toList();
  }
}

class ReadingHistoryNotifier extends StateNotifier<List<String>> {
  ReadingHistoryNotifier() : super([]);

  void addToHistory(String ayahId) {
    state = [ayahId, ...state.where((id) => id != ayahId).take(99)].toList();
  }
}

// Gamification
final userStatsProvider =
    StateNotifierProvider<UserStatsNotifier, UserStats>((ref) {
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
