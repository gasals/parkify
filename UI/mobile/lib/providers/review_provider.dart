import 'package:flutter/material.dart';
import 'package:mobile/models/review_model.dart';
import 'package:mobile/providers/auth_provider.dart';
import '../services/api_service.dart';

class ReviewProvider extends ChangeNotifier {
  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;
  double _averageRating = 0;
  Review? _userReview;

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get averageRating => _averageRating;
  Review? get userReview => _userReview;
  int get reviewCount => _reviews.length;

  final AuthProvider authProvider;
  ReviewProvider(this.authProvider);

  Future<void> getZoneReviews({
    required int parkingZoneId,
    int page = 1,
    int pageSize = 1000,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await ApiService.getZoneReviews(
        parkingZoneId: parkingZoneId,
        page: page,
        pageSize: pageSize,
      );

      final reviewsList = (result['results'] as List)
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList();

      _reviews = reviewsList;
      _calculateAverageRating();

      final currentUserId = authProvider.user?.id;
      if (currentUserId != null) {
        try {
          _userReview = _reviews.firstWhere((r) => r.userId == currentUserId);
        } catch (e) {
          _userReview = null;
        }
      } else {
        _userReview = null;
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Review> createReview({
    required int parkingZoneId,
    required int userId,
    required int rating,
    required String? reviewText,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = {
        'parkingZoneId': parkingZoneId,
        'userId': userId,
        'rating': rating,
        'reviewText': reviewText,
      };
      final result = await ApiService.createReview(data);
      final review = Review.fromJson(result);
      _reviews.insert(0, review);
      _userReview = review;
      _calculateAverageRating();
      return review;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateReview({
    required int reviewId,
    required int rating,
    required String? reviewText,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiService.updateReview(
        reviewId: reviewId,
        rating: rating,
        reviewText: reviewText,
      );

      final index = _reviews.indexWhere((r) => r.id == reviewId);
      if (index != -1) {
        _reviews[index] = Review(
          id: _reviews[index].id,
          parkingZoneId: _reviews[index].parkingZoneId,
          userId: _reviews[index].userId,
          rating: rating,
          reviewText: reviewText,
          createdAt: _reviews[index].createdAt,
          author: _reviews[index].author,
          parkingZone: _reviews[index].parkingZone,
        );
        _userReview = _reviews[index];
        _calculateAverageRating();
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateAverageRating() {
    if (_reviews.isEmpty) {
      _averageRating = 0;
    } else {
      final sum = _reviews.fold<int>(0, (sum, review) => sum + review.rating);
      _averageRating = sum / _reviews.length;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
