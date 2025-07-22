import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/quran_data.dart';
import '../models/surah.dart';
import '../models/ayah.dart';

class QuranDB {
  static final QuranDB _instance = QuranDB._internal();
  factory QuranDB() => _instance;
  QuranDB._internal();

  Database? _database;
  QuranData? _quranData;

  static const String _dbName = 'quran.db';
  static const int _dbVersion = 1;

  // Tables
  static const String _surahsTable = 'surahs';
  static const String _ayahsTable = 'ayahs';
  static const String _favoritesTable = 'favorites';
  static const String _readingHistoryTable = 'reading_history';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = '${documentsDirectory.path}/$_dbName';
    
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table des sourates
    await db.execute('''
      CREATE TABLE $_surahsTable (
        number INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        english_name TEXT NOT NULL,
        english_name_translation TEXT NOT NULL,
        revelation_type TEXT NOT NULL,
        number_of_ayahs INTEGER NOT NULL
      )
    ''');

    // Table des ayahs
    await db.execute('''
      CREATE TABLE $_ayahsTable (
        number INTEGER PRIMARY KEY,
        text TEXT NOT NULL,
        number_in_surah INTEGER NOT NULL,
        surah_number INTEGER NOT NULL,
        juz INTEGER NOT NULL,
        manzil INTEGER NOT NULL,
        page INTEGER NOT NULL,
        ruku INTEGER NOT NULL,
        hizb_quarter INTEGER NOT NULL,
        sajda INTEGER DEFAULT 0,
        translation TEXT,
        FOREIGN KEY (surah_number) REFERENCES $_surahsTable (number)
      )
    ''');

    // Table des favoris
    await db.execute('''
      CREATE TABLE $_favoritesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(surah_number, ayah_number)
      )
    ''');

    // Table de l'historique de lecture
    await db.execute('''
      CREATE TABLE $_readingHistoryTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        read_at TEXT NOT NULL
      )
    ''');

    // Index pour améliorer les performances
    await db.execute('CREATE INDEX idx_ayahs_surah ON $_ayahsTable (surah_number)');
    await db.execute('CREATE INDEX idx_ayahs_text ON $_ayahsTable (text)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Gestion des migrations futures
  }

  /// Initialise la base de données avec les données du Coran
  Future<void> initializeWithQuranData() async {
    final db = await database;
    
    // Vérifier si les données existent déjà
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_surahsTable')
    ) ?? 0;
    
    if (count > 0) {
      print('Base de données déjà initialisée avec ${count} sourates');
      return;
    }

