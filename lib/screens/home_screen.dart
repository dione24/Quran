import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/surah_card.dart';
import '../widgets/quick_actions_widget.dart';
import '../widgets/stats_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialiser les services nécessaires
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sttServiceProvider).initialize();
      ref.read(ttsServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final quranDataAsync = ref.watch(quranDataProvider);
    final currentSurah = ref.watch(currentSurahProvider);
    final userStats = ref.watch(userStatsProvider);

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
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    // Naviguer vers les paramètres
                  },
                ),
              ],
            ),

            // Contenu principal
            SliverPadding(
              padding: EdgeInsets.all(AppConstants.defaultPadding.w),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Salutation islamique
                  _buildIslamicGreeting(),
                  
                  SizedBox(height: 20.h),
                  
                  // Actions rapides
                  const QuickActionsWidget(),
                  
                  SizedBox(height: 20.h),
                  
                  // Statistiques utilisateur
                  StatsWidget(stats: userStats),
                  
                  SizedBox(height: 20.h),
                  
                  // Dernière lecture
                  if (currentSurah != null) _buildLastReading(currentSurah),
                  
                  SizedBox(height: 20.h),
                  
                  // Sourates populaires
                  _buildPopularSurahs(quranDataAsync),
                  
                  SizedBox(height: 20.h),
                  
                  // Verset du jour
                  _buildVerseOfTheDay(),
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
    String greeting;
    IconData icon;

    if (hour < 12) {
      greeting = 'السلام عليكم\nBonne matinée !';
      icon = Icons.wb_sunny;
    } else if (hour < 17) {
      greeting = 'السلام عليكم\nBon après-midi !';
      icon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'السلام عليكم\nBonne soirée !';
      icon = Icons.nights_stay;
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32.sp,
              color: AppConstants.primaryColor,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                greeting,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
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
    // Verset d'Al-Fatiha comme exemple
    const verseText = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
    const translation = 'Au nom d\'Allah, le Tout Miséricordieux, le Très Miséricordieux.';

    return Card(
      color: AppConstants.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppConstants.secondaryColor,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Verset du jour',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              verseText,
              style: AppTheme.arabicTextStyle(
                fontSize: 20.sp,
                color: AppConstants.primaryColor,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 8.h),
            Text(
              translation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Al-Fatiha : 1',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppConstants.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(ttsServiceProvider).speak(verseText);
                  },
                  icon: const Icon(Icons.volume_up),
                  color: AppConstants.primaryColor,
                ),
                IconButton(
                  onPressed: () {
                    // Ajouter aux favoris
                  },
                  icon: const Icon(Icons.favorite_border),
                  color: AppConstants.favoriteColor,
                ),
                IconButton(
                  onPressed: () {
                    // Partager
                  },
                  icon: const Icon(Icons.share),
                  color: AppConstants.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
