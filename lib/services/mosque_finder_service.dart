import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mosque.dart';
import '../utils/app_constants.dart';

// Provider pour le service
final mosqueFinderServiceProvider = Provider<MosqueFinderService>((ref) {
  return MosqueFinderService();
});

// Provider pour la position actuelle
final currentPositionProvider = FutureProvider<Position?>((ref) async {
  final service = ref.read(mosqueFinderServiceProvider);
  return await service.getCurrentPosition();
});

// Provider pour les mosquées à proximité
final nearbyMosquesProvider = FutureProvider.family<List<Mosque>, MosqueFilter?>((ref, filter) async {
  final position = await ref.watch(currentPositionProvider.future);
  if (position == null) return [];
  
  final service = ref.read(mosqueFinderServiceProvider);
  return await service.searchNearbyMosques(
    position.latitude,
    position.longitude,
    filter: filter,
  );
});

// Provider pour les mosquées favorites
final favoriteMosquesProvider = StateNotifierProvider<FavoriteMosquesNotifier, List<String>>((ref) {
  return FavoriteMosquesNotifier();
});

class FavoriteMosquesNotifier extends StateNotifier<List<String>> {
  FavoriteMosquesNotifier() : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorite_mosques') ?? [];
    state = favorites;
  }

  Future<void> toggleFavorite(String mosqueId) async {
    final prefs = await SharedPreferences.getInstance();
    if (state.contains(mosqueId)) {
      state = state.where((id) => id != mosqueId).toList();
    } else {
      state = [...state, mosqueId];
    }
    await prefs.setStringList('favorite_mosques', state);
  }

  bool isFavorite(String mosqueId) {
    return state.contains(mosqueId);
  }
}

class MosqueFinderService {
  // Clé API Google (à remplacer par votre clé)
  static const String _googleApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  // URL de base pour l'API Google Places
  static const String _placesBaseUrl = 'https://maps.googleapis.com/maps/api/place';
  
  // Cache local pour les mosquées
  final Map<String, List<Mosque>> _cache = {};
  final Duration _cacheValidity = const Duration(hours: 1);
  DateTime? _lastCacheTime;

