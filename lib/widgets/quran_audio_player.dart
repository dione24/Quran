import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/app_constants.dart';
import '../services/quran_audio_service.dart';
import '../providers/app_providers.dart';

class QuranAudioPlayer extends ConsumerStatefulWidget {
  final int surahNumber;
  final int? ayahNumber;
  final String surahName;
  final VoidCallback? onClose;

  const QuranAudioPlayer({
    Key? key,
    required this.surahNumber,
    this.ayahNumber,
    required this.surahName,
    this.onClose,
  }) : super(key: key);

  @override
  ConsumerState<QuranAudioPlayer> createState() => _QuranAudioPlayerState();
}

class _QuranAudioPlayerState extends ConsumerState<QuranAudioPlayer>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = false;
  double _volume = 1.0;
  String _currentRecitator = 'ar.alafasy';

  @override
  void initState() {
    super.initState();

    // Animation pour l'apparition
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _initializeAudio();
  }

  void _initializeAudio() {
    final audioService = ref.read(quranAudioServiceProvider);

    // Écouter les changements d'état
    audioService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading =
              state == PlayerState.playing && _totalDuration == Duration.zero;
        });
      }
    });

    // Écouter la position
    audioService.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    // Écouter la durée
    audioService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withOpacity(0.2),
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
                top: BorderSide(color: AppConstants.accentColor, width: 4),
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
                    AppConstants.accentColor.withOpacity(0.1),
                    AppConstants.accentColor.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // En-tête avec titre et bouton fermer
                  _buildHeader(),

                  SizedBox(height: 20.h),

                  // Informations sur la récitation
                  _buildRecitationInfo(),

                  SizedBox(height: 20.h),

                  // Barre de progression
                  _buildProgressBar(),

                  SizedBox(height: 16.h),

                  // Contrôles de lecture
                  _buildPlaybackControls(),

                  SizedBox(height: 16.h),

                  // Contrôles additionnels
                  _buildAdditionalControls(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppConstants.accentColor,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: AppConstants.accentColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.headphones,
            color: Colors.white,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Récitation Audio',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppConstants.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                widget.surahName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        if (widget.onClose != null)
          IconButton(
            onPressed: () {
              _fadeController.reverse().then((_) {
                widget.onClose?.call();
              });
            },
            icon: Icon(
              Icons.close,
              color: Colors.grey[600],
              size: 20.sp,
            ),
          ),
      ],
    );
  }

  Widget _buildRecitationInfo() {
    final recitatorInfo = QuranAudioService.getRecitatorInfo(_currentRecitator);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppConstants.accentColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person,
            color: AppConstants.accentColor,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Récitateur',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Text(
                  recitatorInfo?.name ?? 'Mishary Rashid Alafasy',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.accentColor,
                      ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (recitatorId) {
              setState(() {
                _currentRecitator = recitatorId;
              });
              final audioService = ref.read(quranAudioServiceProvider);
              audioService.setRecitator(recitatorId);
            },
            itemBuilder: (context) {
              return QuranAudioService.getAvailableRecitators()
                  .map((recitator) => PopupMenuItem(
                        value: recitator.id,
                        child: Text(recitator.name),
                      ))
                  .toList();
            },
            child: Icon(
              Icons.keyboard_arrow_down,
              color: AppConstants.accentColor,
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppConstants.accentColor,
            inactiveTrackColor: AppConstants.accentColor.withOpacity(0.3),
            thumbColor: AppConstants.accentColor,
            overlayColor: AppConstants.accentColor.withOpacity(0.2),
            trackHeight: 4.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
          ),
          child: Slider(
            value: _totalDuration.inMilliseconds > 0
                ? _currentPosition.inMilliseconds.toDouble()
                : 0.0,
            max: _totalDuration.inMilliseconds.toDouble(),
            onChanged: (value) {
              final position = Duration(milliseconds: value.toInt());
              final audioService = ref.read(quranAudioServiceProvider);
              audioService.seek(position);
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bouton reculer
        IconButton(
          onPressed: () {
            final newPosition = _currentPosition - const Duration(seconds: 10);
            final audioService = ref.read(quranAudioServiceProvider);
            audioService.seek(
                newPosition > Duration.zero ? newPosition : Duration.zero);
          },
          icon: Icon(
            Icons.replay_10,
            color: AppConstants.accentColor,
            size: 32.sp,
          ),
        ),

        SizedBox(width: 20.w),

        // Bouton play/pause principal
        Container(
          decoration: BoxDecoration(
            color: AppConstants.accentColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppConstants.accentColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: IconButton(
            onPressed: _togglePlayback,
            icon: _isLoading
                ? SizedBox(
                    width: 24.sp,
                    height: 24.sp,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32.sp,
                  ),
            iconSize: 56.sp,
          ),
        ),

        SizedBox(width: 20.w),

        // Bouton avancer
        IconButton(
          onPressed: () {
            final newPosition = _currentPosition + const Duration(seconds: 10);
            final audioService = ref.read(quranAudioServiceProvider);
            audioService.seek(
                newPosition < _totalDuration ? newPosition : _totalDuration);
          },
          icon: Icon(
            Icons.forward_10,
            color: AppConstants.accentColor,
            size: 32.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalControls() {
    return Row(
      children: [
        // Contrôle du volume
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.volume_down,
                color: AppConstants.accentColor.withOpacity(0.7),
                size: 20.sp,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppConstants.accentColor,
                    inactiveTrackColor:
                        AppConstants.accentColor.withOpacity(0.3),
                    thumbColor: AppConstants.accentColor,
                    trackHeight: 2.h,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                  ),
                  child: Slider(
                    value: _volume,
                    onChanged: (value) {
                      setState(() {
                        _volume = value;
                      });
                      final audioService = ref.read(quranAudioServiceProvider);
                      audioService.setVolume(value);
                    },
                  ),
                ),
              ),
              Icon(
                Icons.volume_up,
                color: AppConstants.accentColor.withOpacity(0.7),
                size: 20.sp,
              ),
            ],
          ),
        ),

        SizedBox(width: 16.w),

        // Bouton télécharger
        IconButton(
          onPressed: _downloadAudio,
          icon: Icon(
            Icons.download,
            color: AppConstants.accentColor.withOpacity(0.7),
            size: 24.sp,
          ),
          tooltip: 'Télécharger pour écoute hors-ligne',
        ),
      ],
    );
  }

  void _togglePlayback() async {
    final audioService = ref.read(quranAudioServiceProvider);

    if (_isPlaying) {
      await audioService.pause();
    } else {
      if (_currentPosition == Duration.zero) {
        // Commencer la lecture
        if (widget.ayahNumber != null) {
          await audioService.playAyah(widget.surahNumber, widget.ayahNumber!);
        } else {
          await audioService.playSurah(widget.surahNumber);
        }
      } else {
        // Reprendre la lecture
        await audioService.resume();
      }
    }
  }

  void _downloadAudio() async {
    final audioService = ref.read(quranAudioServiceProvider);

    try {
      final filePath = await audioService.downloadAudio(
        widget.surahNumber,
        ayahNumber: widget.ayahNumber,
      );

      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Audio téléchargé avec succès'),
            backgroundColor: AppConstants.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors du téléchargement'),
            backgroundColor: AppConstants.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r)),
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
