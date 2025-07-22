import 'package:json_annotation/json_annotation.dart';
import 'ayah.dart';

part 'surah.g.dart';

@JsonSerializable()
class Surah {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  final int numberOfAyahs;
  final List<Ayah> ayahs;

  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.numberOfAyahs,
    required this.ayahs,
  });

  factory Surah.fromJson(Map<String, dynamic> json) => _$SurahFromJson(json);
  Map<String, dynamic> toJson() => _$SurahToJson(this);

  @override
  String toString() => 'Surah(number: $number, name: $name, ayahs: ${ayahs.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Surah && runtimeType == other.runtimeType && number == other.number;

  @override
  int get hashCode => number.hashCode;
}
