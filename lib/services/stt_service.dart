import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class STTService {
  static final STTService _instance = STTService._internal();
  factory STTService() => _instance;
  STTService._internal();

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;

  final StreamController<String> _transcriptionController = StreamController<String>.broadcast();
  final StreamController<bool> _listeningController = StreamController<bool>.broadcast();
  final StreamController<double> _confidenceController = StreamController<double>.broadcast();

  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<bool> get listeningStream => _listeningController.stream;
  Stream<double> get confidenceStream => _confidenceController.stream;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  Future<bool> initialize() async {
    try {
      // Demander les permissions
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }

      _isAvailable = await _speechToText.initialize(
        onError: (error) {
          print('STT Error: ${error.errorMsg}');
          _stopListening();
        },
        onStatus: (status) {
          print('STT Status: $status');
          if (status == 'notListening' && _isListening) {
            _stopListening();
          }
        },
      );

      return _isAvailable;
    } catch (e) {
      print('STT initialization error: $e');
      return false;
    }
  }

  Future<void> startListening() async {
    if (!_isAvailable) {
      await initialize();
    }

    if (_isAvailable && !_isListening) {
      _isListening = true;
      _listeningController.add(true);

      await _speechToText.listen(
        onResult: (result) {
          _transcriptionController.add(result.recognizedWords);
          _confidenceController.add(result.confidence);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'ar-SA', // Arabe saoudien
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _stopListening();
    }
  }

  void _stopListening() {
    _isListening = false;
    _listeningController.add(false);
  }

  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isAvailable) {
      await initialize();
    }
    return await _speechToText.locales();
  }

  void dispose() {
    _transcriptionController.close();
    _listeningController.close();
    _confidenceController.close();
  }
}
