import 'dart:async';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  final StreamController<bool> _speakingController = StreamController<bool>.broadcast();
  Stream<bool> get speakingStream => _speakingController.stream;

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configuration de base
      await _flutterTts.setLanguage('ar-SA'); // Arabe saoudien
      await _flutterTts.setSpeechRate(0.6); // Vitesse de lecture modérée
      await _flutterTts.setVolume(0.8);
      await _flutterTts.setPitch(1.0);

      // Attendre la fin de lecture pour compléter les Futures speak()
      try {
        await _flutterTts.awaitSpeakCompletion(true);
      } catch (_) {
        // Certaines plateformes/versions peuvent ne pas supporter cette API
      }

      // Configuration spécifique à la plateforme
      if (Platform.isAndroid) {
        await _flutterTts.setEngine('com.google.android.tts');
      } else if (Platform.isIOS) {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.allowBluetooth,
           IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
           IosTextToSpeechAudioCategoryOptions.mixWithOthers],
        );
      }

      // Gestionnaires d'événements
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _speakingController.add(true);
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _speakingController.add(false);
      });

      _flutterTts.setErrorHandler((msg) {
        print('TTS Error: $msg');
        _isSpeaking = false;
        _speakingController.add(false);
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        _speakingController.add(false);
      });

      _isInitialized = true;
    } catch (e) {
      print('TTS initialization error: $e');
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> pause() async {
    if (_isSpeaking) {
      await _flutterTts.pause();
    }
  }

  Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }
  }

  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  Future<List<dynamic>> getLanguages() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _flutterTts.getLanguages;
  }

  Future<List<dynamic>> getVoices() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _flutterTts.getVoices;
  }

  Future<void> setVoice(Map<String, String> voice) async {
    await _flutterTts.setVoice(voice);
  }

  void dispose() {
    _speakingController.close();
  }
}
