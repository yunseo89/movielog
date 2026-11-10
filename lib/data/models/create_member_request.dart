class CreateMemberRequest {
  const CreateMemberRequest({
    required this.email,
    required this.password,
    required this.nickname,
  });
  final String email;
  final String password;
  final String nickname;
  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
    'nickname': nickname.trim(),
  };
}

String? validatePasswordFormat(String? value) {
  if (value == null ||
      value.length < 8 ||
      !RegExp(r'[a-z]').hasMatch(value) ||
      !RegExp(r'[A-Z]').hasMatch(value) ||
      !RegExp(r'[0-9]').hasMatch(value) ||
      !RegExp(r'[!@#$%^&*]').hasMatch(value)) {
    return '8자 이상, 대문자·소문자·숫자·특수문자(!@#\$%^&*)를 포함해 주세요.';
  }
  return null;
}
