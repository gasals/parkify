import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/parking_zone_model.dart';
import '../models/reservation_model.dart';
import '../models/user_model.dart';
import '../providers/reservation_provider.dart';
import '../widgets/common_widgets.dart';

class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({Key? key}) : super(key: key);

  @override
  State<AdminReservationsScreen> createState() =>
      _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _zoneSearchController = TextEditingController();

  List<User> _allUsers = [];
  List<ParkingZone> _allZones = [];
  User? _selectedUser;
  ParkingZone? _selectedZone;
  ReservationStatus? _selectedStatus;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadDropdownData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ReservationProvider>(
          context,
          listen: false,
        ).searchReservations();
      }
    });
  }

  Future<void> _loadDropdownData() async {
    final provider = Provider.of<ReservationProvider>(context, listen: false);
    final users = await provider.getAllUsersList();
    final zones = await provider.getAllParkingZonesList();

    if (mounted) {
      setState(() {
        _allUsers = users;
        _allZones = zones;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _userSearchController.dispose();
    _zoneSearchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = Provider.of<ReservationProvider>(context, listen: false);
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (provider.currentPage < provider.totalPages && !_isSearching) {
        provider.searchReservations(
          userId: _selectedUser?.id,
          parkingZoneId: _selectedZone?.id,
          status: _selectedStatus?.value,
          page: provider.currentPage + 1,
        );
      }
    }
  }

  Future<void> _performSearch() async {
    final provider = Provider.of<ReservationProvider>(context, listen: false);
    setState(() => _isSearching = true);

    await provider.searchReservations(
      userId: _selectedUser?.id,
      parkingZoneId: _selectedZone?.id,
      status: _selectedStatus?.value,
    );

    setState(() => _isSearching = false);
  }

  void _clearSearch() {
    _selectedUser = null;
    _selectedZone = null;
    _selectedStatus = null;
    _userSearchController.clear();
    _zoneSearchController.clear();
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader.build(title: 'Parking rezervacije'),
            const SizedBox(height: 24),
            _buildSearchContainer(),
            const SizedBox(height: 24),
            Expanded(child: _buildReservationsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchContainer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: SearchContainerStyle.buildDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildUserAutocomplete()),
              const SizedBox(width: 12),
              Expanded(child: _buildZoneAutocomplete()),
              const SizedBox(width: 12),
              Expanded(child: _buildStatusDropdown()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  children: [
                    _buildStatusLegend('Na čekanju', Colors.orange),
                    _buildStatusLegend('Potvrđena', Colors.blue),
                    _buildStatusLegend('Aktivna', Colors.green),
                    _buildStatusLegend('Završena', Colors.grey),
                    _buildStatusLegend('Otkazana', Colors.red),
                    _buildStatusLegend('No show', Colors.purple),
                  ],
                ),
              ),
              CommonButtons.buildClearButton(onPressed: _clearSearch),
              const SizedBox(width: 12),
              CommonButtons.buildSearchButton(
                onPressed: _performSearch,
                isLoading: _isSearching,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserAutocomplete() {
    return Autocomplete<User>(
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return [];
        return _allUsers
            .where(
              (user) =>
                  user.username.toLowerCase().contains(
                    value.text.toLowerCase(),
                  ) ||
                  user.email.toLowerCase().contains(value.text.toLowerCase()),
            )
            .toList();
      },
      onSelected: (User selection) {
        setState(() {
          _selectedUser = selection;
          _userSearchController.text = selection.username;
        });
      },
      displayStringForOption: (User option) =>
          '${option.username} (${option.email})',
      fieldViewBuilder:
          (context, fieldController, focusNode, onEditingComplete) {
            return TextField(
              controller: fieldController,
              focusNode: focusNode,
              onEditingComplete: onEditingComplete,
              onChanged: (value) async {
                if (value.isNotEmpty) {
                  final provider = Provider.of<ReservationProvider>(
                    context,
                    listen: false,
                  );
                  final results = await provider.searchUsersLive(
                    username: value,
                  );
                  setState(() => _allUsers = results);
                }
              },
              decoration: SearchFieldDecoration.buildInputDecoration(
                labelText: 'Korisnik',
                icon: Icons.person_outline,
              ),
            );
          },
    );
  }

  Widget _buildZoneAutocomplete() {
    return Autocomplete<ParkingZone>(
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return [];
        return _allZones
            .where(
              (zone) =>
                  zone.name.toLowerCase().contains(value.text.toLowerCase()),
            )
            .toList();
      },
      onSelected: (ParkingZone selection) {
        setState(() {
          _selectedZone = selection;
          _zoneSearchController.text = selection.name;
        });
      },
      displayStringForOption: (option) => option.name,
      fieldViewBuilder:
          (context, fieldController, focusNode, onEditingComplete) {
            return TextField(
              controller: fieldController,
              focusNode: focusNode,
              onEditingComplete: onEditingComplete,
              onChanged: (value) async {
                if (value.isNotEmpty) {
                  final provider = Provider.of<ReservationProvider>(
                    context,
                    listen: false,
                  );
                  final results = await provider.searchParkingZonesLive(
                    name: value,
                  );
                  setState(() => _allZones = results);
                }
              },
              decoration: SearchFieldDecoration.buildInputDecoration(
                labelText: 'Parking zona',
                icon: Icons.map_outlined,
              ),
            );
          },
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<ReservationStatus>(
        isExpanded: true,
        underline: const SizedBox(),
        hint: const Text('Status'),
        value: _selectedStatus,
        items: ReservationStatus.values.map((status) {
          return DropdownMenuItem(value: status, child: Text(status.label));
        }).toList(),
        onChanged: (status) => setState(() => _selectedStatus = status),
      ),
    );
  }

  Widget _buildStatusLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildReservationsList() {
    return Consumer<ReservationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.reservations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.reservations.isEmpty) {
          return const Center(
            child: Text('Nema rezervacija koje odgovaraju pretrazi.'),
          );
        }

        return GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.5,
          ),
          itemCount:
              provider.reservations.length + (provider.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.reservations.length) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildReservationTile(
              provider.reservations[index],
              provider,
            );
          },
        );
      },
    );
  }

  Widget _buildReservationTile(
    Reservation reservation,
    ReservationProvider provider,
  ) {
    final statusColor = ReservationStatus.fromValue(reservation.status);
    final statusEnum = ReservationStatus.fromValue(reservation.status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReservationHeader(reservation, statusEnum),
            const Divider(height: 32),
            _buildReservationInfo(reservation),
            const Spacer(),
            _buildReservationActions(reservation, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationHeader(
    Reservation reservation,
    ReservationStatus status,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
          child: const Icon(
            Icons.confirmation_number_outlined,
            size: 18,
            color: Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            reservation.reservationCode,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(status.value),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReservationInfo(Reservation reservation) {
    return Column(
      children: [
        _buildInfoRow(
          Icons.local_parking,
          'Zona ID',
          reservation.parkingZoneId.toString(),
        ),
        _buildInfoRow(
          Icons.calendar_today,
          'Datum',
          '${reservation.reservationStart.day}/${reservation.reservationStart.month}/${reservation.reservationStart.year}',
        ),
        _buildInfoRow(
          Icons.access_time,
          'Vrijeme',
          '${reservation.reservationStart.hour}:${reservation.reservationStart.minute.toString().padLeft(2, '0')}',
        ),
        _buildInfoRow(
          Icons.monetization_on,
          'Cijena',
          '${reservation.finalPrice} BAM',
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6366F1)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const Spacer(),
          Text(
            value.trim().isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationActions(
    Reservation reservation,
    ReservationProvider provider,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showChangeStatusDialog(reservation, provider),
            icon: const Icon(Icons.edit, size: 16, color: Colors.white),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            label: const Text(
              'STATUS',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if ((!reservation.isCheckedIn || !reservation.isCheckedOut) &&
            reservation.status == 2)
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(
                !reservation.isCheckedIn ? Icons.login : Icons.logout,
                size: 16,
                color: !reservation.isCheckedIn ? Colors.green : Colors.orange,
              ),
              onPressed: !reservation.isCheckedIn
                  ? () => _performCheckIn(reservation, provider)
                  : () => _performCheckOut(reservation, provider),
              style: OutlinedButton.styleFrom(
                foregroundColor: !reservation.isCheckedIn
                    ? Colors.green
                    : Colors.orange,
                side: BorderSide(
                  color: !reservation.isCheckedIn
                      ? Colors.green
                      : Colors.orange,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              label: Text(
                !reservation.isCheckedIn ? 'CHECK-IN' : 'CHECK-OUT',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _performCheckIn(
    Reservation reservation,
    ReservationProvider provider,
  ) async {
    final success = await provider.checkInReservation(reservation.id);
    if (mounted) {
      if (success) {
        SnackBarHelper.showSuccess(context, 'Check-in uspješan');
      } else {
        SnackBarHelper.showError(context, 'Check-in nije uspio');
      }
    }
  }

  Future<void> _performCheckOut(
    Reservation reservation,
    ReservationProvider provider,
  ) async {
    final success = await provider.checkOutReservation(reservation.id);
    if (mounted) {
      if (success) {
        SnackBarHelper.showSuccess(context, 'Check-out uspješan');
      } else {
        SnackBarHelper.showError(context, 'Check-out nije uspio');
      }
    }
  }

  void _showChangeStatusDialog(
    Reservation reservation,
    ReservationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promijeni status rezervacije'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReservationStatus.values.map((status) {
            return _buildStatusButton(status, reservation, provider);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    ReservationStatus status,
    Reservation reservation,
    ReservationProvider provider,
  ) {
    bool isSelected = reservation.status == status.value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: isSelected
              ? null
              : () async {
                  Navigator.pop(context);
                  final success = await provider.updateReservationStatus(
                    reservation.id,
                    status.value,
                  );
                  if (mounted) {
                    SnackBarHelper.showMessage(
                      context,
                      'Status ažuriran',
                      success,
                    );
                  }
                },
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isSelected ? Colors.transparent : Colors.grey[300]!,
            ),
            backgroundColor: isSelected
                ? const Color(0xFF6366F1).withOpacity(0.1)
                : null,
          ),
          child: Text(
            status.label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF6366F1) : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(int value) {
    switch (ReservationStatus.fromValue(value)) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.confirmed:
        return Colors.blue;
      case ReservationStatus.active:
        return Colors.green;
      case ReservationStatus.completed:
        return Colors.grey;
      case ReservationStatus.cancelled:
        return Colors.red;
      case ReservationStatus.noShow:
        return Colors.purple;
    }
  }
}
