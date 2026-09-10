import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/debug.dart';
import 'package:new_zhic_tool/provider/auth_notifier.dart';
import 'package:new_zhic_tool/provider/schedule_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginInfo {
  const LoginInfo({required this.username, required this.password});

  final String username;
  final String password;
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, required this.username, required this.password});

  final String username;
  final String password;

  static const String _savedAccountsKey = 'login_saved_accounts';

  static Future<bool> open(BuildContext context) async {
    debugShow('开始登入流程');

    final loginInfo = await showLoginDialog(context);

    debugShow(
      '登入配置 Dialog 返回：'
      '${loginInfo == null ? '取消' : '确认'}',
    );

    if (loginInfo == null) {
      return false;
    }

    if (!context.mounted) {
      return false;
    }
    debugShow('准备进入 LoginPage');
    Fluttertoast.showToast(msg: '尝试自动登入中, 无需手动操作');
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LoginPage(
          username: loginInfo.username,
          password: loginInfo.password,
        ),
      ),
    );

    return result == true;
  }

  static Future<LoginInfo?> showLoginDialog(BuildContext context) async {
    final savedAccounts = await _loadSavedAccounts();

    if (!context.mounted) {
      return null;
    }

    debugShow(
      '已读取保存账号：'
      '${savedAccounts.length} 个',
    );

    return showDialog<LoginInfo>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _LoginDialog(savedAccounts: savedAccounts);
      },
    );
  }

  static Future<List<Map<String, dynamic>>> _loadSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_savedAccountsKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where(
            (account) =>
                account['username'] != null && account['password'] != null,
          )
          .toList();
    } catch (e) {
      debugShow('读取登入账号记录失败：$e');
      return [];
    }
  }

  static Future<void> _saveAccount({
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final accounts = await _loadSavedAccounts();

    accounts.removeWhere((account) => account['username'] == username);

    accounts.insert(0, {'username': username, 'password': password});

    if (accounts.length > 5) {
      accounts.removeRange(5, accounts.length);
    }

    await prefs.setString(_savedAccountsKey, jsonEncode(accounts));

    debugShow('保存登入账号：$username');
  }

  static Future<void> _deleteSavedAccount(String username) async {
    final prefs = await SharedPreferences.getInstance();

    final accounts = await _loadSavedAccounts();

    accounts.removeWhere((account) => account['username'] == username);

    await prefs.setString(_savedAccountsKey, jsonEncode(accounts));

    debugShow('删除保存账号：$username');
  }

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginDialog extends StatefulWidget {
  const _LoginDialog({required this.savedAccounts});

  final List<Map<String, dynamic>> savedAccounts;

  @override
  State<_LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<_LoginDialog> {
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;

  bool saveInfo = true;

  @override
  void initState() {
    super.initState();

    usernameController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty) {
      Fluttertoast.showToast(msg: '请输入学号');
      return;
    }

    if (password.isEmpty) {
      Fluttertoast.showToast(msg: '请输入密码');
      return;
    }

    debugShow('完成登入配置');
    debugShow('保存登入信息：$saveInfo');

    if (saveInfo) {
      await LoginPage._saveAccount(username: username, password: password);
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context)
        .pop(LoginInfo(username: username, password: password));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('登入'),

      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              if (widget.savedAccounts.isNotEmpty) ...[
                ...widget.savedAccounts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final account = entry.value;
                  final username = account['username']?.toString() ?? '';
                  final password = account['password']?.toString() ?? '';
                  final padded = username.padRight(5, 'x');
                  final result = padded.substring(padded.length - 5);
                  return M3ESegmentedItem(
                    index: 0,
                    position: .first,
                    outerRadius: 24,
                    innerRadius: 24,
                    gap: .minPositive,
                    onTap: (index) {
                      HapticFeedback.lightImpact();
                      debugShow(
                        '点击保存账号, '
                        '直接登入：$username',
                      );

                      Navigator.of(
                        context,
                      ).pop(LoginInfo(username: username, password: password));
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          child: Text(
                            username.isNotEmpty ? result : '?',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                username,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                '点此即可登入',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: '删除',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            debugShow('删除保存账号：$username');
                            HapticFeedback.lightImpact();

                            await LoginPage._deleteSavedAccount(username);

                            if (!mounted) {
                              return;
                            }

                            if (index >= widget.savedAccounts.length) {
                              return;
                            }

                            setState(() {
                              widget.savedAccounts.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
              TextField(
                controller: usernameController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: '学号',
                  hintText: '请输入学号',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  FocusScope.of(context).nextFocus();
                },
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: '密码',
                  hintText: '请输入密码',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) async {
                  await _submit();
                },
              ),
              Row(
                children: [
                  Checkbox(
                    value: saveInfo,
                    onChanged: (value) {
                      setState(() {
                        saveInfo = value ?? true;
                      });
                    },
                  ),
                  Text('储存账号密码'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedback.heavyImpact();
            debugShow('取消登入');
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () async {
            HapticFeedback.heavyImpact();
            await _submit();
          },
          child: const Text('登入'),
        ),
      ],
    );
  }
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const String _loginUrl =
      'https://cas.tjzhic.edu.cn/cas/login?service=https%3A%2F%2Feams.tjzhic.edu.cn%2Fstudent%2Fsso%2Flogin';
  double _progress = 0;
  bool _checkingLogin = false;
  bool _autoLoginTriggered = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: _progress < 1.0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: M3ELinearProgressIndicator(value: _progress),
              )
            : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(_loginUrl)),
        onWebViewCreated: (controller) {
          debugShow('WebView 已创建');

          debugShow(
            '登入账号已准备：'
            '${widget.username}',
          );
        },
        onProgressChanged: (controller, progress) {
          if (!mounted) {
            return;
          }

          setState(() {
            _progress = progress / 100;
          });
        },
        onLoadStart: (controller, url) {
          if (url == null) {
            return;
          }

          debugShow('WebView LoadStart URL: $url');

          _checkLoginSuccess(url);
        },
        onLoadStop: (controller, url) async {
          if (url == null) {
            return;
          }

          final urlString = url.toString();

          debugShow(
            'WebView LoadStop URL: '
            '$urlString',
          );

          if (urlString.contains('/cas/login')) {
            await _fillLoginForm(controller);
          }

          if (!mounted) {
            return;
          }

          await _checkLoginSuccess(url);
        },
      ),
    );
  }

  Future<void> _fillLoginForm(InAppWebViewController controller) async {
    if (!mounted) return;
    if (widget.username.isEmpty || widget.password.isEmpty) {
      debugShow('没有登入账号信息, 跳过自动填写');
      return;
    }
    if (_autoLoginTriggered) {
      debugShow('自动登入已经触发过');
      return;
    }

    debugShow('开始快速自动填写 CAS 登入');

    final result = await controller.evaluateJavascript(
      source:
          '''
(() => {
  return new Promise((resolve) => {
    const encodedUsername = ${jsonEncode(widget.username)};
    const encodedPassword = ${jsonEncode(widget.password)};
    const maxAttempts = 50;
    const intervalMs = 30;
    let attempts = 0;

    function findInputs() {
      const inputs = Array.from(document.querySelectorAll('input'));
      let username = inputs.find(i =>
        i.placeholder?.includes('教工号') || i.placeholder?.includes('学号')
      );
      let password = inputs.find(i =>
        i.type === 'password' || i.placeholder?.includes('密码')
      );
      if (!username) username = inputs.find(i => i.type === 'text');
      if (!password) {
        password = inputs.find(i =>
          i !== username && (i.type === 'password' || i.autocomplete === 'current-password')
        );
      }
      return { username, password };
    }

    function setNativeValue(input, value) {
      const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set;
      input.focus();
      setter.call(input, value);
      input.dispatchEvent(new InputEvent('input', { bubbles: true, composed: true, inputType: 'insertText', data: value }));
      input.dispatchEvent(new Event('change', { bubbles: true, composed: true }));
      input.dispatchEvent(new Event('blur', { bubbles: true, composed: true }));
    }

    function findAndClickButton() {
      const selectors = ['button', 'a', 'input', 'div', 'span', '[role="button"]'];
      const elements = Array.from(document.querySelectorAll(selectors.join(',')));

      function visible(el) {
        const rect = el.getBoundingClientRect();
        const style = window.getComputedStyle(el);
        return rect.width > 0 && rect.height > 0 &&
               style.display !== 'none' && style.visibility !== 'hidden' && style.opacity !== '0';
      }

      function textOf(el) {
        return (el.innerText || el.textContent || el.value || el.getAttribute('value') || '').trim().toLowerCase();
      }

      function score(el) {
        let s = 0;
        const text = textOf(el);
        const className = (typeof el.className === 'string' ? el.className : '').toLowerCase();
        const id = (el.id || '').toLowerCase();
        const type = (el.getAttribute('type') || '').toLowerCase();
        const aria = (el.getAttribute('aria-label') || '').toLowerCase();

        if (text === '登录' || text === '登入' || text === 'login' || text === 'sign in') s += 100;
        else if (text.includes('登录') || text.includes('登入') || text.includes('login')) s += 60;
        if (type === 'submit') s += 40;
        if (id.includes('login') || id.includes('submit')) s += 30;
        if (className.includes('login') || className.includes('submit') || className.includes('btn')) s += 20;
        if (aria.includes('登录') || aria.includes('login')) s += 20;
        return s;
      }

      let candidates = elements
        .filter(el => visible(el) && el.disabled !== true && score(el) > 0)
        .sort((a, b) => score(b) - score(a));

      if (candidates.length === 0) {
        const form = document.querySelector('form');
        if (form) {
          candidates = Array.from(form.querySelectorAll('button, input[type="submit"], input[type="button"]'))
            .filter(el => visible(el) && el.disabled !== true);
        }
      }

      if (candidates.length === 0) {
        candidates = elements.filter(el => el.tagName === 'BUTTON' && visible(el) && el.disabled !== true);
      }

      if (candidates.length === 0) return null;

      const element = candidates[0];
      element.scrollIntoView({ behavior: 'instant', block: 'center' });
      if (typeof element.focus === 'function') element.focus();
      element.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, cancelable: true, view: window, buttons: 1 }));
      element.dispatchEvent(new MouseEvent('mouseup', { bubbles: true, cancelable: true, view: window, buttons: 1 }));
      element.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
      if (typeof element.click === 'function') element.click();

      return { tag: element.tagName, text: textOf(element) };
    }

    function attempt() {
      attempts++;
      const { username, password } = findInputs();

      if (username && password) {
        
        setNativeValue(username, encodedUsername);
        setNativeValue(password, encodedPassword);

        
        requestAnimationFrame(() => {
          const btn = findAndClickButton();
          if (btn) {
            resolve({ success: true, filled: true, clicked: true, tag: btn.tag, text: btn.text });
          } else {
            resolve({ success: true, filled: true, clicked: false, reason: 'login_control_not_found' });
          }
        });
        return;
      }

      if (attempts >= maxAttempts) {
        resolve({ success: false, filled: false, clicked: false, reason: 'timeout' });
        return;
      }

      setTimeout(attempt, intervalMs);
    }

    attempt();
  });
})();
''',
    );

    debugShow('自动填表与点击结果：$result');

    if (!mounted) return;

    if (result is Map && result['clicked'] == true) {
      _autoLoginTriggered = true;
      debugShow('登入控件点击成功, 等待页面跳转');
    } else {
      debugShow('未能自动点击登录按钮, 请手动点击');
    }
  }

  Future<void> _checkLoginSuccess(WebUri url) async {
    final urlString = url.toString();
    debugShow('检查登入 URL：$urlString');
    if (!urlString.contains('/student/home')) {
      return;
    }
    if (_checkingLogin) {
      debugShow('正在检查登入状态, 跳过重复检测');
      return;
    }
    _checkingLogin = true;
    debugShow('检测到登入成功页面, 开始获取 Cookie');
    try {
      final success = await ref.read(authProvider.notifier).login();
      if (!mounted) {
        return;
      }
      if (success) {
        debugShow('登入成功');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        if (!mounted) {
          return;
        }
        await ref.read(scheduleProvider.notifier).loadCourses();
        if (!mounted) {
          return;
        }
        Fluttertoast.showToast(msg: '登入成功！');
        Confetti.launch(
          context,
          options: const ConfettiOptions(
            particleCount: 150,
            spread: 70,
            y: 0.7,
          ),
        );
        final navigator = Navigator.of(context);
        if (mounted) {
          navigator.pop(true);
        }
      } else {
        debugShow('登入失败：Cookie 获取失败');
        if (mounted) {
          Fluttertoast.showToast(msg: '登入失败, 无法获取登入信息');
        }
        _checkingLogin = false;
      }
    } catch (e, stackTrace) {
      debugShow('登入失败：$e');
      debugShow(stackTrace.toString());
      if (!mounted) {
        return;
      }
      Fluttertoast.showToast(msg: '登入失败');
      _checkingLogin = false;
    }
  }
}
