// Run with: dart run tool/fetch_quran.dart
// This script fetches full Quran text (Arabic Uthmani + French translation)
// from AlQuran Cloud API and writes assets/quran/quran_full.json

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main() async {
  const arabicEdition = 'quran-uthmani';
  // Common French editions include: fr.hamidullah, fr.leclerc, fr.montada
  const frenchEdition = 'fr.hamidullah';

  stdout.writeln('Fetching Arabic ($arabicEdition) ...');
  final arRes = await http.get(Uri.parse('https://api.alquran.cloud/v1/quran/$arabicEdition'));
  if (arRes.statusCode != 200) {
    stderr.writeln('Failed to fetch Arabic edition: ${arRes.statusCode}');
    exit(1);
  }

  stdout.writeln('Fetching French ($frenchEdition) ...');
  final frRes = await http.get(Uri.parse('https://api.alquran.cloud/v1/quran/$frenchEdition'));
  if (frRes.statusCode != 200) {
    stderr.writeln('Failed to fetch French edition: ${frRes.statusCode}');
    exit(1);
  }

  final arJson = json.decode(arRes.body) as Map<String, dynamic>;
  final frJson = json.decode(frRes.body) as Map<String, dynamic>;

  final arSurahs = (arJson['data']['surahs'] as List).cast<Map<String, dynamic>>();
  final frSurahs = (frJson['data']['surahs'] as List).cast<Map<String, dynamic>>();

  // Build our schema
  final mergedSurahs = <Map<String, dynamic>>[];

  for (int i = 0; i < arSurahs.length; i++) {
    final arS = arSurahs[i];
    final frS = frSurahs[i];
    final arAyahs = (arS['ayahs'] as List).cast<Map<String, dynamic>>();
    final frAyahs = (frS['ayahs'] as List).cast<Map<String, dynamic>>();

    final mergedAyahs = <Map<String, dynamic>>[];
    for (int j = 0; j < arAyahs.length; j++) {
      final arA = arAyahs[j];
      final frA = frAyahs[j];
      mergedAyahs.add({
        'number': arA['number'],
        'text': arA['text'],
        'numberInSurah': arA['numberInSurah'],
        'juz': arA['juz'],
        'manzil': arA['manzil'],
        'page': arA['page'],
        'ruku': arA['ruku'],
        'hizbQuarter': arA['hizbQuarter'],
        'sajda': (arA['sajda'] is Map) ? (arA['sajda']['id'] != null) : (arA['sajda'] == true || arA['sajda'] == 1),
        'translation': frA['text'],
      });
    }

    mergedSurahs.add({
      'number': arS['number'],
      'name': arS['name'],
      'englishName': arS['englishName'],
      'englishNameTranslation': arS['englishNameTranslation'],
      'revelationType': arS['revelationType'],
      'numberOfAyahs': arS['numberOfAyahs'],
      'ayahs': mergedAyahs,
    });
  }

  final output = {
    'surahs': mergedSurahs,
    'metadata': {
      'source': 'api.alquran.cloud',
      'arabicEdition': arabicEdition,
      'frenchEdition': frenchEdition,
      'generatedAt': DateTime.now().toIso8601String(),
    }
  };

  final outDir = Directory('assets/quran');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }
  final outFile = File('assets/quran/quran_full.json');
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(output));

  stdout.writeln('Wrote ${mergedSurahs.length} surahs to assets/quran/quran_full.json');
}