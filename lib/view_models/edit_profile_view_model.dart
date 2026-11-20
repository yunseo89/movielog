import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/services/member_api_service.dart';
import 'auth_view_model.dart';

enum EditProfileStatus { idle, saving, success, failure }

class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this._api, this._auth);
  final MemberApiService _api;
  final AuthViewModel _auth;
  EditProfileStatus status = EditProfileStatus.idle;
  String? nicknameError;
  String? message;
  bool _disposed = false;
  String? validateNickname(String value) =>
      value.trim().length < 2 || value.trim().length > 12
      ? '닉네임은 2~12자로 입력해 주세요.'
      : null;
  void clearError() {
    nicknameError = null;
    message = null;
    if (!_disposed) notifyListeners();
  }

  Future<bool> save(String input) async {
    final version = _auth.sessionVersion;
    if (_disposed ||
        status == EditProfileStatus.saving ||
        !_auth.isSignedInVersion(version) ||
        _auth.member == null) {
      return false;
    }
    final nickname = input.trim();
    nicknameError = validateNickname(nickname);
    message = null;
    if (nicknameError != null) {
      notifyListeners();
      return false;
    }
    if (nickname == _auth.member!.nickname) {
      status = EditProfileStatus.success;
      notifyListeners();
      return true;
    }
    status = EditProfileStatus.saving;
    notifyListeners();
    try {
      final updated = await _api.updateNickname(nickname);
      if (_disposed || !_auth.isSignedInVersion(version)) return false;
      _auth.updateMember(updated, expectedVersion: version);
      status = EditProfileStatus.success;
      notifyListeners();
      return true;
    } catch (error) {
      if (_disposed || !_auth.isSignedInVersion(version)) return false;
      status = EditProfileStatus.failure;
      final code = apiErrorCode(error);
      if (isSessionError(error)) {
        await _auth.expireSession(expectedVersion: version);
        return false;
      }
      if (code == 'MEMBER409_1') {
        nicknameError = apiErrorMessage(error) ?? '이미 사용 중인 닉네임이에요.';
      } else if (code == 'COMMON400' || code == 'COMMON4001') {
        nicknameError = apiErrorMessage(error) ?? '닉네임 형식을 확인해 주세요.';
      } else {
        message = userErrorMessage(error);
        if (code == 'MEMBER404_1') await _auth.loadMember(force: true);
      }
      if (!_disposed && _auth.isSignedInVersion(version)) notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
