import 'data/models/create_member_request.dart';
import 'view_models/learning_member_session.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/main_shell.dart';
import 'data/services/sign_up_service.dart';
import 'view_models/sign_up_view_model.dart';
import 'widgets/movielog_button.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SignUpViewModel(context.read<SignUpService>()),
      child: const _SignUpScreenContent(),
    );
  }
}

class _SignUpScreenContent extends StatefulWidget {
  const _SignUpScreenContent();

  @override
  State<_SignUpScreenContent> createState() => _SignUpScreenContentState();
}

class _SignUpScreenContentState extends State<_SignUpScreenContent> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isAgreed = false;

  @override
  void initState() {
    super.initState();

    _nicknameController.addListener(_refresh);
    _emailController.addListener(_refresh);
    _passwordController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+$",
    ).hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final submitting = context.watch<SignUpViewModel>().isSubmitting;
    return PopScope(
      canPop: !submitting,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: submitting ? null : () => Navigator.of(context).pop(),
          ),
          title: const Text(
            '회원가입',
            style: TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildFormFields(),
                  const SizedBox(height: 40),
                  _buildTermsAndSubmit(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          '환영합니다!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          '간단한 정보만 입력하고 시작해보세요.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Consumer<SignUpViewModel>(
      builder: (context, viewModel, child) {
        final nicknameValid =
            _nicknameController.text.trim().length >= 2 &&
            _nicknameController.text.trim().length <= 12;
        final emailValid = _isValidEmail(_emailController.text.trim());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextFieldWithLabel(
              label: '닉네임',
              hint: '닉네임을 입력해주세요',
              controller: _nicknameController,
              nextFocus: _emailFocus,
              validator: (value) {
                if (value == null ||
                    (value.trim().length < 2 || value.trim().length > 12)) {
                  return '닉네임은 2~12자여야 합니다.';
                }
                return null;
              },
              isValid: nicknameValid,
              serverErrorText: viewModel.nicknameErrorText,
              onChanged: viewModel.onNicknameChanged,
              trailing: MovieLogButton(
                label: '중복 확인',
                isLoading:
                    viewModel.nicknameCheckStatus == CheckStatus.checking,
                onPressed: nicknameValid && viewModel.canCheckNickname
                    ? () => viewModel.checkNickname(_nicknameController.text)
                    : null,
              ),
              statusMessage:
                  viewModel.nicknameCheckStatus == CheckStatus.available
                  ? '사용할 수 있는 닉네임입니다.'
                  : null,
            ),
            const SizedBox(height: 24),
            _buildTextFieldWithLabel(
              label: '이메일',
              hint: '이메일 주소를 입력해주세요',
              controller: _emailController,
              focusNode: _emailFocus,
              nextFocus: _passwordFocus,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || !_isValidEmail(value.trim())) {
                  return '올바른 이메일 형식이 아닙니다.';
                }
                return null;
              },
              isValid: emailValid,
              serverErrorText: viewModel.emailErrorText,
              onChanged: viewModel.onEmailChanged,
              trailing: MovieLogButton(
                label: '중복 확인',
                isLoading: viewModel.emailCheckStatus == CheckStatus.checking,
                onPressed: emailValid && viewModel.canCheckEmail
                    ? () => viewModel.checkEmail(_emailController.text)
                    : null,
              ),
              statusMessage: viewModel.emailCheckStatus == CheckStatus.available
                  ? '사용할 수 있는 이메일입니다.'
                  : null,
            ),
            const SizedBox(height: 24),
            _buildTextFieldWithLabel(
              label: '비밀번호',
              hint: '비밀번호를 입력해주세요',
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: true,
              validator: validatePasswordFormat,
              serverErrorText: viewModel.passwordErrorText,
              onChanged: (_) => viewModel.onPasswordChanged(),
              isValid: validatePasswordFormat(_passwordController.text) == null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextFieldWithLabel({
    required String label,
    required String hint,
    required TextEditingController controller,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    TextInputType? keyboardType,
    bool obscureText = false,
    required String? Function(String?) validator,
    required bool isValid,
    String? serverErrorText,
    ValueChanged<String>? onChanged,
    Widget? trailing,
    String? statusMessage,
  }) {
    final hasText = controller.text.isNotEmpty;
    final hasError = hasText && (!isValid || serverErrorText != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled: !context.watch<SignUpViewModel>().isSubmitting,
                focusNode: focusNode,
                keyboardType: keyboardType,
                obscureText: obscureText,
                textInputAction: nextFocus != null
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (nextFocus != null) {
                    FocusScope.of(context).requestFocus(nextFocus);
                  }
                },
                onChanged: onChanged,
                validator: validator,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Colors.grey),
                  errorText: serverErrorText,
                  filled: true,
                  fillColor: hasError
                      ? Colors.red.shade50
                      : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  suffixIcon: hasText
                      ? Icon(
                          isValid && serverErrorText == null
                              ? Icons.check_circle
                              : Icons.error_outline,
                          color: isValid && serverErrorText == null
                              ? Colors.deepPurple
                              : Colors.red,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
        if (statusMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              statusMessage,
              style: const TextStyle(fontSize: 12, color: Colors.deepPurple),
            ),
          ),
      ],
    );
  }

  Widget _buildTermsAndSubmit() {
    return Consumer<SignUpViewModel>(
      builder: (context, viewModel, child) {
        final canSubmit =
            _nicknameController.text.trim().length >= 2 &&
            _isValidEmail(_emailController.text.trim()) &&
            validatePasswordFormat(_passwordController.text) == null &&
            _nicknameController.text.trim().length <= 12 &&
            viewModel.canSubmit &&
            _isAgreed &&
            viewModel.nicknameCheckStatus == CheckStatus.available &&
            viewModel.emailCheckStatus == CheckStatus.available;

        return Column(
          children: [
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _isAgreed,
                    activeColor: Colors.deepPurple,
                    onChanged: (value) {
                      setState(() {
                        _isAgreed = value ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('필수 약관에 동의합니다', style: TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 24),
            MovieLogButton(
              label: '가입하기',
              width: double.infinity,
              isLoading: viewModel.isSubmitting,
              onPressed: canSubmit
                  ? () async {
                      if (!_formKey.currentState!.validate()) return;
                      await viewModel.submit(
                        CreateMemberRequest(
                          email: _emailController.text,
                          password: _passwordController.text,
                          nickname: _nicknameController.text,
                        ),
                      );
                      if (!context.mounted) return;
                      final id = viewModel.createdMemberId;
                      if (viewModel.submitStatus == SubmitStatus.success &&
                          id != null) {
                        context.read<LearningMemberSession>().setMemberId(id);
                        // PopScope가 제출 완료 상태로 재빌드된 뒤 이동합니다.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const MainShell(initialIndex: 1),
                            ),
                            (route) => false,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('회원가입 완료 · 학습용 memberId: $id'),
                            ),
                          );
                        });
                      } else if (viewModel.snackbarMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(viewModel.snackbarMessage!)),
                        );
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '이미 계정이 있나요?',
                  style: TextStyle(color: Colors.black54),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    '로그인',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
