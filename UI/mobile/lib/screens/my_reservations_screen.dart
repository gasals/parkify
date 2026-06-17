import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/parking_zone_model.dart';
import '../models/reservation_model.dart';
import '../providers/auth_provider.dart';
import '../providers/parking_zone_provider.dart';
import '../providers/reservation_provider.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({Key? key}) : super(key: key);

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  bool _isFetchingMore = false;
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _selectedZoneId;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id ?? 0;
      final parkingZoneProvider = Provider.of<ParkingZoneProvider>(
        context,
        listen: false,
      );

      if (mounted) {
        if (parkingZoneProvider.parkingZones.isEmpty) {
          parkingZoneProvider.getParkingZones(page: 1, pageSize: 200);
        }

        Provider.of<ReservationProvider>(
          context,
          listen: false,
        ).getUserReservations(userId: userId, page: _currentPage);
      }
    });
  }

  void _onScroll() async {
    if (!_scrollController.hasClients) return;

    final provider = Provider.of<ReservationProvider>(context, listen: false);

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore &&
        provider.hasMore) {
      _isFetchingMore = true;
      _currentPage++;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await provider.getUserReservations(
        userId: authProvider.user?.id ?? 0,
        page: _currentPage,
      );

      _isFetchingMore = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje rezervacije'),
        backgroundColor: AppColors.primary,
      ),
      body: Consumer2<ReservationProvider, ParkingZoneProvider>(
        builder: (context, provider, parkingZoneProvider, _) {
          final filteredReservations = _applyFilters(provider.reservations);
          final hasActiveFilters =
              _fromDate != null || _toDate != null || _selectedZoneId != null;

          if (provider.isLoading && provider.reservations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.reservations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nemaš rezervacije',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kreiraj prvu rezervaciju na mapi',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildFilters(parkingZoneProvider),
              Expanded(
                child: filteredReservations.isEmpty
                    ? Center(
                        child: Text(
                          'Nema rezervacija za odabrane filtere.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: provider.hasMore && !hasActiveFilters
                            ? filteredReservations.length + 1
                            : filteredReservations.length,
                        itemBuilder: (context, index) {
                          if (index < filteredReservations.length) {
                            final reservation = filteredReservations[index];
                            final zoneName = _resolveZoneName(
                              parkingZoneProvider.parkingZones,
                              reservation.parkingZoneId,
                            );
                            return _buildReservationCard(
                              context,
                              reservation,
                              zoneName,
                            );
                          }

                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Reservation> _applyFilters(List<Reservation> source) {
    return source.where((reservation) {
      if (_selectedZoneId != null &&
          reservation.parkingZoneId != _selectedZoneId) {
        return false;
      }

      final startDate = DateTime(
        reservation.reservationStart.year,
        reservation.reservationStart.month,
        reservation.reservationStart.day,
      );

      if (_fromDate != null) {
        final from = DateTime(
          _fromDate!.year,
          _fromDate!.month,
          _fromDate!.day,
        );
        if (startDate.isBefore(from)) {
          return false;
        }
      }

      if (_toDate != null) {
        final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);
        if (startDate.isAfter(to)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  String _resolveZoneName(List<ParkingZone> zones, int zoneId) {
    for (final zone in zones) {
      if (zone.id == zoneId) {
        return zone.name;
      }
    }
    return 'Zona #$zoneId';
  }

  Future<void> _pickFromDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selected == null) return;

    setState(() {
      _fromDate = selected;
      if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
        _toDate = _fromDate;
      }
    });
  }

  Future<void> _pickToDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? DateTime.now(),
      firstDate:
          _fromDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selected == null) return;

    setState(() {
      _toDate = selected;
    });
  }

  Widget _buildFilters(ParkingZoneProvider zoneProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFromDate,
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    _fromDate == null ? 'Od datuma' : _formatDate(_fromDate!),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickToDate,
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(
                    _toDate == null ? 'Do datuma' : _formatDate(_toDate!),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedZoneId,
                  decoration: const InputDecoration(
                    labelText: 'Zona',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sve zone'),
                    ),
                    ...zoneProvider.parkingZones.map(
                      (zone) => DropdownMenuItem<int?>(
                        value: zone.id,
                        child: Text(zone.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedZoneId = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _fromDate = null;
                    _toDate = null;
                    _selectedZoneId = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Očisti'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(
    BuildContext context,
    Reservation reservation,
    String zoneName,
  ) {
    final statusColor = _getStatusColor(reservation.status);
    final statusText = reservation.getStatusText();
    final statusIcon = _getStatusIcon(reservation.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.confirmation_number,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kod: ${reservation.reservationCode}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 13, color: statusColor),
                            const SizedBox(width: 5),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${reservation.calculatedPrice.toStringAsFixed(2)}KM',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${reservation.durationInHours}h',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRowWithIcon(
                    Icons.local_parking,
                    'Zona',
                    zoneName,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRowWithIcon(
                    Icons.access_time,
                    'Početak',
                    '${reservation.reservationStart.hour.toString().padLeft(2, '0')}:${reservation.reservationStart.minute.toString().padLeft(2, '0')}',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRowWithIcon(
                    Icons.schedule,
                    'Završetak',
                    '${reservation.reservationEnd.hour.toString().padLeft(2, '0')}:${reservation.reservationEnd.minute.toString().padLeft(2, '0')}',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRowWithIcon(
                    Icons.timelapse,
                    'Trajanje',
                    '${reservation.durationInHours} sati',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (reservation.status == ReservationStatus.pending.value) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _confirmReservation(context, reservation),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text(
                        'Potvrdi',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelReservation(context, reservation),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text(
                        'Otkaži',
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildDetailRowWithIcon(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _cancelReservation(BuildContext context, Reservation reservation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Otkaži rezervaciju?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Jeste li sigurni da želite otkazati rezervaciju ${reservation.reservationCode}?',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Ne'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        final provider = Provider.of<ReservationProvider>(
                          context,
                          listen: false,
                        );
                        final success = await provider.cancelReservation(
                          reservation.id,
                        );
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Rezervacija je otkazana'),
                            ),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.errorMessage ??
                                    'Otkazivanje rezervacije nije uspjelo.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Otkaži'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmReservation(BuildContext context, Reservation reservation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Potvrdi rezervaciju?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Želite li potvrditi rezervaciju ${reservation.reservationCode}?',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Ne'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        final provider = Provider.of<ReservationProvider>(
                          context,
                          listen: false,
                        );
                        final success = await provider.confirmReservation(
                          reservation.id,
                        );
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Rezervacija je potvrđena'),
                            ),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.errorMessage ??
                                    'Potvrda rezervacije nije uspjela.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Potvrdi'),
                    ),
                  ),
                ],
              ),
            ],
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
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.schedule;
      case 2:
        return Icons.check_circle;
      case 3:
        return Icons.done_all;
      case 4:
        return Icons.cancel;
      case 5:
        return Icons.close;
      default:
        return Icons.help;
    }
  }
}
