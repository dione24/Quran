import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';

class SurahSelector extends StatefulWidget {
  final int? selectedSurahNumber;
  final Function(int) onSurahSelected;
  final bool showSearch;

  const SurahSelector({
    Key? key,
    this.selectedSurahNumber,
    required this.onSurahSelected,
    this.showSearch = true,
  }) : super(key: key);

  @override
  State<SurahSelector> createState() => _SurahSelectorState();
}

class _SurahSelectorState extends State<SurahSelector> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête avec recherche
          if (widget.showSearch) _buildSearchHeader(),
          
          // Sélecteur de sourate
          _buildSurahSelector(),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.r),
          topRight: Radius.circular(12.r),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: AppConstants.primaryColor,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une sourate...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[500],
                ),
              ),
              style: TextStyle(fontSize: 14.sp),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.clear),
              color: Colors.grey[500],
              iconSize: 18.sp,
            ),
        ],
      ),
    );
  }

  Widget _buildSurahSelector() {
    return SizedBox(
      height: widget.showSearch ? 60.h : 40.h, // Hauteur adaptative
      child: widget.selectedSurahNumber == null
          ? _buildSurahList()
          : _buildSelectedSurah(),
    );
  }

  Widget _buildSurahList() {
    final filteredSurahs = _getFilteredSurahs();
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      itemCount: filteredSurahs.length,
      itemBuilder: (context, index) {
        final surahNumber = filteredSurahs[index];
        return _buildSurahChip(surahNumber);
      },
    );
  }

  Widget _buildSelectedSurah() {
    final surahNumber = widget.selectedSurahNumber!;
    final surahName = _getSurahName(surahNumber);
    final surahNameFrench = _getSurahNameFrench(surahNumber);
    
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          // Numéro de sourate
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor,
                  AppConstants.accentColor,
                ],
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Center(
              child: Text(
                '$surahNumber',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 16.w),
          
          // Informations de la sourate
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  surahName,
                  style: AppTheme.arabicTextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                Text(
                  surahNameFrench,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Bouton pour changer de sourate
          IconButton(
            onPressed: () {
              widget.onSurahSelected(0); // Retourner à la liste
            },
            icon: const Icon(Icons.change_circle),
            color: AppConstants.primaryColor,
            tooltip: 'Changer de sourate',
          ),
        ],
      ),
    );
  }

  Widget _buildSurahChip(int surahNumber) {
    final surahName = _getSurahName(surahNumber);
    final surahNameFrench = _getSurahNameFrench(surahNumber);
    final isSelected = widget.selectedSurahNumber == surahNumber;
    
    return GestureDetector(
      onTap: () => widget.onSurahSelected(surahNumber),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 3.w),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        constraints: BoxConstraints(
          maxWidth: 100.w, // Limiter la largeur pour éviter les débordements
          minHeight: widget.showSearch ? 40.h : 30.h,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppConstants.primaryColor 
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected 
                ? AppConstants.primaryColor 
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14.w,
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white 
                        : AppConstants.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$surahNumber',
                      style: TextStyle(
                        color: isSelected 
                            ? AppConstants.primaryColor 
                            : Colors.white,
                        fontSize: 7.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    surahName,
                    style: AppTheme.arabicTextStyle(
                      fontSize: 9.sp,
                      color: isSelected 
                          ? Colors.white 
                          : AppConstants.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (widget.showSearch) ...[
              SizedBox(height: 1.h),
              Text(
                surahNameFrench,
                style: TextStyle(
                  fontSize: 6.sp,
                  color: isSelected 
                      ? Colors.white.withOpacity(0.9) 
                      : AppConstants.secondaryTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<int> _getFilteredSurahs() {
    if (_searchQuery.isEmpty) {
      return List.generate(114, (index) => index + 1);
    }

    final filtered = <int>[];
    for (int i = 1; i <= 114; i++) {
      final surahName = _getSurahName(i).toLowerCase();
      final surahNameFrench = _getSurahNameFrench(i).toLowerCase();
      final surahNumber = i.toString();

      if (surahName.contains(_searchQuery) ||
          surahNameFrench.contains(_searchQuery) ||
          surahNumber.contains(_searchQuery)) {
        filtered.add(i);
      }
    }

    return filtered;
  }

  String _getSurahName(int number) {
    // Noms des sourates en arabe (échantillon étendu)
    const surahNames = [
      'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة',
      'الأنعام', 'الأعراف', 'الأنفال', 'التوبة', 'يونس',
      'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر',
      'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه',
      'الأنبياء', 'الحج', 'المؤمنون', 'النور', 'الفرقان',
      'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم',
      'لقمان', 'السجدة', 'الأحزاب', 'سبأ', 'فاطر',
      'يس', 'الصافات', 'ص', 'الزمر', 'غافر',
      'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية',
      'الأحقاف', 'محمد', 'الفتح', 'الحجرات', 'ق',
      'الذاريات', 'الطور', 'النجم', 'القمر', 'الرحمن',
      'الواقعة', 'الحديد', 'المجادلة', 'الحشر', 'الممتحنة',
      'الصف', 'الجمعة', 'المنافقون', 'التغابن', 'الطلاق',
      'التحريم', 'الملك', 'القلم', 'الحاقة', 'المعارج',
      'نوح', 'الجن', 'المزمل', 'المدثر', 'القيامة',
      'الإنسان', 'المرسلات', 'النبأ', 'النازعات', 'عبس',
      'التكوير', 'الانفطار', 'المطففين', 'الانشقاق', 'البروج',
      'الطارق', 'الأعلى', 'الغاشية', 'الفجر', 'البلد',
      'الشمس', 'الليل', 'الضحى', 'الشرح', 'التين',
      'العلق', 'القدر', 'البينة', 'الزلزلة', 'العاديات',
      'القارعة', 'التكاثر', 'العصر', 'الهمزة', 'الفيل',
      'قريش', 'الماعون', 'الكوثر', 'الكافرون', 'النصر',
      'المسد', 'الإخلاص', 'الفلق', 'الناس'
    ];
    
    if (number <= surahNames.length) {
      return surahNames[number - 1];
    }
    return 'السورة $number';
  }

  String _getSurahNameFrench(int number) {
    if (number <= AppConstants.surahNamesFrench.length) {
      return AppConstants.surahNamesFrench[number - 1];
    }
    return 'Sourate $number';
  }
}
