import 'package:dio/dio.dart';

import '../models/member_info.dart';
import 'response_parser.dart';

class MemberApiService {
  MemberApiService(this._authDio);
  final Dio _authDio;
  Future<MemberInfo> fetchMe() async => parseResult(
    await _authDio.get('/v8/members/me'),
    200,
    (v) => MemberInfo.fromJson(v as Map<String, dynamic>),
  );
  Future<MemberInfo> updateNickname(String nickname) async => parseResult(
    await _authDio.patch('/v8/members/me', data: {'nickname': nickname.trim()}),
    200,
    (v) => MemberInfo.fromJson(v as Map<String, dynamic>),
  );
}
