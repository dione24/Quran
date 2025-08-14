import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class QuranAudioService {
  static final QuranAudioService _instance = QuranAudioService._internal();
  factory QuranAudioService() => _instance;
  QuranAudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Dio _dio = Dio();

  // APIs disponibles pour les récitations
  static const String _baseApiUrl = 'https://api.alquran.cloud/v1';
  static const String _audioBaseUrl = 'https://verses.quran.com';

  // Récitateurs célèbres avec leurs identifiants
  static const Map<String, RecitatorInfo> recitators = {
    'ar.alafasy': RecitatorInfo(
      id: 'ar.alafasy',
      name: 'Mishary Rashid Alafasy',
      language: 'ar',
      style: 'Hafs',
      format: 'mp3',
      bitrate: 128,
    ),
    'ar.abdurrahmaansudais': RecitatorInfo(
      id: 'ar.abdurrahmaansudais',
      name: 'Abdul Rahman Al-Sudais',
      language: 'ar',
      style: 'Hafs',
      format: 'mp3',
      bitrate: 128,
    ),
    'ar.maheralmaikulai': RecitatorInfo(
      id: 'ar.maheralmaikulai',
      name: 'Maher Al Muaiqly',
      language: 'ar',
      style: 'Hafs',
      format: 'mp3',
      bitrate: 128,
    ),
    'ar.saoodashuraym': RecitatorInfo(
      id: 'ar.saoodashuraym',
      name: 'Saood Al-Shuraym',
      language: 'ar',
      style: 'Hafs',
      format: 'mp3',
      bitrate: 128,
    ),
    'ar.abdulbasitmurattal': RecitatorInfo(
      id: 'ar.abdulbasitmurattal',
      name: 'Abdul Basit Murattal',
      language: 'ar',
      style: 'Hafs',
      format: 'mp3',
      bitrate: 128,
    ),
  };

  String _currentRecitator = 'ar.alafasy';
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Getters pour l'état du lecteur
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  String get currentRecitator => _currentRecitator;

  // Streams pour les mises à jour en temps réel
  Stream<PlayerState> get playerStateStream =>
      _audioPlayer.onPlayerStateChanged;
  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;
  Stream<Duration> get durationStream => _audioPlayer.onDurationChanged;

  /// Initialise le service audio
  Future<void> initialize() async {
    try {
      // Configuration du lecteur audio
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);

      // Écouter les changements d'état
      _audioPlayer.onPlayerStateChanged.listen((state) {
        _isPlaying = state == PlayerState.playing;
        if (kDebugMode) {
          print('Audio state changed: $state');
        }
      });

      // Écouter la position
      _audioPlayer.onPositionChanged.listen((position) {
        _currentPosition = position;
      });

      // Écouter la durée
      _audioPlayer.onDurationChanged.listen((duration) {
        _totalDuration = duration;
      });

      if (kDebugMode) {
        print('QuranAudioService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing QuranAudioService: $e');
      }
    }
  }

  /// Change le récitateur actuel
  void setRecitator(String recitatorId) {
    if (recitators.containsKey(recitatorId)) {
      _currentRecitator = recitatorId;
      if (kDebugMode) {
        print('Recitator changed to: ${recitators[recitatorId]?.name}');
      }
    }
  }

  /// Joue une sourate complète
  Future<void> playSurah(int surahNumber) async {
    try {
      _isLoading = true;
      await stop(); // Arrêter toute lecture en cours

      // URL pour la sourate complète
      final url = _buildSurahUrl(surahNumber);

      if (kDebugMode) {
        print('Playing Surah $surahNumber with URL: $url');
      }

      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing Surah $surahNumber: $e');
      }
    } finally {
      _isLoading = false;
    }
  }

  /// Joue un verset spécifique
  Future<void> playAyah(int surahNumber, int ayahNumber) async {
    try {
      _isLoading = true;
      await stop(); // Arrêter toute lecture en cours

      // URL pour le verset spécifique
      final url = _buildAyahUrl(surahNumber, ayahNumber);

      if (kDebugMode) {
        print('Playing Ayah $surahNumber:$ayahNumber with URL: $url');
      }

      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing Ayah $surahNumber:$ayahNumber: $e');
      }
    } finally {
      _isLoading = false;
    }
  }

  /// Joue une plage de versets
  Future<void> playAyahRange(int surahNumber, int fromAyah, int toAyah) async {
    try {
      _isLoading = true;
      await stop();

      // Pour une plage, on peut jouer verset par verset ou utiliser une API spécialisée
      // Ici, on commence par le premier verset
      await playAyah(surahNumber, fromAyah);

      // TODO: Implémenter la logique pour jouer automatiquement les versets suivants
    } catch (e) {
      if (kDebugMode) {
        print('Error playing Ayah range $surahNumber:$fromAyah-$toAyah: $e');
      }
    } finally {
      _isLoading = false;
    }
  }

  /// Met en pause la lecture
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// Reprend la lecture
  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  /// Arrête la lecture
  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentPosition = Duration.zero;
  }

  /// Cherche à une position spécifique
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Définit le volume (0.0 à 1.0)
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Télécharge un audio pour l'écoute hors-ligne
  Future<String?> downloadAudio(int surahNumber, {int? ayahNumber}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/quran_audio');

      if (!audioDir.existsSync()) {
        audioDir.createSync(recursive: true);
      }

      String filename;
      String url;

      if (ayahNumber != null) {
        filename =
            'surah_${surahNumber}_ayah_${ayahNumber}_$_currentRecitator.mp3';
        url = _buildAyahUrl(surahNumber, ayahNumber);
      } else {
        filename = 'surah_${surahNumber}_$_currentRecitator.mp3';
        url = _buildSurahUrl(surahNumber);
      }

      final filePath = '${audioDir.path}/$filename';
      final file = File(filePath);

      if (file.existsSync()) {
        if (kDebugMode) {
          print('Audio already downloaded: $filePath');
        }
        return filePath;
      }

      if (kDebugMode) {
        print('Downloading audio from: $url');
      }

      await _dio.download(url, filePath);

      if (kDebugMode) {
        print('Audio downloaded successfully: $filePath');
      }

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading audio: $e');
      }
      return null;
    }
  }

  /// Vérifie si un audio est téléchargé
  Future<bool> isAudioDownloaded(int surahNumber, {int? ayahNumber}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      String filename;

      if (ayahNumber != null) {
        filename =
            'surah_${surahNumber}_ayah_${ayahNumber}_$_currentRecitator.mp3';
      } else {
        filename = 'surah_${surahNumber}_$_currentRecitator.mp3';
      }

      final filePath = '${directory.path}/quran_audio/$filename';
      return File(filePath).existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Joue un audio téléchargé
  Future<void> playDownloadedAudio(int surahNumber, {int? ayahNumber}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      String filename;

      if (ayahNumber != null) {
        filename =
            'surah_${surahNumber}_ayah_${ayahNumber}_$_currentRecitator.mp3';
      } else {
        filename = 'surah_${surahNumber}_$_currentRecitator.mp3';
      }

      final filePath = '${directory.path}/quran_audio/$filename';
      final file = File(filePath);

      if (file.existsSync()) {
        _isLoading = true;
        await stop();
        await _audioPlayer.play(DeviceFileSource(filePath));
      } else {
        throw Exception('Audio file not found: $filePath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing downloaded audio: $e');
      }
    } finally {
      _isLoading = false;
    }
  }

  /// Construit l'URL pour une sourate complète
  String _buildSurahUrl(int surahNumber) {
    // Format: https://verses.quran.com/Alafasy/mp3/001.mp3
    final recitatorName = _getRecitatorUrlName(_currentRecitator);
    return '$_audioBaseUrl/$recitatorName/mp3/${surahNumber.toString().padLeft(3, '0')}.mp3';
  }

  /// Construit l'URL pour un verset spécifique
  String _buildAyahUrl(int surahNumber, int ayahNumber) {
    // Format: https://verses.quran.com/Alafasy/mp3/001001.mp3
    final recitatorName = _getRecitatorUrlName(_currentRecitator);
    final surahStr = surahNumber.toString().padLeft(3, '0');
    final ayahStr = ayahNumber.toString().padLeft(3, '0');
    return '$_audioBaseUrl/$recitatorName/mp3/$surahStr$ayahStr.mp3';
  }

  /// Obtient le nom du récitateur pour l'URL
  String _getRecitatorUrlName(String recitatorId) {
    switch (recitatorId) {
      case 'ar.alafasy':
        return 'Alafasy';
      case 'ar.abdurrahmaansudais':
        return 'Abdul_Basit_Murattal';
      case 'ar.maheralmaikulai':
        return 'Maher_AlMuaiqly';
      case 'ar.saoodashuraym':
        return 'Saood_ash-Shuraym';
      case 'ar.abdulbasitmurattal':
        return 'Abdul_Basit_Murattal';
      default:
        return 'Alafasy';
    }
  }

  /// Nettoie les ressources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }

  /// Obtient la liste des récitateurs disponibles
  static List<RecitatorInfo> getAvailableRecitators() {
    return recitators.values.toList();
  }

  /// Obtient les informations d'un récitateur
  static RecitatorInfo? getRecitatorInfo(String recitatorId) {
    return recitators[recitatorId];
  }
}

/// Informations sur un récitateur
class RecitatorInfo {
  final String id;
  final String name;
  final String language;
  final String style;
  final String format;
  final int bitrate;

  const RecitatorInfo({
    required this.id,
    required this.name,
    required this.language,
    required this.style,
    required this.format,
    required this.bitrate,
  });

  @override
  String toString() {
    return 'RecitatorInfo(id: $id, name: $name, style: $style)';
  }
}
