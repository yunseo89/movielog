import '../widgets/rating_write_feedback.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../view_models/session_ratings_view_model.dart';
import '../widgets/delete_rating_dialog.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});
  Future<void> _edit(
    BuildContext context,
    int id,
    int score,
    String? comment,
  ) async {
    final vm = context.read<SessionRatingsViewModel>();
    final auth = context.read<AuthViewModel>();
    final version = auth.sessionVersion;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        initialScore: score,
        initialComment: comment,
        onSubmit: (score, comment) => reportRatingWrite(
          context,
          () => vm.update(id, score: score, comment: comment),
        ),
      ),
    );
    if (!context.mounted || !auth.isSignedInVersion(version) || saved != true) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('평점을 수정했어요.')));
  }

  Future<void> _delete(BuildContext context, int id) async {
    final vm = context.read<SessionRatingsViewModel>();
    final auth = context.read<AuthViewModel>();
    final version = auth.sessionVersion;
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteRatingDialog(
        onDelete: () => reportRatingWrite(context, () => vm.delete(id)),
      ),
    );
    if (!context.mounted ||
        !auth.isSignedInVersion(version) ||
        deleted != true) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('평점을 삭제했어요.')));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SessionRatingsViewModel>();
    return PopScope(
      canPop: !vm.isWriting,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('이번 로그인에서 등록한 평점'),
          centerTitle: true,
          leading: BackButton(
            onPressed: vm.isWriting
                ? null
                : () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/my');
                    }
                  },
          ),
        ),
        body: vm.ratings.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    '현재 세션에서 등록한 평점이 없습니다.\n영화 상세에서 평점을 남겨보세요.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: vm.ratings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final rating = vm.ratings[index];
                  final movie = vm.movieFor(rating.movieId);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TmdbPosterImage(
                            posterPath: movie?.posterPath,
                            width: 64,
                            height: 96,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movie?.title ?? '영화 #${rating.movieId}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('별점 ${rating.score} / 5'),
                                if (rating.comment != null)
                                  Text(rating.comment!),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                tooltip: '수정',
                                onPressed: vm.isWriting
                                    ? null
                                    : () => _edit(
                                        context,
                                        rating.ratingId,
                                        rating.score,
                                        rating.comment,
                                      ),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: '삭제',
                                onPressed: vm.isWriting
                                    ? null
                                    : () => _delete(context, rating.ratingId),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
