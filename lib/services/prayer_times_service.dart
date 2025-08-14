import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service avancé pour les heures de prière avec APIs multiples et géolocalisation
class PrayerTimesService {
  static final PrayerTimesService _instance = PrayerTimesService._internal();
  factory PrayerTimesService() => _instance;
  PrayerTimesService._internal();

  // APIs disponibles
  static const String _aladhanAPI = 'http://api.aladhan.com/v1/timings';
  static const String _masjidiAPI = 'https://api.masjidiapp.com';
  static const String _islamicFinderAPI =
      'https://api.islamicfinder.org/v1/prayer_times';

  // Clés de stockage
  static const String _lastLocationKey = 'last_prayer_location';
  static const String _lastTimesKey = 'last_prayer_times';
  static const String _calculationMethodKey = 'calculation_method';
  static const String _showPrayerTimesKey = 'show_prayer_times';

  // État du service
  Position? _currentLocation;
  List<PrayerTime>? _todayPrayers;
  Timer? _timer;
  StreamController<PrayerTime>? _nextPrayerController;
  StreamController<List<PrayerTime>>? _allPrayersController;
  StreamController<bool>? _visibilityController;

  // Méthodes de calcul disponibles
  final Map<int, String> _calculationMethods = {
    1: 'University of Islamic Sciences, Karachi',
    2: 'Islamic Society of North America (ISNA)',
    3: 'Muslim World League (MWL)',
    4: 'Umm al-Qura University, Makkah',
    5: 'Egyptian General Authority of Survey',
    7: 'Institute of Geophysics, University of Tehran',
    8: 'Gulf Region',
    9: 'Kuwait',
    10: 'Qatar',
    11: 'Majlis Ugama Islam Singapura',
    12: 'Union Organization islamic de France',
    13: 'Diyanet İşleri Başkanlığı, Turkey',
    14: 'Spiritual Administration of Muslims of Russia',
  };

  // Getters
  Stream<PrayerTime> get nextPrayerStream => _nextPrayerController!.stream;
  Stream<List<PrayerTime>> get allPrayersStream =>
      _allPrayersController!.stream;
  Stream<bool> get visibilityStream => _visibilityController!.stream;

  bool get isVisible => _visibilityController?.hasListener == true;
  List<PrayerTime>? get todayPrayers => _todayPrayers;
  Map<int, String> get calculationMethods => _calculationMethods;

  /// Initialisation du service
  Future<void> initialize() async {
    try {
      // Initialiser les controllers
      _nextPrayerController = StreamController<PrayerTime>.broadcast();
      _allPrayersController = StreamController<List<PrayerTime>>.broadcast();
      _visibilityController = StreamController<bool>.broadcast();

      // Charger les préférences
      final prefs = await SharedPreferences.getInstance();
      final showPrayerTimes = prefs.getBool(_showPrayerTimesKey) ?? false;
      _visibilityController!.add(showPrayerTimes);

      if (showPrayerTimes) {
        await _loadPrayerTimes();
      }

      // Timer pour mise à jour périodique
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (showPrayerTimes) {
          _updateStreams();
        }
      });

