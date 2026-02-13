import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'constants/app_strings.dart';
import 'providers/auth_provider.dart';
import 'providers/parking_zone_provider.dart';
import 'providers/reservation_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/parking_zone_detail_screen.dart';
import 'screens/select_parking_spot_screen.dart';
import 'screens/make_reservation_screen.dart';
import 'screens/reservation_confirmed_screen.dart';
import 'screens/my_reservations_screen.dart';
import 'models/parking_zone_model.dart';

void main() {
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
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        home: _buildHome(),
        routes: {
          '/login': (_) => LoginScreen(),
          '/home': (_) => HomeScreen(),
          '/my-reservations': (_) => MyReservationsScreen(),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/parking-zone-detail':
              final zoneId = settings.arguments as int;
              return MaterialPageRoute(
                builder: (_) => ParkingZoneDetailScreen(zoneId: zoneId),
              );
            case '/select-parking-spot':
              final zone = settings.arguments as ParkingZone;
              return MaterialPageRoute(
                builder: (_) => SelectParkingSpotScreen(zone: zone),
              );
            case '/make-reservation':
              final args = settings.arguments as Map<String, dynamic>;
              final zone = args['zone'] as ParkingZone;
              final spot = args['spot'] as ParkingSpot;
              return MaterialPageRoute(
                builder: (_) => MakeReservationScreen(zone: zone, spot: spot),
              );
            case '/reservation-confirmed':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => ReservationConfirmedScreen(
                  zone: args['zone'] as ParkingZone,
                  spot: args['spot'] as ParkingSpot,
                  startTime: args['startTime'] as DateTime,
                  endTime: args['endTime'] as DateTime,
                  price: args['price'] as double,
                ),
              );
            default:
              return null;
          }
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
