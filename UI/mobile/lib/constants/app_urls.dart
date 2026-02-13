class AppUrls {
  static const String baseUrl = 'https://elina-disinclined-fulsomely.ngrok-free.dev/api';
  
  // Auth endpoints
  static const String login = '$baseUrl/users/login';
  static const String register = '$baseUrl/users/register';
  
  // ParkingZone endpoints
  static const String parkingZones = '$baseUrl/parkingzones';
  
  // Reservation endpoints
  static const String reservations = '$baseUrl/reservation';
  
  // Payment endpoints
  static const String payments = '$baseUrl/payment';
  
  // Notification endpoints
  static const String notifications = '$baseUrl/notification';
  
  // Review endpoints
  static const String reviews = '$baseUrl/reviews';
  
  // Preference endpoints
  static const String preferences = '$baseUrl/preferences';
}
