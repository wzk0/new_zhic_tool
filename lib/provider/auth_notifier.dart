import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_zhic_tool/core/debug.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthNotifier extends Notifier<bool> {
  static const String _homeUrl = 'https://eams.tjzhic.edu.cn/student/home';

  static const String _cookieKey = 'cookies';

  @override
  bool build() {
    return false;
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

      for (final cookie in cookies) {
        debugShow(
          'Cookie: '
          '${cookie.name}=${cookie.value}',
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
      }

      final cookieString = cookies
          .map((cookie) => '${cookie.name}=${cookie.value}')
          .join('; ');

      final prefs = await SharedPreferences.getInstance();

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
