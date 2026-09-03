import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'auth_service.dart';

// Mirrors backend role_permission.py defaults
const _rolePermissions = <String, List<String>>{
  'admin': [
    'payment.confirm',
    'payment.view_receipt',
    'dashboard.view',
    'users.manage',
    'permissions.manage',
    'token.generate',
    'token.bulk',
    'token.view',
    'event.manage',
    'content.manage',
    'expense.manage',
  ],
  'managing_committee': ['dashboard.view'],
  'core_committee':     ['dashboard.view'],
  'executive':          ['dashboard.view'],
  'cashier': [
    'payment.initiate',
    'payment.confirm',
    'payment.view_receipt',
    'collector.view_own',
    'dashboard.view',
    'expense.manage',
  ],
  'collector': [
    'payment.initiate',
    'payment.confirm',
    'payment.view_receipt',
    'collector.view_own',
    'token.generate',
  ],
  'committee': [
    'payment.initiate',
    'payment.confirm',
    'payment.view_receipt',
    'collector.view_own',
    'token.generate',
  ],
  'general': [
    'payment.initiate',
    'payment.confirm',
    'payment.view_receipt',
    'collector.view_own',
    'token.generate',
  ],
};

/// Roles that see aggregate dashboards but not individual payment records.
/// Mirrors OVERSIGHT_ROLES in the web frontend's config/roles.ts.
const oversightRoles = {'managing_committee', 'core_committee', 'executive'};

class AuthState {
  final bool isLoggedIn;
  final String? role;
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? avatarUrl;
  final bool canCollectFlag;

  const AuthState({
    this.isLoggedIn = false,
    this.role,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.avatarUrl,
    this.canCollectFlag = false,
  });

  AuthState copyWith({String? avatarUrl, bool clearAvatar = false}) => AuthState(
        isLoggedIn: isLoggedIn,
        role: role,
        name: name,
        email: email,
        phone: phone,
        address: address,
        avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
        canCollectFlag: canCollectFlag,
      );

  bool hasPermission(String key) {
    if (role == null) return false;
    return _rolePermissions[role]?.contains(key) ?? false;
  }

  bool get isOversight => oversightRoles.contains(role);

  // Mirrors web userCanCollect():
  // admin → never, collector/committee/general → always, all others → check DB flag
  bool get canCollect {
    if (role == null) return false;
    if (role == 'admin') return false;
    if (role == 'collector' || role == 'committee' || role == 'general') return true;
    // oversight, cashier, and any other role: check per-user flag from DB
    return canCollectFlag;
  }

  bool get canViewDashboard   => hasPermission('dashboard.view');
  bool get canViewCollections => hasPermission('collector.view_own');
  bool get canGenerateToken   => hasPermission('token.generate');
  bool get canManageUsers     => hasPermission('users.manage');
  bool get canManageEvents    => hasPermission('event.manage');
  bool get canManageContent   => hasPermission('content.manage');
  bool get canManageExpenses  => hasPermission('expense.manage');
  bool get canBulkToken       => hasPermission('token.bulk');

  /// Payment records are hidden from oversight roles — they see only aggregates.
  bool get canViewPaymentRecords => canViewDashboard && !isOversight;

  // Matches web: admin and cashier cannot create pledges
  bool get canCreatePledge =>
      role != null && role != 'admin' && role != 'cashier';

  /// Two-letter fallback shown when no profile picture is set.
  String get initials {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final raw = parts.length == 1
        ? (parts.first.length <= 2 ? parts.first : parts.first.substring(0, 2))
        : parts.first[0] + parts.last[0];
    return raw.toUpperCase();
  }

  String get roleLabel => (role ?? '').replaceAll('_', ' ').toUpperCase();
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;
  AuthNotifier(this._service) : super(const AuthState());

  Future<void> init() async {
    final loggedIn = await _service.isLoggedIn();
    if (!loggedIn) return;
    state = await _readCache();
    // Refresh from the server in the background; stale cache stays usable if offline.
    unawaited(refresh());
  }

  Future<AuthState> _readCache() async {
    final avatar = await _service.getAvatarUrl();
    return AuthState(
      isLoggedIn:     true,
      role:           await _service.getRole(),
      name:           await _service.getName(),
      email:          await _service.getEmail(),
      phone:          await _service.getPhone(),
      address:        await _service.getAddress(),
      avatarUrl:      (avatar == null || avatar.isEmpty) ? null : avatar,
      canCollectFlag: await _service.getCanCollect(),
    );
  }

  /// Pulls the current profile from /api/auth/me. Silently keeps the cached
  /// state when the request fails, so going offline never logs the user out.
  Future<void> refresh() async {
    final user = await _service.fetchMe();
    if (user == null) return;
    state = await _readCache();
  }

  Future<void> login(String username, String password) async {
    final data = await _service.login(username, password);
    final avatar = data['avatarUrl'] as String?;
    state = AuthState(
      isLoggedIn:     true,
      role:           data['role'] as String?,
      name:           data['name'] as String?,
      email:          data['email'] as String?,
      phone:          data['phone'] as String?,
      address:        data['address'] as String?,
      avatarUrl:      (avatar == null || avatar.isEmpty) ? null : avatar,
      canCollectFlag: data['canCollect'] == true,
    );
  }

  Future<void> uploadAvatar(XFile file) async {
    final url = await _service.uploadAvatar(file);
    state = state.copyWith(avatarUrl: url);
  }

  Future<void> removeAvatar() async {
    await _service.removeAvatar();
    state = state.copyWith(clearAvatar: true);
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthState();
  }
}

final authServiceProvider = Provider((_) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
