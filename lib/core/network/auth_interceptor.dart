import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_error.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._storage, {
    required this.origin,
    required this.sessionVersion,
    required this.onSessionExpired,
  });
  final TokenStorage _storage;
  final Uri origin;
  final int Function() sessionVersion;
  final Future<void> Function(int version) onSessionExpired;
  static const _versionKey = 'movielog.sessionVersion';
  bool _protected(RequestOptions o) {
    final uri = o.uri;
    final trusted =
        uri.scheme == origin.scheme &&
        uri.host == origin.host &&
        uri.port == origin.port;
    final method = o.method.toUpperCase();
    return trusted &&
        ((uri.path == '/v8/members/me' &&
                const {'GET', 'PATCH'}.contains(method)) ||
            (uri.path == '/v8/favorites' &&
                const {'GET', 'POST'}.contains(method)) ||
            (RegExp(r'^/v8/favorites/[1-9][0-9]*$').hasMatch(uri.path) &&
                const {'GET', 'DELETE'}.contains(method)) ||
            (uri.path == '/v8/ratings' && method == 'POST') ||
            (RegExp(r'^/v8/ratings/[1-9][0-9]*$').hasMatch(uri.path) &&
                const {'PATCH', 'DELETE'}.contains(method)));
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 이 client에서 과거 Authorization을 공개/외부 요청으로 재전송하지 않습니다.
    options.headers.removeWhere(
      (key, _) => key.toLowerCase() == 'authorization',
    );
    options.extra.remove(_versionKey);
    if (!_protected(options)) {
      handler.next(options);
      return;
    }
    final version = sessionVersion();
    options.extra[_versionKey] = version;
    options.followRedirects = false;
    try {
      final token = await _storage.readAccessToken();
      if (version != sessionVersion()) {
        handler.reject(
          DioException(requestOptions: options, type: DioExceptionType.cancel),
        );
        return;
      }
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (_) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: StateError('보안 저장소를 읽지 못했습니다.'),
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final version = err.requestOptions.extra[_versionKey];
    if (_protected(err.requestOptions) &&
        version is int &&
        isSessionError(err)) {
      await onSessionExpired(version);
    }
    handler.next(err);
  }
}
