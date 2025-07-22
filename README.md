# 🕌 Coran Intelligent - Application Flutter

[![Flutter](https://img.shields.io/badge/Flutter-3.24.5-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.5.4-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Une application Flutter complète pour la lecture et l'écoute intelligente du Saint Coran avec reconnaissance vocale en arabe.

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

### 🎨 **Interface Utilisateur**
- Design islamique respectueux (vert émeraude, doré)
- 4 écrans principaux avec navigation fluide
- Animations et transitions douces
- Mode sombre et clair
- Interface responsive

### 💾 **Gestion des Données**
- Base de données SQLite embarquée
- Système de favoris et historique de lecture
- Stockage local pour fonctionnement hors-ligne
- Modèles JSON pour Ayah, Surah, QuranData

## 🏗️ Architecture

```
lib/
├── data/
│   └── quran_db.dart          # Base de données SQLite
├── models/
│   ├── ayah.dart              # Modèle de verset
│   ├── surah.dart             # Modèle de sourate
│   └── quran_data.dart        # Données complètes du Coran
├── providers/
│   └── app_providers.dart     # Gestion d'état Riverpod
├── screens/
│   ├── home_screen.dart       # Écran d'accueil
│   ├── read_screen.dart       # Écran de lecture
│   ├── listen_screen.dart     # Écran d'écoute/STT
│   └── favorites_screen.dart  # Écran des favoris
├── services/
│   ├── stt_service.dart       # Reconnaissance vocale
│   ├── tts_service.dart       # Synthèse vocale
│   └── audio_matcher.dart     # Correspondance IA
├── utils/
│   ├── app_constants.dart     # Constantes
│   └── app_theme.dart         # Thèmes
├── widgets/
│   └── ...                    # Composants réutilisables
└── main.dart                  # Point d'entrée
```

## 🚀 Installation

### Prérequis
- Flutter SDK 3.24.5+
- Dart 3.5.4+
- Android SDK 33+
- Java 17 (recommandé)

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

3. **Lancer l'application**
   ```bash
   flutter run
   ```

4. **Construire l'APK de release**
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
- **Base de données**: SQLite (sqflite)
- **Audio**: speech_to_text, flutter_tts
- **UI**: flutter_screenutil, responsive_framework
- **Sérialisation**: json_annotation

## 📦 Dépendances Principales

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.7
  flutter_screenutil: ^5.9.3
  speech_to_text: ^7.0.0
  flutter_tts: ^4.1.0
  sqflite: ^2.3.3+1
  string_similarity: ^2.0.0
  # ... et plus
```

## 🎯 Fonctionnalités Avancées (Prévues)

- [ ] Module Tajwid avec couleurs
- [ ] Tafsir Ibn Kathir intégré
- [ ] Gamification avec badges
- [ ] Mode enfant avec syllabation
- [ ] Qibla et horaires de prière
- [ ] Partage social
- [ ] Firebase Auth & Cloud

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
- **Contributors** des packages utilisés

---

**Développé avec ❤️ pour la communauté musulmane**

*"Et Nous avons fait descendre vers toi le Livre, comme un exposé explicite de toute chose, ainsi qu'un guide, une miséricorde et une bonne annonce aux Musulmans."* - Coran 16:89

**بارك الله فيكم**
