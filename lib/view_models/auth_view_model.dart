import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/storage/token_storage.dart';
import '../data/models/login_models.dart';
import '../data/models/member_info.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';

enum AuthStatus {
  initializing,
  signedOut,
  authenticating,
  signedIn,
  retryRequired,
}

enum MemberLoadStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authApi, this._memberApi, this._storage);
  final AuthApiService _authApi;
  final MemberApiService _memberApi;
  final TokenStorage _storage;
  AuthStatus status = AuthStatus.initializing;
  MemberInfo? member;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  String? message;
  int _version = 0;
  int _memberRevision = 0;
  int get sessionVersion => _version;
  bool sessionExpired = false;
  bool storageCleanupInProgress = false;
  bool _cleanupRequired = false;
  bool _disposed = false;
  Future<void>? _tokenWrite;
  bool isCurrent(int version) => !_disposed && version == _version;
  bool isSignedInVersion(int version) =>
      isCurrent(version) && status == AuthStatus.signedIn;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> restoreSession() async {
    if (_disposed ||
        storageCleanupInProgress ||
        status == AuthStatus.authenticating) {
      return;
    }
    if (_cleanupRequired) {
      await _clear(expired: false);
      return;
    }
    final version = ++_version;
    status = AuthStatus.initializing;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    message = null;
    _notify();
    try {
      final token = await _storage.readAccessToken();
      if (!isCurrent(version)) return;
      if (token == null || token.isEmpty) {
        status = AuthStatus.signedOut;
      } else {
        final verified = await _memberApi.fetchMe();
        if (!isCurrent(version)) return;
        member = verified;
        memberStatus = MemberLoadStatus.success;
        status = AuthStatus.signedIn;
      }
    } catch (error) {
      if (!isCurrent(version)) return;
      if (isSessionError(error)) {
        await expireSession(expectedVersion: version);
        return;
      }
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했어요. 연결 상태와 보안 저장소를 확인하고 다시 시도해 주세요.';
    }
    if (isCurrent(version)) _notify();
  }

  Future<void> login(String email, String password) async {
    if (_disposed ||
        storageCleanupInProgress ||
        _cleanupRequired ||
        status == AuthStatus.authenticating ||
        status == AuthStatus.signedIn) {
      return;
    }
    final version = ++_version;
    status = AuthStatus.authenticating;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    message = null;
    sessionExpired = false;
    _notify();
    try {
      final result = await _authApi.login(
        LoginRequest(email: email, password: password),
      );
      if (!isCurrent(version)) return;
      final writing = _storage.saveAccessToken(result.accessToken);
      _tokenWrite = writing;
      try {
        await writing;
      } finally {
        if (identical(_tokenWrite, writing)) _tokenWrite = null;
      }
      if (!isCurrent(version)) return;
      // 로그인 성공 응답 + 저장 완료. 내 정보는 MainShell이 post-frame에 호출합니다.
      status = AuthStatus.signedIn;
    } catch (error) {
      if (!isCurrent(version)) return;
      status = AuthStatus.signedOut;
      message = apiErrorCode(error) == 'AUTH401_1'
          ? '이메일 또는 비밀번호를 확인해 주세요.'
          : userErrorMessage(error);
    }
    if (isCurrent(version)) _notify();
  }

  Future<void> loadMember({bool force = false}) async {
    if (_disposed ||
        status != AuthStatus.signedIn ||
        memberStatus == MemberLoadStatus.loading ||
        (member != null && !force)) {
      return;
    }
    final version = _version;
    final revision = _memberRevision;
    memberStatus = MemberLoadStatus.loading;
    message = null;
    _notify();
    try {
      final me = await _memberApi.fetchMe();
      if (!isSignedInVersion(version) || revision != _memberRevision) return;
      member = me;
      memberStatus = MemberLoadStatus.success;
    } catch (error) {
      if (!isSignedInVersion(version) || revision != _memberRevision) return;
      if (isSessionError(error)) {
        await expireSession(expectedVersion: version);
        return;
      }
      memberStatus = MemberLoadStatus.error;
      message = userErrorMessage(error);
    }
    if (isSignedInVersion(version)) _notify();
  }

  void updateMember(MemberInfo updated, {required int expectedVersion}) {
    if (!isSignedInVersion(expectedVersion)) return;
    _memberRevision++;
    member = updated;
    memberStatus = MemberLoadStatus.success;
    _notify();
  }

  Future<void> expireSession({required int expectedVersion}) async {
    if (!isCurrent(expectedVersion) ||
        storageCleanupInProgress ||
        status == AuthStatus.signedOut) {
      return;
    }
    await _clear(expired: true);
  }

  Future<void> logout() => _clear(expired: false);
  Future<void> _clear({required bool expired}) async {
    if (_disposed || storageCleanupInProgress) return;
    final version = ++_version;
    storageCleanupInProgress = true;
    status = AuthStatus.signedOut;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = expired;
    message = null;
    _notify();
    try {
      try {
        await _tokenWrite;
      } catch (_) {
        /* 저장 실패와 무관하게 삭제 */
      }
      await _storage.deleteAccessToken();
      _cleanupRequired = false;
    } catch (_) {
      if (isCurrent(version)) {
        _cleanupRequired = true;
        status = AuthStatus.retryRequired;
        message = '인증 정보 삭제에 실패했어요. 다시 시도해 주세요.';
      }
    } finally {
      storageCleanupInProgress = false;
      if (isCurrent(version)) _notify();
    }
  }

  bool consumeSessionExpired() {
    if (!sessionExpired) return false;
    sessionExpired = false;
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    super.dispose();
  }
}
