import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../providers/app_providers.dart';
import '../services/audio_matcher.dart';
import '../widgets/listening_animation.dart';

class ListenScreen extends ConsumerStatefulWidget {
  const ListenScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends ConsumerState<ListenScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  String transcribedText = '';
  List<AudioMatchResult> matchResults = [];
  double confidence = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isListening = ref.watch(isListeningProvider);
    final quranDataAsync = ref.watch(quranDataProvider);

    // Écouter les changements d'état d'écoute
    ref.listen<bool>(isListeningProvider, (previous, next) {
      if (next) {
        _startListeningAnimation();
      } else {
        _stopListeningAnimation();
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.primaryColor.withOpacity(0.05),
              AppConstants.secondaryColor.withOpacity(0.03),
              Colors.white,
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // AppBar moderne avec gradient
            SliverAppBar(
              expandedHeight: 120.h,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppConstants.primaryColor,
                        AppConstants.secondaryColor,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 20.h),
                        Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 32.sp,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Écouter & Reconnaître',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.white),
                  onPressed: () => _showHelpDialog(),
                  tooltip: 'Aide',
                ),
              ],
            ),

            // Contenu principal
            SliverToBoxAdapter(
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.defaultPadding.w),
                  child: Column(
                    children: [
                      // Instructions
                      _buildInstructions(),

                      SizedBox(height: 32.h),

                      // Animation d'écoute
                      Container(
                        height: 200.h,
                        child: Center(
                          child: ListeningAnimation(
                            isListening: isListening,
                            confidence: confidence,
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Texte transcrit
                      _buildTranscribedText(),

                      SizedBox(height: 24.h),

                      // Résultats de correspondance
                      if (matchResults.isNotEmpty) _buildMatchResults(),

                      SizedBox(height: 32.h),

                      // Boutons d'action
                      _buildActionButtons(quranDataAsync),

                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppConstants.primaryColor, width: 4),
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppConstants.primaryColor.withOpacity(0.1),
                  AppConstants.primaryColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(height: 16.w),
                Text(
                  'Reconnaissance Vocale Intelligente',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Récitez ou jouez une sourate à voix haute.\nL\'application reconnaîtra automatiquement les versets.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTranscribedText() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 60.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: transcribedText.isNotEmpty
              ? AppConstants.primaryColor
              : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.hearing,
                size: 16.sp,
                color: AppConstants.primaryColor,
              ),
              SizedBox(width: 8.w),
              Text(
                'Texte reconnu :',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            transcribedText.isNotEmpty
                ? transcribedText
                : 'Aucun texte reconnu pour le moment...',
            style: transcribedText.isNotEmpty
                ? AppTheme.arabicTextStyle(
                    fontSize: 16.sp,
                    color: AppConstants.textColor,
                  )
                : Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
            textDirection: transcribedText.isNotEmpty
                ? TextDirection.rtl
                : TextDirection.ltr,
          ),
          if (confidence > 0) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Text(
                  'Confiance: ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${(confidence * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: confidence > 0.7
                            ? AppConstants.successColor
                            : confidence > 0.4
                                ? AppConstants.warningColor
                                : AppConstants.errorColor,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchResults() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppConstants.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppConstants.successColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 16.sp,
                color: AppConstants.successColor,
              ),
              SizedBox(width: 8.w),
              Text(
                'Correspondances trouvées :',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.successColor,
                    ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...matchResults.take(3).map((result) => _buildMatchItem(result)),
        ],
      ),
    );
  }

  Widget _buildMatchItem(AudioMatchResult result) {
    if (!result.hasMatch) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${result.matchedSurah!.name} - Verset ${result.matchedAyah!.numberInSurah}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${(result.confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            result.matchedText,
            style: AppTheme.arabicTextStyle(
              fontSize: 14.sp,
              color: AppConstants.primaryColor,
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              IconButton(
                onPressed: () => _playMatchedAyah(result),
                icon: const Icon(Icons.play_arrow, size: 16),
                color: AppConstants.primaryColor,
                constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                onPressed: () => _goToMatchedAyah(result),
                icon: const Icon(Icons.open_in_new, size: 16),
                color: AppConstants.primaryColor,
                constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AsyncValue<dynamic> quranDataAsync) {
    final isListening = ref.watch(isListeningProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Bouton d'écoute principal
        GestureDetector(
          onTap: () => _toggleListening(quranDataAsync),
          child: Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: isListening
                  ? AppConstants.errorColor
                  : AppConstants.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isListening
                          ? AppConstants.errorColor
                          : AppConstants.primaryColor)
                      .withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isListening ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: 32.sp,
            ),
          ),
        ),

        // Bouton pour effacer
        ElevatedButton.icon(
          onPressed: transcribedText.isNotEmpty ? _clearResults : null,
          icon: const Icon(Icons.clear),
          label: const Text('Effacer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[600],
          ),
        ),

        // Bouton d'aide
        ElevatedButton.icon(
          onPressed: () => _showHelpDialog(),
          icon: const Icon(Icons.help_outline),
          label: const Text('Aide'),
        ),
      ],
    );
  }

  void _startListeningAnimation() {
    _pulseController.repeat();
    _waveController.repeat();
  }

  void _stopListeningAnimation() {
    _pulseController.stop();
    _waveController.stop();
  }

  void _toggleListening(AsyncValue<dynamic> quranDataAsync) async {
    final isListening = ref.read(isListeningProvider);
    final sttService = ref.read(sttServiceProvider);

    if (isListening) {
      // Arrêter l'écoute
      await sttService.stopListening();
      ref.read(isListeningProvider.notifier).state = false;
    } else {
      // Commencer l'écoute
      await sttService.startListening();
      if (sttService.isAvailable) {
        ref.read(isListeningProvider.notifier).state = true;

        // Écouter les transcriptions
        sttService.transcriptionStream.listen((text) {
          setState(() {
            transcribedText = text;
          });
          _processTranscription(text, quranDataAsync);
        });

        // Écouter les niveaux de confiance
        sttService.confidenceStream.listen((conf) {
          setState(() {
            confidence = conf;
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'accéder au microphone'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _processTranscription(
      String text, AsyncValue<dynamic> quranDataAsync) async {
    if (text.isEmpty) return;

    quranDataAsync.whenData((quranData) async {
      final audioMatcher = ref.read(audioMatcherProvider);
      final results = await audioMatcher.findMatches(text, quranData);

      setState(() {
        matchResults = results;
      });

      // Mettre à jour l'historique si une correspondance est trouvée
      if (results.isNotEmpty && results.first.hasMatch) {
        final match = results.first;
        ref.read(readingHistoryProvider.notifier).addToHistory(
            '${match.matchedSurah!.number}_${match.matchedAyah!.number}');
      }
    });
  }

  void _playMatchedAyah(AudioMatchResult result) {
    if (result.hasMatch) {
      ref.read(ttsServiceProvider).speak(result.matchedText);
    }
  }

  void _goToMatchedAyah(AudioMatchResult result) {
    if (result.hasMatch) {
      // Naviguer vers la sourate correspondante
      ref.read(currentSurahProvider.notifier).state =
          result.matchedSurah!.number;
      ref.read(currentAyahProvider.notifier).state = result.matchedAyah!.number;

      // Changer d'onglet vers la lecture
      // (Ceci nécessiterait une communication avec le widget parent)
    }
  }

  void _clearResults() {
    setState(() {
      transcribedText = '';
      matchResults = [];
      confidence = 0.0;
    });
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comment utiliser la reconnaissance vocale'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                Icons.mic,
                'Appuyez sur le bouton microphone pour commencer l\'écoute',
              ),
              _buildHelpItem(
                Icons.record_voice_over,
                'Récitez ou jouez une sourate à voix haute et claire',
              ),
              _buildHelpItem(
                Icons.hearing,
                'L\'application reconnaît automatiquement les versets',
              ),
              _buildHelpItem(
                Icons.search,
                'Les correspondances s\'affichent avec un score de confiance',
              ),
              _buildHelpItem(
                Icons.volume_up,
                'Vous pouvez écouter les versets trouvés',
              ),
              _buildHelpItem(
                Icons.tips_and_updates,
                'Conseil: Récitez lentement et distinctement pour de meilleurs résultats',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: AppConstants.primaryColor,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
