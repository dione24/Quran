import 'package:string_similarity/string_similarity.dart';
import '../models/ayah.dart';
import '../models/surah.dart';
import '../models/quran_data.dart';

class AudioMatchResult {
  final Surah? matchedSurah;
  final Ayah? matchedAyah;
  final double confidence;
  final String originalText;
  final String matchedText;

  const AudioMatchResult({
    this.matchedSurah,
    this.matchedAyah,
    required this.confidence,
    required this.originalText,
    required this.matchedText,
  });

  bool get hasMatch => matchedSurah != null && matchedAyah != null;
}

class AudioMatcher {
  static final AudioMatcher _instance = AudioMatcher._internal();
  factory AudioMatcher() => _instance;
  AudioMatcher._internal();

  static const double _minimumConfidence = 0.3;
  static const int _maxSearchResults = 5;

  /// Nettoie le texte arabe pour améliorer la correspondance
  String _cleanArabicText(String text) {
    // Supprimer les diacritiques (tashkeel)
    text = text.replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0640]'), '');
    
    // Normaliser les caractères arabes
    text = text.replaceAll('ي', 'ی');
    text = text.replaceAll('ك', 'ک');
    text = text.replaceAll('ة', 'ه');
    
    // Supprimer les espaces multiples et les caractères non arabes
    text = text.replaceAll(RegExp(r'[^\u0600-\u06FF\s]'), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    
    return text.trim();
  }

  /// Trouve les correspondances possibles pour un texte transcrit
  Future<List<AudioMatchResult>> findMatches(
    String transcribedText,
    QuranData quranData, {
    double minConfidence = _minimumConfidence,
  }) async {
    if (transcribedText.isEmpty) return [];

    final cleanedInput = _cleanArabicText(transcribedText);
    final List<AudioMatchResult> results = [];

    // Parcourir toutes les sourates et ayahs
    for (final surah in quranData.surahs) {
      for (final ayah in surah.ayahs) {
        final cleanedAyah = _cleanArabicText(ayah.text);
        
        // Calculer la similarité
        final similarity = _calculateSimilarity(cleanedInput, cleanedAyah);
        
        if (similarity >= minConfidence) {
          results.add(AudioMatchResult(
            matchedSurah: surah,
            matchedAyah: ayah,
            confidence: similarity,
            originalText: transcribedText,
            matchedText: ayah.text,
          ));
        }
      }
    }

    // Trier par confiance décroissante et limiter les résultats
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results.take(_maxSearchResults).toList();
  }

  /// Recherche par mots-clés dans le Coran
  Future<List<AudioMatchResult>> searchByKeywords(
    String keywords,
    QuranData quranData, {
    double minConfidence = 0.2,
  }) async {
    final cleanedKeywords = _cleanArabicText(keywords);
    final keywordList = cleanedKeywords.split(' ').where((w) => w.isNotEmpty).toList();
    
    if (keywordList.isEmpty) return [];

    final List<AudioMatchResult> results = [];

    for (final surah in quranData.surahs) {
      for (final ayah in surah.ayahs) {
        final cleanedAyah = _cleanArabicText(ayah.text);
        
        // Compter les mots-clés trouvés
        int matchedWords = 0;
        for (final keyword in keywordList) {
          if (cleanedAyah.contains(keyword)) {
            matchedWords++;
          }
        }

        if (matchedWords > 0) {
          final confidence = matchedWords / keywordList.length;
          if (confidence >= minConfidence) {
            results.add(AudioMatchResult(
              matchedSurah: surah,
              matchedAyah: ayah,
              confidence: confidence,
              originalText: keywords,
              matchedText: ayah.text,
            ));
          }
        }
      }
    }

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results.take(_maxSearchResults).toList();
  }

  /// Calcule la similarité entre deux textes arabes
  double _calculateSimilarity(String text1, String text2) {
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    // Utiliser plusieurs méthodes de similarité
    final jaccardSimilarity = text1.similarityTo(text2);
    
    // Similarité basée sur les mots communs
    final words1 = text1.split(' ').toSet();
    final words2 = text2.split(' ').toSet();
    final commonWords = words1.intersection(words2).length;
    final totalWords = words1.union(words2).length;
    final wordSimilarity = totalWords > 0 ? commonWords / totalWords : 0.0;

    // Combinaison des deux méthodes
    return (jaccardSimilarity * 0.7) + (wordSimilarity * 0.3);
  }

  /// Trouve la sourate la plus probable basée sur le texte transcrit
  Future<Surah?> findMostLikelySurah(
    String transcribedText,
    QuranData quranData,
  ) async {
    final matches = await findMatches(transcribedText, quranData);
    if (matches.isEmpty) return null;

    // Grouper par sourate et calculer la confiance moyenne
    final surahConfidences = <int, List<double>>{};
    for (final match in matches) {
      if (match.matchedSurah != null) {
        surahConfidences.putIfAbsent(match.matchedSurah!.number, () => []);
        surahConfidences[match.matchedSurah!.number]!.add(match.confidence);
      }
    }

    // Trouver la sourate avec la meilleure confiance moyenne
    double bestConfidence = 0.0;
    int? bestSurahNumber;

    surahConfidences.forEach((surahNumber, confidences) {
      final avgConfidence = confidences.reduce((a, b) => a + b) / confidences.length;
      if (avgConfidence > bestConfidence) {
        bestConfidence = avgConfidence;
        bestSurahNumber = surahNumber;
      }
    });

    return bestSurahNumber != null 
        ? quranData.getSurahByNumber(bestSurahNumber!) 
        : null;
  }
}
