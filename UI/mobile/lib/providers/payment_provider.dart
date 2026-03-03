import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../models/payment_model.dart';
import '../services/api_service.dart';

class PaymentProvider extends ChangeNotifier {
  List<Payment> _payments = [];
  List<Payment> _walletPayments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Payment> get payments => _payments;
  List<Payment> get walletPayments => _walletPayments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<Payment> createPayment({
    int? reservationId,
    int? walletId,
    required int userId,
    required double amount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.createPayment(
        reservationId: reservationId,
        walletId: walletId,
        userId: userId,
        amount: amount,
      );

      final payment = Payment.fromJson(result);
      _payments.add(payment);
      notifyListeners();
      return payment;
    } catch (e) {
      log('PaymentProvider.createPayment error: $e');
      _errorMessage = 'Došlo je do greške pri kreiranju plaćanja.';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> presentPaymentSheet({required String clientSecret}) async {
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
      log('PaymentProvider.presentPaymentSheet StripeException: ${e.error.message}');
      _errorMessage = 'Došlo je do greške pri plaćanju.';
      notifyListeners();
      return false;
    } catch (e) {
      log('PaymentProvider.presentPaymentSheet error: $e');
      _errorMessage = 'Došlo je do greške pri plaćanju.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmPayment({required int paymentId}) async {
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
      log('PaymentProvider.confirmPayment error: $e');
      _errorMessage = 'Došlo je do greške pri potvrdi plaćanja.';
      notifyListeners();
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
      final result = await ApiService.getPayments(userId: userId);
      _payments = (result['results'] as List)
          .map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      log('PaymentProvider.getUserPayments error: $e');
      _errorMessage = 'Došlo je do greške pri učitavanju plaćanja.';
      notifyListeners();
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
      await ApiService.refundPayment(paymentId: paymentId, reason: reason);
      final index = _payments.indexWhere((p) => p.id == paymentId);
      if (index != -1) {
        _payments[index].status = 5;
      }
      notifyListeners();
      return true;
    } catch (e) {
      log('PaymentProvider.refundPayment error: $e');
      _errorMessage = 'Došlo je do greške pri vraćanju plaćanja.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getWalletPayments({required int walletId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.getPayments(walletId: walletId);

      _walletPayments = (result['results'] as List)
          .map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList();

      _errorMessage = null;
    } catch (e) {
      log('PaymentProvider.getWalletPayments error: $e');
      _errorMessage = 'Došlo je do greške pri učitavanju transakcija novčanika.';
      debugPrint('Greška pri učitavanju transakcija novčanika: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
