class LoginRequest {
  const LoginRequest({required this.email, required this.password});
  final String email;
  final String password;
  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
  };
}

class LoginResult {
  const LoginResult({required this.nickname, required this.accessToken});
  final String nickname;
  final String accessToken;
  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken'] as String;
    if (token.trim().isEmpty) throw StateError('로그인 토큰이 없습니다.');
    return LoginResult(
      nickname: json['nickname'] as String,
      accessToken: token,
    );
  }
}
