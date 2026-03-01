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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ReservationProvider>(
          context,
          listen: false,
        ).getAllReservations();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = Provider.of<ReservationProvider>(context, listen: false);
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (provider.currentPage < provider.totalPages) {
        provider.getAllReservations(page: provider.currentPage + 1);
      }
    }
  }

  Future<void> _performSearch() async {
    final provider = Provider.of<ReservationProvider>(context, listen: false);

    if (_searchQuery.isEmpty) {
      await provider.getAllReservations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parking rezervacije',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Pretraga po kodu...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _performSearch,
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Traži'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: Consumer<ReservationProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.reservations.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.reservations.isEmpty) {
                    return const Center(child: Text('Nema rezervacija'));
                  }

                  final filtered = provider.reservations
                      .where(
                        (res) => res.reservationCode.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();

                  return GridView.builder(
                    controller: _scrollController,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.30,
                        ),
                    itemCount: filtered.length + (provider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filtered.length) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return _buildReservationTile(filtered[index], provider);
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

  Widget _buildReservationTile(
    Reservation reservation,
    ReservationProvider provider,
  ) {
    final statusColor = _getStatusColor(reservation.status);
    final statusText = _getStatusText(reservation.status);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.confirmation_number,
                    size: 22,
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reservation.reservationCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            _buildInfoRow(
              Icons.location_on,
              "Zona",
              reservation.parkingZoneName ?? "N/A",
            ),
            _buildInfoRow(
              Icons.calendar_today,
              "Datum",
              "${reservation.reservationStart.day}/${reservation.reservationStart.month}",
            ),
            _buildInfoRow(
              Icons.access_time,
              "Vrijeme",
              "${reservation.reservationStart.hour.toString().padLeft(2, '0')}:${reservation.reservationStart.minute.toString().padLeft(2, '0')}",
            ),
            _buildInfoRow(
              Icons.timer,
              "Trajanje",
              "${reservation.durationInHours}h",
            ),
            _buildInfoRow(
              Icons.payments,
              "Cijena",
              "${reservation.finalPrice} BAM",
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _buildStatusChip(
                  reservation.isCheckedIn,
                  Icons.login,
                  "Check-in",
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  reservation.isCheckedOut,
                  Icons.logout,
                  "Check-out",
                ),
              ],
            ),

            const SizedBox(height: 14),

            Column(
              children: [
                if (!reservation.isCheckedIn)
                  _buildActionButton(
                    icon: Icons.login,
                    label: "Check-in",
                    color: Colors.green,
                    onPressed: () => _performCheckIn(reservation, provider),
                  ),
                if (!reservation.isCheckedOut && reservation.isCheckedIn)
                  _buildActionButton(
                    icon: Icons.logout,
                    label: "Check-out",
                    color: Colors.orange,
                    onPressed: () => _performCheckOut(reservation, provider),
                  ),
                _buildActionButton(
                  icon: Icons.edit,
                  label: "Promijeni status",
                  color: const Color.fromARGB(255, 255, 255, 255),
                  onPressed: () =>
                      _showChangeStatusDialog(reservation, provider),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6366F1)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool value, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: value ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            value ? "✓ $label" : label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 4:
        return Colors.grey;
      case 5:
        return Colors.red;
      case 6:
        return Colors.purple;
      default:
        return Colors.grey;
    }
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
            success ? 'Check-in je izvršen' : 'Greška pri check-in-u',
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
            success ? 'Check-out je izvršen' : 'Greška pri check-out-u',
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
        title: const Text('Promijeni status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusButton('Pending', 1, reservation, provider),
            _buildStatusButton('Confirmed', 2, reservation, provider),
            _buildStatusButton('Active', 3, reservation, provider),
            _buildStatusButton('Completed', 4, reservation, provider),
            _buildStatusButton('Cancelled', 5, reservation, provider),
            _buildStatusButton('NoShow', 6, reservation, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    String label,
    int status,
    Reservation reservation,
    ReservationProvider provider,
  ) {
    final isCurrentStatus = reservation.status == status;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isCurrentStatus
              ? null
              : () async {
                  Navigator.pop(context);
                  final success = await provider.updateReservationStatus(
                    reservation.id,
                    status,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Status je ažuriran na $label'
                              : 'Greška pri ažuriranju',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: isCurrentStatus
                ? Colors.grey
                : const Color(0xFF6366F1),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Pending';
      case 2:
        return 'Confirmed';
      case 3:
        return 'Active';
      case 4:
        return 'Completed';
      case 5:
        return 'Cancelled';
      case 6:
        return 'NoShow';
      default:
        return 'Unknown';
    }
  }
}
