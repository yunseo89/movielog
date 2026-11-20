import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> readAccessToken();
  Future<void> deleteAccessToken();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);
  final FlutterSecureStorage _storage;
  static const accessTokenKey = 'movielog.access_token';
  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: accessTokenKey, value: token);
  @override
  Future<String?> readAccessToken() => _storage.read(key: accessTokenKey);
  @override
  Future<void> deleteAccessToken() => _storage.delete(key: accessTokenKey);
}

// 저장/읽기/삭제를 직렬화하여 로그아웃 뒤 이전 write가 토큰을 되살리지 못하게 합니다.
class SerializedTokenStorage implements TokenStorage {
  SerializedTokenStorage(this._delegate);
  final TokenStorage _delegate;
  Future<void> _tail = Future<void>.value();
  Future<T> _run<T>(Future<T> Function() operation) {
    final next = _tail.then((_) => operation());
    _tail = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  @override
  Future<void> saveAccessToken(String token) =>
      _run(() => _delegate.saveAccessToken(token));
  @override
  Future<String?> readAccessToken() => _run(_delegate.readAccessToken);
  @override
  Future<void> deleteAccessToken() => _run(_delegate.deleteAccessToken);
}
