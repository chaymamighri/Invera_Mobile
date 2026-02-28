import 'package:dio/dio.dart';
import '../model/jwt_response.dart';

class AuthApi {
  final Dio dio;
  AuthApi(this.dio);

  Future<JwtResponse> login({required String email, required String password}) async {
    final res = await dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );

    return JwtResponse.fromJson(res.data);
  }
}