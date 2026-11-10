import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

class SignUpService {
  SignUpService(this._dio);
  final Dio _dio;
  Future<bool> checkNickname(String nickname) async {
    final response = await _dio.get(
      '/v6/members/nickname/${Uri.encodeComponent(nickname.trim())}',
    );
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  Future<bool> checkEmail(String email) async {
    final response = await _dio.get(
      '/v6/members/email/${Uri.encodeComponent(email.trim())}',
    );
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post('/v6/members', data: request.toJson());
    if (response.statusCode != 201) throw StateError('예상하지 못한 가입 응답');
    final result = CommonResponse<SignUpResult>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
    if (!result.isSuccess) throw StateError('가입 응답 실패');
    return result;
  }
}
