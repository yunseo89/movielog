import 'package:flutter/material.dart';

import 'movielog_button.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.initialScore = 0,
    this.initialComment,
    required this.onSubmit,
  });
  final int initialScore;
  final String? initialComment;
  final Future<void> Function(int score, String? comment) onSubmit;
  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _score = widget.initialScore;
  late final _commentController = TextEditingController(
    text: widget.initialComment ?? '',
  );
  bool _isSubmitting = false;
  String? _errorText;
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isSubmitting,
    child: AlertDialog(
      title: const Text('평점을 남겨주세요'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
  5,
  (index) => Expanded(
    child: IconButton(
      constraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 48,
      ),
      padding: const EdgeInsets.all(4),
      tooltip: '${index + 1}점',
      onPressed: _isSubmitting
          ? null
          : () => setState(() => _score = index + 1),
      icon: Icon(
        index < _score ? Icons.star : Icons.star_border,
        color: Colors.deepPurple,
      ),
    ),
  ),
),
            Text(_score == 0 ? '별점을 선택해 주세요' : '$_score / 5점'),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 500,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(hintText: '코멘트를 남겨보세요 (선택)'),
            ),
            if (_errorText != null)
              Text(_errorText!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: [
        MovieLogButton(
          label: '취소',
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
        ),
        MovieLogButton(
          label: '확인',
          isLoading: _isSubmitting,
          onPressed: _score >= 1 && _score <= 5 && !_isSubmitting
              ? _confirm
              : null,
        ),
      ],
    ),
  );
  Future<void> _confirm() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    final comment = _commentController.text.trim();
    try {
      await widget.onSubmit(_score, comment.isEmpty ? null : comment);
      if (!mounted) return;
      // PopScope를 먼저 해제한 뒤 결과를 반환합니다.
      setState(() => _isSubmitting = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = error is StateError
            ? error.message.toString()
            : '저장하지 못했습니다. 다시 시도해 주세요.';
      });
    }
  }
}
