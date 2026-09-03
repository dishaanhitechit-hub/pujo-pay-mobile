import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
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
    final user = (data['user'] as Map).cast<String, dynamic>();
    await _storage.write(key: 'jwt', value: data['accessToken'] as String);
    await _cacheUser(user);
    return user;
  }

  /// Re-reads the profile from the server and refreshes the local cache.
  /// Returns null when the session is no longer valid.
  Future<Map<String, dynamic>?> fetchMe() async {
    try {
      final res = await _client.get(Api.me);
      if (res.statusCode != 200) return null;
      final user = (res.data['data'] as Map?)?.cast<String, dynamic>();
      if (user == null) return null;
      await _cacheUser(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadAvatar(XFile file) async {
    final res = await _client.upload(Api.myAvatar, file.path);
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(res.data?['message'] ?? 'upload failed');
    }
    final url = (res.data['data'] as Map?)?['avatarUrl'] as String?;
    await _storage.write(key: 'avatar_url', value: url ?? '');
    return url;
  }

  Future<void> removeAvatar() async {
    await _client.delete(Api.myAvatar);
    await _storage.write(key: 'avatar_url', value: '');
  }

  Future<void> _cacheUser(Map<String, dynamic> user) async {
    await _storage.write(key: 'role',        value: user['role'] as String? ?? '');
    await _storage.write(key: 'name',        value: user['name'] as String? ?? '');
    await _storage.write(key: 'email',       value: user['email'] as String? ?? '');
    await _storage.write(key: 'phone',       value: user['phone'] as String? ?? '');
    await _storage.write(key: 'address',     value: user['address'] as String? ?? '');
    await _storage.write(key: 'avatar_url',  value: user['avatarUrl'] as String? ?? '');
    await _storage.write(key: 'user_id',     value: user['id'].toString());
    await _storage.write(key: 'can_collect', value: (user['canCollect'] == true).toString());
  }

  Future<void> logout() async {
    try { await _client.post(Api.logout); } catch (_) {}
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async => await _storage.read(key: 'jwt') != null;

  Future<String?> getRole()      => _storage.read(key: 'role');
  Future<String?> getName()      => _storage.read(key: 'name');
  Future<String?> getEmail()     => _storage.read(key: 'email');
  Future<String?> getPhone()     => _storage.read(key: 'phone');
  Future<String?> getAddress()   => _storage.read(key: 'address');
  Future<String?> getAvatarUrl() => _storage.read(key: 'avatar_url');
  Future<String?> getUserId()    => _storage.read(key: 'user_id');

  Future<bool> getCanCollect() async =>
      await _storage.read(key: 'can_collect') == 'true';
}
