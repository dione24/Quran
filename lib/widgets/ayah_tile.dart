import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ayah.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';

class AyahTile extends StatefulWidget {
  final Ayah ayah;
  final int surahNumber;
  final bool showTranslation;
  final bool isHighlighted;
  final bool isPlaying;
  final bool showFavoriteButton;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onFavorite;

  const AyahTile({
    Key? key,
    required this.ayah,
    required this.surahNumber,
    this.showTranslation = true,
    this.isHighlighted = false,
    this.isPlaying = false,
    this.showFavoriteButton = true,
    this.onTap,
    this.onPlay,
    this.onFavorite,
  }) : super(key: key);

  @override
  State<AyahTile> createState() => _AyahTileState();
}

class _AyahTileState extends State<AyahTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isPlaying) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AyahTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _animationController.repeat(reverse: true);
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isPlaying ? _pulseAnimation.value : 1.0,
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(12.r),
              border: widget.isHighlighted
                  ? Border.all(
                      color: AppConstants.primaryColor,
                      width: 2,
                    )
                  : null,
              boxShadow: widget.isHighlighted || widget.isPlaying
                  ? [
                      BoxShadow(
                        color: AppConstants.primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12.r),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec numéro d'ayah et actions
                    _buildHeader(),
                    
                    SizedBox(height: 12.h),
                    
                    // Texte arabe de l'ayah
                    _buildArabicText(),
                    
                    // Traduction (si activée)
                    if (widget.showTranslation && widget.ayah.translation != null)
                      _buildTranslation(),
                    
                    // Informations supplémentaires (si étendues)
                    if (_isExpanded) _buildAdditionalInfo(),
                    
                    SizedBox(height: 8.h),
                    
                    // Boutons d'action
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Numéro d'ayah
        Container(
          width: 32.w,
          height: 32.h,
          decoration: BoxDecoration(
            color: widget.isHighlighted
                ? AppConstants.primaryColor
                : AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppConstants.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: Text(
              '${widget.ayah.numberInSurah}',
              style: TextStyle(
                color: widget.isHighlighted
                    ? Colors.white
                    : AppConstants.primaryColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        SizedBox(width: 12.w),
        
        // Informations de l'ayah
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verset ${widget.ayah.numberInSurah}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.isHighlighted
                      ? AppConstants.primaryColor
                      : AppConstants.textColor,
                ),
              ),
              Text(
                'Juz ${widget.ayah.juz} • Page ${widget.ayah.page}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        
        // Indicateur de lecture
        if (widget.isPlaying)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.volume_up,
                  size: 12.sp,
                  color: Colors.white,
                ),
                SizedBox(width: 4.w),
                Text(
                  'En cours',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildArabicText() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(
        widget.ayah.text,
        style: AppTheme.arabicTextStyle(
          fontSize: 20.sp,
          color: widget.isHighlighted
              ? AppConstants.primaryColor
              : AppConstants.textColor,
          height: 2.0,
        ),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildTranslation() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Text(
        widget.ayah.translation ?? _getDefaultTranslation(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          height: 1.4,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations détaillées',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          SizedBox(height: 8.h),
          _buildInfoRow('Numéro global', '${widget.ayah.number}'),
          _buildInfoRow('Juz (Para)', '${widget.ayah.juz}'),
          _buildInfoRow('Manzil', '${widget.ayah.manzil}'),
          _buildInfoRow('Page', '${widget.ayah.page}'),
          _buildInfoRow('Ruku', '${widget.ayah.ruku}'),
          _buildInfoRow('Hizb Quarter', '${widget.ayah.hizbQuarter}'),
          if (widget.ayah.sajda)
            _buildInfoRow('Sajda', 'Oui', isSpecial: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isSpecial = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSpecial ? AppConstants.secondaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Bouton lecture
        _buildActionButton(
          icon: widget.isPlaying ? Icons.pause : Icons.play_arrow,
          label: widget.isPlaying ? 'Pause' : 'Lire',
          onPressed: widget.onPlay,
          color: AppConstants.primaryColor,
        ),
        
        // Bouton favori
        if (widget.showFavoriteButton)
          _buildActionButton(
            icon: Icons.favorite_border,
            label: 'Favori',
            onPressed: widget.onFavorite,
            color: AppConstants.favoriteColor,
          ),
        
        // Bouton copier
        _buildActionButton(
          icon: Icons.copy,
          label: 'Copier',
          onPressed: () => _copyToClipboard(),
          color: AppConstants.infoColor,
        ),
        
        // Bouton partager
        _buildActionButton(
          icon: Icons.share,
          label: 'Partager',
          onPressed: () => _shareAyah(),
          color: AppConstants.successColor,
        ),
        
        // Bouton plus d'infos
        _buildActionButton(
          icon: _isExpanded ? Icons.expand_less : Icons.expand_more,
          label: 'Info',
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          color: AppConstants.secondaryTextColor,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: color,
          iconSize: 20.sp,
          constraints: BoxConstraints(
            minWidth: 32.w,
            minHeight: 32.h,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getBackgroundColor() {
    if (widget.isPlaying) {
      return AppConstants.currentAyahColor.withOpacity(0.3);
    } else if (widget.isHighlighted) {
      return AppConstants.ayahHighlightColor;
    }
    return Colors.white;
  }

  String _getDefaultTranslation() {
    // Traduction par défaut basique (à remplacer par une vraie traduction)
    if (widget.surahNumber == 1) {
      const translations = [
        'Au nom d\'Allah, le Tout Miséricordieux, le Très Miséricordieux.',
        'Louange à Allah, Seigneur de l\'univers.',
        'Le Tout Miséricordieux, le Très Miséricordieux,',
        'Maître du Jour de la rétribution.',
        'C\'est Toi [Seul] que nous adorons, et c\'est Toi [Seul] dont nous implorons secours.',
        'Guide-nous dans le droit chemin,',
        'le chemin de ceux que Tu as comblés de faveurs, non pas de ceux qui ont encouru Ta colère, ni des égarés.',
      ];
      
      if (widget.ayah.numberInSurah <= translations.length) {
        return translations[widget.ayah.numberInSurah - 1];
      }
    }
    return 'Traduction non disponible';
  }

  void _copyToClipboard() {
    final text = '${widget.ayah.text}\n\n${widget.ayah.translation ?? _getDefaultTranslation()}\n\nSourate ${widget.surahNumber} - Verset ${widget.ayah.numberInSurah}';
    
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verset copié dans le presse-papiers'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareAyah() {
    final text = '${widget.ayah.text}\n\n${widget.ayah.translation ?? _getDefaultTranslation()}\n\nSourate ${widget.surahNumber} - Verset ${widget.ayah.numberInSurah}';
    Share.share(text, subject: 'Verset du Coran');
  }
}
