import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:new_zhic_tool/core/debug.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetworkService {
  NetworkService._();

  static final NetworkService instance = NetworkService._();

  static const String _cookieKey = 'cookies';

  /// 全局请求延迟。
  /// 后续可直接在设置页面修改此值：
  /// `NetworkService.instance.requestDelay = Duration(milliseconds: 500);`
  Duration requestDelay = Duration.zero;

  Future<Map<String, String>> _buildHeaders({
    bool withCookies = false,
    bool json = false,
  }) async {
    String? cookie;

    if (withCookies) {
      final prefs = await SharedPreferences.getInstance();
      cookie = prefs.getString(_cookieKey);
    }

    return {
      'Accept': 'application/json, text/plain, */*',
      'User-Agent': 'Mozilla/5.0',
      if (json) 'Content-Type': 'application/json;charset=UTF-8',
      if (withCookies && cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
    };
  }

  Future<dynamic> get(
    String url, {
    Map<String, String>? queryParameters,
    Duration timeout = const Duration(seconds: 8),
    bool withCookies = false,
  }) async {
    await _applyDelay();

    final uri = Uri.parse(url).replace(queryParameters: queryParameters);
    debugShow('GET: $uri');

    final headers = await _buildHeaders(withCookies: withCookies);
    _checkCookie(withCookies: withCookies, headers: headers);

    final response = await http.get(uri, headers: headers).timeout(timeout);
    return _handleResponse(response);
  }

  Future<dynamic> post(
    String url, {
    Object? body,
    Map<String, String>? queryParameters,
    Duration timeout = const Duration(seconds: 8),
    bool withCookies = false,
  }) async {
    await _applyDelay();

    final uri = Uri.parse(url).replace(queryParameters: queryParameters);
    debugShow('POST: $uri');

    final headers = await _buildHeaders(withCookies: withCookies, json: true);
    _checkCookie(withCookies: withCookies, headers: headers);

    final response = await http
        .post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout);

    return _handleResponse(response);
  }

  Future<void> _applyDelay() async {
    if (requestDelay > Duration.zero) {
      await Future.delayed(requestDelay);
    }
  }

  void _checkCookie({
    required bool withCookies,
    required Map<String, String> headers,
  }) {
    if (withCookies && !headers.containsKey('Cookie')) {
      debugShow('警告：当前请求需要 Cookie，但没有 Cookie');
    }
  }

  dynamic _handleResponse(http.Response response) {
    debugShow(
      'HTTP ${response.statusCode}: '
      '${response.request?.url}',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'HTTP ${response.statusCode}: '
        '${response.reasonPhrase}',
      );
    }

    if (response.body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(response.body);
    } on FormatException catch (e) {
      throw FormatException('服务器返回的数据不是有效 JSON: $e');
    }
  }

  /// 获取请求信息及重定向后的最终 URL
  // 在 NetworkService 类中添加此方法
  Future<String?> getRedirectUrl(
    String url, {
    Map<String, String>? queryParameters,
    Duration timeout = const Duration(seconds: 8),
    bool withCookies = false,
  }) async {
    await _applyDelay();

    final uri = Uri.parse(url).replace(queryParameters: queryParameters);
    debugShow('GET Redirect: $uri');

    final headers = await _buildHeaders(withCookies: withCookies);

    // 使用独立的 http.Client 以便手动控制重定向
    final client = http.Client();
    try {
      var currentUri = uri;
      // 发起请求，禁用自动跟随重定向以便捕获 location
      // 或者用循环追踪重定向
      while (true) {
        final request = http.Request('GET', currentUri)
          ..headers.addAll(headers);
        final streamedResponse = await client.send(request).timeout(timeout);

        // 检查是否是重定向状态码 (301, 302, 303, 307, 308)
        if ([301, 302, 303, 307, 308].contains(streamedResponse.statusCode)) {
          final location = streamedResponse.headers['location'];
          if (location != null) {
            // 处理相对路径或绝对路径
            currentUri = currentUri.resolve(location);
            continue;
          }
        }
        return currentUri.toString();
      }
    } finally {
      client.close();
    }
  }

  // 在 NetworkService 类中添加此方法
  Future<String?> fetchRedirectUrl(
    String url, {
    Map<String, String>? queryParameters,
    Duration timeout = const Duration(seconds: 8),
    bool withCookies = false,
  }) async {
    await _applyDelay();

    final uri = Uri.parse(url).replace(queryParameters: queryParameters);
    debugShow('GET Redirect URL: $uri');

    final headers = await _buildHeaders(withCookies: withCookies);

    // 使用独立的 Client 以防污染全局
    final client = http.Client();
    try {
      // 发起 GET 请求（http 默认会自动跟随 302 重定向，最多 5 次）
      final request = http.Request('GET', uri)..headers.addAll(headers);
      final streamedResponse = await client.send(request).timeout(timeout);

      // streamedResponse.request?.url 就是经历所有 302 重定向后的最终 URL！
      final finalUrl = streamedResponse.request?.url.toString();

      // 消费掉流，释放连接
      await streamedResponse.stream.drain();

      return finalUrl;
    } finally {
      client.close();
    }
  }
}
