import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:mobile/constants/stripe_keys.dart';
import 'package:mobile/providers/city_provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/providers/payment_provider.dart';
import 'package:mobile/providers/preference_provider.dart';
import 'package:mobile/providers/review_provider.dart';
import 'package:mobile/providers/vehicle_provider.dart';
import 'package:mobile/providers/wallet_provider.dart';
import 'package:mobile/screens/notifications_screen.dart';
import 'package:mobile/screens/register_screen.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'constants/app_strings.dart';
import 'providers/auth_provider.dart';
import 'providers/parking_zone_provider.dart';
import 'providers/reservation_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/my_reservations_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Stripe.publishableKey = StripeKeys.publishableKey;
  Stripe.merchantIdentifier = StripeKeys.merchantIdentifier;
  Stripe.urlScheme = StripeKeys.urlScheme;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ParkingZoneProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => PreferenceProvider()),
        ChangeNotifierProvider(create: (_) => CityProvider()),
        ChangeNotifierProvider(
          create: (context) =>
              ReviewProvider(Provider.of<AuthProvider>(context, listen: false)),
        ),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: _buildHome(),
        routes: {
          '/login': (_) => LoginScreen(),
          '/home': (_) => HomeScreen(),
          '/my-reservations': (_) => MyReservationsScreen(),
          '/settings': (_) => SettingsScreen(),
          '/register': (_) => RegisterScreen(),
          '/notifications': (context) => const NotificationsScreen(),
        },
      ),
    );
  }

  Widget _buildHome() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return authProvider.isAuthenticated ? HomeScreen() : LoginScreen();
      },
    );
  }
}
