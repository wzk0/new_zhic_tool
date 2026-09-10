import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:new_zhic_tool/core/debug.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetworkService {
  NetworkService._();
  static final NetworkService instance = NetworkService._();
  static const String _cookieKey = 'cookies';
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
      debugShow('警告：当前请求需要 Cookie, 但没有 Cookie');
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

  Future<String?> getStudentBusinessId() async {
    const url = 'https://eams.tjzhic.edu.cn/student/for-std/grade/sheet/';
    final prefs = await SharedPreferences.getInstance();
    final cookies = prefs.getString('cookies')?.replaceAll('"', '');
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url))
        ..followRedirects = false
        ..headers['Cookie'] = cookies ?? ''
        ..headers['User-Agent'] = 'Mozilla/5.0';
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      final location = response.headers['location'];
      if (location != null) {
        final id = _extractId(location);
        if (id != null) {
          return id;
        }
      }
      final finalUrl = response.request?.url.toString() ?? '';
      return _extractId(finalUrl);
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  String? _extractId(String url) {
    final regExp = RegExp(r'/(\d+)(?:\?|$)');

    final match = regExp.firstMatch(url);

    return match?.group(1);
  }
}
