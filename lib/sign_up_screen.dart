import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // 컨트롤러
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 포커스 노드
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // 상태 변수
  bool _isAgreed = false;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    // 텍스트가 변경될 때마다 폼 유효성 검사 실행
    _nicknameController.addListener(_checkFormValidity);
    _emailController.addListener(_checkFormValidity);
    _passwordController.addListener(_checkFormValidity);
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

  // 이메일 정규식 검사
  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  // 실시간 버튼 활성화 체크
  void _checkFormValidity() {
    final isNicknameValid = _nicknameController.text.length >= 2;
    final isEmailValid = _isValidEmail(_emailController.text);
    final isPasswordValid = _passwordController.text.length >= 8;

    final isValid = isNicknameValid && isEmailValid && isPasswordValid && _isAgreed;
    
    if (_isButtonEnabled != isValid) {
      setState(() {
        _isButtonEnabled = isValid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Text('회원가입', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView( // 키보드 Overflow 방지
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
    );
  }

  // 1. 헤더 위젯
  Widget _buildHeader() {
    return const Column(
      children: [
        Text('환영합니다!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('간단한 정보만 입력하고 시작해보세요.', style: TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  // 2. 폼 필드 위젯
  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldWithLabel(
          label: '닉네임',
          hint: '닉네임을 입력해주세요',
          controller: _nicknameController,
          nextFocus: _emailFocus,
          validator: (value) => (value == null || value.length < 2) ? '닉네임은 2자 이상이어야 합니다.' : null,
          isValid: _nicknameController.text.length >= 2,
        ),
        const SizedBox(height: 24),
        _buildTextFieldWithLabel(
          label: '이메일',
          hint: '이메일 주소를 입력해주세요',
          controller: _emailController,
          focusNode: _emailFocus,
          nextFocus: _passwordFocus,
          keyboardType: TextInputType.emailAddress,
          validator: (value) => (value == null || !_isValidEmail(value)) ? '올바른 이메일 형식이 아닙니다.' : null,
          isValid: _isValidEmail(_emailController.text),
        ),
        const SizedBox(height: 24),
        _buildTextFieldWithLabel(
          label: '비밀번호',
          hint: '비밀번호를 입력해주세요',
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: true,
          validator: (value) => (value == null || value.length < 8) ? '비밀번호는 8자 이상이어야 합니다.' : null,
          isValid: _passwordController.text.length >= 8,
        ),
      ],
    );
  }

  // 텍스트 필드 공통 빌더 (디자인 시안의 에러/완료 UI 완벽 반영)
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
  }) {
    final hasText = controller.text.isNotEmpty;
    final hasError = hasText && !isValid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
          onFieldSubmitted: (_) {
            if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
          },
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: hasError ? Colors.red.shade50 : Colors.grey.shade100, // 에러 시 붉은 배경
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: hasText
                ? Icon(
                    isValid ? Icons.check_circle : Icons.error_outline,
                    color: isValid ? Colors.deepPurple : Colors.red,
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
      ],
    );
  }

  // 3. 약관 및 하단 영역 위젯
  
// 3. 약관 및 하단 영역 위젯
  Widget _buildTermsAndSubmit() {
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
                    _checkFormValidity();
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text('필수 약관에 동의합니다', style: TextStyle(fontSize: 14)),
          ],
        ),
        const SizedBox(height: 24),
        
        // 👇 바로 이 가입하기 버튼의 onPressed 동작이 수정되었습니다.
        ElevatedButton(
          onPressed: _isButtonEnabled
              ? () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('가입이 완료되었습니다!')),
                    );
                    
                    // ✨ 중요: 회원가입 완료 후 홈으로 이동 (뒤로가기 불가)
                    context.go('/home');
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            disabledBackgroundColor: Colors.deepPurple.shade200, 
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: const Text('가입하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('이미 계정이 있나요?', style: TextStyle(color: Colors.black54)),
            TextButton(
              onPressed: () {},
              child: const Text('로그인', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}