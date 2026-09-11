import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/debug.dart';
import 'package:new_zhic_tool/core/icon.dart';
import 'package:new_zhic_tool/page/home_page.dart';
import 'package:new_zhic_tool/page/login_page.dart';
import 'package:new_zhic_tool/provider/auth_notifier.dart';
import 'package:new_zhic_tool/provider/schedule_notifier.dart';
import 'package:new_zhic_tool/widget/drawer_widget.dart';
import 'package:share_plus/share_plus.dart';

class WidgetTree extends ConsumerStatefulWidget {
  const WidgetTree({super.key});

  @override
  ConsumerState<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends ConsumerState<WidgetTree> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final classWidgetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final isLoggedIn = await ref.read(authProvider.notifier).checkLogin();
    if (!mounted) {
      return;
    }
    debugShow('恢复登入状态: $isLoggedIn');
    if (!isLoggedIn) {
      return;
    }
    await ref.read(scheduleProvider.notifier).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authProvider);
    return Scaffold(
      key: scaffoldKey,
      drawer: const DrawerWidget(),
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: M3EButton(
            onPressed: () {
              scaffoldKey.currentState?.openDrawer();
            },
            style: .text,
            size: .sm,
            child: Icon(Mdi.apps, size: 26),
          ),
        ),
        title: Text('掌环', style: Theme.of(context).textTheme.titleMedium),
        actions: [
          M3ESplitButton(
            label: isLoggedIn ? '登出' : '登入',
            leadingIcon: isLoggedIn ? Mdi.logout : Mdi.login,
            size: .xs,
            style: .tonal,
            items: const [
              M3ESplitButtonItem(value: 'refresh', child: Text('以上次登录学号重新登入')),
              M3ESplitButtonItem(value: 'share', child: Text('以图片形式分享课表')),
            ],
            onPressed: () async {
              if (isLoggedIn) {
                await _logout();
              } else {
                await _openLoginPage();
              }
            },
            onSelected: (value) async {
              switch (value) {
                case 'refresh':
                  await _refreshLoginStatus();
                  break;
                case 'share':
                  await _shareClassSchedule();
                  break;
              }
            },
          ),
        ],
      ),
      body: HomePage(classWidgetKey: classWidgetKey),
    );
  }

  Future<void> _openLoginPage() async {
    final success = await LoginPage.open(context);
    if (!mounted) {
      return;
    }
    if (success) {
      await ref.read(scheduleProvider.notifier).initialize();
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) {
      return;
    }
    _showMessage('已退出登入');
  }

  Future<void> _refreshLoginStatus() async {
    HapticFeedback.lightImpact();
    debugShow('开始重新登入流程');
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
      debugShow('没有保存的账号, 打开登入弹窗');
      _showMessage('账号密码未储存, 请手动登入');
      final success = await LoginPage.open(context);
      if (!mounted) {
        return;
      }
      if (success) {
        await ref.read(scheduleProvider.notifier).initialize();
      }
      return;
    }
    debugShow(
      '使用当前保存的账号重新登入：'
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
      await ref.read(scheduleProvider.notifier).initialize();
      if (!mounted) {
        return;
      }
      _showMessage('重新登入成功');
    } else {
      _showMessage('重新登入失败');
    }
  }

  Future<void> _shareClassSchedule() async {
    HapticFeedback.lightImpact();
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
      final renderObject = classWidgetKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        _showMessage('课表还没有准备好, 请稍后再试');
        return;
      }
      final renderBox = renderObject;
      final sharePositionOrigin =
          renderBox.localToGlobal(Offset.zero) & renderBox.size;
      final ui.Image image = await renderObject.toImage(pixelRatio: 3.0);
      try {
        final ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData == null) {
          _showMessage('生成课表图片失败');
          return;
        }
        final Uint8List bytes = byteData.buffer.asUint8List();
        final result = await SharePlus.instance.share(
          ShareParams(
            title: '分享课表',
            subject: '我的课表',
            text: '我的本周课表',
            files: [
              XFile.fromData(bytes, mimeType: 'image/png', name: '课表.png'),
            ],
            fileNameOverrides: const ['课表.png'],
            sharePositionOrigin: sharePositionOrigin,
          ),
        );
        debugShow(
          '分享结果: '
          '${result.status}',
        );
      } finally {
        image.dispose();
      }
    } catch (e, stackTrace) {
      debugShow('分享课表失败: $e');
      debugShow(stackTrace.toString());
      if (mounted) {
        _showMessage('分享课表失败');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    Fluttertoast.showToast(msg: message);
  }
}
