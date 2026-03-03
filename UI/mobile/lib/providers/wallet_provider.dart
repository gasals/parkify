import 'package:flutter/material.dart';
import 'dart:developer';
import '../models/wallet_model.dart';
import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  Wallet? _userWallet;
  bool _isLoading = false;
  String? _errorMessage;
  List<WalletTransaction> _walletTransactions = [];

  Wallet? get userWallet => _userWallet;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<WalletTransaction> get walletTransactions => _walletTransactions;

  Future<void> fetchUserWallet(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await ApiService.getUserWallet(userId);

      final List<dynamic> results = result['results'] ?? [];
      if (results.isNotEmpty) {
        _userWallet = Wallet.fromJson(results.first as Map<String, dynamic>);
      }

      _errorMessage = null;
    } catch (e) {
      log('WalletProvider.fetchUserWallet error: $e');
      _errorMessage = 'Došlo je do greške pri učitavanju novčanika.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getWalletHistory({required int walletId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await ApiService.getWalletHistory(walletId);

      final List<dynamic> results = result['results'] ?? [];
      _walletTransactions = results
          .map(
            (data) => WalletTransaction.fromJson(data as Map<String, dynamic>),
          )
          .toList();

      _walletTransactions.sort((a, b) => b.created.compareTo(a.created));
    } catch (e) {
      log('WalletProvider.getWalletHistory error: $e');
      _errorMessage = 'Došlo je do greške pri učitavanju povijesti novčanika.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