      debugPrint('✅ PrayerTimesService initialisé');
    } catch (e) {
      debugPrint('❌ Erreur initialisation PrayerTimesService: $e');
    }
  }

  /// Toggle de la visibilité des heures de prière
  Future<void> toggleVisibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVisibility = prefs.getBool(_showPrayerTimesKey) ?? false;
      final newVisibility = !currentVisibility;

      await prefs.setBool(_showPrayerTimesKey, newVisibility);
      _visibilityController?.add(newVisibility);

      if (newVisibility) {
        await _loadPrayerTimes();
      } else {
        // Nettoyer les données quand masqué
        _todayPrayers = null;
      }

      debugPrint('🔄 Visibilité heures de prière: $newVisibility');
    } catch (e) {
      debugPrint('❌ Erreur toggle visibilité: $e');
    }
  }

  /// Vérifier et obtenir la permission de localisation
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Services de localisation désactivés');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('❌ Permission de localisation refusée');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Permission de localisation refusée définitivement');
      return false;
    }

    return true;
  }

  /// Obtenir la localisation actuelle
  Future<Position?> _getCurrentLocation() async {
    try {
      if (!await _checkLocationPermission()) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint(
          '📍 Position obtenue: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ Erreur obtention localisation: $e');
      return null;
    }
  }

  /// Charger les heures de prière
  Future<void> _loadPrayerTimes() async {
    try {
      // Obtenir la localisation
      _currentLocation = await _getCurrentLocation();

      if (_currentLocation == null) {
        // Utiliser la localisation par défaut (Paris)
        _currentLocation = Position(
          longitude: 2.3522,
          latitude: 48.8566,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        debugPrint('📍 Utilisation localisation par défaut: Paris');
      }

      // Essayer différentes APIs dans l'ordre de priorité
      _todayPrayers = await _fetchFromAladhanAPI() ??
          await _fetchFromIslamicFinderAPI() ??
          await _generateFallbackTimes();

      if (_todayPrayers != null) {
        await _savePrayerTimesToCache();
        _updateStreams();
        debugPrint(
            '✅ Heures de prière chargées: ${_todayPrayers!.length} prières');
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement heures de prière: $e');
      // Charger depuis le cache en cas d'erreur
      await _loadFromCache();
    }
  }

  /// API Aladhan (recommandée)
  Future<List<PrayerTime>?> _fetchFromAladhanAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final method = prefs.getInt(_calculationMethodKey) ?? 3; // MWL par défaut

      final url =
          '$_aladhanAPI/${DateTime.now().millisecondsSinceEpoch ~/ 1000}'
          '?latitude=${_currentLocation!.latitude}'
          '&longitude=${_currentLocation!.longitude}'
          '&method=$method';

      debugPrint('🌐 Appel API Aladhan: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timings = data['data']['timings'];

        return _parseAladhanResponse(timings);
      } else {
        debugPrint('❌ Erreur API Aladhan: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur Aladhan API: $e');
    }
    return null;
  }

  /// API Islamic Finder (alternative)
  Future<List<PrayerTime>?> _fetchFromIslamicFinderAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final method = prefs.getInt(_calculationMethodKey) ?? 3;

      final url = '$_islamicFinderAPI'
          '?latitude=${_currentLocation!.latitude}'
          '&longitude=${_currentLocation!.longitude}'
          '&method=$method'
          '&format=json';

      debugPrint('🌐 Appel API Islamic Finder: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseIslamicFinderResponse(data);
      } else {
        debugPrint('❌ Erreur API Islamic Finder: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur Islamic Finder API: $e');
    }
    return null;
  }

  /// Parser la réponse Aladhan
  List<PrayerTime> _parseAladhanResponse(Map<String, dynamic> timings) {
    final now = DateTime.now();

    return [
      PrayerTime('Fajr', 'الفجر', _parseTime(timings['Fajr'], now)),
      PrayerTime('Dhuhr', 'الظهر', _parseTime(timings['Dhuhr'], now)),
      PrayerTime('Asr', 'العصر', _parseTime(timings['Asr'], now)),
      PrayerTime('Maghrib', 'المغرب', _parseTime(timings['Maghrib'], now)),
      PrayerTime('Isha', 'العشاء', _parseTime(timings['Isha'], now)),
    ];
  }

  /// Parser la réponse Islamic Finder
  List<PrayerTime> _parseIslamicFinderResponse(Map<String, dynamic> data) {
    final results = data['results'];
    final now = DateTime.now();

    return [
      PrayerTime('Fajr', 'الفجر', _parseTime(results['Fajr'], now)),
      PrayerTime('Dhuhr', 'الظهر', _parseTime(results['Dhuhr'], now)),
      PrayerTime('Asr', 'العصر', _parseTime(results['Asr'], now)),
      PrayerTime('Maghrib', 'المغرب', _parseTime(results['Maghrib'], now)),
      PrayerTime('Isha', 'العشاء', _parseTime(results['Isha'], now)),
    ];
  }

  /// Parser l'heure depuis string
  DateTime _parseTime(String timeStr, DateTime date) {
    try {
      // Format: "HH:MM" ou "HH:MM (CET)"
      final cleanTime = timeStr.split(' ')[0];
      final parts = cleanTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      debugPrint('❌ Erreur parsing time: $timeStr - $e');
      return DateTime.now();
    }
  }

  /// Générer des heures de secours basées sur calculs astronomiques
  Future<List<PrayerTime>> _generateFallbackTimes() async {
    debugPrint('🔄 Génération heures de secours');

    final now = DateTime.now();
    final lat = _currentLocation?.latitude ?? 48.8566;
    final lng = _currentLocation?.longitude ?? 2.3522;

    // Calculs simplifiés basés sur les formules astronomiques
    final julianDay = _getJulianDay(now);
    final declination = _getSunDeclination(julianDay);
    final equation = _getEquationOfTime(julianDay);

    final dhuhrTime = 12.0 - (lng / 15.0) - (equation / 60.0);
    final fajrTime =
        dhuhrTime - _getTimeForAngle(-18.0, declination, lat) / 15.0;
    final asrTime = dhuhrTime + _getAsrTime(declination, lat) / 15.0;
    final maghribTime =
        dhuhrTime + _getTimeForAngle(-0.833, declination, lat) / 15.0;
    final ishaTime =
        dhuhrTime + _getTimeForAngle(-17.0, declination, lat) / 15.0;

    return [
      PrayerTime('Fajr', 'الفجر', _timeToDateTime(now, fajrTime)),
      PrayerTime('Dhuhr', 'الظهر', _timeToDateTime(now, dhuhrTime)),
      PrayerTime('Asr', 'العصر', _timeToDateTime(now, asrTime)),
      PrayerTime('Maghrib', 'المغرب', _timeToDateTime(now, maghribTime)),
      PrayerTime('Isha', 'العشاء', _timeToDateTime(now, ishaTime)),
    ];
  }

  /// Calculs astronomiques (méthodes helper)
  double _getJulianDay(DateTime date) {
    final a = (14 - date.month) ~/ 12;
    final y = date.year - a;
    final m = date.month + 12 * a - 3;

    return date.day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045.0;
  }

  double _getSunDeclination(double julianDay) {
    final n = julianDay - 2451545.0;
    final l = (280.460 + 0.9856474 * n) % 360;
    final g = math.pi / 180 * ((357.528 + 0.9856003 * n) % 360);
    final lambda =
        math.pi / 180 * (l + 1.915 * math.sin(g) + 0.020 * math.sin(2 * g));

    return math.asin(math.sin(lambda) * math.sin(math.pi / 180 * 23.439));
  }

  double _getEquationOfTime(double julianDay) {
    final n = julianDay - 2451545.0;
    final l = (280.460 + 0.9856474 * n) % 360;
    final g = math.pi / 180 * ((357.528 + 0.9856003 * n) % 360);
    final lambda =
        math.pi / 180 * (l + 1.915 * math.sin(g) + 0.020 * math.sin(2 * g));
    final alpha = math.atan2(
        math.cos(math.pi / 180 * 23.439) * math.sin(lambda), math.cos(lambda));

    return 4 * (l - 180 / math.pi * alpha);
  }

  double _getTimeForAngle(double angle, double declination, double latitude) {
    final latRad = latitude * math.pi / 180;
    final angleRad = angle * math.pi / 180;

    final cosH =
        (math.sin(angleRad) - math.sin(latRad) * math.sin(declination)) /
            (math.cos(latRad) * math.cos(declination));

    if (cosH.abs() > 1) return 0;

    return 180 / math.pi * math.acos(cosH);
  }

  double _getAsrTime(double declination, double latitude) {
    final latRad = latitude * math.pi / 180;
    final cotA = 1 +
        1 /
            math.tan(
                math.atan(1 / (1 + math.tan((latRad - declination).abs()))));
    final cosH = (math.sin(math.atan(1 / cotA)) -
            math.sin(latRad) * math.sin(declination)) /
        (math.cos(latRad) * math.cos(declination));

    if (cosH.abs() > 1) return 0;

    return 180 / math.pi * math.acos(cosH);
  }

  DateTime _timeToDateTime(DateTime date, double time) {
    final hours = time.floor();
    final minutes = ((time - hours) * 60).round();

    return DateTime(date.year, date.month, date.day, hours, minutes);
  }

  /// Mettre à jour les streams
  void _updateStreams() {
    if (_todayPrayers == null) return;

    final nextPrayer = getNextPrayer();
    _nextPrayerController?.add(nextPrayer);
    _allPrayersController?.add(_todayPrayers!);
  }

  /// Obtenir la prochaine prière
  PrayerTime getNextPrayer() {
    if (_todayPrayers == null) {
      return PrayerTime(
          'Fajr', 'الفجر', DateTime.now().add(const Duration(hours: 1)));
    }

    final now = DateTime.now();

    // Trouver la prochaine prière
    for (final prayer in _todayPrayers!) {
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }

    // Si toutes les prières sont passées, retourner Fajr de demain
    final tomorrow = now.add(const Duration(days: 1));
    return PrayerTime('Fajr', 'الفجر',
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 5, 30));
  }

  /// Sauvegarder dans le cache
  Future<void> _savePrayerTimesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_currentLocation != null) {
        await prefs.setString(_lastLocationKey,
            '${_currentLocation!.latitude},${_currentLocation!.longitude}');
      }

      if (_todayPrayers != null) {
        final prayersJson = _todayPrayers!
            .map((p) => {
                  'nameEn': p.nameEn,
                  'nameAr': p.nameAr,
                  'time': p.time.millisecondsSinceEpoch,
                })
            .toList();

        await prefs.setString(_lastTimesKey, json.encode(prayersJson));
      }
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde cache: $e');
    }
  }

  /// Charger depuis le cache
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedTimes = prefs.getString(_lastTimesKey);

      if (cachedTimes != null) {
        final prayersData = json.decode(cachedTimes) as List;
        _todayPrayers = prayersData
            .map((data) => PrayerTime(
                  data['nameEn'],
                  data['nameAr'],
                  DateTime.fromMillisecondsSinceEpoch(data['time']),
                ))
            .toList();

        _updateStreams();
        debugPrint('✅ Heures de prière chargées depuis le cache');
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement cache: $e');
    }
  }

  /// Changer la méthode de calcul
  Future<void> setCalculationMethod(int method) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_calculationMethodKey, method);

      // Recharger les heures de prière
      final showPrayerTimes = prefs.getBool(_showPrayerTimesKey) ?? false;
      if (showPrayerTimes) {
        await _loadPrayerTimes();
      }

      debugPrint('🔄 Méthode de calcul changée: $method');
    } catch (e) {
      debugPrint('❌ Erreur changement méthode: $e');
    }
  }

  /// Forcer la mise à jour
  Future<void> forceUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final showPrayerTimes = prefs.getBool(_showPrayerTimesKey) ?? false;

    if (showPrayerTimes) {
      await _loadPrayerTimes();
    }
  }

  /// Nettoyer les ressources
  void dispose() {
    _timer?.cancel();
    _nextPrayerController?.close();
    _allPrayersController?.close();
    _visibilityController?.close();
  }
}

/// Classe pour représenter une heure de prière
class PrayerTime {
  final String nameEn;
  final String nameAr;
  final DateTime time;

  PrayerTime(this.nameEn, this.nameAr, this.time);

  Duration get timeUntil {
    final now = DateTime.now();
    if (time.isAfter(now)) {
      return time.difference(now);
    }
    return Duration.zero;
  }

  String get timeUntilFormatted {
    final duration = timeUntil;
    if (duration == Duration.zero) return "Maintenant";

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return "${hours}h ${minutes}min";
    } else {
      return "${minutes}min";
    }
  }

  String get formattedTime {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  /// Icône selon la prière
  String get icon {
    switch (nameEn.toLowerCase()) {
      case 'fajr':
        return '🌅';
      case 'dhuhr':
        return '☀️';
      case 'asr':
        return '🌤️';
      case 'maghrib':
        return '🌅';
      case 'isha':
        return '🌙';
      default:
        return '🕌';
    }
  }
}
