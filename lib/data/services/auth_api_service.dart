import 'package:dio/dio.dart';

import '../models/login_models.dart';
import 'response_parser.dart';

class AuthApiService {
  AuthApiService(this._publicDio);
  final Dio _publicDio;
  Future<LoginResult> login(LoginRequest request) async => parseResult(
    await _publicDio.post('/v7/auth/login', data: request.toJson()),
    200,
    (v) => LoginResult.fromJson(v as Map<String, dynamic>),
  );
}
