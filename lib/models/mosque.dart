import 'package:json_annotation/json_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'mosque.g.dart';

@JsonSerializable()
class Mosque {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? distance; // Distance en mètres depuis la position actuelle
  final String? phoneNumber;
  final String? website;
  final double? rating;
  final int? totalRatings;
  final List<String>? photos;
  final Map<String, String>? openingHours;
  final List<String>? services;
  final bool? isOpen;
  final String? placeId; // Google Places ID
  final MosqueType type;
  final bool isFavorite;
  final DateTime? lastVisited;
  final Map<String, String>? prayerTimes; // Horaires de prières spécifiques
  final List<String>? specialEvents;
  final ParkingInfo? parking;
  final AccessibilityInfo? accessibility;

  Mosque({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distance,
    this.phoneNumber,
    this.website,
    this.rating,
    this.totalRatings,
    this.photos,
    this.openingHours,
    this.services,
    this.isOpen,
    this.placeId,
    this.type = MosqueType.standard,
    this.isFavorite = false,
    this.lastVisited,
    this.prayerTimes,
    this.specialEvents,
    this.parking,
    this.accessibility,
  });

  // Conversion pour Google Maps
  LatLng get location => LatLng(latitude, longitude);

  // Distance formatée
  String get formattedDistance {
    if (distance == null) return '';
    if (distance! < 1000) {
      return '${distance!.toStringAsFixed(0)} m';
    } else {
      return '${(distance! / 1000).toStringAsFixed(1)} km';
    }
  }

  // Temps de trajet estimé (à pied)
  String get estimatedWalkingTime {
    if (distance == null) return '';
    // Estimation : 5 km/h de marche
    final minutes = (distance! / 1000 * 12).round();
    if (minutes < 60) {
      return '$minutes min à pied';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '$hours h ${mins > 0 ? '$mins min' : ''} à pied';
    }
  }

  // Services disponibles
  bool get hasParking => services?.contains('parking') ?? false;
  bool get hasWudu => services?.contains('wudu') ?? false;
  bool get hasWomenSection => services?.contains('women_section') ?? false;
  bool get hasSchool => services?.contains('school') ?? false;
  bool get hasLibrary => services?.contains('library') ?? false;
  bool get hasAirConditioning => services?.contains('air_conditioning') ?? false;
  bool get hasWheelchairAccess => accessibility?.wheelchairAccessible ?? false;

  factory Mosque.fromJson(Map<String, dynamic> json) => _$MosqueFromJson(json);
  Map<String, dynamic> toJson() => _$MosqueToJson(this);

  Mosque copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? distance,
    String? phoneNumber,
    String? website,
    double? rating,
    int? totalRatings,
    List<String>? photos,
    Map<String, String>? openingHours,
    List<String>? services,
    bool? isOpen,
    String? placeId,
    MosqueType? type,
    bool? isFavorite,
    DateTime? lastVisited,
    Map<String, String>? prayerTimes,
    List<String>? specialEvents,
    ParkingInfo? parking,
    AccessibilityInfo? accessibility,
  }) {
    return Mosque(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      photos: photos ?? this.photos,
      openingHours: openingHours ?? this.openingHours,
      services: services ?? this.services,
      isOpen: isOpen ?? this.isOpen,
      placeId: placeId ?? this.placeId,
      type: type ?? this.type,
      isFavorite: isFavorite ?? this.isFavorite,
      lastVisited: lastVisited ?? this.lastVisited,
      prayerTimes: prayerTimes ?? this.prayerTimes,
      specialEvents: specialEvents ?? this.specialEvents,
      parking: parking ?? this.parking,
      accessibility: accessibility ?? this.accessibility,
    );
  }
}

enum MosqueType {
  standard,
  grand,
  historical,
  educational,
  community,
}

@JsonSerializable()
class ParkingInfo {
  final bool available;
  final bool free;
  final int? capacity;
  final String? details;

  ParkingInfo({
    required this.available,
    this.free = false,
    this.capacity,
    this.details,
  });

  factory ParkingInfo.fromJson(Map<String, dynamic> json) => 
      _$ParkingInfoFromJson(json);
  Map<String, dynamic> toJson() => _$ParkingInfoToJson(this);
}

@JsonSerializable()
class AccessibilityInfo {
  final bool wheelchairAccessible;
  final bool elevatorAvailable;
  final bool accessibleParking;
  final bool accessibleWudu;
  final String? details;

  AccessibilityInfo({
    required this.wheelchairAccessible,
    this.elevatorAvailable = false,
    this.accessibleParking = false,
    this.accessibleWudu = false,
    this.details,
  });

  factory AccessibilityInfo.fromJson(Map<String, dynamic> json) => 
      _$AccessibilityInfoFromJson(json);
  Map<String, dynamic> toJson() => _$AccessibilityInfoToJson(this);
}

// Filtre pour la recherche
class MosqueFilter {
  final double? maxDistance;
  final MosqueType? type;
  final double? minRating;
  final List<String>? requiredServices;
  final bool? isOpenNow;
  final bool? wheelchairAccessible;

  MosqueFilter({
    this.maxDistance,
    this.type,
    this.minRating,
    this.requiredServices,
    this.isOpenNow,
    this.wheelchairAccessible,
  });
}