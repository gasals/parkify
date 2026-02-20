import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile/providers/city_provider.dart';
import 'package:mobile/providers/preference_provider.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/parking_zone_model.dart';
import '../models/preference_model.dart';
import '../providers/parking_zone_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/parking_details_screen.dart';

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
    final zoneProvider = Provider.of<ParkingZoneProvider>(context, listen: false);
    final preferenceProvider = Provider.of<PreferenceProvider>(context, listen: false);
    final cityProvider = Provider.of<CityProvider>(context, listen: false);

    final userId = authProvider.user?.id;

    if (userId != null) {
      await preferenceProvider.loadUserPreference(userId: userId);
      setState(() {
        _userPreference = preferenceProvider.userPreference;
      });
    }

    await zoneProvider.getParkingZones();
    await cityProvider.getAllCities();

    setState(() {
      _filteredZones = zoneProvider.parkingZones;
    });

    _animateToPreferredCity(cityProvider);
  }

  void _animateToPreferredCity(CityProvider cityProvider) {
    if (_userPreference?.preferredCityId != null && _mapController != null) {
      final preferredCity = cityProvider.findCityById(_userPreference!.preferredCityId!);
      
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
        onTap: () {
          setState(() {
            _selectedZone = zone;
            if (_selectedZone != null) {
              _selectedZone!.isFavorite = _userPreference?.favoriteParkingZoneId == zone.id;
            }
            _sheetState = BottomSheetState.info;
          });
        },
      );
    }).toSet();
  }

  Future<void> _toggleFavorite(ParkingZone zone) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final preferenceProvider = Provider.of<PreferenceProvider>(context, listen: false);

    try {
      final isFavorite = zone.isFavorite;
      final newFavoriteId = isFavorite ? 0 : zone.id;

      await preferenceProvider.updateFavoriteParking(
        userId: authProvider.user!.id,
        parkingZoneId: newFavoriteId,
      );

      setState(() {
        for (var z in _filteredZones) {
          z.isFavorite = preferenceProvider.userPreference?.favoriteParkingZoneId == z.id;
        }
        
        if (_selectedZone != null) {
          _selectedZone!.isFavorite = preferenceProvider.userPreference?.favoriteParkingZoneId == _selectedZone!.id;
        }
        
        _userPreference = preferenceProvider.userPreference;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(zone.isFavorite ? 'Dodano u favorite' : 'Uklonjeno iz favorite'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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
              ? _filteredZones.firstWhere(
                  (zone) => zone.id == _userPreference?.favoriteParkingZoneId,
                  orElse: () => _filteredZones.isNotEmpty ? _filteredZones.first : null as ParkingZone,
                )
              : null;

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
                    onTap: () {
                      setState(() {
                        _selectedZone = favoriteZone;
                        _selectedZone!.isFavorite = true;
                        _sheetState = BottomSheetState.info;
                      });
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(
                          LatLng(favoriteZone.latitude, favoriteZone.longitude),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                          ),
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

              Positioned(
                top: favoriteZone != null ? 110 : 100,
                left: 12,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Upišite lokaciju...',
                      prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _filterZones(provider.parkingZones);
                              },
                              child: Icon(Icons.close, color: AppColors.textSecondary),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  top: favoriteZone != null ? 170 : 160,
                  left: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount:
                          _filteredZones.length > 5 ? 5 : _filteredZones.length,
                      itemBuilder: (context, index) {
                        final zone = _filteredZones[index];
                        return ListTile(
                          leading: Icon(Icons.location_on,
                              color: AppColors.primary, size: 18),
                          title: Text(
                            zone.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '${zone.address}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () {
                            _searchController.text = zone.name;
                            setState(() {
                              _selectedZone = zone;
                              _selectedZone!.isFavorite = _userPreference?.favoriteParkingZoneId == zone.id;
                              _sheetState = BottomSheetState.info;
                              _searchQuery = '';
                            });
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLng(
                                LatLng(zone.latitude, zone.longitude),
                              ),
                            );
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
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoChip(
                '${_selectedZone!.availableSpots}',
                'Dostupna',
              ),
              _buildInfoChip(
                '${_selectedZone!.coveredSpots}',
                'Pokrivena',
              ),
              _buildInfoChip(
                '${_selectedZone!.disabledSpots}',
                'Invalidska',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ParkingDetailsScreen(parkingZone: _selectedZone!),
                  ),
                );

                setState(() {
                  _sheetState = BottomSheetState.closed;
                  _selectedZone = null;
                });
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}