import 'package:flutter/material.dart';
import 'package:mobile/models/review_model.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/parking_zone_model.dart';
import '../providers/auth_provider.dart';
import '../providers/review_provider.dart';

class ReviewsScreen extends StatefulWidget {
  final ParkingZone parkingZone;
  const ReviewsScreen({required this.parkingZone});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReviewProvider>(context, listen: false)
          .getZoneReviews(parkingZoneId: widget.parkingZone.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.parkingZone.name} - Ocjene'),
        backgroundColor: AppColors.primary,
      ),
      body: Consumer<ReviewProvider>(
        builder: (context, reviewProvider, _) {
          return Column(
            children: [
              _buildRatingHeader(reviewProvider),
              Expanded(child: _buildReviewsList(reviewProvider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRatingHeader(ReviewProvider reviewProvider) {
    final avgRating  = reviewProvider.averageRating;
    final reviewCount = reviewProvider.reviewCount;
    final hasUserReview = reviewProvider.userReview != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildRatingStars(avgRating),
                      const SizedBox(width: 12),
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$reviewCount ocjena',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddReviewDialog(context),
                icon: Icon(hasUserReview ? Icons.edit : Icons.add, size: 18),
                label: Text(hasUserReview ? 'Izmijeni' : 'Napiši'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
              ),
            ],
          ),
          if (hasUserReview) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tvoja ocjena',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      _buildRatingStars(
                          reviewProvider.userReview!.rating.toDouble()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsList(ReviewProvider reviewProvider) {
    if (reviewProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (reviewProvider.reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('Nema ocjena',
                style:
                    TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Budi prvi da ocijeniš ovaj parking',
                style:
                    TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: reviewProvider.reviews.length,
      itemBuilder: (context, index) {
        final review = reviewProvider.reviews[index];
        return _buildReviewCard(context, review, reviewProvider);
      },
    );
  }

  Widget _buildReviewCard(
      BuildContext context, Review review, ReviewProvider reviewProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.author?.firstName ?? 'Anoniman',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(review.formattedDate,
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                5,
                (i) => Icon(Icons.star,
                    size: 16,
                    color: i < review.rating
                        ? Colors.amber
                        : AppColors.textTertiary),
              ),
            ),
            if (review.reviewText != null &&
                review.reviewText!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(review.reviewText!,
                  style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        final fill = (rating - index).clamp(0.0, 1.0);
        return Icon(Icons.star,
            size: 18,
            color: fill > 0.5
                ? Colors.amber
                : fill > 0
                    ? Colors.amber.withOpacity(0.5)
                    : AppColors.textTertiary);
      }),
    );
  }

  void _showAddReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          _AddReviewDialog(parkingZoneId: widget.parkingZone.id),
    );
  }
}

class _AddReviewDialog extends StatefulWidget {
  final int parkingZoneId;
  const _AddReviewDialog({required this.parkingZoneId});

  @override
  State<_AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<_AddReviewDialog> {
  final _formKey = GlobalKey<FormState>();

  int _rating = 5;
  late TextEditingController _textController;
  bool _isLoading = false;
  bool _ratingTouched = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    final reviewProvider =
        Provider.of<ReviewProvider>(context, listen: false);
    if (reviewProvider.userReview != null) {
      _rating = reviewProvider.userReview!.rating;
      _textController.text = reviewProvider.userReview!.reviewText ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String? _validateText(String? v) {
    if (v != null && v.trim().isNotEmpty && v.trim().length < 10) {
      return 'Recenzija mora imati najmanje 10 znakova';
    }
    if (v != null && v.trim().length > 500) {
      return 'Recenzija ne smije imati više od 500 znakova';
    }
    return null;
  }

  Future<void> _submitReview() async {
    setState(() => _ratingTouched = true);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);

      if (reviewProvider.userReview != null) {
        await reviewProvider.updateReview(
          reviewId: reviewProvider.userReview!.id,
          rating: _rating,
          reviewText: _textController.text.trim().isEmpty
              ? null
              : _textController.text.trim(),
        );
      } else {
        await reviewProvider.createReview(
          parkingZoneId: widget.parkingZoneId,
          userId: authProvider.user!.id,
          rating: _rating,
          reviewText: _textController.text.trim().isEmpty
              ? null
              : _textController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocjena uspješno spremljena')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Došlo je do greške. Pokušajte ponovno.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ocijeni parking',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: Navigator.of(context).pop,
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Center(
                  child: Text('Odaberi ocjenu *',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 12),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setState(() {
                          _rating = index + 1;
                          _ratingTouched = true;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            Icons.star,
                            size: 44,
                            color: index < _rating
                                ? Colors.amber
                                : AppColors.textTertiary,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                if (_ratingTouched && _rating == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Center(
                      child: Text('Ocjena je obavezna',
                          style: TextStyle(
                              fontSize: 12, color: Colors.red[700])),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      ['', 'Loše', 'Ispod prosjeka', 'Prosječno',
                          'Dobro', 'Odlično'][_rating],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: [
                          Colors.transparent,
                          Colors.red,
                          Colors.orange,
                          Colors.amber,
                          Colors.lightGreen,
                          Colors.green,
                        ][_rating],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Napiši recenziju (opcionalno)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _textController,
                  enabled: !_isLoading,
                  maxLines: 3,
                  maxLength: 500,
                  validator: _validateText,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    hintText: 'Šta misliš o ovom parkingu?',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isLoading ? null : Navigator.of(context).pop,
                        child: const Text('Otkaži'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitReview,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                        Colors.white)),
                              )
                            : const Text('Spremi',
                                style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}