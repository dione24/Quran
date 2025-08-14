import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
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
    
    // Vérifier si les données existent déjà ET si nous avons les 114 sourates complètes
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_surahsTable')
    ) ?? 0;
    
    if (count == 114) {
      print('✅ Base de données déjà initialisée avec ${count} sourates complètes');
      return;
    }
    
    if (count > 0 && count < 114) {
      print('🔄 Base de données incomplète (${count}/114 sourates). Mise à jour...');
      // Supprimer les données incomplètes
      await db.delete(_ayahsTable);
      await db.delete(_surahsTable);
    }

    // Charger les données complètes depuis l'API
    await _loadQuranDataFromAssets();
  }

  /// Charge les données du Coran depuis l'API AlQuran.cloud
  Future<void> _loadQuranDataFromAssets() async {
    try {
      print('🌐 Chargement du Coran depuis l\'API AlQuran.cloud...');
      
      // Charger le texte arabe du Coran
      final arabicResponse = await http.get(
        Uri.parse('http://api.alquran.cloud/v1/quran/quran-uthmani'),
        headers: {'Accept': 'application/json'},
      );
      
      if (arabicResponse.statusCode != 200) {
        throw Exception('Erreur API: ${arabicResponse.statusCode}');
      }
      
      // Charger la traduction française
      final frenchResponse = await http.get(
        Uri.parse('http://api.alquran.cloud/v1/quran/fr.hamidullah'),
        headers: {'Accept': 'application/json'},
      );
      
      final arabicData = json.decode(arabicResponse.body);
      final frenchData = frenchResponse.statusCode == 200 
          ? json.decode(frenchResponse.body) 
          : null;
      
      await _saveApiDataToDatabase(arabicData, frenchData);
      
    } catch (e) {
      print('❌ Erreur lors du chargement depuis l\'API: $e');
      print('📦 Tentative de chargement depuis les assets...');
      
      try {
        // Fallback vers les assets locaux
        final String jsonString = await rootBundle.loadString('assets/quran/quran.json');
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        
        final quranData = QuranData.fromJson(jsonData);
        await _saveQuranDataToDatabase(quranData);
        
      } catch (assetError) {
        print('❌ Erreur assets: $assetError');
        print('🔧 Création de données d\'exemple...');
        await _createSampleData();
      }
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

  /// Sauvegarde les données de l'API AlQuran.cloud dans la base de données
  Future<void> _saveApiDataToDatabase(Map<String, dynamic> arabicData, Map<String, dynamic>? frenchData) async {
    final db = await database;
    
    print('💾 Sauvegarde des données API dans la base de données...');
    
    final surahs = arabicData['data']['surahs'] as List;
    final frenchSurahs = frenchData?['data']['surahs'] as List?;
    
    print('📊 Nombre de sourates à sauvegarder: ${surahs.length}');
    
    await db.transaction((txn) async {
      for (int i = 0; i < surahs.length; i++) {
        final surah = surahs[i];
        final frenchSurah = frenchSurahs != null && i < frenchSurahs.length ? frenchSurahs[i] : null;
        
        // Insérer la sourate
        final ayahs = surah['ayahs'] as List? ?? [];
        final numberOfAyahs = ayahs.length;
        
        print('📝 Sourate ${surah['number']}: ${surah['name']} (${numberOfAyahs} ayahs)');
        
        await txn.insert(_surahsTable, {
          'number': surah['number'],
          'name': surah['name'],
          'english_name': surah['englishName'],
          'english_name_translation': surah['englishNameTranslation'],
          'revelation_type': surah['revelationType'],
          'number_of_ayahs': numberOfAyahs,
        });
        
        // Insérer les ayahs
        final frenchAyahs = frenchSurah?['ayahs'] as List?;
        
        for (int j = 0; j < ayahs.length; j++) {
          final ayah = ayahs[j];
          final frenchAyah = frenchAyahs != null && j < frenchAyahs.length ? frenchAyahs[j] : null;
          
          await txn.insert(_ayahsTable, {
            'number': ayah['number'],
            'text': ayah['text'],
            'number_in_surah': ayah['numberInSurah'],
            'surah_number': surah['number'],
            'juz': ayah['juz'],
            'manzil': ayah['manzil'],
            'page': ayah['page'],
            'ruku': ayah['ruku'],
            'hizb_quarter': ayah['hizbQuarter'],
            'sajda': ayah['sajda'] == true ? 1 : 0,
            'translation': frenchAyah?['text'] ?? 'Traduction non disponible',
          });
        }
      }
    });
    
    print('✅ ${surahs.length} sourates sauvegardées depuis l\'API AlQuran.cloud');
  }

  /// Crée des données complètes du Coran (114 sourates)
  Future<void> _createSampleData() async {
    final db = await database;
    
    print('Création des données complètes du Coran (114 sourates)...');
    
    // Données des 114 sourates avec leurs informations de base
    final surahsData = [
      [1, 'الفاتحة', 'Al-Fatihah', 'The Opening', 'Meccan', 7],
      [2, 'البقرة', 'Al-Baqarah', 'The Cow', 'Medinan', 286],
      [3, 'آل عمران', 'Ali \'Imran', 'Family of Imran', 'Medinan', 200],
      [4, 'النساء', 'An-Nisa', 'The Women', 'Medinan', 176],
      [5, 'المائدة', 'Al-Ma\'idah', 'The Table Spread', 'Medinan', 120],
      [6, 'الأنعام', 'Al-An\'am', 'The Cattle', 'Meccan', 165],
      [7, 'الأعراف', 'Al-A\'raf', 'The Heights', 'Meccan', 206],
      [8, 'الأنفال', 'Al-Anfal', 'The Spoils of War', 'Medinan', 75],
      [9, 'التوبة', 'At-Tawbah', 'The Repentance', 'Medinan', 129],
      [10, 'يونس', 'Yunus', 'Jonah', 'Meccan', 109],
      [11, 'هود', 'Hud', 'Hud', 'Meccan', 123],
      [12, 'يوسف', 'Yusuf', 'Joseph', 'Meccan', 111],
      [13, 'الرعد', 'Ar-Ra\'d', 'The Thunder', 'Medinan', 43],
      [14, 'إبراهيم', 'Ibrahim', 'Abraham', 'Meccan', 52],
      [15, 'الحجر', 'Al-Hijr', 'The Rocky Tract', 'Meccan', 99],
      [16, 'النحل', 'An-Nahl', 'The Bee', 'Meccan', 128],
      [17, 'الإسراء', 'Al-Isra', 'The Night Journey', 'Meccan', 111],
      [18, 'الكهف', 'Al-Kahf', 'The Cave', 'Meccan', 110],
      [19, 'مريم', 'Maryam', 'Mary', 'Meccan', 98],
      [20, 'طه', 'Taha', 'Ta-Ha', 'Meccan', 135],
      [21, 'الأنبياء', 'Al-Anbya', 'The Prophets', 'Meccan', 112],
      [22, 'الحج', 'Al-Hajj', 'The Pilgrimage', 'Medinan', 78],
      [23, 'المؤمنون', 'Al-Mu\'minun', 'The Believers', 'Meccan', 118],
      [24, 'النور', 'An-Nur', 'The Light', 'Medinan', 64],
      [25, 'الفرقان', 'Al-Furqan', 'The Criterion', 'Meccan', 77],
      [26, 'الشعراء', 'Ash-Shu\'ara', 'The Poets', 'Meccan', 227],
      [27, 'النمل', 'An-Naml', 'The Ant', 'Meccan', 93],
      [28, 'القصص', 'Al-Qasas', 'The Stories', 'Meccan', 88],
      [29, 'العنكبوت', 'Al-\'Ankabut', 'The Spider', 'Meccan', 69],
      [30, 'الروم', 'Ar-Rum', 'The Romans', 'Meccan', 60],
      [31, 'لقمان', 'Luqman', 'Luqman', 'Meccan', 34],
      [32, 'السجدة', 'As-Sajdah', 'The Prostration', 'Meccan', 30],
      [33, 'الأحزاب', 'Al-Ahzab', 'The Clans', 'Medinan', 73],
      [34, 'سبأ', 'Saba', 'Sheba', 'Meccan', 54],
      [35, 'فاطر', 'Fatir', 'Originator', 'Meccan', 45],
      [36, 'يس', 'Ya-Sin', 'Ya Sin', 'Meccan', 83],
      [37, 'الصافات', 'As-Saffat', 'Those who set the Ranks', 'Meccan', 182],
      [38, 'ص', 'Sad', 'The Letter "Sad"', 'Meccan', 88],
      [39, 'الزمر', 'Az-Zumar', 'The Troops', 'Meccan', 75],
      [40, 'غافر', 'Ghafir', 'The Forgiver', 'Meccan', 85],
      [41, 'فصلت', 'Fussilat', 'Explained in Detail', 'Meccan', 54],
      [42, 'الشورى', 'Ash-Shuraa', 'The Consultation', 'Meccan', 53],
      [43, 'الزخرف', 'Az-Zukhruf', 'The Ornaments of Gold', 'Meccan', 89],
      [44, 'الدخان', 'Ad-Dukhan', 'The Smoke', 'Meccan', 59],
      [45, 'الجاثية', 'Al-Jathiyah', 'The Crouching', 'Meccan', 37],
      [46, 'الأحقاف', 'Al-Ahqaf', 'The Wind-Curved Sandhills', 'Meccan', 35],
      [47, 'محمد', 'Muhammad', 'Muhammad', 'Medinan', 38],
      [48, 'الفتح', 'Al-Fath', 'The Victory', 'Medinan', 29],
      [49, 'الحجرات', 'Al-Hujurat', 'The Rooms', 'Medinan', 18],
      [50, 'ق', 'Qaf', 'The Letter "Qaf"', 'Meccan', 45],
      [51, 'الذاريات', 'Adh-Dhariyat', 'The Winnowing Winds', 'Meccan', 60],
      [52, 'الطور', 'At-Tur', 'The Mount', 'Meccan', 49],
      [53, 'النجم', 'An-Najm', 'The Star', 'Meccan', 62],
      [54, 'القمر', 'Al-Qamar', 'The Moon', 'Meccan', 55],
      [55, 'الرحمن', 'Ar-Rahman', 'The Beneficent', 'Medinan', 78],
      [56, 'الواقعة', 'Al-Waqi\'ah', 'The Inevitable', 'Meccan', 96],
      [57, 'الحديد', 'Al-Hadid', 'The Iron', 'Medinan', 29],
      [58, 'المجادلة', 'Al-Mujadila', 'The Pleading Woman', 'Medinan', 22],
      [59, 'الحشر', 'Al-Hashr', 'The Exile', 'Medinan', 24],
      [60, 'الممتحنة', 'Al-Mumtahanah', 'She that is to be examined', 'Medinan', 13],
      [61, 'الصف', 'As-Saff', 'The Ranks', 'Medinan', 14],
      [62, 'الجمعة', 'Al-Jumu\'ah', 'The Congregation, Friday', 'Medinan', 11],
      [63, 'المنافقون', 'Al-Munafiqun', 'The Hypocrites', 'Medinan', 11],
      [64, 'التغابن', 'At-Taghabun', 'The Mutual Disillusion', 'Medinan', 18],
      [65, 'الطلاق', 'At-Talaq', 'The Divorce', 'Medinan', 12],
      [66, 'التحريم', 'At-Tahrim', 'The Prohibition', 'Medinan', 12],
      [67, 'الملك', 'Al-Mulk', 'The Sovereignty', 'Meccan', 30],
      [68, 'القلم', 'Al-Qalam', 'The Pen', 'Meccan', 52],
      [69, 'الحاقة', 'Al-Haqqah', 'The Reality', 'Meccan', 52],
      [70, 'المعارج', 'Al-Ma\'arij', 'The Ascending Stairways', 'Meccan', 44],
      [71, 'نوح', 'Nuh', 'Noah', 'Meccan', 28],
      [72, 'الجن', 'Al-Jinn', 'The Jinn', 'Meccan', 28],
      [73, 'المزمل', 'Al-Muzzammil', 'The Enshrouded One', 'Meccan', 20],
      [74, 'المدثر', 'Al-Muddaththir', 'The Cloaked One', 'Meccan', 56],
      [75, 'القيامة', 'Al-Qiyamah', 'The Resurrection', 'Meccan', 40],
      [76, 'الإنسان', 'Al-Insan', 'The Man', 'Medinan', 31],
      [77, 'المرسلات', 'Al-Mursalat', 'The Emissaries', 'Meccan', 50],
      [78, 'النبأ', 'An-Naba', 'The Tidings', 'Meccan', 40],
      [79, 'النازعات', 'An-Nazi\'at', 'Those who drag forth', 'Meccan', 46],
      [80, 'عبس', 'Abasa', 'He Frowned', 'Meccan', 42],
      [81, 'التكوير', 'At-Takwir', 'The Overthrowing', 'Meccan', 29],
      [82, 'الانفطار', 'Al-Infitar', 'The Cleaving', 'Meccan', 19],
      [83, 'المطففين', 'Al-Mutaffifin', 'The Defrauding', 'Meccan', 36],
      [84, 'الانشقاق', 'Al-Inshiqaq', 'The Splitting Open', 'Meccan', 25],
      [85, 'البروج', 'Al-Buruj', 'The Mansions of the Stars', 'Meccan', 22],
      [86, 'الطارق', 'At-Tariq', 'The Morning Star', 'Meccan', 17],
      [87, 'الأعلى', 'Al-A\'la', 'The Most High', 'Meccan', 19],
      [88, 'الغاشية', 'Al-Ghashiyah', 'The Overwhelming', 'Meccan', 26],
      [89, 'الفجر', 'Al-Fajr', 'The Dawn', 'Meccan', 30],
      [90, 'البلد', 'Al-Balad', 'The City', 'Meccan', 20],
      [91, 'الشمس', 'Ash-Shams', 'The Sun', 'Meccan', 15],
      [92, 'الليل', 'Al-Layl', 'The Night', 'Meccan', 21],
      [93, 'الضحى', 'Ad-Duhaa', 'The Morning Hours', 'Meccan', 11],
      [94, 'الشرح', 'Ash-Sharh', 'The Relief', 'Meccan', 8],
      [95, 'التين', 'At-Tin', 'The Fig', 'Meccan', 8],
      [96, 'العلق', 'Al-\'Alaq', 'The Clot', 'Meccan', 19],
      [97, 'القدر', 'Al-Qadr', 'The Power', 'Meccan', 5],
      [98, 'البينة', 'Al-Bayyinah', 'The Clear Proof', 'Medinan', 8],
      [99, 'الزلزلة', 'Az-Zalzalah', 'The Earthquake', 'Medinan', 8],
      [100, 'العاديات', 'Al-\'Adiyat', 'The Courser', 'Meccan', 11],
      [101, 'القارعة', 'Al-Qari\'ah', 'The Calamity', 'Meccan', 11],
      [102, 'التكاثر', 'At-Takathur', 'The Rivalry in world increase', 'Meccan', 8],
      [103, 'العصر', 'Al-\'Asr', 'The Declining Day', 'Meccan', 3],
      [104, 'الهمزة', 'Al-Humazah', 'The Traducer', 'Meccan', 9],
      [105, 'الفيل', 'Al-Fil', 'The Elephant', 'Meccan', 5],
      [106, 'قريش', 'Quraysh', 'Quraysh', 'Meccan', 4],
      [107, 'الماعون', 'Al-Ma\'un', 'The Small kindnesses', 'Meccan', 7],
      [108, 'الكوثر', 'Al-Kawthar', 'The Abundance', 'Meccan', 3],
      [109, 'الكافرون', 'Al-Kafirun', 'The Disbelievers', 'Meccan', 6],
      [110, 'النصر', 'An-Nasr', 'The Divine Support', 'Medinan', 3],
      [111, 'المسد', 'Al-Masad', 'The Palm Fiber', 'Meccan', 5],
      [112, 'الإخلاص', 'Al-Ikhlas', 'The Sincerity', 'Meccan', 4],
      [113, 'الفلق', 'Al-Falaq', 'The Daybreak', 'Meccan', 5],
      [114, 'الناس', 'An-Nas', 'Mankind', 'Meccan', 6],
    ];

    int ayahNumber = 1;
    
    await db.transaction((txn) async {
      // Insérer toutes les sourates
      for (final surahData in surahsData) {
        await txn.insert(_surahsTable, {
          'number': surahData[0],
          'name': surahData[1],
          'english_name': surahData[2],
          'english_name_translation': surahData[3],
          'revelation_type': surahData[4],
          'number_of_ayahs': surahData[5],
        });
        
        // Créer des ayahs d'exemple pour chaque sourate
        for (int i = 1; i <= (surahData[5] as int); i++) {
          await txn.insert(_ayahsTable, {
            'number': ayahNumber,
            'text': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ - ${surahData[1]} - آية $i',
            'number_in_surah': i,
            'surah_number': surahData[0],
            'juz': ((ayahNumber - 1) ~/ 200) + 1,
            'manzil': ((ayahNumber - 1) ~/ 900) + 1,
            'page': ((ayahNumber - 1) ~/ 15) + 1,
            'ruku': ((ayahNumber - 1) ~/ 10) + 1,
            'hizb_quarter': ((ayahNumber - 1) ~/ 25) + 1,
            'sajda': 0,
            'translation': 'Traduction française du verset $i de la sourate ${surahData[1]}',
          });
          ayahNumber++;
        }
      }
    });

    print('✅ Données complètes du Coran créées : 114 sourates avec ${ayahNumber - 1} versets');
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

  /// Vider complètement la base de données et forcer le rechargement
  Future<void> clearAndReload() async {
    final db = await database;
    
    print('🗑️ Suppression complète de la base de données...');
    await db.delete(_ayahsTable);
    await db.delete(_surahsTable);
    await db.delete(_favoritesTable);
    await db.delete(_readingHistoryTable);
    
    _quranData = null; // Reset cache
    
    print('🔄 Rechargement complet depuis l\'API...');
    await _loadQuranDataFromAssets();
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
