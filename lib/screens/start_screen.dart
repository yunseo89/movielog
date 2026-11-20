import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final retry = auth.status == AuthStatus.retryRequired;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Text('FLUTTER 8주차'),
                const SizedBox(height: 40),
                SvgPicture.asset(
                  'assets/logos/movielog_logo.svg',
                  height: 84,
                  width: 84,
                ),
                const SizedBox(height: 32),
                Text(
                  '영화의 순간을\n기록하세요',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                if (retry) ...[
                  Text(
                    auth.message ?? '로그인 상태를 확인하지 못했어요.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  MovieLogButton(
                    label: '다시 시도',
                    onPressed: auth.storageCleanupInProgress
                        ? null
                        : auth.restoreSession,
                  ),
                ] else ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('로그인 상태를 확인하고 있어요.'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
