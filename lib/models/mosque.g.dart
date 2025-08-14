// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mosque.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mosque _$MosqueFromJson(Map<String, dynamic> json) => Mosque(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distance: (json['distance'] as num?)?.toDouble(),
      phoneNumber: json['phoneNumber'] as String?,
      website: json['website'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      totalRatings: (json['totalRatings'] as num?)?.toInt(),
      photos:
          (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList(),
      openingHours: (json['openingHours'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      services: (json['services'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isOpen: json['isOpen'] as bool?,
      placeId: json['placeId'] as String?,
      type: $enumDecodeNullable(_$MosqueTypeEnumMap, json['type']) ??
          MosqueType.standard,
      isFavorite: json['isFavorite'] as bool? ?? false,
      lastVisited: json['lastVisited'] == null
          ? null
          : DateTime.parse(json['lastVisited'] as String),
      prayerTimes: (json['prayerTimes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      specialEvents: (json['specialEvents'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      parking: json['parking'] == null
          ? null
          : ParkingInfo.fromJson(json['parking'] as Map<String, dynamic>),
      accessibility: json['accessibility'] == null
          ? null
          : AccessibilityInfo.fromJson(
              json['accessibility'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MosqueToJson(Mosque instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'distance': instance.distance,
      'phoneNumber': instance.phoneNumber,
      'website': instance.website,
      'rating': instance.rating,
      'totalRatings': instance.totalRatings,
      'photos': instance.photos,
      'openingHours': instance.openingHours,
      'services': instance.services,
      'isOpen': instance.isOpen,
      'placeId': instance.placeId,
      'type': _$MosqueTypeEnumMap[instance.type]!,
      'isFavorite': instance.isFavorite,
      'lastVisited': instance.lastVisited?.toIso8601String(),
      'prayerTimes': instance.prayerTimes,
      'specialEvents': instance.specialEvents,
      'parking': instance.parking,
      'accessibility': instance.accessibility,
    };

const _$MosqueTypeEnumMap = {
  MosqueType.standard: 'standard',
  MosqueType.grand: 'grand',
  MosqueType.historical: 'historical',
  MosqueType.educational: 'educational',
  MosqueType.community: 'community',
};

ParkingInfo _$ParkingInfoFromJson(Map<String, dynamic> json) => ParkingInfo(
      available: json['available'] as bool,
      free: json['free'] as bool? ?? false,
      capacity: (json['capacity'] as num?)?.toInt(),
      details: json['details'] as String?,
    );

Map<String, dynamic> _$ParkingInfoToJson(ParkingInfo instance) =>
    <String, dynamic>{
      'available': instance.available,
      'free': instance.free,
      'capacity': instance.capacity,
      'details': instance.details,
    };

AccessibilityInfo _$AccessibilityInfoFromJson(Map<String, dynamic> json) =>
    AccessibilityInfo(
      wheelchairAccessible: json['wheelchairAccessible'] as bool,
      elevatorAvailable: json['elevatorAvailable'] as bool? ?? false,
      accessibleParking: json['accessibleParking'] as bool? ?? false,
      accessibleWudu: json['accessibleWudu'] as bool? ?? false,
      details: json['details'] as String?,
    );

Map<String, dynamic> _$AccessibilityInfoToJson(AccessibilityInfo instance) =>
    <String, dynamic>{
      'wheelchairAccessible': instance.wheelchairAccessible,
      'elevatorAvailable': instance.elevatorAvailable,
      'accessibleParking': instance.accessibleParking,
      'accessibleWudu': instance.accessibleWudu,
      'details': instance.details,
    };
