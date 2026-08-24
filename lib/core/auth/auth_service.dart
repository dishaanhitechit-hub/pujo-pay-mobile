import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/dio_client.dart';
import '../../config/api.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final _client = DioClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _client.post(Api.login, data: {
      'email':    email,
      'password': password,
    });
    final data = res.data['data'];
    final user = data['user'] as Map;
    await _storage.write(key: 'jwt',     value: data['accessToken'] as String);
    await _storage.write(key: 'role',    value: user['role'] as String);
    await _storage.write(key: 'name',    value: user['name'] as String);
    await _storage.write(key: 'user_id', value: user['id'].toString());
    return user as Map<String, dynamic>;
  }

  Future<void> logout() async {
    try { await _client.post(Api.logout); } catch (_) {}
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt');
    return token != null;
  }

  Future<String?> getRole()   => _storage.read(key: 'role');
  Future<String?> getName()   => _storage.read(key: 'name');
  Future<String?> getUserId() => _storage.read(key: 'user_id');
}