  // Obtenir la position actuelle
  Future<Position?> getCurrentPosition() async {
    try {
      // Vérifier les permissions
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        return null;
      }

      // Vérifier si le service de localisation est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Obtenir la position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention de la position: $e');
      return null;
    }
  }

  // Rechercher les mosquées à proximité
  Future<List<Mosque>> searchNearbyMosques(
    double latitude,
    double longitude, {
    double radius = 5000, // Rayon en mètres
    MosqueFilter? filter,
  }) async {
    // Vérifier le cache
    final cacheKey = '$latitude,$longitude,$radius';
    if (_cache.containsKey(cacheKey) && 
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < _cacheValidity) {
      return _applyFilter(_cache[cacheKey]!, filter);
    }

    try {
      // Recherche via Google Places API
      final url = Uri.parse(
        '$_placesBaseUrl/nearbysearch/json'
        '?location=$latitude,$longitude'
        '&radius=$radius'
        '&type=mosque'
        '&key=$_googleApiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        // Convertir les résultats en objets Mosque
        final mosques = await Future.wait(
          results.map((place) async => await _placeToMosque(place, latitude, longitude))
        );
        
        // Mettre en cache
        _cache[cacheKey] = mosques;
        _lastCacheTime = DateTime.now();
        
        return _applyFilter(mosques, filter);
      } else {
        // En cas d'erreur, retourner des données mockées pour le développement
        return _getMockMosques(latitude, longitude);
      }
    } catch (e) {
      debugPrint('Erreur lors de la recherche de mosquées: $e');
      // Retourner des données mockées en cas d'erreur
      return _getMockMosques(latitude, longitude);
    }
  }

  // Rechercher une mosquée par nom
  Future<List<Mosque>> searchMosqueByName(String query, {Position? userPosition}) async {
    try {
      final url = Uri.parse(
        '$_placesBaseUrl/textsearch/json'
        '?query=mosque+$query'
        '&key=$_googleApiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        // Convertir les résultats
        final mosques = await Future.wait(
          results.map((place) async => await _placeToMosque(
            place, 
            userPosition?.latitude ?? 0, 
            userPosition?.longitude ?? 0
          ))
        );
        
        return mosques;
      }
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la recherche par nom: $e');
      return [];
    }
  }

  // Obtenir les détails d'une mosquée
  Future<Mosque?> getMosqueDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_placesBaseUrl/details/json'
        '?place_id=$placeId'
        '&fields=name,formatted_address,geometry,formatted_phone_number,'
        'website,rating,user_ratings_total,photos,opening_hours,reviews'
        '&key=$_googleApiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];
        
        return await _placeToMosque(result, 0, 0, isDetailed: true);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des détails: $e');
      return null;
    }
  }

  // Obtenir l'itinéraire vers une mosquée
  Future<List<LatLng>> getDirections(
    double startLat,
    double startLng,
    double endLat,
    double endLng, {
    String mode = 'walking', // walking, driving, transit
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$startLat,$startLng'
        '&destination=$endLat,$endLng'
        '&mode=$mode'
        '&key=$_googleApiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylinePoints = route['overview_polyline']['points'];
          
          // Décoder le polyline
          return _decodePolyline(polylinePoints);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'itinéraire: $e');
      return [];
    }
  }

  // Convertir les données Google Places en objet Mosque
  Future<Mosque> _placeToMosque(
    Map<String, dynamic> place,
    double userLat,
    double userLng, {
    bool isDetailed = false,
  }) async {
    final location = place['geometry']['location'];
    final lat = location['lat'].toDouble();
    final lng = location['lng'].toDouble();
    
    // Calculer la distance
    final distance = _calculateDistance(userLat, userLng, lat, lng);
    
    // Extraire les services disponibles
    final services = <String>[];
    if (place['types']?.contains('parking') ?? false) services.add('parking');
    
    // Photos
    final photos = <String>[];
    if (place['photos'] != null) {
      for (var photo in place['photos']) {
        final photoRef = photo['photo_reference'];
        photos.add(
          'https://maps.googleapis.com/maps/api/place/photo'
          '?maxwidth=400'
          '&photo_reference=$photoRef'
          '&key=$_googleApiKey'
        );
      }
    }
    
    // Horaires d'ouverture
    Map<String, String>? openingHours;
    if (place['opening_hours'] != null && place['opening_hours']['weekday_text'] != null) {
      openingHours = {};
      final weekdays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
      final texts = place['opening_hours']['weekday_text'] as List;
      for (int i = 0; i < texts.length && i < weekdays.length; i++) {
        openingHours[weekdays[i]] = texts[i].toString().split(': ').last;
      }
    }
    
    return Mosque(
      id: place['place_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: place['name'] ?? 'Mosquée',
      address: place['formatted_address'] ?? place['vicinity'] ?? '',
      latitude: lat,
      longitude: lng,
      distance: distance,
      phoneNumber: place['formatted_phone_number'],
      website: place['website'],
      rating: place['rating']?.toDouble(),
      totalRatings: place['user_ratings_total'],
      photos: photos.isNotEmpty ? photos : null,
      openingHours: openingHours,
      services: services.isNotEmpty ? services : null,
      isOpen: place['opening_hours']?['open_now'],
      placeId: place['place_id'],
      type: _determineMosqueType(place['name'] ?? ''),
    );
  }

  // Déterminer le type de mosquée basé sur le nom
  MosqueType _determineMosqueType(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('grand') || lowerName.contains('grande')) {
      return MosqueType.grand;
    } else if (lowerName.contains('historique') || lowerName.contains('ancien')) {
      return MosqueType.historical;
    } else if (lowerName.contains('école') || lowerName.contains('institut')) {
      return MosqueType.educational;
    } else if (lowerName.contains('centre') || lowerName.contains('communautaire')) {
      return MosqueType.community;
    }
    return MosqueType.standard;
  }

  // Calculer la distance entre deux points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Rayon de la Terre en mètres
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  // Appliquer les filtres
  List<Mosque> _applyFilter(List<Mosque> mosques, MosqueFilter? filter) {
    if (filter == null) return mosques;
    
    return mosques.where((mosque) {
      // Filtre par distance
      if (filter.maxDistance != null && mosque.distance != null) {
        if (mosque.distance! > filter.maxDistance!) return false;
      }
      
      // Filtre par type
      if (filter.type != null && mosque.type != filter.type) {
        return false;
      }
      
      // Filtre par note
      if (filter.minRating != null && mosque.rating != null) {
        if (mosque.rating! < filter.minRating!) return false;
      }
      
      // Filtre par services
      if (filter.requiredServices != null && filter.requiredServices!.isNotEmpty) {
        if (mosque.services == null) return false;
        for (var service in filter.requiredServices!) {
          if (!mosque.services!.contains(service)) return false;
        }
      }
      
      // Filtre par ouverture
      if (filter.isOpenNow != null && filter.isOpenNow! && mosque.isOpen != true) {
        return false;
      }
      
      return true;
    }).toList()
      ..sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
  }

  // Décoder un polyline Google
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int shift = 0;
      int result = 0;
      int byte;
      
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      
      int deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += deltaLat;

      shift = 0;
      result = 0;
      
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      
      int deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += deltaLng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    
    return points;
  }

  // Données mockées pour le développement
  List<Mosque> _getMockMosques(double userLat, double userLng) {
    return [
      Mosque(
        id: '1',
        name: 'Grande Mosquée de Paris',
        address: '2bis Place du Puits de l\'Ermite, 75005 Paris',
        latitude: 48.8419,
        longitude: 2.3556,
        distance: _calculateDistance(userLat, userLng, 48.8419, 2.3556),
        phoneNumber: '+33 1 45 35 97 33',
        website: 'https://www.mosqueedeparis.net',
        rating: 4.5,
        totalRatings: 2543,
        photos: ['https://via.placeholder.com/400x300'],
        services: ['parking', 'wudu', 'women_section', 'school', 'library'],
        isOpen: true,
        type: MosqueType.grand,
        openingHours: {
          'Lundi': '09:00 - 18:00',
          'Mardi': '09:00 - 18:00',
          'Mercredi': '09:00 - 18:00',
          'Jeudi': '09:00 - 18:00',
          'Vendredi': '09:00 - 20:00',
          'Samedi': '09:00 - 18:00',
          'Dimanche': '09:00 - 18:00',
        },
      ),
      Mosque(
        id: '2',
        name: 'Mosquée Omar Ibn Al-Khattab',
        address: '79 Rue Jean-Pierre Timbaud, 75011 Paris',
        latitude: 48.8667,
        longitude: 2.3756,
        distance: _calculateDistance(userLat, userLng, 48.8667, 2.3756),
        rating: 4.3,
        totalRatings: 876,
        services: ['wudu', 'women_section'],
        isOpen: true,
        type: MosqueType.community,
      ),
      Mosque(
        id: '3',
        name: 'Centre Islamique de Belleville',
        address: '53 Rue de Belleville, 75019 Paris',
        latitude: 48.8723,
        longitude: 2.3845,
        distance: _calculateDistance(userLat, userLng, 48.8723, 2.3845),
        rating: 4.1,
        totalRatings: 432,
        services: ['wudu', 'school'],
        isOpen: false,
        type: MosqueType.educational,
      ),
    ];
  }
}