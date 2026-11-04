import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rating.dart';
import '../../services/rating_service.dart';
import '../../widgets/rating_stars.dart';

class MyRatingsScreen extends StatefulWidget {
  const MyRatingsScreen({super.key});
  @override
  State<MyRatingsScreen> createState() => _MyRatingsScreenState();
}

class _MyRatingsScreenState extends State<MyRatingsScreen> {
  final _ratingService = RatingService();
  List<Rating> _ratings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ratings = await _ratingService.listMyRatings();
    if (!mounted) return;
    setState(() {
      _ratings = ratings;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final average = _ratings.isEmpty ? null : _ratings.map((r) => r.score).reduce((a, b) => a + b) / _ratings.length;
    return Scaffold(
      appBar: AppBar(title: const Text("Ratings & Reviews")),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RatingStars(rating: average, size: 26),
                          const SizedBox(width: 10),
                          Text("(${_ratings.length} rating${_ratings.length == 1 ? '' : 's'})",
                              style: const TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_ratings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text("No ratings yet.", style: TextStyle(color: AppColors.textSecondary))),
                    )
                  else
                    ..._ratings.map((r) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    RatingStars(rating: r.score.toDouble(), size: 14),
                                  ],
                                ),
                                if (r.review?.title.isNotEmpty == true) ...[
                                  const SizedBox(height: 6),
                                  Text(r.review!.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                                if (r.review?.body.isNotEmpty == true) Text(r.review!.body, style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(DateFormat.yMMMd().format(r.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
      ),
    );
  }
}
