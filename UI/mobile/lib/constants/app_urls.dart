class AppUrls {
  static const String baseUrl =
      'http://10.0.2.2:5050/api';

  static const String users = '$baseUrl/users';
  static const String login = '$users/login';
  static const String register = '$users/register';

  static const String parkingZones = '$baseUrl/parkingzones';

  static const String parkingSpots = '$baseUrl/parkingspots';

  static const String reservations = '$baseUrl/reservation';

  static const String payments = '$baseUrl/payments';

  static const String notifications = '$baseUrl/notification';

  static const String reviews = '$baseUrl/review';

  static const String preferences = '$baseUrl/preferences';

  static const String cities = '$baseUrl/city';

  static const String vehicles = '$baseUrl/vehicle';

  static const String wallets = '$baseUrl/wallet';

  static const String walletTransactions = '$baseUrl/wallettransaction';

  static const String navigation =
      'https://www.google.com/maps/dir/?api=1&destination={lat},{lng}&travelmode=driving';
}
