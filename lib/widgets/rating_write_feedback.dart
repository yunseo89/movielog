import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';

// 저장 실패는 Dialog 입력을 유지하면서 Snackbar로도 안내합니다.
Future<void> reportRatingWrite(
  BuildContext context,
  Future<void> Function() action,
) async {
  final auth = context.read<AuthViewModel>();
  final version = auth.sessionVersion;
  try {
    await action();
  } catch (error) {
    if (context.mounted && auth.isSignedInVersion(version)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : '평점 요청에 실패했어요. 다시 시도해 주세요.',
          ),
        ),
      );
    }
    rethrow;
  }
}
