import 'package:json_annotation/json_annotation.dart';

part 'ayah.g.dart';

@JsonSerializable()
class Ayah {
  final int number;
  final String text;
  final int numberInSurah;
  final int juz;
  final int manzil;
  final int page;
  final int ruku;
  final int hizbQuarter;
  final bool sajda;
  final String? translation;

  const Ayah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    required this.manzil,
    required this.page,
    required this.ruku,
    required this.hizbQuarter,
    this.sajda = false,
    this.translation,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) => _$AyahFromJson(json);
  Map<String, dynamic> toJson() => _$AyahToJson(this);

  @override
  String toString() => 'Ayah(number: $number, numberInSurah: $numberInSurah, text: ${text.substring(0, text.length > 50 ? 50 : text.length)}...)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ayah && runtimeType == other.runtimeType && number == other.number;

  @override
  int get hashCode => number.hashCode;

  Ayah copyWith({
    int? number,
    String? text,
    int? numberInSurah,
    int? juz,
    int? manzil,
    int? page,
    int? ruku,
    int? hizbQuarter,
    bool? sajda,
    String? translation,
  }) {
    return Ayah(
      number: number ?? this.number,
      text: text ?? this.text,
      numberInSurah: numberInSurah ?? this.numberInSurah,
      juz: juz ?? this.juz,
      manzil: manzil ?? this.manzil,
      page: page ?? this.page,
      ruku: ruku ?? this.ruku,
      hizbQuarter: hizbQuarter ?? this.hizbQuarter,
      sajda: sajda ?? this.sajda,
      translation: translation ?? this.translation,
    );
  }
}