    // Charger les données depuis les assets ou une API
    await _loadQuranDataFromAssets();
  }

  /// Charge les données du Coran depuis les assets
  Future<void> _loadQuranDataFromAssets() async {
    try {
      // Essayer de charger depuis les assets
      final String jsonString = await rootBundle.loadString('assets/quran/quran.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final quranData = QuranData.fromJson(jsonData);
      await _saveQuranDataToDatabase(quranData);
      
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      // En cas d'erreur, créer des données de base
      await _createSampleData();
    }
  }

  /// Sauvegarde les données du Coran dans la base de données
  Future<void> _saveQuranDataToDatabase(QuranData quranData) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Insérer les sourates
      for (final surah in quranData.surahs) {
        await txn.insert(_surahsTable, {
          'number': surah.number,
          'name': surah.name,
          'english_name': surah.englishName,
          'english_name_translation': surah.englishNameTranslation,
          'revelation_type': surah.revelationType,
          'number_of_ayahs': surah.numberOfAyahs,
        });

        // Insérer les ayahs de cette sourate
        for (final ayah in surah.ayahs) {
          await txn.insert(_ayahsTable, {
            'number': ayah.number,
            'text': ayah.text,
            'number_in_surah': ayah.numberInSurah,
            'surah_number': surah.number,
            'juz': ayah.juz,
            'manzil': ayah.manzil,
            'page': ayah.page,
            'ruku': ayah.ruku,
            'hizb_quarter': ayah.hizbQuarter,
            'sajda': ayah.sajda ? 1 : 0,
            'translation': ayah.translation,
          });
        }
      }
    });

    print('Données du Coran sauvegardées: ${quranData.surahs.length} sourates');
  }

  /// Crée des données d'exemple si les assets ne sont pas disponibles
  Future<void> _createSampleData() async {
    final db = await database;
    
    // Insérer quelques sourates d'exemple
    await db.transaction((txn) async {
      // Al-Fatiha
      await txn.insert(_surahsTable, {
        'number': 1,
        'name': 'الفاتحة',
        'english_name': 'Al-Fatihah',
        'english_name_translation': 'The Opening',
        'revelation_type': 'Meccan',
        'number_of_ayahs': 7,
      });

      // Quelques ayahs d'Al-Fatiha
      final fatihaAyahs = [
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
        'الرَّحْمَٰنِ الرَّحِيمِ',
        'مَالِكِ يَوْمِ الدِّينِ',
        'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
        'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
        'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
      ];

      for (int i = 0; i < fatihaAyahs.length; i++) {
        await txn.insert(_ayahsTable, {
          'number': i + 1,
          'text': fatihaAyahs[i],
          'number_in_surah': i + 1,
          'surah_number': 1,
          'juz': 1,
          'manzil': 1,
          'page': 1,
          'ruku': 1,
          'hizb_quarter': 1,
          'sajda': 0,
        });
      }
    });

    print('Données d\'exemple créées');
  }

  /// Récupère toutes les sourates
  Future<List<Surah>> getAllSurahs() async {
    final db = await database;
    final surahMaps = await db.query(_surahsTable, orderBy: 'number');
    
    final surahs = <Surah>[];
    for (final surahMap in surahMaps) {
      final ayahs = await getAyahsBySurah(surahMap['number'] as int);
      surahs.add(Surah(
        number: surahMap['number'] as int,
        name: surahMap['name'] as String,
        englishName: surahMap['english_name'] as String,
        englishNameTranslation: surahMap['english_name_translation'] as String,
        revelationType: surahMap['revelation_type'] as String,
        numberOfAyahs: surahMap['number_of_ayahs'] as int,
        ayahs: ayahs,
      ));
    }
    
    return surahs;
  }

  /// Récupère une sourate par son numéro
  Future<Surah?> getSurahByNumber(int number) async {
    final db = await database;
    final surahMaps = await db.query(
      _surahsTable,
      where: 'number = ?',
      whereArgs: [number],
    );
    
    if (surahMaps.isEmpty) return null;
    
    final surahMap = surahMaps.first;
    final ayahs = await getAyahsBySurah(number);
    
    return Surah(
      number: surahMap['number'] as int,
      name: surahMap['name'] as String,
      englishName: surahMap['english_name'] as String,
      englishNameTranslation: surahMap['english_name_translation'] as String,
      revelationType: surahMap['revelation_type'] as String,
      numberOfAyahs: surahMap['number_of_ayahs'] as int,
      ayahs: ayahs,
    );
  }

  /// Récupère les ayahs d'une sourate
  Future<List<Ayah>> getAyahsBySurah(int surahNumber) async {
    final db = await database;
    final ayahMaps = await db.query(
      _ayahsTable,
      where: 'surah_number = ?',
      whereArgs: [surahNumber],
      orderBy: 'number_in_surah',
    );
    
    return ayahMaps.map((map) => Ayah(
      number: map['number'] as int,
      text: map['text'] as String,
      numberInSurah: map['number_in_surah'] as int,
      juz: map['juz'] as int,
      manzil: map['manzil'] as int,
      page: map['page'] as int,
      ruku: map['ruku'] as int,
      hizbQuarter: map['hizb_quarter'] as int,
      sajda: (map['sajda'] as int) == 1,
      translation: map['translation'] as String?,
    )).toList();
  }

  /// Récupère toutes les données du Coran
  Future<QuranData> getQuranData() async {
    if (_quranData != null) return _quranData!;
    
    final surahs = await getAllSurahs();
    _quranData = QuranData(surahs: surahs);
    return _quranData!;
  }

  /// Ajouter un verset aux favoris
  Future<void> addToFavorites(int surahNumber, int ayahNumber) async {
    final db = await database;
    await db.insert(
      _favoritesTable,
      {
        'surah_number': surahNumber,
        'ayah_number': ayahNumber,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Supprimer un verset des favoris
  Future<void> removeFromFavorites(int surahNumber, int ayahNumber) async {
    final db = await database;
    await db.delete(
      _favoritesTable,
      where: 'surah_number = ? AND ayah_number = ?',
      whereArgs: [surahNumber, ayahNumber],
    );
  }

  /// Vérifier si un verset est dans les favoris
  Future<bool> isFavorite(int surahNumber, int ayahNumber) async {
    final db = await database;
    final result = await db.query(
      _favoritesTable,
      where: 'surah_number = ? AND ayah_number = ?',
      whereArgs: [surahNumber, ayahNumber],
    );
    return result.isNotEmpty;
  }

  /// Ajouter à l'historique de lecture
  Future<void> addToReadingHistory(int surahNumber, int ayahNumber) async {
    final db = await database;
    await db.insert(_readingHistoryTable, {
      'surah_number': surahNumber,
      'ayah_number': ayahNumber,
      'read_at': DateTime.now().toIso8601String(),
    });
  }

  /// Fermer la base de données
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
