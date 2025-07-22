import 'package:flutter/material.dart';

class AppConstants {
  // Couleurs principales
  static const Color primaryColor = Color(0xFF2E7D5B); // Vert émeraude
  static const Color secondaryColor = Color(0xFFD4AF37); // Doré
  static const Color accentColor = Color(0xFF1B5E20); // Vert foncé
  
  // Couleurs de fond
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  
  // Couleurs mode sombre
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkCardColor = Color(0xFF1E1E1E);
  static const Color darkSurfaceColor = Color(0xFF2C2C2C);
  
  // Couleurs de texte
  static const Color textColor = Color(0xFF212121);
  static const Color secondaryTextColor = Color(0xFF757575);
  static const Color darkTextColor = Color(0xFFE0E0E0);
  static const Color darkSecondaryTextColor = Color(0xFFBDBDBD);
  
  // Couleurs d'état
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);
  
  // Couleurs spéciales pour le Coran
  static const Color ayahHighlightColor = Color(0xFFE8F5E8);
  static const Color currentAyahColor = Color(0xFFFFE0B2);
  static const Color favoriteColor = Color(0xFFE91E63);
  
  // Dimensions
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  
  // Tailles de police pour le texte arabe
  static const double arabicSmallFontSize = 16.0;
  static const double arabicMediumFontSize = 20.0;
  static const double arabicLargeFontSize = 24.0;
  static const double arabicExtraLargeFontSize = 28.0;
  
  // Animations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);
  
  // Noms des sourates en français
  static const List<String> surahNamesFrench = [
    'L\'Ouverture', 'La Vache', 'La Famille d\'Imran', 'Les Femmes',
    'La Table Servie', 'Les Bestiaux', 'Al-A\'raf', 'Le Butin',
    'Le Repentir', 'Jonas', 'Hud', 'Joseph', 'Le Tonnerre',
    'Abraham', 'Al-Hijr', 'Les Abeilles', 'Le Voyage Nocturne',
    'La Caverne', 'Marie', 'Ta-Ha', 'Les Prophètes', 'Le Pèlerinage',
    'Les Croyants', 'La Lumière', 'Le Discernement', 'Les Poètes',
    'Les Fourmis', 'Le Récit', 'L\'Araignée', 'Les Romains',
    'Luqman', 'La Prosternation', 'Les Coalisés', 'Saba',
    'Le Créateur', 'Ya-Sin', 'Les Rangés', 'Sad', 'Les Groupes',
    'Le Pardonneur', 'Les Versets Détaillés', 'La Consultation',
    'L\'Ornement', 'La Fumée', 'L\'Agenouillée', 'Al-Ahqaf',
    'Muhammad', 'La Victoire Éclatante', 'Les Appartements',
    'Qaf', 'Qui Éparpillent', 'At-Tur', 'L\'Étoile',
    'La Lune', 'Le Tout Miséricordieux', 'L\'Événement',
    'Le Fer', 'La Discussion', 'L\'Exode', 'L\'Éprouvée',
    'Le Rang', 'Le Vendredi', 'Les Hypocrites', 'La Grande Perte',
    'Le Divorce', 'L\'Interdiction', 'La Royauté', 'La Plume',
    'Celle qui Montre la Vérité', 'Les Degrés', 'Noé',
    'Les Djinns', 'L\'Emmitouflé', 'Le Revêtu d\'un Manteau',
    'La Résurrection', 'L\'Homme', 'Les Envoyés', 'La Nouvelle',
    'Ceux qui Arrachent', 'Il s\'est Renfrogné', 'L\'Obscurcissement',
    'La Rupture', 'Les Fraudeurs', 'La Déchirure', 'Les Constellations',
    'L\'Astre Nocturne', 'Le Très-Haut', 'L\'Enveloppante',
    'L\'Aube', 'La Cité', 'Le Soleil', 'La Nuit', 'Le Jour Montant',
    'L\'Ouverture de la Poitrine', 'Le Figuier', 'L\'Adhérence',
    'La Destinée', 'La Preuve', 'Le Tremblement', 'Les Coursiers',
    'Le Fracas', 'La Course aux Richesses', 'L\'Époque',
    'Le Calomniateur', 'L\'Éléphant', 'Quraych', 'L\'Ustensile',
    'L\'Abondance', 'Les Infidèles', 'Le Secours', 'Les Fibres',
    'La Pureté du Culte', 'L\'Aube Naissante', 'Les Hommes'
  ];
  
  // Messages de l'application
  static const String appName = 'Coran Intelligent';
  static const String welcomeMessage = 'Bienvenue dans votre compagnon spirituel';
  static const String listeningMessage = 'Écoute en cours...';
  static const String speakingMessage = 'Lecture en cours...';
  static const String noInternetMessage = 'Pas de connexion Internet';
  static const String errorMessage = 'Une erreur s\'est produite';
  static const String loadingMessage = 'Chargement...';
  
  // Clés de préférences
  static const String prefThemeMode = 'theme_mode';
  static const String prefLanguage = 'language';
  static const String prefFontSize = 'font_size';
  static const String prefTTSSpeed = 'tts_speed';
  static const String prefShowTranslation = 'show_translation';
  static const String prefLastSurah = 'last_surah';
  static const String prefLastAyah = 'last_ayah';
  
  // URLs et APIs
  static const String quranApiUrl = 'https://api.alquran.cloud/v1';
  static const String tafsirApiUrl = 'https://api.quran.com/api/v4';
  
  // Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
}
