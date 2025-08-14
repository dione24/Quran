import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/surah_card.dart';
import '../widgets/quick_actions_widget_modern.dart';
import '../widgets/prayer_times_widget.dart';
import '../services/prayer_times_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Les services sont maintenant initialisés dans le splash screen
    // pour éviter la surcharge du thread principal
  }

  @override
  Widget build(BuildContext context) {
    final quranDataAsync = ref.watch(quranDataProvider);
    final currentSurah = ref.watch(currentSurahProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Column(
                children: [
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    AppConstants.welcomeMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                // Bouton temporaire pour forcer le rechargement de la base de données
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('🔄 Rechargement de la base de données...')),
                    );

                    try {
                      final db = ref.read(quranDBProvider);
                      await db.clearAndReload();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('✅ Base de données rechargée avec succès !'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Invalider le cache pour forcer le rechargement
                      ref.invalidate(quranDataProvider);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Erreur: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  tooltip: 'Recharger la base de données',
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    context.push('/settings');
                  },
                  tooltip: 'Paramètres',
                ),
              ],
            ),

            // Contenu principal optimisé
            SliverPadding(
              padding: EdgeInsets.all(AppConstants.defaultPadding.w),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Layout adaptatif selon l'état des heures de prière
                  StreamBuilder<bool>(
                    stream: PrayerTimesService().visibilityStream,
                    initialData: false,
                    builder: (context, snapshot) {
                      final showPrayerTimes = snapshot.data ?? false;

                      return Column(
                        children: [
                          // Salutation adaptative
                          showPrayerTimes
                              ? _buildCompactGreeting()
                              : _buildIslamicGreeting(),

                          SizedBox(height: showPrayerTimes ? 16.h : 20.h),

                          // Heures de prière (si activées)
                          if (showPrayerTimes) ...[
                            const PrayerTimesWidget(),
                            SizedBox(height: 16.h),
                          ],

                          // Actions rapides
                          const QuickActionsWidgetModern(),

                          SizedBox(height: 20.h),

                          // Contenu selon l'espace disponible
                          if (showPrayerTimes)
                            _buildCompactContent(quranDataAsync, currentSurah)
                          else
                            _buildFullContent(quranDataAsync, currentSurah),
                        ],
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIslamicGreeting() {
    final hour = DateTime.now().hour;
    final now = DateTime.now();
    String greeting;
    String islamicGreeting;
    IconData icon;
    Color iconColor;

    if (hour < 6) {
      greeting = 'Bonne nuit';
      islamicGreeting = 'السلام عليكم ورحمة الله';
      icon = Icons.nights_stay;
      iconColor = AppConstants.primaryColor.withOpacity(0.8);
    } else if (hour < 12) {
      greeting = 'Bonne matinée';
      islamicGreeting = 'السلام عليكم ورحمة الله';
      icon = Icons.wb_sunny;
      iconColor = Colors.orange;
    } else if (hour < 17) {
      greeting = 'Bon après-midi';
      islamicGreeting = 'السلام عليكم ورحمة الله';
      icon = Icons.wb_sunny_outlined;
      iconColor = Colors.amber;
    } else if (hour < 20) {
      greeting = 'Bonne soirée';
      islamicGreeting = 'السلام عليكم ورحمة الله';
      icon = Icons.wb_twilight;
      iconColor = Colors.deepOrange;
    } else {
      greeting = 'Bonne nuit';
      islamicGreeting = 'السلام عليكم ورحمة الله';
      icon = Icons.nights_stay;
      iconColor = AppConstants.primaryColor;
    }

    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              iconColor.withOpacity(0.1),
              AppConstants.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      icon,
                      size: 28.sp,
                      color: iconColor,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          islamicGreeting,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryColor,
                            fontFamily: 'Amiri',
                          ),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          greeting,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color:
                                    AppConstants.primaryColor.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppConstants.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  '${_getIslamicDate(now)} • ${_getHijriMonth(now.month)} ${now.year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getIslamicDate(DateTime date) {
    // Approximation simple du calendrier hégirien
    // Pour une application réelle, utiliser une bibliothèque spécialisée
    final hijriYear = ((date.year - 622) * 1.030684).floor() + 1;
    return 'Aujourd\'hui • ${hijriYear}H';
  }

  String _getHijriMonth(int gregorianMonth) {
    final hijriMonths = [
      'Mouharram',
      'Safar',
      'Rabi\' al-awwal',
      'Rabi\' al-thani',
      'Joumada al-awwal',
      'Joumada al-thani',
      'Rajab',
      'Cha\'ban',
      'Ramadan',
      'Chawwal',
      'Dhou al-qi\'da',
      'Dhou al-hijja'
    ];
    // Approximation simple - décalage d'environ 1 mois
    final hijriMonthIndex = (gregorianMonth - 2) % 12;
    return hijriMonths[
        hijriMonthIndex < 0 ? hijriMonthIndex + 12 : hijriMonthIndex];
  }

  Widget _buildLastReading(int surahNumber) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: AppConstants.primaryColor,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Dernière lecture',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'Sourate ${AppConstants.surahNamesFrench[surahNumber - 1]}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 8.h),
            ElevatedButton(
              onPressed: () {
                context.push('/surah/$surahNumber');
              },
              child: const Text('Continuer la lecture'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularSurahs(AsyncValue<dynamic> quranDataAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sourates populaires',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 120.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5, // Les 5 premières sourates
            itemBuilder: (context, index) {
              final surahNumber = index + 1;
              return Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: SurahCard(
                  surahNumber: surahNumber,
                  isHorizontal: true,
                  onTap: () => context.push('/surah/$surahNumber'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVerseOfTheDay() {
    // Verset inspirant qui change selon le jour
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final verses = [
      {
        'arabic': 'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا',
        'translation':
            'Et quiconque craint Allah, Il lui donnera une issue favorable.',
        'reference': 'At-Talaq : 2'
      },
      {
        'arabic': 'وَاللَّهُ خَيْرٌ حَافِظًا ۖ وَهُوَ أَرْحَمُ الرَّاحِمِينَ',
        'translation':
            'Allah est le meilleur gardien, et Il est le plus miséricordieux des miséricordieux.',
        'reference': 'Yusuf : 64'
      },
      {
        'arabic': 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا',
        'translation': 'À côté de la difficulté est, certes, une facilité.',
        'reference': 'Ash-Sharh : 5'
      },
      {
        'arabic': 'وَبَشِّرِ الصَّابِرِينَ',
        'translation': 'Et annonce la bonne nouvelle aux endurants.',
        'reference': 'Al-Baqarah : 155'
      },
      {
        'arabic': 'وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ',
        'translation': 'Il est avec vous où que vous soyez.',
        'reference': 'Al-Hadid : 4'
      },
    ];

    final todayVerse = verses[dayOfYear % verses.length];

    return Card(
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.secondaryColor.withOpacity(0.1),
              AppConstants.primaryColor.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppConstants.secondaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppConstants.secondaryColor,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Verset du jour',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // Verset en arabe
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppConstants.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  todayVerse['arabic']!,
                  style: AppTheme.arabicTextStyle(
                    fontSize: 22.sp,
                    color: AppConstants.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),

              SizedBox(height: 16.h),

              // Traduction
              Text(
                todayVerse['translation']!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                      color: AppConstants.primaryColor.withOpacity(0.8),
                    ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12.h),

              // Référence
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  todayVerse['reference']!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),

              SizedBox(height: 16.h),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildVerseAction(
                    icon: Icons.volume_up,
                    label: 'Écouter',
                    color: AppConstants.primaryColor,
                    onTap: () {
                      ref.read(ttsServiceProvider).speak(todayVerse['arabic']!);
                    },
                  ),
                  _buildVerseAction(
                    icon: Icons.favorite_border,
                    label: 'Favoris',
                    color: AppConstants.favoriteColor,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ajouté aux favoris'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                  _buildVerseAction(
                    icon: Icons.share,
                    label: 'Partager',
                    color: AppConstants.secondaryColor,
                    onTap: () {
                      // Implémenter le partage
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Fonctionnalité de partage à implémenter')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerseAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Salutation compacte pour quand les heures de prière sont affichées
  Widget _buildCompactGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    String arabicGreeting;
    IconData icon;
    Color color;

    if (hour < 12) {
      greeting = 'Bon matin';
      arabicGreeting = 'صباح الخير';
      icon = Icons.wb_sunny;
      color = Colors.orange;
    } else if (hour < 17) {
      greeting = 'Bon après-midi';
      arabicGreeting = 'مساء الخير';
      icon = Icons.wb_sunny_outlined;
      color = Colors.amber;
    } else {
      greeting = 'Bonne soirée';
      arabicGreeting = 'مساء الخير';
      icon = Icons.nightlight_round;
      color = Colors.indigo;
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  arabicGreeting,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 14.sp,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Contenu compact quand les heures de prière sont visibles
  Widget _buildCompactContent(
      AsyncValue<dynamic> quranDataAsync, int? currentSurah) {
    return Column(
      children: [
        // Verset du jour compact
        _buildCompactVerseOfTheDay(),
        SizedBox(height: 16.h),
        // Dernière lecture si disponible
        if (currentSurah != null) _buildLastReading(currentSurah),
        if (currentSurah != null) SizedBox(height: 16.h),
        // Sourates populaires réduites
        _buildCompactPopularSurahs(quranDataAsync),
      ],
    );
  }

  // Contenu complet quand les heures de prière sont masquées
  Widget _buildFullContent(
      AsyncValue<dynamic> quranDataAsync, int? currentSurah) {
    return Column(
      children: [
        // Dernière lecture
        if (currentSurah != null) _buildLastReading(currentSurah),
        if (currentSurah != null) SizedBox(height: 20.h),
        // Sourates populaires complètes
        _buildPopularSurahs(quranDataAsync),
        SizedBox(height: 20.h),
        // Verset du jour complet
        _buildVerseOfTheDay(),
      ],
    );
  }

  // Version compacte du verset du jour
  Widget _buildCompactVerseOfTheDay() {
    final verses = [
      {
        'arabic': 'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا',
        'translation':
            'Et quiconque craint Allah, Il lui donnera une issue favorable.',
        'reference': 'Coran 65:2'
      },
      {
        'arabic': 'وَاللَّهُ خَيْرُ الرَّازِقِينَ',
        'translation': 'Et Allah est le Meilleur des pourvoyeurs.',
        'reference': 'Coran 62:11'
      },
    ];

    final verse = verses[DateTime.now().day % verses.length];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.secondaryColor.withOpacity(0.1),
            AppConstants.secondaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book,
                color: AppConstants.secondaryColor,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Verset du jour',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppConstants.secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            verse['arabic']!,
            style: AppTheme.arabicTextStyle(
              fontSize: 16.sp,
              color: AppConstants.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Text(
            verse['translation']!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Version compacte des sourates populaires
  Widget _buildCompactPopularSurahs(AsyncValue<dynamic> quranDataAsync) {
    return quranDataAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (quranData) {
        final popularSurahs = [
          quranData.getSurahByNumber(1), // Al-Fatiha
          quranData.getSurahByNumber(2), // Al-Baqarah
          quranData.getSurahByNumber(36), // Ya-Sin
        ].where((s) => s != null).cast<dynamic>().take(3).toList();

        if (popularSurahs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: AppConstants.favoriteColor,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Sourates populaires',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            SizedBox(
              height: 80.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: popularSurahs.length,
                itemBuilder: (context, index) {
                  final surah = popularSurahs[index];
                  return Container(
                    width: 120.w,
                    margin: EdgeInsets.only(right: 8.w),
                    child: SurahCard(
                      surah: surah,
                      isCompact: true,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
