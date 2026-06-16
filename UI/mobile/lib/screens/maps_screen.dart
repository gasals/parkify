import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile/providers/city_provider.dart';
import 'package:mobile/providers/preference_provider.dart';
import 'package:mobile/providers/review_provider.dart';
import 'package:mobile/screens/reviews_screen.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/parking_zone_model.dart';
import '../models/parking_zone_recommendation_model.dart';
import '../models/preference_model.dart';
import '../providers/parking_zone_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/parking_details_screen.dart';
import '../screens/reservation_screen.dart';
import '../services/api_service.dart';

class MapsScreen extends StatefulWidget {
  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

enum BottomSheetState { closed, info }

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  List<ParkingZone> _filteredZones = [];
  ParkingZone? _selectedZone;
  BottomSheetState _sheetState = BottomSheetState.closed;
  Preference? _userPreference;
  ParkingZone? _recommendedZone;
  ParkingZoneRecommendation? _recommendedExplanation;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const LatLng _initialCenter = LatLng(43.8578333, 18.4230758);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreferencesAndZones();
    });
  }

  Future<void> _loadPreferencesAndZones() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final zoneProvider = Provider.of<ParkingZoneProvider>(
      context,
      listen: false,
    );
    final preferenceProvider = Provider.of<PreferenceProvider>(
      context,
      listen: false,
    );
    final cityProvider = Provider.of<CityProvider>(context, listen: false);

    final userId = authProvider.user?.id;

    if (userId != null) {
      await preferenceProvider.loadUserPreference(userId: userId);
      setState(() {
        _userPreference = preferenceProvider.userPreference;
      });
    }

    await zoneProvider.getParkingZones();
    await zoneProvider.getRecommendedZones(userId: userId ?? 0);
    await cityProvider.getAllCities();

    setState(() {
      _filteredZones = zoneProvider.parkingZones;
      _recommendedExplanation = zoneProvider.topRecommendation;
      _recommendedZone = zoneProvider.recommendedZones.isNotEmpty
          ? zoneProvider.recommendedZones.first
          : null;
    });

    _animateToPreferredCity(cityProvider);
  }

  void _animateToPreferredCity(CityProvider cityProvider) {
    if (_userPreference?.preferredCityId != null && _mapController != null) {
      final preferredCity = cityProvider.findCityById(
        _userPreference!.preferredCityId!,
      );

      if (preferredCity != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(preferredCity.latitude, preferredCity.longitude),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterZones(List<ParkingZone> zones) {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredZones = zones;
      } else {
        final query = _searchQuery.toLowerCase();
        _filteredZones = zones.where((zone) {
          return zone.name.toLowerCase().contains(query) ||
              zone.address.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  ParkingZone? _findZoneById(List<ParkingZone> zones, int? zoneId) {
    if (zoneId == null) {
      return null;
    }

    for (final zone in zones) {
      if (zone.id == zoneId) {
        return zone;
      }
    }

    return null;
  }

  Future<void> _openZoneInfo(
    ParkingZone zone, {
    bool clearSearch = false,
  }) async {
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    final zoneProvider = Provider.of<ParkingZoneProvider>(
      context,
      listen: false,
    );

    await reviewProvider.getZoneReviews(parkingZoneId: zone.id);

    if (!mounted) {
      return;
    }

    final resolvedZone =
        _findZoneById(_filteredZones, zone.id) ??
        _findZoneById(zoneProvider.parkingZones, zone.id) ??
        zone;

    if (clearSearch) {
      _searchController.clear();
      FocusScope.of(context).unfocus();
    }

    setState(() {
      _selectedZone = resolvedZone;
      _selectedZone!.isFavorite =
          _userPreference?.favoriteParkingZoneId == resolvedZone.id;
      _selectedZone!.averageRating = reviewProvider.averageRating;
      _selectedZone!.reviewCount = reviewProvider.reviewCount;
      _sheetState = BottomSheetState.info;
      if (clearSearch) {
        _searchQuery = '';
      }
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(resolvedZone.latitude, resolvedZone.longitude),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    return _filteredZones.map((zone) {
      final isSelected = _selectedZone?.id == zone.id;
      return Marker(
        markerId: MarkerId(zone.id.toString()),
        position: LatLng(zone.latitude, zone.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: zone.name,
          snippet: '${zone.pricePerHour}KM/h',
        ),
        onTap: () async {
          await _openZoneInfo(zone);
        },
      );
    }).toSet();
  }

  Future<void> _toggleFavorite(ParkingZone zone) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final preferenceProvider = Provider.of<PreferenceProvider>(
      context,
      listen: false,
    );

    try {
      final isFavorite = zone.isFavorite;
      final newFavoriteId = isFavorite ? 0 : zone.id;

      await preferenceProvider.updateFavoriteParking(
        userId: authProvider.user!.id,
        parkingZoneId: newFavoriteId,
      );

      setState(() {
        for (var z in _filteredZones) {
          z.isFavorite =
              preferenceProvider.userPreference?.favoriteParkingZoneId == z.id;
        }

        if (_selectedZone != null) {
          _selectedZone!.isFavorite =
              preferenceProvider.userPreference?.favoriteParkingZoneId ==
              _selectedZone!.id;
        }

        _userPreference = preferenceProvider.userPreference;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            zone.isFavorite ? 'Dodano u favorite' : 'Uklonjeno iz favorite',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška prilikom ažuriranja favorita.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _refreshSelectedZoneRating() async {
    if (_selectedZone == null) {
      return;
    }

    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    await reviewProvider.getZoneReviews(parkingZoneId: _selectedZone!.id);

    if (!mounted || _selectedZone == null) {
      return;
    }

    setState(() {
      _selectedZone!.averageRating = reviewProvider.averageRating;
      _selectedZone!.reviewCount = reviewProvider.reviewCount;
    });
  }

  Future<ParkingZone> _loadZoneForSpotPicker(ParkingZone baseZone) async {
    try {
      final freshZone = await ApiService.getParkingZoneById(baseZone.id);

      if (freshZone.spots == null || freshZone.spots!.isEmpty) {
        final spotsResult = await ApiService.getParkingSpotsByZoneId(
          baseZone.id,
        );
        freshZone.spots = spotsResult.results;
      }

      freshZone.isFavorite =
          _userPreference?.favoriteParkingZoneId == freshZone.id;
      freshZone.averageRating = baseZone.averageRating;
      freshZone.reviewCount = baseZone.reviewCount;

      return freshZone;
    } catch (_) {
      return baseZone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ParkingZoneProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.parkingZones.isEmpty) {
            return Center(child: Text(AppStrings.noData));
          }

          if (_filteredZones.isEmpty && _searchQuery.isEmpty) {
            _filteredZones = provider.parkingZones;
          }

          final favoriteZone = _userPreference?.favoriteParkingZoneId != null
              ? _findZoneById(
                  _filteredZones,
                  _userPreference?.favoriteParkingZoneId,
                )
              : null;
          final recommendedZone = _recommendedZone;
          final recommendationReasons =
              _recommendedExplanation?.reasons ?? const <String>[];
          final visibleRecommendationReasons = recommendationReasons
              .take(3)
              .toList();

          final hasFavoriteBanner = favoriteZone != null;
          final hasRecommendationBanner = recommendedZone != null;
          final hasRecommendationStatusBanner = recommendedZone == null;
          const baseBannerTop = 50.0;
          const favoriteBannerHeight = 44.0;
          const statusBannerHeight = 56.0;
          const interBannerGap = 10.0;
          const afterBannerGap = 12.0;

          final recommendationBannerTop = hasFavoriteBanner
              ? baseBannerTop + favoriteBannerHeight + interBannerGap
              : baseBannerTop;

          final recommendationBannerHeight = hasRecommendationBanner
              ? 56.0 + (visibleRecommendationReasons.length * 18.0)
              : statusBannerHeight;

          final searchTop =
              hasFavoriteBanner ||
                  hasRecommendationBanner ||
                  hasRecommendationStatusBanner
              ? recommendationBannerTop +
                    recommendationBannerHeight +
                    afterBannerGap
              : 100.0;
          final searchResultsTop = searchTop + 50.0;

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _initialCenter,
                  zoom: 13,
                ),
                markers: _buildMarkers(),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
              ),

              if (favoriteZone != null)
                Positioned(
                  top: 50,
                  left: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () async {
                      await _openZoneInfo(favoriteZone);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Moj favorit: ${favoriteZone.name}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (recommendedZone != null)
                Positioned(
                  top: recommendationBannerTop,
                  left: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () async {
                      final resolvedZone =
                          _findZoneById(
                            provider.parkingZones,
                            recommendedZone.id,
                          ) ??
                          recommendedZone;
                      await _openZoneInfo(resolvedZone);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Preporučena zona: ${recommendedZone.name}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (visibleRecommendationReasons.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Razlozi preporuke:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            for (final reason in visibleRecommendationReasons)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.circle,
                                        color: Colors.white70,
                                        size: 6,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        reason,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              if (recommendedZone == null)
                Positioned(
                  top: recommendationBannerTop,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Trenutno nema preporučene zone za vaš profil.',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Positioned(
                top: searchTop,
                left: 12,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Upišite lokaciju...',
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _filterZones(provider.parkingZones);
                              },
                              child: Icon(
                                Icons.close,
                                color: AppColors.textSecondary,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _filterZones(provider.parkingZones);
                    },
                  ),
                ),
              ),

              if (_searchQuery.isNotEmpty && _filteredZones.isNotEmpty)
                Positioned(
                  top: searchResultsTop,
                  left: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredZones.length > 5
                          ? 5
                          : _filteredZones.length,
                      itemBuilder: (context, index) {
                        final zone = _filteredZones[index];
                        return ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          title: Text(
                            zone.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '${zone.address}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () async {
                            await _openZoneInfo(zone, clearSearch: true);
                          },
                        );
                      },
                    ),
                  ),
                ),

              if (_selectedZone != null && _sheetState == BottomSheetState.info)
                _buildBottomSheet(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedZone!.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_selectedZone!.pricePerHour}KM/h',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _toggleFavorite(_selectedZone!),
                      child: Icon(
                        _selectedZone!.isFavorite
                            ? Icons.star
                            : Icons.star_outline,
                        color: _selectedZone!.isFavorite
                            ? Colors.amber
                            : AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _sheetState = BottomSheetState.closed;
                          _selectedZone = null;
                        });
                      },
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoPanel(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${_selectedZone!.address}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final hasChanges = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) =>
                      ReviewsScreen(parkingZone: _selectedZone!),
                ),
              );

              if (hasChanges == true) {
                await _refreshSelectedZoneRating();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, size: 18, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    _selectedZone!.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '(${_selectedZone!.reviewCount} ocjena)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoChip('${_selectedZone!.availableSpots}', 'Dostupna'),
              _buildInfoChip('${_selectedZone!.disabledSpots}', 'Invalidska'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final selectedZone = _selectedZone;
                if (selectedZone == null) {
                  return;
                }

                final freshZone = await _loadZoneForSpotPicker(selectedZone);

                final selectedSpot = await showModalBottomSheet<ParkingSpot>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (sheetContext) =>
                      ParkingDetailsScreen(parkingZone: freshZone),
                );

                if (!mounted) {
                  return;
                }

                if (selectedSpot != null) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ReservationScreen(
                        parkingZone: freshZone,
                        parkingSpot: selectedSpot,
                      ),
                    ),
                  );
                }

                setState(() {
                  _selectedZone = freshZone;
                  _selectedZone!.isFavorite =
                      _userPreference?.favoriteParkingZoneId == freshZone.id;
                  _sheetState = BottomSheetState.info;
                });

                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(freshZone.latitude, freshZone.longitude),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Odaberite mjesto',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
