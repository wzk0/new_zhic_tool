import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_zhic_tool/core/debug.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedLoginAccount {
  const SavedLoginAccount({required this.username, required this.password});

  final String username;
  final String password;
}

class AuthNotifier extends Notifier<bool> {
  static const String _homeUrl = 'https://eams.tjzhic.edu.cn/student/home';

  static const String _cookieKey = 'cookies';

  static const String _savedAccountsKey = 'login_saved_accounts';

  @override
  bool build() {
    return false;
  }

  /// 获取当前最近保存的登入账号
  ///
  /// 返回 null 表示没有可用账号
  Future<SavedLoginAccount?> getCurrentSavedAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final raw = prefs.getString(_savedAccountsKey);

      if (raw == null || raw.isEmpty) {
        debugShow('没有保存的登入账号');
        return null;
      }

      final decoded = jsonDecode(raw);

      if (decoded is! List || decoded.isEmpty) {
        debugShow('保存的登入账号格式错误或为空');
        return null;
      }

      final accounts = decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where(
            (account) =>
                account['username'] != null && account['password'] != null,
          )
          .toList();

      if (accounts.isEmpty) {
        debugShow('没有有效的保存账号');
        return null;
      }

      final account = accounts.first;

      final username = account['username']?.toString().trim() ?? '';

      final password = account['password']?.toString() ?? '';

      if (username.isEmpty || password.isEmpty) {
        debugShow('当前保存账号信息无效');
        return null;
      }

      debugShow('获取当前保存账号成功：$username');

      return SavedLoginAccount(username: username, password: password);
    } catch (e, stackTrace) {
      debugShow('获取当前保存账号失败：$e');
      debugShow(stackTrace.toString());

      return null;
    }
  }

  Future<bool> login() async {
    try {
      final cookieManager = CookieManager.instance();

      final cookies = await cookieManager.getCookies(url: WebUri(_homeUrl));

      debugShow('获取到 Cookie 数量: ${cookies.length}');

      if (cookies.isEmpty) {
        debugShow('Cookie 为空');

        state = false;

        return false;
      }

      final prefs = await SharedPreferences.getInstance();

      for (final cookie in cookies) {
        debugShow(
          'Cookie: '
          '${cookie.name}=${cookie.value}',
        );

        await prefs.setBool('is_logged_in', true);
      }

      final cookieString = cookies
          .map((cookie) => '${cookie.name}=${cookie.value}')
          .join('; ');

      final success = await prefs.setString(_cookieKey, cookieString);

      if (success) {
        state = true;

        debugShow('Cookie 保存成功');
        debugShow('登入状态: true');
      } else {
        state = false;

        debugShow('Cookie 保存失败');
      }

      return success;
    } catch (e, stackTrace) {
      debugShow('Cookie 捕获失败: $e');
      debugShow(stackTrace.toString());

      state = false;

      return false;
    }
  }

  Future<bool> checkLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final cookies = prefs.getString(_cookieKey);

      final loggedIn = cookies != null && cookies.isNotEmpty;

      state = loggedIn;

      debugShow('恢复登入状态: $loggedIn');

      return loggedIn;
    } catch (e, stackTrace) {
      debugShow('检查登入状态失败: $e');
      debugShow(stackTrace.toString());

      state = false;

      return false;
    }
  }

  Future<String?> getCookies() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return prefs.getString(_cookieKey);
    } catch (e) {
      debugShow('获取 Cookie 失败: $e');

      return null;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_cookieKey);

      await prefs.setBool('is_logged_in', false);

      await CookieManager.instance().deleteAllCookies();

      state = false;

      debugShow('已登出');
    } catch (e, stackTrace) {
      debugShow('登出失败: $e');
      debugShow(stackTrace.toString());

      state = false;
    }
  }

  void setLoggedIn(bool value) {
    state = value;
  }
}

final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);
