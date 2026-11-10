import 'package:flutter/material.dart';

import 'movielog_button.dart';

class DeleteRatingDialog extends StatefulWidget {
  const DeleteRatingDialog({super.key, required this.onDelete});
  final Future<void> Function() onDelete;
  @override
  State<DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<DeleteRatingDialog> {
  bool _busy = false;
  String? _error;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('평점을 삭제할까요?'),
      content: Text(_error ?? '삭제한 평점과 코멘트는 복구할 수 없습니다.'),
      actions: [
        MovieLogButton(
          label: '취소',
          onPressed: _busy ? null : () => Navigator.pop(context, false),
        ),
        MovieLogButton(
          label: '삭제',
          isLoading: _busy,
          onPressed: _busy
              ? null
              : () async {
                  setState(() {
                    _busy = true;
                    _error = null;
                  });
                  try {
                    await widget.onDelete();
                    if (!mounted) return;
                    setState(() => _busy = false);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) Navigator.pop(context, true);
                    });
                  } catch (error) {
                    if (mounted) {
                      setState(() {
                        _busy = false;
                        _error = error is StateError
                            ? error.message.toString()
                            : '삭제하지 못했습니다.';
                      });
                    }
                  }
                },
        ),
      ],
    ),
  );
}
