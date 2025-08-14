import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/mosque.dart';
import '../services/mosque_finder_service.dart';
import '../widgets/mosque_card.dart';
import '../utils/app_constants.dart';

class MosqueFinderScreen extends ConsumerStatefulWidget {
  const MosqueFinderScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MosqueFinderScreen> createState() => _MosqueFinderScreenState();
}

class _MosqueFinderScreenState extends ConsumerState<MosqueFinderScreen> 
    with SingleTickerProviderStateMixin {
  // Controllers
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  late TabController _tabController;
  
  // State
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Position? _currentPosition;
  Mosque? _selectedMosque;
  List<Mosque> _nearbyMosques = [];
  List<Mosque> _favoriteMosques = [];
  bool _isLoading = false;
  bool _showList = false;
  MapType _mapType = MapType.normal;
  
  // Filtres
  double _searchRadius = 5000; // 5km par défaut
  MosqueFilter? _currentFilter;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeLocation();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _sheetController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeLocation() async {
    setState(() => _isLoading = true);
    
    try {
      final position = await ref.read(mosqueFinderServiceProvider).getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
        
        // Centrer la carte sur la position actuelle
        final controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            14,
          ),
        );
        
        // Charger les mosquées à proximité
        await _loadNearbyMosques();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadNearbyMosques() async {
    if (_currentPosition == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final mosques = await ref.read(mosqueFinderServiceProvider).searchNearbyMosques(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        radius: _searchRadius,
        filter: _currentFilter,
      );
      
      setState(() {
        _nearbyMosques = mosques;
        _updateMarkers(mosques);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _updateMarkers(List<Mosque> mosques) {
    final markers = <Marker>{};
    
    // Marqueur pour la position actuelle
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_position'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Ma position'),
        ),
      );
    }
    
    // Marqueurs pour les mosquées
    for (final mosque in mosques) {
      markers.add(
        Marker(
          markerId: MarkerId(mosque.id),
          position: mosque.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerHue(mosque.type),
          ),
          infoWindow: InfoWindow(
            title: mosque.name,
            snippet: mosque.formattedDistance,
            onTap: () => _selectMosque(mosque),
          ),
          onTap: () => _selectMosque(mosque),
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
  }
  
  double _getMarkerHue(MosqueType type) {
    switch (type) {
      case MosqueType.grand:
        return BitmapDescriptor.hueMagenta;
      case MosqueType.historical:
        return BitmapDescriptor.hueOrange;
      case MosqueType.educational:
        return BitmapDescriptor.hueCyan;
      case MosqueType.community:
        return BitmapDescriptor.hueGreen;
      default:
        return BitmapDescriptor.hueRed;
    }
  }
  
  void _selectMosque(Mosque mosque) {
    setState(() {
      _selectedMosque = mosque;
    });
    
    // Afficher la bottom sheet avec les détails
    _showMosqueDetails(mosque);
  }
  
  void _showMosqueDetails(Mosque mosque) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // Handle
                Container(
                  margin: EdgeInsets.only(top: 12.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                
                // Contenu
                MosqueCard(
                  mosque: mosque,
                  isFavorite: ref.watch(favoriteMosquesProvider).contains(mosque.id),
                  onFavoriteToggle: () {
                    ref.read(favoriteMosquesProvider.notifier).toggleFavorite(mosque.id);
                  },
                  onNavigate: () => _navigateToMosque(mosque),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _navigateToMosque(Mosque mosque) async {
    if (_currentPosition == null) return;
    
    // Obtenir l'itinéraire
    final directions = await ref.read(mosqueFinderServiceProvider).getDirections(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      mosque.latitude,
      mosque.longitude,
    );
    
    if (directions.isNotEmpty) {
      // Afficher l'itinéraire sur la carte
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: directions,
            color: AppConstants.primaryColor,
            width: 5,
          ),
        };
      });
      
      // Ajuster la vue pour montrer tout l'itinéraire
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          _calculateBounds(directions),
          100.w,
        ),
      );
    }
    
    // Ouvrir dans l'application de navigation native
    final url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}'
        '&destination=${mosque.latitude},${mosque.longitude}'
        '&travelmode=walking';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
  
  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (final point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
  
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        currentFilter: _currentFilter,
        searchRadius: _searchRadius,
        onApply: (filter, radius) {
          setState(() {
            _currentFilter = filter;
            _searchRadius = radius;
          });
          Navigator.pop(context);
          _loadNearbyMosques();
        },
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Carte Google Maps
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null 
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(48.8566, 2.3522), // Paris par défaut
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            mapType: _mapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController.complete(controller);
            },
          ),
          
          // Barre de recherche et actions
          SafeArea(
            child: Column(
              children: [
                // Barre de recherche
                Container(
                  margin: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Bouton retour
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 24.sp,
                        ),
                      ),
                      
                      // Champ de recherche
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher une mosquée...',
                            hintStyle: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14.sp,
                              color: Colors.grey,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14.sp,
                          ),
                          onSubmitted: (query) async {
                            if (query.isNotEmpty) {
                              final mosques = await ref.read(mosqueFinderServiceProvider)
                                  .searchMosqueByName(query, userPosition: _currentPosition);
                              setState(() {
                                _nearbyMosques = mosques;
                                _updateMarkers(mosques);
                              });
                            }
                          },
                        ),
                      ),
                      
                      // Bouton filtre
                      IconButton(
                        onPressed: _showFilterSheet,
                        icon: Badge(
                          isLabelVisible: _currentFilter != null,
                          child: Icon(
                            Icons.filter_list,
                            color: AppConstants.primaryColor,
                            size: 24.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                
                // Actions rapides
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      _buildActionChip(
                        icon: Icons.map,
                        label: _mapType == MapType.normal ? 'Satellite' : 'Normal',
                        onTap: () {
                          setState(() {
                            _mapType = _mapType == MapType.normal 
                                ? MapType.satellite 
                                : MapType.normal;
                          });
                        },
                      ),
                      SizedBox(width: 8.w),
                      _buildActionChip(
                        icon: Icons.list,
                        label: 'Liste',
                        onTap: () {
                          setState(() => _showList = !_showList);
                        },
                        isSelected: _showList,
                      ),
                      SizedBox(width: 8.w),
                      _buildActionChip(
                        icon: Icons.favorite,
                        label: 'Favoris',
                        onTap: () {
                          _tabController.animateTo(1);
                          _showBottomSheet();
                        },
                      ),
                      SizedBox(width: 8.w),
                      _buildActionChip(
                        icon: Icons.refresh,
                        label: 'Actualiser',
                        onTap: _loadNearbyMosques,
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideX(begin: -0.1, end: 0, delay: 100.ms),
              ],
            ),
          ),
          
          // Boutons flottants
          Positioned(
            right: 16.w,
            bottom: 100.h,
            child: Column(
              children: [
                // Bouton ma position
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () async {
                    if (_currentPosition != null) {
                      final controller = await _mapController.future;
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          15,
                        ),
                      );
                    }
                  },
                  child: Icon(
                    Icons.my_location,
                    color: AppConstants.primaryColor,
                    size: 24.sp,
                  ),
                ),
                
                SizedBox(height: 12.h),
                
                // Bouton zoom in
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () async {
                    final controller = await _mapController.future;
                    controller.animateCamera(CameraUpdate.zoomIn());
                  },
                  child: Icon(
                    Icons.add,
                    color: Colors.black87,
                    size: 24.sp,
                  ),
                ),
                
                SizedBox(height: 8.h),
                
                // Bouton zoom out
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () async {
                    final controller = await _mapController.future;
                    controller.animateCamera(CameraUpdate.zoomOut());
                  },
                  child: Icon(
                    Icons.remove,
                    color: Colors.black87,
                    size: 24.sp,
                  ),
                ),
              ],
            ).animate().fadeIn().scale(delay: 200.ms),
          ),
          
          // Liste des mosquées (si activée)
          if (_showList)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      margin: EdgeInsets.only(top: 12.h),
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    
                    // Titre
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_nearbyMosques.length} mosquées trouvées',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _showList = false),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    
                    // Liste
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: 20.h),
                        itemCount: _nearbyMosques.length,
                        itemBuilder: (context, index) {
                          final mosque = _nearbyMosques[index];
                          final isFavorite = ref.watch(favoriteMosquesProvider).contains(mosque.id);
                          
                          return MosqueListTile(
                            mosque: mosque,
                            isFavorite: isFavorite,
                            onTap: () => _selectMosque(mosque),
                            onFavoriteToggle: () {
                              ref.read(favoriteMosquesProvider.notifier).toggleFavorite(mosque.id);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
            ),
          
          // Indicateur de chargement
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: AppConstants.primaryColor,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Recherche des mosquées...',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: isSelected ? Colors.white : AppConstants.primaryColor,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppConstants.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppConstants.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppConstants.primaryColor,
              tabs: const [
                Tab(text: 'À proximité'),
                Tab(text: 'Favoris'),
                Tab(text: 'Récents'),
              ],
            ),
            
            // Contenu des tabs
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab: À proximité
                  ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _nearbyMosques.length,
                    itemBuilder: (context, index) {
                      final mosque = _nearbyMosques[index];
                      return MosqueCard(
                        mosque: mosque,
                        isFavorite: ref.watch(favoriteMosquesProvider).contains(mosque.id),
                        onTap: () {
                          Navigator.pop(context);
                          _selectMosque(mosque);
                        },
                        onNavigate: () {
                          Navigator.pop(context);
                          _navigateToMosque(mosque);
                        },
                        onFavoriteToggle: () {
                          ref.read(favoriteMosquesProvider.notifier).toggleFavorite(mosque.id);
                        },
                      );
                    },
                  ),
                  
                  // Tab: Favoris
                  Consumer(
                    builder: (context, ref, child) {
                      final favoriteIds = ref.watch(favoriteMosquesProvider);
                      final favorites = _nearbyMosques.where((m) => favoriteIds.contains(m.id)).toList();
                      
                      if (favorites.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_border,
                                size: 80.sp,
                                color: Colors.grey[300],
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Aucune mosquée favorite',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 16.sp,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final mosque = favorites[index];
                          return MosqueCard(
                            mosque: mosque,
                            isFavorite: true,
                            onTap: () {
                              Navigator.pop(context);
                              _selectMosque(mosque);
                            },
                            onNavigate: () {
                              Navigator.pop(context);
                              _navigateToMosque(mosque);
                            },
                            onFavoriteToggle: () {
                              ref.read(favoriteMosquesProvider.notifier).toggleFavorite(mosque.id);
                            },
                          );
                        },
                      );
                    },
                  ),
                  
                  // Tab: Récents
                  Center(
                    child: Text(
                      'Mosquées visitées récemment',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour les filtres
class _FilterSheet extends StatefulWidget {
  final MosqueFilter? currentFilter;
  final double searchRadius;
  final Function(MosqueFilter?, double) onApply;
  
  const _FilterSheet({
    Key? key,
    this.currentFilter,
    required this.searchRadius,
    required this.onApply,
  }) : super(key: key);
  
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late double _radius;
  MosqueType? _selectedType;
  double? _minRating;
  List<String> _requiredServices = [];
  bool? _isOpenNow;
  bool? _wheelchairAccessible;
  
  @override
  void initState() {
    super.initState();
    _radius = widget.searchRadius;
    if (widget.currentFilter != null) {
      _selectedType = widget.currentFilter!.type;
      _minRating = widget.currentFilter!.minRating;
      _requiredServices = widget.currentFilter!.requiredServices ?? [];
      _isOpenNow = widget.currentFilter!.isOpenNow;
      _wheelchairAccessible = widget.currentFilter!.wheelchairAccessible;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          
          // Titre
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtres de recherche',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _radius = 5000;
                      _selectedType = null;
                      _minRating = null;
                      _requiredServices = [];
                      _isOpenNow = null;
                      _wheelchairAccessible = null;
                    });
                  },
                  child: Text(
                    'Réinitialiser',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rayon de recherche
                  Text(
                    'Distance maximale: ${(_radius / 1000).toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Slider(
                    value: _radius,
                    min: 500,
                    max: 20000,
                    divisions: 39,
                    activeColor: AppConstants.primaryColor,
                    onChanged: (value) {
                      setState(() => _radius = value);
                    },
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // Type de mosquée
                  Text(
                    'Type de mosquée',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    children: MosqueType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return FilterChip(
                        label: Text(_getTypeLabel(type)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = selected ? type : null;
                          });
                        },
                        selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                        checkmarkColor: AppConstants.primaryColor,
                      );
                    }).toList(),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // Note minimale
                  Text(
                    'Note minimale',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [3.0, 3.5, 4.0, 4.5].map((rating) {
                      final isSelected = _minRating == rating;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 16.sp,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 4.w),
                              Text(rating.toString()),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _minRating = selected ? rating : null;
                            });
                          },
                          selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                          checkmarkColor: AppConstants.primaryColor,
                        ),
                      );
                    }).toList(),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // Services requis
                  Text(
                    'Services disponibles',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      _buildServiceFilter('Parking', 'parking', Icons.local_parking),
                      _buildServiceFilter('Ablutions', 'wudu', Icons.water_drop),
                      _buildServiceFilter('Section Femmes', 'women_section', Icons.woman),
                      _buildServiceFilter('École', 'school', Icons.school),
                      _buildServiceFilter('Bibliothèque', 'library', Icons.menu_book),
                      _buildServiceFilter('Climatisation', 'air_conditioning', Icons.ac_unit),
                    ],
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // Options supplémentaires
                  CheckboxListTile(
                    title: Text(
                      'Ouvert maintenant',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14.sp,
                      ),
                    ),
                    value: _isOpenNow ?? false,
                    onChanged: (value) {
                      setState(() => _isOpenNow = value);
                    },
                    activeColor: AppConstants.primaryColor,
                  ),
                  
                  CheckboxListTile(
                    title: Text(
                      'Accès PMR',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14.sp,
                      ),
                    ),
                    value: _wheelchairAccessible ?? false,
                    onChanged: (value) {
                      setState(() => _wheelchairAccessible = value);
                    },
                    activeColor: AppConstants.primaryColor,
                  ),
                  
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
          
          // Bouton appliquer
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final filter = MosqueFilter(
                    maxDistance: _radius,
                    type: _selectedType,
                    minRating: _minRating,
                    requiredServices: _requiredServices.isNotEmpty ? _requiredServices : null,
                    isOpenNow: _isOpenNow,
                    wheelchairAccessible: _wheelchairAccessible,
                  );
                  widget.onApply(filter, _radius);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Appliquer les filtres',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildServiceFilter(String label, String service, IconData icon) {
    final isSelected = _requiredServices.contains(service);
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: isSelected ? AppConstants.primaryColor : Colors.grey,
          ),
          SizedBox(width: 4.w),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _requiredServices.add(service);
          } else {
            _requiredServices.remove(service);
          }
        });
      },
      selectedColor: AppConstants.primaryColor.withOpacity(0.2),
      checkmarkColor: AppConstants.primaryColor,
    );
  }
  
  String _getTypeLabel(MosqueType type) {
    switch (type) {
      case MosqueType.grand:
        return 'Grande Mosquée';
      case MosqueType.historical:
        return 'Historique';
      case MosqueType.educational:
        return 'École Coranique';
      case MosqueType.community:
        return 'Communautaire';
      default:
        return 'Standard';
    }
  }
}