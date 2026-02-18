import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../models/payment_model.dart';
import '../services/api_service.dart';

class PaymentProvider extends ChangeNotifier {
  List<Payment> _payments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<Payment> createPayment({
    required int reservationId,
    required int userId,
    required double amount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await ApiService.createPayment(
        reservationId: reservationId,
        userId: userId,
        amount: amount,
      );
      final payment = Payment.fromJson(result);
      _payments.add(payment);
      notifyListeners();
      return payment;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> presentPaymentSheet({
    required String clientSecret,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Parkify',
          style: ThemeMode.dark,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      _errorMessage = 'Stripe greška: ${e.error.message}';
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmPayment({
    required int paymentId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await ApiService.confirmPayment(paymentId: paymentId);
      final index = _payments.indexWhere((p) => p.id == paymentId);
      if (index != -1) {
        _payments[index].status = 3;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getUserPayments({required int userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await ApiService.getUserPayments(userId: userId);
      _payments = (result['results'] as List)
          .map((e) => Payment.fromJson(e))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> refundPayment({
    required int paymentId,
    required String reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await ApiService.refundPayment(
        paymentId: paymentId,
        reason: reason,
      );
      final index = _payments.indexWhere((p) => p.id == paymentId);
      if (index != -1) {
        _payments[index].status = 5;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}