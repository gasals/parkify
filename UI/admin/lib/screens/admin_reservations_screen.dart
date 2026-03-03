import 'package:admin/widgets/admin_dialog_widgets.dart';
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
  final _userSearchCtrl = TextEditingController();
  final _zoneSearchCtrl = TextEditingController();

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
        Provider.of<ReservationProvider>(context, listen: false)
            .searchReservations();
      }
    });
  }

  Future<void> _loadDropdownData() async {
    final p = Provider.of<ReservationProvider>(context, listen: false);
    final users = await p.getAllUsersList();
    final zones = await p.getAllParkingZonesList();
    if (mounted) setState(() { _allUsers = users; _allZones = zones; });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _userSearchCtrl.dispose();
    _zoneSearchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final p = Provider.of<ReservationProvider>(context, listen: false);
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (p.currentPage < p.totalPages && !_isSearching) {
        p.searchReservations(
          userId: _selectedUser?.id,
          parkingZoneId: _selectedZone?.id,
          status: _selectedStatus?.value,
          page: p.currentPage + 1,
        );
      }
    }
  }

  Future<void> _performSearch() async {
    setState(() => _isSearching = true);
    await Provider.of<ReservationProvider>(context, listen: false)
        .searchReservations(
      userId: _selectedUser?.id,
      parkingZoneId: _selectedZone?.id,
      status: _selectedStatus?.value,
    );
    setState(() => _isSearching = false);
  }

  void _clearSearch() {
    setState(() {
      _selectedUser = null;
      _selectedZone = null;
      _selectedStatus = null;
    });
    _userSearchCtrl.clear();
    _zoneSearchCtrl.clear();
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
              // FIX: isti stil kao autocomplete polja pored njega
              Expanded(
                child: DropdownButtonFormField<ReservationStatus>(
                  value: _selectedStatus,
                  isExpanded: true,
                  decoration: SearchFieldDecoration.buildInputDecoration(
                    labelText: 'Status',
                    icon: Icons.flag_outlined,
                  ),
                  items: [
                    const DropdownMenuItem<ReservationStatus>(
                      value: null,
                      child: Text('Svi statusi', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                    ...ReservationStatus.values.map((s) => DropdownMenuItem(
                          value: s,
                          child: Row(children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                  color: _statusColorStatic(s), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(s.label, style: const TextStyle(fontSize: 13)),
                          ]),
                        )),
                  ],
                  onChanged: (s) => setState(() => _selectedStatus = s),
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
                  runSpacing: 4,
                  children: [
                    _legendItem('Na \u010dekanju', Colors.orange),
                    _legendItem('Potvr\u0111ena', Colors.blue),
                    _legendItem('Aktivna', Colors.green),
                    _legendItem('Zavr\u0161ena', Colors.grey),
                    _legendItem('Otkazana', Colors.red),
                    _legendItem('No show', Colors.purple),
                  ],
                ),
              ),
              CommonButtons.buildClearButton(onPressed: _clearSearch),
              const SizedBox(width: 12),
              CommonButtons.buildSearchButton(
                  onPressed: _performSearch, isLoading: _isSearching),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildUserAutocomplete() {
    return Autocomplete<User>(
      optionsBuilder: (val) {
        if (val.text.isEmpty) return [];
        return _allUsers.where((u) =>
            u.username.toLowerCase().contains(val.text.toLowerCase()) ||
            u.email.toLowerCase().contains(val.text.toLowerCase()));
      },
      onSelected: (u) => setState(() => _selectedUser = u),
      displayStringForOption: (u) => '${u.username} (${u.email})',
      fieldViewBuilder: (ctx, fc, fn, oec) => TextField(
        controller: fc,
        focusNode: fn,
        onEditingComplete: oec,
        onChanged: (v) async {
          if (v.isNotEmpty) {
            final r = await Provider.of<ReservationProvider>(ctx, listen: false)
                .searchUsersLive(username: v);
            setState(() => _allUsers = r);
          }
        },
        decoration: SearchFieldDecoration.buildInputDecoration(
            labelText: 'Korisnik', icon: Icons.person_outline),
      ),
    );
  }

  Widget _buildZoneAutocomplete() {
    return Autocomplete<ParkingZone>(
      optionsBuilder: (val) {
        if (val.text.isEmpty) return [];
        return _allZones.where((z) =>
            z.name.toLowerCase().contains(val.text.toLowerCase()));
      },
      onSelected: (z) => setState(() => _selectedZone = z),
      displayStringForOption: (z) => z.name,
      fieldViewBuilder: (ctx, fc, fn, oec) => TextField(
        controller: fc,
        focusNode: fn,
        onEditingComplete: oec,
        onChanged: (v) async {
          if (v.isNotEmpty) {
            final r = await Provider.of<ReservationProvider>(ctx, listen: false)
                .searchParkingZonesLive(name: v);
            setState(() => _allZones = r);
          }
        },
        decoration: SearchFieldDecoration.buildInputDecoration(
            labelText: 'Parking zona', icon: Icons.map_outlined),
      ),
    );
  }

  Widget _buildReservationsList() {
    return Consumer<ReservationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.reservations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.reservations.isEmpty) {
          return const Center(child: Text('Nema rezervacija koje odgovaraju pretrazi.'));
        }
        return GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.5,
          ),
          itemCount: provider.reservations.length + (provider.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.reservations.length) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildReservationTile(
                provider.reservations[index], provider);
          },
        );
      },
    );
  }

  Widget _buildReservationTile(
      Reservation reservation, ReservationProvider provider) {
    final statusEnum = ReservationStatus.fromValue(reservation.status);
    final statusColor = _statusColor(statusEnum);

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
                  backgroundColor: kPrimary.withOpacity(0.1),
                  child: const Icon(Icons.confirmation_number_outlined,
                      size: 18, color: kPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reservation.reservationCode,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AdminStatusBadge(
                  label: statusEnum.label,
                  color: statusColor,
                ),
              ],
            ),
            const Divider(height: 28),
            _infoRow(Icons.local_parking, 'Zona ID',
                reservation.parkingZoneId.toString()),
            _infoRow(Icons.calendar_today, 'Datum',
                '${reservation.reservationStart.day.toString().padLeft(2, '0')}.'
                '${reservation.reservationStart.month.toString().padLeft(2, '0')}.'
                '${reservation.reservationStart.year}'),
            _infoRow(Icons.access_time, 'Vrijeme',
                '${reservation.reservationStart.hour.toString().padLeft(2, '0')}:'
                '${reservation.reservationStart.minute.toString().padLeft(2, '0')}'),
            _infoRow(Icons.monetization_on, 'Cijena',
                '${reservation.finalPrice} BAM'),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showChangeStatusDialog(reservation, provider),
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                    label: const Text('STATUS',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                if ((!reservation.isCheckedIn && reservation.status == 2) || (!reservation.isCheckedOut && reservation.status == 3)) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        !reservation.isCheckedIn
                            ? Icons.login
                            : Icons.logout,
                        size: 16,
                        color: !reservation.isCheckedIn
                            ? Colors.green
                            : Colors.orange,
                      ),
                      onPressed: !reservation.isCheckedIn
                          ? () => _checkIn(reservation, provider)
                          : () => _checkOut(reservation, provider),
                      label: Text(
                        !reservation.isCheckedIn ? 'CHECK-IN' : 'CHECK-OUT',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: !reservation.isCheckedIn
                            ? Colors.green
                            : Colors.orange,
                        side: BorderSide(
                            color: !reservation.isCheckedIn
                                ? Colors.green
                                : Colors.orange),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: kPrimary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const Spacer(),
          Text(value.trim().isEmpty ? '-' : value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // static verzija za koristenje u DropdownMenuItem builderu
  static Color _statusColorStatic(ReservationStatus s) => switch (s) {
        ReservationStatus.pending   => Colors.orange,
        ReservationStatus.confirmed => Colors.blue,
        ReservationStatus.active    => Colors.green,
        ReservationStatus.completed => Colors.grey,
        ReservationStatus.cancelled => Colors.red,
        ReservationStatus.noShow    => Colors.purple,
      };

  Color _statusColor(ReservationStatus s) => _statusColorStatic(s);

  Future<void> _checkIn(Reservation r, ReservationProvider p) async {
    final ok = await p.checkInReservation(r.id);
    if (mounted) AdminSnackBar.show(context, ok ? 'Check-in uspje\u0161an' : 'Check-in nije uspio', ok);
  }

  Future<void> _checkOut(Reservation r, ReservationProvider p) async {
    final ok = await p.checkOutReservation(r.id);
    if (mounted) AdminSnackBar.show(context, ok ? 'Check-out uspje\u0161an' : 'Check-out nije uspio', ok);
  }

  void _showChangeStatusDialog(
      Reservation reservation, ReservationProvider provider) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AdminDialogHeader(
                  icon: Icons.swap_horiz_outlined,
                  title: 'Promijeni status rezervacije'),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: ReservationStatus.values.map((status) {
                    final isSelected = reservation.status == status.value;
                    final color = _statusColor(status);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: isSelected
                              ? null
                              : () async {
                                  Navigator.pop(context);
                                  final ok =
                                      await provider.updateReservationStatus(
                                    reservation.id,
                                    status.value,
                                  );
                                  if (mounted) {
                                    AdminSnackBar.show(
                                        context, 'Status a\u017euriran', ok);
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isSelected
                                ? color.withOpacity(0.1)
                                : null,
                            side: BorderSide(
                                color: isSelected ? color : Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(status.label,
                                  style: TextStyle(
                                      color: isSelected ? color : Colors.black87,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              AdminDialogFooter(
                  children: [const AdminCancelButton(label: 'Zatvori')]),
            ],
          ),
        ),
      ),
    );
  }
}