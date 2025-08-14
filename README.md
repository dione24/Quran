# 🕌 Coran Intelligent - Application Flutter

[![Flutter](https://img.shields.io/badge/Flutter-3.24.5-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.5.4-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Une application Flutter complète pour la lecture et l'écoute intelligente du Saint Coran avec reconnaissance vocale en arabe et localisation de mosquées.

## ✨ Fonctionnalités

### 🔊 **Reconnaissance Vocale Intelligente**
- Reconnaissance vocale en arabe (ar-SA)
- Correspondance automatique avec les versets du Coran
- Algorithme de similarité avec nettoyage des diacritiques
- Affichage des résultats avec score de confiance

### 📖 **Lecture Interactive**
- Navigation complète dans les 114 sourates
- Affichage du texte arabe avec polices authentiques (Amiri Quran)
- Traductions françaises intégrées
- Lecture vocale Text-to-Speech en arabe
- Mode lecture continue

### 🕌 **Localisation de Mosquées**
- Recherche de mosquées à proximité
- Cartes interactives avec Google Maps
- Informations détaillées sur chaque mosquée
- Navigation GPS vers les mosquées
- Horaires de prière localisés

### 🎨 **Interface Utilisateur**
- Design islamique respectueux (vert émeraude, doré)
- 5 écrans principaux avec navigation fluide
- Animations et transitions douces
- Mode sombre et clair
- Interface responsive

### 💾 **Gestion des Données**
- Base de données SQLite embarquée
- Système de favoris et historique de lecture
- Stockage local pour fonctionnement hors-ligne
- Modèles JSON pour Ayah, Surah, QuranData, Mosque

## 🏗️ Architecture

```
lib/
├── data/
│   └── quran_db.dart          # Base de données SQLite
├── models/
│   ├── ayah.dart              # Modèle de verset
│   ├── surah.dart             # Modèle de sourate
│   ├── mosque.dart            # Modèle de mosquée
│   └── quran_data.dart        # Données complètes du Coran
├── providers/
│   └── app_providers.dart     # Gestion d'état Riverpod
├── screens/
│   ├── home_screen.dart       # Écran d'accueil
│   ├── read_screen.dart       # Écran de lecture
│   ├── listen_screen.dart     # Écran d'écoute/STT
│   ├── prayers_screen.dart    # Écran des prières
│   ├── mosque_finder_screen.dart # Écran de recherche de mosquées
│   └── favorites_screen.dart  # Écran des favoris
├── services/
│   ├── stt_service.dart       # Reconnaissance vocale
│   ├── tts_service.dart       # Synthèse vocale
│   ├── audio_matcher.dart     # Correspondance IA
│   └── mosque_finder_service.dart # Service de recherche de mosquées
├── utils/
│   ├── app_constants.dart     # Constantes
│   └── app_theme.dart         # Thèmes
├── widgets/
│   ├── mosque_card.dart       # Composant carte de mosquée
│   └── ...                    # Autres composants réutilisables
└── main.dart                  # Point d'entrée
```

## 🚀 Installation

### Prérequis
- Flutter SDK 3.24.5+
- Dart 3.5.4+
- Android SDK 33+
- Java 17 (recommandé)
- Clé API Google Maps

### Étapes

1. **Cloner le repository**
   ```bash
   git clone https://github.com/dione24/Quran.git
   cd Quran
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   flutter packages pub run build_runner build
   ```

3. **Configurer Google Maps**
   - Obtenir une clé API Google Maps
   - Ajouter la clé dans `android/app/src/main/AndroidManifest.xml`
   - Ajouter la clé dans `ios/Runner/AppDelegate.swift`

4. **Lancer l'application**
   ```bash
   flutter run
   ```

5. **Construire l'APK de release**
   ```bash
   flutter build apk --release
   ```

## 📱 Écrans Principaux

### 🏠 Accueil
- Salutation islamique contextuelle
- Actions rapides (Lire, Écouter, Favoris, Recherche)
- Statistiques utilisateur
- Verset du jour avec lecture audio

### 📖 Lecture
- Sélecteur de sourates avec recherche
- Affichage texte arabe + traduction française
- Basmalah automatique
- Contrôles de lecture/pause/favori/partage
- Navigation verset par verset

### 🎙️ Écoute
- Animation microphone en temps réel
- Reconnaissance vocale arabe
- Correspondance automatique avec le Coran
- Affichage des correspondances trouvées
- Navigation vers versets détectés

### 🕌 Mosquées
- Carte interactive avec localisation
- Recherche de mosquées par nom ou adresse
- Informations détaillées (adresse, téléphone, horaires)
- Navigation GPS vers la mosquée sélectionnée
- Liste des mosquées à proximité

### 🕊️ Prières
- Horaires de prière basés sur la localisation
- Direction de la Qibla avec boussole
- Notifications pour les heures de prière
- Calendrier islamique

### ⭐ Favoris
- Liste des versets favoris
- Historique de lecture (50 derniers)
- Export et partage
- Recherche dans les favoris

## 🛠️ Technologies Utilisées

- **Framework**: Flutter 3.24.5
- **Langage**: Dart 3.5.4
- **État**: Riverpod
- **Navigation**: GoRouter
- **Base de données**: SQLite (sqflite), Hive
- **Audio**: speech_to_text, flutter_tts
- **Maps**: Google Maps Flutter
- **Location**: Geolocator, Geocoding
- **UI**: flutter_screenutil, responsive_framework
- **Sérialisation**: json_annotation, freezed

## 📦 Dépendances Principales

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.7
  flutter_screenutil: ^5.9.3
  speech_to_text: ^7.0.0
  flutter_tts: ^4.1.0
  sqflite: ^2.3.3+1
  google_maps_flutter: ^2.5.3
  geolocator: ^13.0.1
  string_similarity: ^2.0.0
  # ... et plus
```

## 🎯 Fonctionnalités Avancées (Prévues)

- [ ] Module Tajwid avec couleurs
- [ ] Tafsir Ibn Kathir intégré
- [ ] Gamification avec badges
- [ ] Mode enfant avec syllabation
- [ ] Partage social
- [ ] Firebase Auth & Cloud
- [ ] Mode hors-ligne pour les cartes
- [ ] Avis et commentaires sur les mosquées

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📄 License

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🙏 Remerciements

- **Communauté musulmane** pour l'inspiration
- **Équipe Flutter** pour le framework
- **Google Maps** pour les services de cartographie
- **Contributors** des packages utilisés

---

**Développé avec ❤️ pour la communauté musulmane**

*"Et Nous avons fait descendre vers toi le Livre, comme un exposé explicite de toute chose, ainsi qu'un guide, une miséricorde et une bonne annonce aux Musulmans."* - Coran 16:89

**بارك الله فيكم**
