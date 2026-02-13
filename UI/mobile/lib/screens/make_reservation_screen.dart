import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/parking_zone_model.dart';
import '../models/reservation_model.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';

class MakeReservationScreen extends StatefulWidget {
  final ParkingZone zone;
  final ParkingSpot spot;

  const MakeReservationScreen({
    required this.zone,
    required this.spot,
  });

  @override
  State<MakeReservationScreen> createState() => _MakeReservationScreenState();
}

class _MakeReservationScreenState extends State<MakeReservationScreen> {
  late DateTime _startTime;
  late DateTime _endTime;
  bool _requiresDisabledSpot = false;
  double _calculatedPrice = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now().add(const Duration(hours: 1));
    _endTime = _startTime.add(const Duration(hours: 1));
    _calculatePrice();
  }

  void _calculatePrice() {
    final duration = _endTime.difference(_startTime);
    final hours = duration.inHours + (duration.inMinutes % 60 > 0 ? 1 : 0);
    setState(() {
      _calculatedPrice = hours * widget.zone.pricePerHour;
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStartTime ? _startTime : _endTime),
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = DateTime(
            _startTime.year,
            _startTime.month,
            _startTime.day,
            picked.hour,
            picked.minute,
          );
          if (_startTime.isAfter(_endTime)) {
            _endTime = _startTime.add(const Duration(hours: 1));
          }
        } else {
          _endTime = DateTime(
            _endTime.year,
            _endTime.month,
            _endTime.day,
            picked.hour,
            picked.minute,
          );
        }
        _calculatePrice();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final duration = _endTime.difference(_startTime);
    final durationText = '${duration.inHours}h ${duration.inMinutes % 60}m';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Napravi rezervaciju'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.zone.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.spot.spotCode,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.zone.address}, ${widget.zone.city}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Vrijeme rezervacije',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            _buildTimeSelector(
              label: 'Vrijeme početka',
              time: _startTime,
              onTap: () => _selectTime(context, true),
            ),
            const SizedBox(height: 12),

            _buildTimeSelector(
              label: 'Vrijeme završetka',
              time: _endTime,
              onTap: () => _selectTime(context, false),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        durationText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Trajanje',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${_calculatedPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Ukupna cijena',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.wheelchair_pickup,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: const Text('Parking za invalide'),
                  ),
                  Switch(
                    value: _requiresDisabledSpot,
                    onChanged: (value) {
                      setState(() => _requiresDisabledSpot = value);
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: Consumer<ReservationProvider>(
                builder: (context, provider, _) {
                  return ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () => _makeReservation(context, authProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Rezerviši mjesto',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required DateTime time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.access_time,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _makeReservation(
      BuildContext context, AuthProvider authProvider) async {
    final reservationProvider =
        Provider.of<ReservationProvider>(context, listen: false);

    final reservationData = {
      'userId': authProvider.user!.id,
      'parkingZoneId': widget.zone.id,
      'parkingSpotId': widget.spot.id,
      'reservationStart': _startTime.toIso8601String(),
      'reservationEnd': _endTime.toIso8601String(),
      'requiresDisabledSpot': _requiresDisabledSpot,
    };

    final success = await reservationProvider.createReservation(reservationData);

    if (success) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/reservation-confirmed',
        (route) => false,
        arguments: {
          'zone': widget.zone,
          'spot': widget.spot,
          'startTime': _startTime,
          'endTime': _endTime,
          'price': _calculatedPrice,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reservationProvider.errorMessage ?? 'Greška pri rezervaciji'),
        ),
      );
    }
  }
}
