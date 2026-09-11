import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/debug.dart';
import 'package:new_zhic_tool/page/login_page.dart';
import 'package:new_zhic_tool/provider/auth_notifier.dart';

class ErrorPage extends ConsumerStatefulWidget {
  final String text;
  final IconData icon;

  const ErrorPage({super.key, required this.text, required this.icon});

  @override
  ConsumerState<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends ConsumerState<ErrorPage> {
  bool _loggingIn = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 20,
        children: [
          Icon(widget.icon, size: 32, color: cs.error),

          Text(
            widget.text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: cs.outline),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              M3EButton(
                style: .filled,
                onPressed: _loggingIn
                    ? null
                    : () async {
                        HapticFeedback.lightImpact();
                        await _openLoginPage();
                      },
                child: Text(
                  '登入账号',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                ),
              ),

              M3EButton(
                style: .tonal,
                onPressed: _loggingIn
                    ? null
                    : () async {
                        HapticFeedback.lightImpact();
                        await _refreshLogin();
                      },
                child: _loggingIn
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: M3ELoadingIndicator(),
                      )
                    : Text(
                        '以上次登录学号重新登入',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openLoginPage() async {
    final success = await LoginPage.open(context);

    if (!mounted) {
      return;
    }

    if (success) {
      Fluttertoast.showToast(msg: '登入成功');
    }
  }

  Future<void> _refreshLogin() async {
    if (_loggingIn) {
      return;
    }

    setState(() {
      _loggingIn = true;
    });

    try {
      debugShow('ErrorPage 开始重新登入流程');

      final authNotifier = ref.read(authProvider.notifier);
      final account = await authNotifier.getCurrentSavedAccount();

      if (!mounted) {
        return;
      }
      await authNotifier.logout();

      if (!mounted) {
        return;
      }

      debugShow('当前登入状态已清除');
      if (account == null) {
        debugShow('没有保存的账号，打开登入弹窗');

        Fluttertoast.showToast(msg: '账号密码未储存，请手动登入');

        final success = await LoginPage.open(context);

        if (!mounted) {
          return;
        }

        if (success) {
          Fluttertoast.showToast(msg: '登入成功');
        }

        return;
      }
      debugShow(
        '使用保存账号重新登入：'
        '${account.username}',
      );

      Fluttertoast.showToast(msg: '正在重新登入...');

      final success = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              LoginPage(username: account.username, password: account.password),
        ),
      );

      if (!mounted) {
        return;
      }

      if (success == true) {
        Fluttertoast.showToast(msg: '重新登入成功');
      } else {
        Fluttertoast.showToast(msg: '重新登入失败');
      }
    } catch (e, stackTrace) {
      debugShow('重新登入失败: $e');
      debugShow(stackTrace.toString());

      if (mounted) {
        Fluttertoast.showToast(msg: '重新登入失败');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loggingIn = false;
        });
      }
    }
  }
}
