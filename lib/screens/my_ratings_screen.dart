import '../widgets/rating_dialog.dart';
import '../widgets/delete_rating_dialog.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/my_ratings_view_model.dart';
import '../widgets/tmdb_poster_image.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final writing = context.watch<MyRatingsViewModel>().isWriting;
    return PopScope(
      canPop: !writing,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: writing ? null : () => Navigator.pop(context),
          ),
          title: const Text('내가 등록한 평점'),
          centerTitle: true,
        ),
        body: Consumer<MyRatingsViewModel>(
          builder: (context, viewModel, child) {
            switch (viewModel.status) {
              case MyRatingsLoadStatus.idle:
              case MyRatingsLoadStatus.loading:
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('평점을 불러오는 중이에요...'),
                    ],
                  ),
                );

              case MyRatingsLoadStatus.empty:
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_border, size: 52, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('등록된 평점이 없습니다.'),
                    ],
                  ),
                );

              case MyRatingsLoadStatus.error:
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 52,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          viewModel.message ?? '평점을 불러오지 못했습니다.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: viewModel.load,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            viewModel.refreshPending
                                ? '목록 새로고침 (GET)'
                                : '다시 시도',
                          ),
                        ),
                      ],
                    ),
                  ),
                );

              case MyRatingsLoadStatus.success:
                return Column(
                  children: [
                    if (viewModel.message != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          viewModel.message!,
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: viewModel.ratings.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final entry = viewModel.ratings[index];
                          final rating = entry.rating;
                          final movie = entry.movie;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: TmdbPosterImage(
                                      posterPath: movie?.posterPath,
                                      width: 80,
                                      height: 116,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          movie?.title ?? '영화 정보를 찾을 수 없습니다.',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (movie == null)
                                          Text(
                                            '영화 ID: ${rating.movieId}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${rating.score}점',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatDate(rating.createdAt),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (rating.comment != null &&
                                            rating.comment!
                                                .trim()
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(rating.comment!),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        tooltip: '수정',
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: viewModel.isWriting
                                            ? null
                                            : () => _edit(
                                                context,
                                                viewModel,
                                                rating.ratingId,
                                                rating.score,
                                                rating.comment,
                                              ),
                                      ),
                                      IconButton(
                                        tooltip: '삭제',
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: viewModel.isWriting
                                            ? null
                                            : () => _delete(
                                                context,
                                                viewModel,
                                                rating.ratingId,
                                              ),
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
                  ],
                );
            }
          },
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    MyRatingsViewModel vm,
    int ratingId,
    int score,
    String? comment,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        initialScore: score,
        initialComment: comment,
        onSubmit: (score, comment) =>
            vm.updateRating(ratingId: ratingId, score: score, comment: comment),
      ),
    );
    if (!context.mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vm.refreshPending ? '수정 완료 · 목록 새로고침을 재시도해 주세요.' : '평점을 수정했습니다.',
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    MyRatingsViewModel vm,
    int ratingId,
  ) async {
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          DeleteRatingDialog(onDelete: () => vm.deleteRating(ratingId)),
    );
    if (!context.mounted || deleted != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vm.refreshPending ? '삭제 완료 · 목록 새로고침을 재시도해 주세요.' : '평점을 삭제했습니다.',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    return '${localDate.year}.'
        '${localDate.month.toString().padLeft(2, '0')}.'
        '${localDate.day.toString().padLeft(2, '0')}';
  }
}
