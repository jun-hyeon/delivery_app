import 'package:delivery_app/common/const/data.dart';
import 'package:delivery_app/common/secure_storage/secure_storage.dart';
import 'package:delivery_app/user/repository/auth_repository.dart';
import 'package:delivery_app/user/repository/user_me_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../model/user_model.dart';

final userMeProvider =
    StateNotifierProvider<UserMeStateNotifier, UserModelBase?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final repository = ref.watch(userMeRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  return UserMeStateNotifier(
    authRepository: authRepository,
    repository: repository,
    storage: storage,
  );
});

class UserMeStateNotifier extends StateNotifier<UserModelBase?> {
  final AuthRepository authRepository;
  final UserMeRepository repository;
  final FlutterSecureStorage storage;
  UserMeStateNotifier({
    required this.authRepository,
    required this.repository,
    required this.storage,
  }) : super(UserModelLoading()) {
    //내 정보 가져오기
    getMe();
  }

  getMe() async {
    final accessToken = await storage.read(key: ACCESS_TOKEN_KEY);
    final refreshToken = await storage.read(key: REFRESH_TOKEN_KEY);

    if (refreshToken == null || accessToken == null) {
      state = null;
      return;
    }

    final response = await repository.getMe();

    state = response;
  }

  Future<UserModelBase> login({
    required String username,
    required String password,
  }) async {
    try {
      state = UserModelLoading();

      final resp = await authRepository.login(
        username: username,
        password: password,
      );

      await storage.write(key: REFRESH_TOKEN_KEY, value: resp.refreshToken);
      await storage.write(key: ACCESS_TOKEN_KEY, value: resp.accessToken);

      final userResp = await repository.getMe();

      state = userResp;

      return userResp;
    } catch (e) {
      state = UserModelError(message: '로그인에 실패했습니다.');
      return Future.value(state);
    }
  }

  Future<void> logout() async {
    state = null;

    await Future.wait([
      storage.delete(key: REFRESH_TOKEN_KEY),
      storage.delete(key: ACCESS_TOKEN_KEY),
    ]);
  }
}
