import '../data/models/create_member_request.dart';
import '../data/services/api_error.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/services/sign_up_service.dart';

enum SubmitStatus { idle, submitting, success, error }

enum CheckStatus { idle, checking, available, duplicated, error }

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);

  final SignUpService _service;

  CheckStatus nicknameCheckStatus = CheckStatus.idle;
  String? nicknameErrorText;
  String? _duplicatedNickname;
  String _currentNickname = '';
  int _nicknameRequestVersion = 0;

  CheckStatus emailCheckStatus = CheckStatus.idle;
  String? emailErrorText;
  String? _duplicatedEmail;
  String _currentEmail = '';
  int _emailRequestVersion = 0;

  bool _disposed = false;
  SubmitStatus submitStatus = SubmitStatus.idle;
  int? createdMemberId;
  String? passwordErrorText;
  String? snackbarMessage;
  bool get isSubmitting => submitStatus == SubmitStatus.submitting;
  bool get canSubmit =>
      !isSubmitting &&
      nicknameCheckStatus == CheckStatus.available &&
      emailCheckStatus == CheckStatus.available;
  void onPasswordChanged() {
    passwordErrorText = null;
    snackbarMessage = null;
    if (!_disposed) notifyListeners();
  }

  Future<void> submit(CreateMemberRequest request) async {
    if (_disposed ||
        !canSubmit ||
        request.nickname.trim() != _currentNickname ||
        request.email.trim() != _currentEmail) {
      return;
    }
    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();
    try {
      final response = await _service.signUp(request);
      if (_disposed) return;
      final id = response.result?.memberId;
      if (id == null || id <= 0) throw StateError('회원 ID가 없습니다.');
      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      final message = apiErrorMessage(error);
      if (error is DioException &&
          error.response?.statusCode == 400 &&
          message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
      }
    }
    if (!_disposed) notifyListeners();
  }

  bool get canCheckNickname =>
      !isSubmitting &&
      nicknameCheckStatus != CheckStatus.checking &&
      nicknameCheckStatus != CheckStatus.duplicated;

  bool get canCheckEmail =>
      !isSubmitting &&
      emailCheckStatus != CheckStatus.checking &&
      emailCheckStatus != CheckStatus.duplicated;

  void onNicknameChanged(String value) {
    if (isSubmitting) return;
    passwordErrorText = null;
    snackbarMessage = null;
    final trimmed = value.trim();

    _currentNickname = trimmed;
    _nicknameRequestVersion++;

    if (_duplicatedNickname != null && trimmed == _duplicatedNickname) {
      nicknameCheckStatus = CheckStatus.duplicated;
      nicknameErrorText = '이미 사용 중인 닉네임입니다.';
    } else {
      nicknameCheckStatus = CheckStatus.idle;
      nicknameErrorText = null;
    }

    if (!_disposed) notifyListeners();
  }

  Future<void> checkNickname(String value) async {
    final requested = value.trim();

    if (requested.isEmpty ||
        requested != _currentNickname ||
        !canCheckNickname) {
      return;
    }

    final version = ++_nicknameRequestVersion;

    nicknameCheckStatus = CheckStatus.checking;
    nicknameErrorText = null;
    notifyListeners();

    try {
      final available = await _service.checkNickname(requested);

      if (_disposed ||
          version != _nicknameRequestVersion ||
          _currentNickname != requested) {
        return;
      }

      nicknameCheckStatus = available
          ? CheckStatus.available
          : CheckStatus.duplicated;

      nicknameErrorText = available ? null : '이미 사용 중인 닉네임입니다.';

      if (!available) {
        _duplicatedNickname = requested;
      }
    } on DioException {
      if (_disposed ||
          version != _nicknameRequestVersion ||
          _currentNickname != requested) {
        return;
      }

      nicknameCheckStatus = CheckStatus.error;
      nicknameErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }

    if (!_disposed && version == _nicknameRequestVersion) {
      notifyListeners();
    }
  }

  void onEmailChanged(String value) {
    if (isSubmitting) return;
    passwordErrorText = null;
    snackbarMessage = null;
    final trimmed = value.trim();

    _currentEmail = trimmed;
    _emailRequestVersion++;

    if (_duplicatedEmail != null && trimmed == _duplicatedEmail) {
      emailCheckStatus = CheckStatus.duplicated;
      emailErrorText = '이미 사용 중인 이메일입니다.';
    } else {
      emailCheckStatus = CheckStatus.idle;
      emailErrorText = null;
    }

    if (!_disposed) notifyListeners();
  }

  Future<void> checkEmail(String value) async {
    final requested = value.trim();

    if (requested.isEmpty || requested != _currentEmail || !canCheckEmail) {
      return;
    }

    final version = ++_emailRequestVersion;

    emailCheckStatus = CheckStatus.checking;
    emailErrorText = null;
    notifyListeners();

    try {
      final available = await _service.checkEmail(requested);

      if (_disposed ||
          version != _emailRequestVersion ||
          _currentEmail != requested) {
        return;
      }

      emailCheckStatus = available
          ? CheckStatus.available
          : CheckStatus.duplicated;

      emailErrorText = available ? null : '이미 사용 중인 이메일입니다.';

      if (!available) {
        _duplicatedEmail = requested;
      }
    } on DioException {
      if (_disposed ||
          version != _emailRequestVersion ||
          _currentEmail != requested) {
        return;
      }

      emailCheckStatus = CheckStatus.error;
      emailErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }

    if (!_disposed && version == _emailRequestVersion) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _nicknameRequestVersion++;
    _emailRequestVersion++;
    super.dispose();
  }
}
