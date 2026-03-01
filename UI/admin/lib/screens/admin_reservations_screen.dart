import 'package:admin/models/parking_zone_model.dart';
import 'package:admin/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reservation_model.dart';
import '../providers/reservation_provider.dart';

class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({Key? key}) : super(key: key);

  @override
  State<AdminReservationsScreen> createState() =>
      _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _parkingZoneIdController =
      TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _zoneSearchController = TextEditingController();

  bool _isSearching = false;

  List<User> _allUsers = [];
  List<ParkingZone> _allZones = [];
  User? _selectedUser;
  ParkingZone? _selectedZone;
  ReservationStatus? _selectedStatus;

  void _loadDropdownData() async {
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

  @override
  void dispose() {
    _scrollController.dispose();
    _userIdController.dispose();
    _parkingZoneIdController.dispose();
    _statusController.dispose();
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
            const Text(
              'Parking rezervacije',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Autocomplete<User>(
                          optionsBuilder: (TextEditingValue value) {
                            if (value.text.isEmpty) {
                              return [];
                            }
                            return _allUsers
                                .where(
                                  (user) =>
                                      user.username.toLowerCase().contains(
                                        value.text.toLowerCase(),
                                      ) ||
                                      user.email.toLowerCase().contains(
                                        value.text.toLowerCase(),
                                      ),
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
                              (
                                BuildContext context,
                                TextEditingController fieldController,
                                FocusNode fieldFocusNode,
                                VoidCallback onFieldSubmitted,
                              ) {
                                return TextField(
                                  controller: fieldController,
                                  focusNode: fieldFocusNode,
                                  onChanged: (String value) async {
                                    if (value.isNotEmpty) {
                                      final provider =
                                          Provider.of<ReservationProvider>(
                                            context,
                                            listen: false,
                                          );
                                      final results = await provider
                                          .searchUsersList(username: value);
                                      setState(() => _allUsers = results);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Korisnik',
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                      size: 20,
                                    ),
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                  ),
                                );
                              },
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Autocomplete<ParkingZone>(
                          optionsBuilder: (TextEditingValue value) {
                            if (value.text.isEmpty) {
                              return [];
                            }
                            return _allZones
                                .where(
                                  (zone) => zone.name.toLowerCase().contains(
                                    value.text.toLowerCase(),
                                  ),
                                )
                                .toList();
                          },
                          onSelected: (ParkingZone selection) {
                            setState(() {
                              _selectedZone = selection;
                              _zoneSearchController.text = selection.name;
                            });
                          },
                          displayStringForOption: (ParkingZone option) =>
                              option.name,
                          fieldViewBuilder:
                              (
                                BuildContext context,
                                TextEditingController fieldController,
                                FocusNode fieldFocusNode,
                                VoidCallback onFieldSubmitted,
                              ) {
                                return TextField(
                                  controller: fieldController,
                                  focusNode: fieldFocusNode,
                                  onChanged: (String value) async {
                                    if (value.isNotEmpty) {
                                      final provider =
                                          Provider.of<ReservationProvider>(
                                            context,
                                            listen: false,
                                          );
                                      final results = await provider
                                          .searchParkingZonesList(name: value);
                                      setState(() => _allZones = results);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Parking zona',
                                    prefixIcon: const Icon(
                                      Icons.map_outlined,
                                      size: 20,
                                    ),
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                  ),
                                );
                              },
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Container(
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
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status.label),
                              );
                            }).toList(),
                            onChanged: (status) {
                              setState(() => _selectedStatus = status);
                            },
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Očisti'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isSearching ? null : _performSearch,
                        icon: _isSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search, size: 18),
                        label: const Text('Pretraži'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 12,
                          children: [
                            _buildMiniLegend('1: Pending', Colors.orange),
                            _buildMiniLegend('2: Confirmed', Colors.blue),
                            _buildMiniLegend('3: Active', Colors.green),
                            _buildMiniLegend('4: Completed', Colors.grey),
                            _buildMiniLegend('5: Cancelled', Colors.red),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: Consumer<ReservationProvider>(
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1.5,
                        ),
                    itemCount:
                        provider.reservations.length +
                        (provider.isLoading ? 1 : 0),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
    );
  }

  Widget _buildMiniLegend(String label, Color color) {
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

  Widget _buildReservationTile(
    Reservation reservation,
    ReservationProvider provider,
  ) {
    final statusColor = _getStatusColor(reservation.status);
    final statusText = _getStatusText(reservation.status);

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
            Row(
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(
              Icons.map_outlined,
              "Zona ID",
              reservation.parkingZoneId.toString(),
            ),
            _buildInfoRow(
              Icons.calendar_today,
              "Datum",
              "${reservation.reservationStart.day}/${reservation.reservationStart.month}/${reservation.reservationStart.year}",
            ),
            _buildInfoRow(
              Icons.access_time,
              "Vrijeme",
              "${reservation.reservationStart.hour}:${reservation.reservationStart.minute}",
            ),
            _buildInfoRow(
              Icons.payments_outlined,
              "Cijena",
              "${reservation.finalPrice} BAM",
            ),
            const Spacer(),
            Row(
              children: [
                _buildStatusChip(reservation.isCheckedIn, Icons.login, "In"),
                const SizedBox(width: 8),
                _buildStatusChip(reservation.isCheckedOut, Icons.logout, "Out"),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _showChangeStatusDialog(reservation, provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'STATUS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!reservation.isCheckedIn || !reservation.isCheckedOut)
                  Expanded(
                    child: OutlinedButton(
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
                      child: Text(
                        !reservation.isCheckedIn ? 'CHECK-IN' : 'CHECK-OUT',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isActive, IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.withOpacity(0.08) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.green.withOpacity(0.3) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 12,
              color: isActive ? Colors.green : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.green : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(int status) {
    final statusEnum = ReservationStatus.fromValue(status);
    switch (statusEnum) {
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

  String _getStatusText(int status) {
    return ReservationStatus.fromValue(status).label;
  }

  Future<void> _performCheckIn(
    Reservation res,
    ReservationProvider provider,
  ) async {
    final success = await provider.checkInReservation(res.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Check-in uspješan' : 'Greška pri check-in-u',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _performCheckOut(
    Reservation res,
    ReservationProvider provider,
  ) async {
    final success = await provider.checkOutReservation(res.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Check-out uspješan' : 'Greška pri check-out-u',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
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
          children: [
            _buildStatusDialogBtn('Pending', 1, reservation, provider),
            _buildStatusDialogBtn('Confirmed', 2, reservation, provider),
            _buildStatusDialogBtn('Active', 3, reservation, provider),
            _buildStatusDialogBtn('Completed', 4, reservation, provider),
            _buildStatusDialogBtn('Cancelled', 5, reservation, provider),
            _buildStatusDialogBtn('NoShow', 6, reservation, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDialogBtn(
    String label,
    int status,
    Reservation res,
    ReservationProvider provider,
  ) {
    bool isSelected = res.status == status;
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
                    res.id,
                    status,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success ? 'Status ažuriran' : 'Greška pri ažuriranju',
                        ),
                      ),
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
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF6366F1) : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
