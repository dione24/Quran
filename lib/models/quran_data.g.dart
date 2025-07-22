// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quran_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuranData _$QuranDataFromJson(Map<String, dynamic> json) => QuranData(
      surahs: (json['surahs'] as List<dynamic>)
          .map((e) => Surah.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$QuranDataToJson(QuranData instance) => <String, dynamic>{
      'surahs': instance.surahs,
      'metadata': instance.metadata,
    };
