import 'package:http/http.dart' as http;
import 'package:mobile/models/api_models.dart';
import 'package:mobile/models/city_model.dart';
import 'package:mobile/models/notification_model.dart';
import 'package:mobile/models/parking_zone_model.dart';
import 'package:mobile/models/parking_zone_recommendation_model.dart';
import 'package:mobile/models/payment_model.dart';
import 'package:mobile/models/preference_model.dart';
import 'package:mobile/models/reservation_model.dart';
import 'package:mobile/models/request_models.dart';
import 'package:mobile/models/review_model.dart';
import 'package:mobile/models/user_model.dart';
import 'package:mobile/models/vehicle_model.dart';
import 'package:mobile/models/wallet_model.dart';
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

  static String _messageFromBody(
    String body, {
    String fallback = 'Došlo je do greške.',
  }) {
    if (body.isEmpty) return fallback;

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map) {
        final decodedMap = decoded.cast<String, Object?>();
        final error = decodedMap['error'];
        if (error is String && error.isNotEmpty) return error;

        final message = decodedMap['message'];
        if (message is String && message.isNotEmpty) return message;

        final title = decodedMap['title'];
        if (title is String && title.isNotEmpty) return title;

        final errors = decodedMap['errors'];
        if (errors is Map) {
          final messages = <String>[];

          errors.cast<Object?, Object?>().forEach((_, value) {
            if (value is List) {
              messages.addAll(value.whereType<String>());
            } else if (value is String && value.isNotEmpty) {
              messages.add(value);
            }
          });

          if (messages.isNotEmpty) {
            return messages.join('\n');
          }
        }
      }

      if (decoded is String && decoded.isNotEmpty) {
        return decoded;
      }
    } catch (_) {
      // Ignore invalid/non-JSON response bodies and use fallback text.
    }

    return fallback;
  }

  static bool _isTechnicalErrorMessage(String message) {
    final lower = message.toLowerCase();

    const technicalPatterns = [
      'clientexception',
      'socketexception',
      'failed host lookup',
      'connection refused',
      'connection reset',
      'connection closed',
      'handshakeexception',
      'os error',
      'xmlhttprequest error',
      'formatexception',
      'nosuchmethoderror',
      'null check operator used on a null value',
      "type '",
    ];

    return technicalPatterns.any(lower.contains);
  }

  static String userFriendlyError(Object error, {required String fallback}) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();

    if (message.isEmpty) {
      return fallback;
    }

    final lower = message.toLowerCase();

    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Zahtjev je istekao. Provjerite konekciju i pokušajte ponovo.';
    }

    if (_isTechnicalErrorMessage(message)) {
      return 'Došlo je do problema sa mrežom ili serverom. Pokušajte ponovo.';
    }

    if (message.length > 220) {
      return fallback;
    }

    return message;
  }

  static Never _throwWithMessage(Object error, String fallback) {
    throw Exception(userFriendlyError(error, fallback: fallback));
  }

  static Map<String, Object?> _parseJsonMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      return decoded.cast<String, Object?>();
    }

    throw Exception('Neispravan format server odgovora.');
  }

  static List<Map<String, Object?>> _parseJsonMaps(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => item.cast<String, Object?>())
          .toList();
    }

    if (decoded is Map) {
      final decodedMap = decoded.cast<String, Object?>();
      final results = decodedMap['results'];
      if (results is List) {
        return results
            .whereType<Map>()
            .map((item) => item.cast<String, Object?>())
            .toList();
      }
    }

    return const [];
  }

  static Future<Map<String, Object?>> _handleObjectResponse(
    http.Response response,
  ) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) {
        return <String, Object?>{};
      }

      return _parseJsonMap(response.body);
    } else if (response.statusCode == 401) {
      _token = null;
      throw Exception(
        _messageFromBody(response.body, fallback: 'Neautorizovan pristup'),
      );
    }

    throw Exception(
      _messageFromBody(
        response.body,
        fallback: 'Greška: ${response.statusCode}',
      ),
    );
  }

  static Future<T> _handleModelResponse<T>(
    http.Response response,
    T Function(Map<String, Object?> json) fromJson,
  ) async {
    final json = await _handleObjectResponse(response);
    return fromJson(json);
  }

  static Future<PagedResponse<T>> _handlePagedResponse<T>(
    http.Response response,
    T Function(Map<String, Object?> json) fromJson,
  ) async {
    final json = await _handleObjectResponse(response);
    return PagedResponse<T>.fromJson(json, fromJson);
  }

  static Future<List<T>> _handleListResponse<T>(
    http.Response response,
    T Function(Map<String, Object?> json) fromJson,
  ) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) {
        return <T>[];
      }

      return _parseJsonMaps(response.body).map(fromJson).toList();
    }

    if (response.statusCode == 401) {
      _token = null;
    }

    throw Exception(
      _messageFromBody(
        response.body,
        fallback: 'Greška: ${response.statusCode}',
      ),
    );
  }

  static Future<Map<String, String>> _buildQueryParams({
    int? page,
    int? pageSize,
    Map<String, Object?>? filters,
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

  static Future<AuthSession> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.login),
            headers: _getHeaders(),
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(_timeout);

      final session = await _handleModelResponse(response, AuthSession.fromJson);

      if (session.token.isNotEmpty) {
        setToken(session.token);
      }
      return session;
    } catch (e) {
      log('ApiService.login error: $e');
      _throwWithMessage(e, 'Login greška');
    }
  }

  static Future<AuthSession> register(
    UserRegistrationRequest request,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.register),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      final session = await _handleModelResponse(response, AuthSession.fromJson);

      if (session.token.isNotEmpty) {
        setToken(session.token);
      }
      return session;
    } catch (e) {
      log('ApiService.register error: $e');
      _throwWithMessage(e, 'Registracija greška');
    }
  }

  static Future<User> getUserById(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('${AppUrls.users}/$userId'), headers: _getHeaders())
          .timeout(_timeout);

      return await _handleModelResponse(response, User.fromJson);
    } catch (e) {
      log('ApiService.getUserById error: $e');
      _throwWithMessage(e, 'Greška pri preuzimanju korisnika');
    }
  }

  static Future<User> updateUser({
    required int userId,
    required UserUpdateRequestDto request,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.users}/$userId'),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      return await _handleModelResponse(response, User.fromJson);
    } catch (e) {
      log('ApiService.updateUser error: $e');
      _throwWithMessage(e, 'Greška pri ažuriranju korisnika');
    }
  }

  static Future<bool> changePassword({
    required int userId,
    required ChangePasswordRequestDto request,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.users}/$userId'),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      await _handleObjectResponse(response);
      return true;
    } catch (e) {
      log('ApiService.changePassword error: $e');
      _throwWithMessage(e, 'Greška pri promjeni lozinke');
    }
  }

  static Future<PagedResponse<City>> getAllCities({
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final params = await _buildQueryParams(page: page, pageSize: pageSize);
      final response = await http
          .get(_buildUri(AppUrls.cities, params), headers: _getHeaders())
          .timeout(_timeout);

      return await _handlePagedResponse(response, City.fromJson);
    } catch (e) {
      log('ApiService.getAllCities error: $e');
      _throwWithMessage(e, 'Greška pri učitavanju gradova');
    }
  }

  static Future<City> getCityById(int cityId) async {
    try {
      final response = await http
          .get(Uri.parse('${AppUrls.cities}/$cityId'), headers: _getHeaders())
          .timeout(_timeout);

      return await _handleModelResponse(response, City.fromJson);
    } catch (e) {
      log('ApiService.getCityById error: $e');
      _throwWithMessage(e, 'Greška pri učitavanju grada');
    }
  }

  static Future<PagedResponse<ParkingZone>> getParkingZones({
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

      return await _handlePagedResponse(response, ParkingZone.fromJson);
    } catch (e) {
      log('ApiService.getParkingZones error: $e');
      _throwWithMessage(e, 'Greška pri učitavanju parking zona');
    }
  }

  static Future<ParkingZone> getParkingZoneById(int id) async {
    try {
      final response = await http
          .get(Uri.parse('${AppUrls.parkingZones}/$id'), headers: _getHeaders())
          .timeout(_timeout);

      return await _handleModelResponse(response, ParkingZone.fromJson);
    } catch (e) {
      log('ApiService.getParkingZoneById error: $e');
      _throwWithMessage(e, 'Greška pri učitavanju parking zone');
    }
  }

  static Future<List<ParkingZone>> getRecommendedParkingZones({
    required int userId,
    int count = 5,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${AppUrls.parkingZones}/recommendations/$userId?count=$count',
            ),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return await _handleListResponse(response, ParkingZone.fromJson);
    } catch (e) {
      log('ApiService.getRecommendedParkingZones error: $e');
      _throwWithMessage(e, 'Greška pri učitavanju preporučenih zona');
    }
  }

  static Future<List<ParkingZoneRecommendation>>
  getExplainedRecommendedParkingZones({
    required int userId,
    int count = 5,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${AppUrls.parkingZones}/recommendations/$userId/explained?count=$count',
            ),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return await _handleListResponse(
        response,
        ParkingZoneRecommendation.fromJson,
      );
    } catch (e) {
      log('ApiService.getExplainedRecommendedParkingZones error: $e');
      _throwWithMessage(e, 'Greška pri učitavanju preporučenih zona');
    }
  }

  static Future<PagedResponse<ParkingSpot>> getParkingSpotsByZoneId(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppUrls.parkingSpots}?parkingZoneId=$id'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return await _handlePagedResponse(response, ParkingSpot.fromJson);
    } catch (e) {
      log('ApiService.getParkingSpotsByZoneId error: $e');
      _throwWithMessage(e, 'Greška pri učitavanju parking mjesta');
    }
  }

  static Future<Reservation> createReservation(
    ReservationCreateRequest request,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.reservations),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

          return await _handleModelResponse(response, Reservation.fromJson);
    } catch (e) {
      log('ApiService.createReservation error: $e');
      _throwWithMessage(e, 'Greška pri kreiranju rezervacije');
    }
  }

  static Future<PagedResponse<Reservation>> getUserReservations({
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

      return await _handlePagedResponse(response, Reservation.fromJson);
    } catch (e) {
      log('ApiService.getUserReservations error: $e');
      _throwWithMessage(e, 'Greška pri učitavanju rezervacija');
    }
  }

  static Future<Reservation> cancelReservation(
    int reservationId,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.reservations}/$reservationId'),
            headers: _getHeaders(),
            body: jsonEncode({'status': ReservationStatus.cancelled.value}),
          )
          .timeout(_timeout);

      return await _handleModelResponse(response, Reservation.fromJson);
    } catch (e) {
      log('ApiService.cancelReservation error: $e');
      _throwWithMessage(e, 'Greška pri otkazivanju rezervacije');
    }
  }

  static Future<PaymentIntentResult> createPayment(
    PaymentCreateRequest request,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppUrls.payments}/create-with-intent'),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      return await _handleModelResponse(response, PaymentIntentResult.fromJson);
    } catch (e) {
      log('ApiService.createPayment error: $e');
      _throwWithMessage(e, 'Greška pri kreiranju plaćanja');
    }
  }

  static Future<Payment> confirmPayment({
    required int paymentId,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.payments}/$paymentId/confirm'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return await _handleModelResponse(response, Payment.fromJson);
    } catch (e) {
      log('ApiService.confirmPayment error: $e');
      _throwWithMessage(e, 'Greška pri potvrdi plaćanja');
    }
  }

  static Future<PagedResponse<Payment>> getPayments({
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

      return await _handlePagedResponse(response, Payment.fromJson);
    } catch (e) {
      log('ApiService.getPayments error: $e');
      _throwWithMessage(e, 'Greška pri učitavanju plaćanja');
    }
  }

  static Future<Payment> refundPayment({
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

      return await _handleModelResponse(response, Payment.fromJson);
    } catch (e) {
      log('ApiService.refundPayment error: $e');
      _throwWithMessage(e, 'Greška pri vraćanju plaćanja');
    }
  }

  static Future<Preference> getUserPreference({
    required int userId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppUrls.preferences}/user/$userId'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return await _handleModelResponse(response, Preference.fromJson);
    } catch (e) {
      log('ApiService.getUserPreference error: $e');
      _throwWithMessage(e, 'Greška pri učitavanju preference');
    }
  }

  static Future<Preference> updateUserPreferences({
    required int userId,
    required PreferenceUpdateRequest request,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.preferences}/user/$userId'),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      return await _handleModelResponse(response, Preference.fromJson);
    } catch (e) {
      log('ApiService.updateUserPreferences error: $e');
      _throwWithMessage(e, 'Greška pri ažuriranju preference');
    }
  }

  static Future<Review> createReview(
    ReviewUpsertRequest request,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.reviews),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

          return await _handleModelResponse(response, Review.fromJson);
    } catch (e) {
      log('ApiService.createReview error: $e');
      _throwWithMessage(e, 'Greška pri kreiranju recenzije');
    }
  }

  static Future<PagedResponse<Review>> getZoneReviews({
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

      return await _handlePagedResponse(response, Review.fromJson);
    } catch (e) {
      log('ApiService.getZoneReviews error: $e');
      _throwWithMessage(e, 'Greška pri učitavanju recenzija');
    }
  }

  static Future<PagedResponse<AppNotification>> getUserNotifications({
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

      return await _handlePagedResponse(response, AppNotification.fromJson);
    } catch (e) {
      log('ApiService.getUserNotifications error: $e');
      _throwWithMessage(e, 'Greška pri učitavanju notifikacija');
    }
  }

  static Future<Review> updateReview({
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

      return await _handleModelResponse(response, Review.fromJson);
    } catch (e) {
      log('ApiService.updateReview error: $e');
      _throwWithMessage(e, 'Greška pri ažuriranju recenzije');
    }
  }

  static Future<PagedResponse<Vehicle>> getUserVehicles(int userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppUrls.vehicles}?UserId=$userId'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return await _handlePagedResponse(response, Vehicle.fromJson);
    } catch (e) {
      log('ApiService.getUserVehicles error: $e');
      _throwWithMessage(e, 'Greška pri učitavanju vozila');
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

      final data = await _handleObjectResponse(response);
      return Vehicle.fromJson(data);
    } catch (e) {
      log('ApiService.addVehicle error: $e');
      _throwWithMessage(e, 'Greška pri dodavanju vozila');
    }
  }

  static Future<Vehicle> updateVehicle({
    required int vehicleId,
    required VehicleUpdateRequest request,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.vehicles}/$vehicleId'),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      return await _handleModelResponse(response, Vehicle.fromJson);
    } catch (e) {
      log('ApiService.updateVehicle error: $e');
      _throwWithMessage(e, 'Greška pri ažuriranju vozila');
    }
  }

  static Future<PagedResponse<Wallet>> getUserWallet(int userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppUrls.wallets}?UserId=$userId'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return await _handlePagedResponse(response, Wallet.fromJson);
    } catch (e) {
      log('ApiService.getUserWallet error: $e');
      _throwWithMessage(e, 'Greška pri učitavanju novčanika');
    }
  }

  static Future<PagedResponse<WalletTransaction>> getWalletHistory(int walletId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppUrls.walletTransactions}?WalletId=$walletId'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return await _handlePagedResponse(response, WalletTransaction.fromJson);
    } catch (e) {
      log('ApiService.getWalletHistory error: $e');
      _throwWithMessage(e, 'Greška pri učitavanju novčanika');
    }
  }

  static Future<PagedResponse<AppNotification>> getNotifications({
    int? userId,
    bool? isRead,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final params = await _buildQueryParams(
        page: page,
        pageSize: pageSize,
        filters: {'userId': userId, 'isRead': isRead},
      );

      final response = await http
          .get(_buildUri(AppUrls.notifications, params), headers: _getHeaders())
          .timeout(_timeout);

      return await _handlePagedResponse(response, AppNotification.fromJson);
    } catch (e) {
      log('ApiService.getNotifications error: $e');
      _throwWithMessage(e, 'Greška pri učitavanju notifikacija');
    }
  }

  static Future<void> sendNotification(NotificationSendRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppUrls.notifications}/send'),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

          await _handleObjectResponse(response);
    } catch (e) {
      log('ApiService.sendNotification error: $e');
      _throwWithMessage(e, 'Greška pri slanju notifikacije');
    }
  }

  static Future<void> sendNotificationToAll(NotificationSendRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppUrls.notifications}/send-all'),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

          await _handleObjectResponse(response);
    } catch (e) {
      log('ApiService.sendNotificationToAll error: $e');
      _throwWithMessage(e, 'Greška pri slanju notifikacija');
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

      await _handleObjectResponse(response);
    } catch (e) {
      log('ApiService.markNotificationRead error: $e');
      _throwWithMessage(e, 'Greška pri označavanju notifikacije');
    }
  }
}
