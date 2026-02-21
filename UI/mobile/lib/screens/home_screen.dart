import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';
import '../providers/preference_provider.dart';
import '../providers/city_provider.dart';
import '../screens/maps_screen.dart';
import '../screens/my_reservations_screen.dart';
import '../screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id ?? 0;

      if (mounted) {
        Provider.of<ReservationProvider>(context, listen: false)
            .getUserReservations(userId: userId);
        Provider.of<PreferenceProvider>(context, listen: false)
            .loadUserPreference(userId: userId);
        Provider.of<CityProvider>(context, listen: false).getAllCities();
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _buildCustomNavBar(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _withTopSpacing(_buildHomeTab());
      case 1:
        return _withTopSpacing(_buildWalletTab());
      case 2:
        return MapsScreen();
      case 3:
        return MyReservationsScreen();
      case 4:
        return SettingsScreen();
      default:
        return _withTopSpacing(_buildHomeTab());
    }
  }

  Widget _withTopSpacing(Widget child) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 56),
        child: child,
      ),
    );
  }

  Widget _buildCustomNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(index: 0, icon: Icons.home, label: 'Home'),
          _buildNavItem(index: 1, icon: Icons.account_balance_wallet, label: 'Novčanik'),
          GestureDetector(
            onTap: () => _onItemTapped(2),
            child: Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          _buildNavItem(index: 3, icon: Icons.calendar_today, label: 'Rezervacije'),
          _buildNavItem(index: 4, icon: Icons.settings, label: 'Postavke'),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_parking, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Dobrodošli, ${authProvider.user?.firstName}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final clientSecret = "pi_3T1BX3JZZ3t7DnXE1vJJrSYi_secret_A6HPav1c3aS62VdRc3TJuzzp3";

                try {
                  print('=== STRIPE TEST ===');
                  print('ClientSecret: $clientSecret');
                  print('PublishableKey: ${Stripe.publishableKey}');
                  print('Merchant: ${Stripe.merchantIdentifier}');
                  print('URLScheme: ${Stripe.urlScheme}');

                  print('\n1. initPaymentSheet...');
                  await Stripe.instance.initPaymentSheet(
                    paymentSheetParameters: SetupPaymentSheetParameters(
                      paymentIntentClientSecret: clientSecret,
                      merchantDisplayName: 'Parkify',
                      style: ThemeMode.dark,
                    ),
                  );
                  print('✅ initPaymentSheet OK');

                  print('\n2. presentPaymentSheet...');
                  await Stripe.instance.presentPaymentSheet();
                  print('✅ presentPaymentSheet OK');

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Plaćanje uspješno!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } on StripeException catch (e) {
                  print('\n❌ StripeException');
                  print('Message: ${e.error.message}');
                  print('Code: ${e.error.code}');
                  print('Type: ${e.error.type}');

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Stripe greška: ${e.error.message}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  print('\n❌ Exception: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Test Stripe Payment', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dostupan balans',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '\$0.00',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Korisnik',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authProvider.user?.firstName ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Akcije',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj sredstva'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.money_off_rounded),
                  label: const Text('Povuci'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Prethodne transakcije',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildTransactionItem(
            title: 'Parking - Cenčić Vila',
            amount: '-\$5.00',
            date: '15 feb 2025',
            icon: Icons.local_parking,
            isDebit: true,
          ),
          _buildTransactionItem(
            title: 'Dodano sredstava',
            amount: '+\$20.00',
            date: '10 feb 2025',
            icon: Icons.add_circle,
            isDebit: false,
          ),
          _buildTransactionItem(
            title: 'Parking - Park B',
            amount: '-\$3.50',
            date: '08 feb 2025',
            icon: Icons.local_parking,
            isDebit: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String amount,
    required String date,
    required IconData icon,
    required bool isDebit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDebit ? Colors.red : Colors.green,
            ),
          ),
        ],
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
}