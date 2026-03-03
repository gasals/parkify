import 'package:http/http.dart' as http;
import 'package:mobile/models/vehicle_model.dart';
import 'dart:convert';
import 'dart:developer';
import '../constants/app_urls.dart';

class ApiService {
  static String? _token;
  static const Duration _timeout = Duration(seconds: 30);

  static void setToken(String token) => _token = token;
  static void logout() => _token = null;
  static String? getToken() => _token;

  static Map<String, String> _getHeaders() => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
    'ngrok-skip-browser-warning': 'true',
  };

  static Future<Map<String, dynamic>> _handleResponse(
    http.Response response,
  ) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      _token = null;
      throw Exception('Neautorizovan pristup');
    } else if (response.statusCode == 400) {
      throw Exception('Pogrešan zahtjev');
    }
    throw Exception('Greška: ${response.statusCode}');
  }

  static Future<Map<String, String>> _buildQueryParams({
    int? page,
    int? pageSize,
    Map<String, dynamic>? filters,
  }) async {
    final params = <String, String>{};
    if (page != null) params['page'] = page.toString();
    if (pageSize != null) params['pageSize'] = pageSize.toString();
    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          params[key] = value.toString();
        }
      });
    }
    return params;
  }

  static Uri _buildUri(String endpoint, Map<String, String> params) =>
      Uri.parse(
        endpoint,
      ).replace(queryParameters: params.isNotEmpty ? params : null);

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppUrls.login}?username=$username&password=$password'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      final data = await _handleResponse(response);

      if (data.containsKey('token')) {
        setToken(data['token']);
      }
      return data;
    } catch (e) {
      log('ApiService.login error: $e');
      throw Exception('Login greška');
    }
  }

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.register),
            headers: _getHeaders(),
            body: jsonEncode(userData),
          )
          .timeout(_timeout);

      final data = await _handleResponse(response);

      if (data.containsKey('token')) {
        setToken(data['token']);
      }
      return data;
    } catch (e) {
      log('ApiService.register error: $e');
      throw Exception('Registracija greška');
    }
  }

  static Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppUrls.users}/$userId'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.getUserById error: $e');
      throw Exception('Greška pri preuzimanju korisnika');
    }
  }

  static Future<Map<String, dynamic>> updateUser({
    required int userId,
    required String email,
    required String firstName,
    required String lastName,
    required String? phoneNumber,
  }) async {
    try {
      final body = {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
      };

      final response = await http
          .put(
            Uri.parse('${AppUrls.users}/$userId'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.updateUser error: $e');
      throw Exception('Greška pri ažuriranju korisnika');
    }
  }

  static Future<bool> changePassword({
    required int userId,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      final body = {'password': password, 'passwordConfirm': passwordConfirm};

      final response = await http
          .put(
            Uri.parse('${AppUrls.users}/$userId'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      await _handleResponse(response);
      return true;
    } catch (e) {
      log('ApiService.changePassword error: $e');
      throw Exception('Greška pri promjeni lozinke');
    }
  }

  static Future<Map<String, dynamic>> getAllCities({
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final params = await _buildQueryParams(page: page, pageSize: pageSize);
      final response = await http
          .get(_buildUri(AppUrls.cities, params), headers: _getHeaders())
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.getAllCities error: $e');
      throw Exception('Greška pri učitavanju gradova');
    }
  }

  static Future<Map<String, dynamic>> getCityById(int cityId) async {
    try {
      final response = await http
          .get(Uri.parse('${AppUrls.cities}/$cityId'), headers: _getHeaders())
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.getCityById error: $e');
      throw Exception('Greška pri učitavanju grada');
    }
  }

  static Future<Map<String, dynamic>> getParkingZones({
    int page = 1,
    int pageSize = 10,
    bool includeSpots = true,
  }) async {
    try {
      final params = await _buildQueryParams(
        page: page,
        pageSize: pageSize,
        filters: {'includeSpots': includeSpots},
      );

      final response = await http
          .get(_buildUri(AppUrls.parkingZones, params), headers: _getHeaders())
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.getParkingZones error: $e');
      throw Exception('Greška pri učitavanju parking zona');
    }
  }

  static Future<Map<String, dynamic>> getParkingZoneById(int id) async {
    try {
      final response = await http
          .get(Uri.parse('${AppUrls.parkingZones}/$id'), headers: _getHeaders())
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.getParkingZoneById error: $e');
      throw Exception('Greška pri učitavanju parking zone');
    }
  }

  static Future<Map<String, dynamic>> getParkingSpotsByZoneId(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppUrls.parkingSpots}?parkingZoneId=$id'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.getParkingSpotsByZoneId error: $e');
      throw Exception('Greška pri učitavanju parking mjesta');
    }
  }

  static Future<Map<String, dynamic>> createReservation(
    Map<String, dynamic> reservationData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.reservations),
            headers: _getHeaders(),
            body: jsonEncode(reservationData),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.createReservation error: $e');
      throw Exception('Greška pri kreiranju rezervacije');
    }
  }

  static Future<Map<String, dynamic>> getUserReservations({
    required int userId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final params = await _buildQueryParams(
        page: page,
        pageSize: pageSize,
        filters: {'userId': userId},
      );

      final response = await http
          .get(_buildUri(AppUrls.reservations, params), headers: _getHeaders())
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.getUserReservations error: $e');
      throw Exception('Greška pri učitavanju rezervacija');
    }
  }

  static Future<Map<String, dynamic>> cancelReservation(
    int reservationId,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.reservations}/$reservationId'),
            headers: _getHeaders(),
            body: jsonEncode({'status': 5}),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.cancelReservation error: $e');
      throw Exception('Greška pri otkazivanju rezervacije');
    }
  }

  static Future<Map<String, dynamic>> createPayment({
    int? reservationId,
    int? walletId,
    required int userId,
    required double amount,
  }) async {
    try {
      final body = {
        'reservationId': reservationId,
        'walletId': walletId,
        'userId': userId,
        'amount': amount,
        'currency': 'bam',
      };

      final response = await http
          .post(
            Uri.parse('${AppUrls.payments}/create-with-intent'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.createPayment error: $e');
      throw Exception('Greška pri kreiranju plaćanja');
    }
  }

  static Future<Map<String, dynamic>> confirmPayment({
    required int paymentId,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.payments}/$paymentId/confirm'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.confirmPayment error: $e');
      throw Exception('Greška pri potvrdi plaćanja');
    }
  }

  static Future<Map<String, dynamic>> getPayments({
    int? userId,
    int? walletId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final params = await _buildQueryParams(
        page: page,
        pageSize: pageSize,
        filters: {'userId': userId, 'walletId': walletId},
      );

      final response = await http
          .get(_buildUri(AppUrls.payments, params), headers: _getHeaders())
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.getPayments error: $e');
      throw Exception('Greška pri učitavanju plaćanja');
    }
  }

  static Future<Map<String, dynamic>> refundPayment({
    required int paymentId,
    required String reason,
  }) async {
    try {
      final body = {'reason': reason};

      final response = await http
          .put(
            Uri.parse('${AppUrls.payments}/$paymentId/refund'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.refundPayment error: $e');
      throw Exception('Greška pri vraćanju plaćanja');
    }
  }

  static Future<Map<String, dynamic>> getUserPreference({
    required int userId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppUrls.preferences}/user/$userId'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.getUserPreference error: $e');
      throw Exception('Greška pri učitavanju preference');
    }
  }

  static Future<Map<String, dynamic>> updateUserPreferences({
    required int userId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.preferences}/user/$userId'),
            headers: _getHeaders(),
            body: jsonEncode(preferences),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.updateUserPreferences error: $e');
      throw Exception('Greška pri ažuriranju preference');
    }
  }

  static Future<Map<String, dynamic>> createReview(
    Map<String, dynamic> reviewData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.reviews),
            headers: _getHeaders(),
            body: jsonEncode(reviewData),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.createReview error: $e');
      throw Exception('Greška pri kreiranju recenzije');
    }
  }

  static Future<Map<String, dynamic>> getZoneReviews({
    required int parkingZoneId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final params = await _buildQueryParams(
        page: page,
        pageSize: pageSize,
        filters: {'parkingZoneId': parkingZoneId},
      );

      final response = await http
          .get(_buildUri(AppUrls.reviews, params), headers: _getHeaders())
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.getZoneReviews error: $e');
      throw Exception('Greška pri učitavanju recenzija');
    }
  }

  static Future<Map<String, dynamic>> getUserNotifications({
    required int userId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final params = await _buildQueryParams(
        page: page,
        pageSize: pageSize,
        filters: {'userId': userId},
      );

      final response = await http
          .get(_buildUri(AppUrls.notifications, params), headers: _getHeaders())
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.getUserNotifications error: $e');
      throw Exception('Greška pri učitavanju notifikacija');
    }
  }

  static Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    required int rating,
    required String? reviewText,
  }) async {
    try {
      final body = {'rating': rating, 'reviewText': reviewText};

      final response = await http
          .put(
            Uri.parse('${AppUrls.reviews}/$reviewId'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.updateReview error: $e');
      throw Exception('Greška pri ažuriranju recenzije');
    }
  }

  static Future<Map<String, dynamic>> getUserVehicles(int userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppUrls.vehicles}?UserId=$userId'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.getUserVehicles error: $e');
      throw Exception('Greška pri učitavanju vozila');
    }
  }

  static Future<Vehicle> addVehicle(Vehicle vehicle) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.vehicles),
            headers: _getHeaders(),
            body: jsonEncode(vehicle.toJson()),
          )
          .timeout(_timeout);

      return Vehicle.fromJson(jsonDecode(response.body));
    } catch (e) {
      log('ApiService.addVehicle error: $e');
      throw Exception('Greška pri dodavanju vozila');
    }
  }

  static Future<Map<String, dynamic>> updateVehicle({
    required int vehicleId,
    required int userId,
    required String licensePlate,
    required String model,
    required String category,
  }) async {
    try {
      final body = {
        'userId': userId,
        'licensePlate': licensePlate,
        'model': model,
        'category': category,
      };

      final response = await http
          .put(
            Uri.parse('${AppUrls.vehicles}/$vehicleId'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.updateVehicle error: $e');
      throw Exception('Greška pri ažuriranju vozila');
    }
  }

  static Future<Map<String, dynamic>> getUserWallet(int userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppUrls.wallets}?UserId=$userId'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.getUserWallet error: $e');
      throw Exception('Greška pri učitavanju novčanika');
    }
  }

  static Future<dynamic> getWalletHistory(int walletId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppUrls.walletTransactions}?WalletId=$walletId'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.getWalletHistory error: $e');
      throw Exception('Greška pri učitavanju novčanika');
    }
  }

  static Future<Map<String, dynamic>> getNotifications({
    int? userId,
    bool? isRead,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final params = await _buildQueryParams(
        page: page,
        pageSize: pageSize,
        filters: {
          if (userId != null) 'userId': userId,
          if (isRead != null) 'isRead': isRead,
        },
      );

      final response = await http
          .get(_buildUri(AppUrls.notifications, params), headers: _getHeaders())
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('ApiService.getNotifications error: $e');
      throw Exception('Greška pri učitavanju notifikacija');
    }
  }

  static Future<void> sendNotification(Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppUrls.notifications}/send'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      await _handleResponse(response);
    } catch (e) {
      log('ApiService.sendNotification error: $e');
      throw Exception('Greška pri slanju notifikacije');
    }
  }

  static Future<void> sendNotificationToAll(Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppUrls.notifications}/send-all'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      await _handleResponse(response);
    } catch (e) {
      log('ApiService.sendNotificationToAll error: $e');
      throw Exception('Greška pri slanju notifikacija');
    }
  }

  static Future<void> markNotificationRead(int id) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${AppUrls.notifications}/$id/read'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }
    } catch (e) {
      log('ApiService.markNotificationRead error: $e');
      throw Exception('Greška pri označavanju notifikacije');
    }
  }
}
