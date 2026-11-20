import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final AuthViewModel _auth;
  bool _noticeScheduled = false;
  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    _auth.addListener(_scheduleNotice);
    _scheduleNotice();
  }

  void _scheduleNotice() {
    if (_noticeScheduled || !_auth.sessionExpired) return;
    _noticeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _noticeScheduled = false;
      if (!mounted || !_auth.consumeSessionExpired()) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')),
        );
    });
  }

  @override
  void dispose() {
    _auth.removeListener(_scheduleNotice);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final busy =
        auth.status == AuthStatus.authenticating ||
        auth.storageCleanupInProgress;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('로그인'),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  SvgPicture.asset(
                    'assets/logos/movielog_logo.svg',
                    height: 72,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'MovieLog에 로그인',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _email,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: '이메일'),
                    validator: (v) =>
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(v?.trim() ?? '')
                        ? null
                        : '이메일 형식을 확인해 주세요.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    enabled: !busy,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(labelText: '비밀번호'),
                    validator: (v) =>
                        v == null || v.isEmpty ? '비밀번호를 입력해 주세요.' : null,
                  ),
                  if (auth.message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        auth.message!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  MovieLogButton(
                    label: '로그인',
                    isLoading: busy,
                    onPressed: busy
                        ? null
                        : () {
                            if (_form.currentState!.validate()) {
                              auth.login(_email.text, _password.text);
                            }
                          },
                  ),
                  TextButton(
                    onPressed: busy ? null : () => context.push('/register'),
                    child: const Text('회원가입'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
