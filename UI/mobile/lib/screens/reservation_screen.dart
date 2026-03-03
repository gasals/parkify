import 'package:flutter/material.dart';
import 'package:mobile/providers/payment_provider.dart';
import 'package:mobile/providers/vehicle_provider.dart';
import 'package:mobile/providers/wallet_provider.dart';
import 'package:mobile/services/navigation_service.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/parking_zone_model.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';

class ReservationScreen extends StatefulWidget {
  final ParkingZone parkingZone;
  final ParkingSpot parkingSpot;

  const ReservationScreen({
    Key? key,
    required this.parkingZone,
    required this.parkingSpot,
  }) : super(key: key);

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  late DateTime _startTime;
  late DateTime _endTime;
  bool _isDailyOption = false;
  String _reservationCode = '';
  bool _isConfirmed = false;

  static const int _maxHours = 23;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now().add(const Duration(hours: 1));
    _endTime = _startTime.add(const Duration(hours: 1));
  }

  int get _durationHours {
    final diff = _endTime.difference(_startTime);
    return (diff.inMinutes / 60).ceil();
  }

  double get _calculatedPrice =>
      widget.parkingZone.pricePerHour * _durationHours;

  String _formatDateTime(DateTime dt) {
    final date =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  Future<void> _pickStartDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
    );
    if (time == null) return;

    final newStart = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      _startTime = newStart;
      if (_isDailyOption) {
        _endTime = _startTime.add(const Duration(hours: 24));
      } else {
        final currentDuration = _endTime.difference(_startTime);
        final clampedDuration =
            currentDuration > const Duration(hours: _maxHours)
            ? const Duration(hours: _maxHours)
            : currentDuration < const Duration(hours: 1)
            ? const Duration(hours: 1)
            : currentDuration;
        _endTime = _startTime.add(clampedDuration);
      }
    });
  }

  Future<void> _pickEndDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endTime,
      firstDate: _startTime,
      lastDate: _startTime.add(const Duration(hours: _maxHours)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime),
    );
    if (time == null) return;

    final newEnd = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (newEnd.isBefore(_startTime) || newEnd.isAtSameMomentAs(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Završetak mora biti nakon početka.')),
      );
      return;
    }

    final diff = newEnd.difference(_startTime);
    if (diff.inMinutes > _maxHours * 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maksimalno trajanje rezervacije je $_maxHours sati.'),
        ),
      );
      return;
    }

    setState(() {
      _endTime = newEnd;
      _isDailyOption = false;
    });
  }

  void _applyDailyOption() {
    setState(() {
      _isDailyOption = true;
      _endTime = _startTime.add(const Duration(hours: 24));
    });
  }

  Future<void> _makeReservation(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reservationProvider = Provider.of<ReservationProvider>(
      context,
      listen: false,
    );
    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    try {
      final licensePlate = context
          .read<VehicleProvider>()
          .selectedVehicle
          ?.licensePlate;
      if (licensePlate == null || licensePlate.isEmpty) {
        throw Exception('Molimo odaberite vozilo prije rezervacije.');
      }

      final reservationData = {
        'userId': authProvider.user!.id,
        'parkingZoneId': widget.parkingZone.id,
        'parkingSpotId': widget.parkingSpot.id,
        'reservationStart': _startTime.toIso8601String(),
        'reservationEnd': _endTime.toIso8601String(),
        'vehicleLicensePlate': licensePlate,
      };

      final reservation = await reservationProvider.createReservation(
        reservationData,
      );

      if (reservation.id == 0) {
        throw Exception('Greška pri kreiranju rezervacije');
      }

      String finalCode = reservation.reservationCode;

      if (reservation.finalPrice > 0) {
        final payment = await paymentProvider.createPayment(
          reservationId: reservation.id,
          userId: authProvider.user!.id,
          amount: reservation.finalPrice,
        );

        if (payment.id == 0) {
          throw Exception('Greška pri kreiranju plaćanja');
        }

        final paymentSuccess = await paymentProvider.presentPaymentSheet(
          clientSecret: payment.clientSecret,
        );

        if (!paymentSuccess) {
          throw Exception('Plaćanje je otkazano');
        }

        final confirmed = await paymentProvider.confirmPayment(
          paymentId: payment.id,
        );

        if (!confirmed) {
          throw Exception('Plaćanje nije potvrđeno');
        }
        finalCode = payment.paymentCode;
      }

      await walletProvider.fetchUserWallet(authProvider.user!.id);

      setState(() {
        _reservationCode = finalCode;
        _isConfirmed = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Neuspješno kreiranje rezervacije: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isConfirmed) {
      return _buildConfirmedScreen(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezerviši mjesto'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.parkingZone.name} - ${widget.parkingSpot.spotCode}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Početak rezervacije',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _DateTimePickerTile(
                dateTime: _startTime,
                onTap: () => _pickStartDateTime(context),
              ),
              const SizedBox(height: 16),

              const Text(
                'Završetak rezervacije',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _DateTimePickerTile(
                dateTime: _endTime,
                onTap: () => _pickEndDateTime(context),
                enabled: !_isDailyOption,
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _isDailyOption
                    ? () => setState(() => _isDailyOption = false)
                    : _applyDailyOption,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _isDailyOption
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary,
                      width: _isDailyOption ? 0 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isDailyOption
                            ? Icons.check_circle
                            : Icons.wb_sunny_outlined,
                        color: _isDailyOption
                            ? Colors.white
                            : AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Dnevna opcija (24h)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _isDailyOption
                              ? Colors.white
                              : AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      if (_isDailyOption)
                        Text(
                          '24h',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Trajanje',
                      _durationHours >= 24
                          ? '24h (dnevna)'
                          : '${_durationHours.toStringAsFixed(1)}h',
                    ),
                    const Divider(height: 16),
                    _buildDetailRow(
                      'Ukupno',
                      '${_calculatedPrice.toStringAsFixed(2)} KM',
                      valueStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: Consumer2<ReservationProvider, PaymentProvider>(
                  builder: (context, reservationProvider, paymentProvider, _) {
                    final isLoading =
                        reservationProvider.isLoading ||
                        paymentProvider.isLoading;
                    return ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => _makeReservation(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Rezerviši mjesto',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmedScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezervacija potvrđena'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Plaćanje uspješno!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Kod: $_reservationCode',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _buildDetailRow('Parking', widget.parkingZone.name),
              _buildDetailRow('Mjesto', widget.parkingSpot.spotCode),
              _buildDetailRow('Početak', _formatDateTime(_startTime)),
              _buildDetailRow('Završetak', _formatDateTime(_endTime)),
              _buildDetailRow(
                'Trajanje',
                _durationHours >= 24
                    ? '24h (dnevna)'
                    : '${_durationHours.toStringAsFixed(1)}h',
              ),
              _buildDetailRow(
                'Cijena',
                '${_calculatedPrice.toStringAsFixed(2)} KM',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _startNavigation,
                  icon: const Icon(Icons.navigation),
                  label: const Text(
                    'Kreni na parking',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                  ),
                  child: Text(
                    'Nazad na mapu',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startNavigation() {
    NavigationService.startNavigation(
      destinationLat: widget.parkingZone.latitude,
      destinationLng: widget.parkingZone.longitude,
      destinationName: widget.parkingZone.name,
    ).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška prilikom pokretanja navigacije: $error'), backgroundColor: Colors.red),
      );
    });
  }

  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style:
                valueStyle ??
                const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _DateTimePickerTile extends StatelessWidget {
  final DateTime dateTime;
  final VoidCallback onTap;
  final bool enabled;

  const _DateTimePickerTile({
    required this.dateTime,
    required this.onTap,
    this.enabled = true,
  });

  String get _formatted {
    final date =
        '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date  $time';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? null : Colors.grey.withOpacity(0.05),
          border: Border.all(
            color: enabled ? AppColors.border : Colors.grey.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatted,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: enabled ? null : Colors.grey,
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 18,
              color: enabled ? AppColors.primary : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
