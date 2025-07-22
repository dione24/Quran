import 'package:json_annotation/json_annotation.dart';
import 'surah.dart';

part 'quran_data.g.dart';

@JsonSerializable()
class QuranData {
  final List<Surah> surahs;
  final Map<String, dynamic> metadata;

  const QuranData({
    required this.surahs,
    this.metadata = const {},
  });

  factory QuranData.fromJson(Map<String, dynamic> json) => _$QuranDataFromJson(json);
  Map<String, dynamic> toJson() => _$QuranDataToJson(this);

  Surah? getSurahByNumber(int number) {
    try {
      return surahs.firstWhere((surah) => surah.number == number);
    } catch (e) {
      return null;
    }
  }

  List<Surah> searchSurahsByName(String query) {
    final lowercaseQuery = query.toLowerCase();
    return surahs.where((surah) =>
      surah.name.toLowerCase().contains(lowercaseQuery) ||
      surah.englishName.toLowerCase().contains(lowercaseQuery) ||
      surah.englishNameTranslation.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  int get totalAyahs => surahs.fold(0, (sum, surah) => sum + surah.numberOfAyahs);
}
