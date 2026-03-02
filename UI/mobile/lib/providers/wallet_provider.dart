import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  Wallet? _userWallet;
  bool _isLoading = false;
  String? _errorMessage;

  Wallet? get userWallet => _userWallet;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}