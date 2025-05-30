//1) 요청을 받았을 때
//2) 응답을 받았을 때
//3) 에러가 났을 때
import 'package:delivery_app/common/const/data.dart';
import 'package:delivery_app/common/secure_storage/secure_storage.dart';
import 'package:delivery_app/user/provider/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();

  final storage = ref.watch(secureStorageProvider);

  dio.interceptors.add(
    CustomInterceptor(
      storage: storage,
      ref: ref,
    ),
  );
  return dio;
});

class CustomInterceptor extends Interceptor {
  final FlutterSecureStorage storage;
  final Ref ref;
  CustomInterceptor({
    required this.storage,
    required this.ref,
  });

  // 1) 요청 보낼때
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    print('[REQ] [${options.method} ${options.uri}]');

    if (options.headers['accessToken'] == 'true') {
      //헤더 삭제
      options.headers.remove('accessToken');

      final token = await storage.read(key: ACCESS_TOKEN_KEY);
      //실제 토큰으로 대체
      options.headers.addAll({
        'authorization': 'Bearer $token',
      });
    }

    if (options.headers['refreshToken'] == 'true') {
      //헤더 삭제
      options.headers.remove('accessToken');

      final token = await storage.read(key: REFRESH_TOKEN_KEY);
      //실제 토큰으로 대체
      options.headers.addAll({
        'authorization': 'Bearer $token',
      });
    }

    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // TODO: implement onResponse
    print(
      '[RES][${response.requestOptions.method}] ${response.requestOptions.uri} ${response.data}',
    );
    return super.onResponse(response, handler);
  }

//3) 에러가 났을 때
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    //401에러가 났을 때 (status code)
    //토큰을 재발급 받는 시도를 하고 토큰이 재발급되면
    //다시 새로운 토큰을 요청을 한다.
    print('[ERR] [${err.requestOptions.method} ${err.requestOptions.uri}]');

    final refreshToken = await storage.read(key: REFRESH_TOKEN_KEY);

    // refreshToken 아예 없으면
    // 당연히 에러를 던진다.
    if (refreshToken == null) {
      //에러를 던질때는 handler.reject를 사용한다.
      return handler.reject(err);
    }

    final isStatus401 = err.response?.statusCode == 401;
    final isPathRefresh = err.requestOptions.path == '/auth/token';
    //accessToken을 요청하려던 상황에서 401에러가 발생
    //refreshToken을 이용하여 accessToken을 재발급
    if (isStatus401 && !isPathRefresh) {
      final dio = Dio();

      try {
        final resp = await dio.post(
          'http://$ip/auth/token',
          options: Options(
            headers: {
              'authorization': 'Bearer $refreshToken',
            },
          ),
        );

        final accessToken = resp.data['accessToken'];

        final options = err.requestOptions;
        //토큰 변경하기
        options.headers.addAll({
          'authorization': 'Bearer $accessToken',
        });

        await storage.write(key: ACCESS_TOKEN_KEY, value: accessToken);

        //요청 재전송
        final response = await dio.fetch(options);

        return handler.resolve(response);
      } on DioException {
        // circular dependency error
        // A, B
        // A -> B의 친구
        // B -> A의 친구
        // A는 B의 친구구나
        // A -> B -> A -> B -> A
        // userMeProvider -> dio -> userMeProvider -> dio
        ref.read(authProvider.notifier).logout();
        return handler.reject(err);
      }
    }
    return handler.reject(err);
  }
}
