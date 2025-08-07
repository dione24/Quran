import 'dart:async';
import 'package:just_audio/just_audio.dart';

class Reciter {
  final String id;
  final String name;
  const Reciter({required this.id, required this.name});
}

class RecitationService {
  static final RecitationService _instance = RecitationService._internal();
  factory RecitationService() => _instance;
  RecitationService._internal();

  static const Reciter defaultReciter = Reciter(id: 'alafasy', name: 'Mishary Alafasy');
  final List<Reciter> availableReciters = const [
    Reciter(id: 'alafasy', name: 'Mishary Alafasy'),
    Reciter(id: 'husary', name: 'Mahmoud Al-Husary'),
  ];

  final AudioPlayer _player = AudioPlayer();
  Reciter _currentReciter = defaultReciter;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Reciter get currentReciter => _currentReciter;

  Future<void> setReciter(Reciter reciter) async {
    _currentReciter = reciter;
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Play a specific ayah if asset exists. Fallback to playing whole surah if available.
  /// Returns true if playback started.
  Future<bool> playAyah(int surahNumber, int ayahNumber) async {
    await _player.stop();
    final candidates = _buildAyahAssetCandidates(surahNumber, ayahNumber);
    for (final assetPath in candidates) {
      try {
        await _player.setAsset(assetPath);
        await _player.play();
        return true;
      } catch (_) {
        // try next candidate
      }
    }
    // try whole surah as a fallback
    final surahCandidates = _buildSurahAssetCandidates(surahNumber);
    for (final assetPath in surahCandidates) {
      try {
        await _player.setAsset(assetPath);
        await _player.play();
        return true;
      } catch (_) {}
    }
    return false;
  }

  /// Plays and completes when playback finishes (or immediately if cannot play)
  Future<void> playAyahAndAwait(int surahNumber, int ayahNumber) async {
    final started = await playAyah(surahNumber, ayahNumber);
    if (!started) return;
    // Wait until completed
    await playerStateStream
        .firstWhere((s) => s.processingState == ProcessingState.completed);
  }

  List<String> _buildAyahAssetCandidates(int surahNumber, int ayahNumber) {
    final s3 = surahNumber.toString().padLeft(3, '0');
    final a3 = ayahNumber.toString().padLeft(3, '0');
    final base = 'assets/audio/${_currentReciter.id}';
    return [
      // common schemes
      '$base/$s3/$a3.mp3',
      '$base/${s3}_$a3.mp3',
      '$base/${surahNumber}_$ayahNumber.mp3',
      '$base/$surahNumber/$ayahNumber.mp3',
    ];
  }

  List<String> _buildSurahAssetCandidates(int surahNumber) {
    final s3 = surahNumber.toString().padLeft(3, '0');
    final base = 'assets/audio/${_currentReciter.id}';
    return [
      '$base/$s3.mp3',
      '$base/$surahNumber.mp3',
      '$base/surah_$surahNumber.mp3',
    ];
  }

  void dispose() {
    _player.dispose();
  }
}