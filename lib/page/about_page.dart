import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/avatar_spin.dart';
import 'package:new_zhic_tool/core/icon.dart';
import 'package:new_zhic_tool/page/donation_page.dart';
import 'package:new_zhic_tool/widget/chip_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});
  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  String _currentVersion = 'v2.0.3';
  bool _isChecking = false;

  /// 头像旋转彩蛋的状态。
  late final AvatarSpinController _spin;

  static const String _kPrefsClickCount = 'about_icon_click_count';
  static const String _kPrefsAnimationValue = 'about_icon_animation_value';

  static const List<String> _funQuotes = [
    '别点了！',
    '生活明朗, 万物可爱, 除了教务系统.',
    '今天又是努力的一天呢！',
    '正在加载中环好运气... 100%！',
    '这只猫其实是中环校猫.',
  ];
  static const String _releaseApiUrl =
      'https://api.github.com/repos/wzk0/new_zhic_tool/releases/latest';

  static const String _sourceCodeUrl = 'https://github.com/wzk0/new_zhic_tool';

  @override
  void initState() {
    super.initState();
    _spin = AvatarSpinController(
      vsync: this,
      clickCountKey: _kPrefsClickCount,
      animationValueKey: _kPrefsAnimationValue,
    );
    _loadSavedState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPackageInfo();
    });
  }

  Future<void> _loadSavedState() async {
    await _spin.restore();

    if (!mounted || !_spin.isSpinning) {
      return;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform().timeout(
        const Duration(seconds: 3),
      );
      if (!mounted) return;
      final version = packageInfo.version.trim();
      if (version.isNotEmpty) {
        setState(() {
          _currentVersion = 'v$version';
        });
      }
    } catch (e) {
      debugPrint('获取版本号失败: $e');
    }
  }

  Future<void> _checkUpdate() async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
    });
    try {
      final response = await http
          .get(
            Uri.parse(_releaseApiUrl),
            headers: const {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (response.statusCode != 200) {
        Fluttertoast.showToast(msg: '检查更新失败：服务器响应异常');
        return;
      }
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        Fluttertoast.showToast(msg: '获取版本信息失败');
        return;
      }
      final latestVersion = data['tag_name']?.toString().trim() ?? '';
      final downloadUrl = data['html_url']?.toString().trim() ?? '';
      if (latestVersion.isEmpty || downloadUrl.isEmpty) {
        Fluttertoast.showToast(msg: '获取版本信息失败');
        return;
      }
      if (latestVersion == _currentVersion) {
        Fluttertoast.showToast(msg: '当前已是最新版本');
        return;
      }
      _showUpdateDialog(latestVersion, downloadUrl);
    } on TimeoutException {
      Fluttertoast.showToast(msg: '检查更新超时, 请检查网络');
    } catch (e) {
      debugPrint('检查更新失败: $e');
      Fluttertoast.showToast(msg: '无法连接到服务器, 请检查网络');
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  void _showUpdateDialog(String version, String url) {
    Confetti.launch(
      context,
      options: const ConfettiOptions(particleCount: 150, spread: 70, y: 0.7),
    );
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('发现新版本'),
          content: Text('检测到新版本 $version, 是否前往 GitHub 下载? '),
          actions: [
            M3EButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: .text,
              child: const Text('取消'),
            ),
            M3EButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _openUrl(url, failureMessage: '无法打开下载页面');
              },
              child: const Text('去更新'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openUrl(String url, {String failureMessage = '无法打开链接'}) async {
    try {
      final uri = Uri.parse(url);
      final success = await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.externalApplication,
      );
      if (!success) {
        Fluttertoast.showToast(msg: failureMessage);
      }
    } catch (e) {
      debugPrint('打开链接失败: $e');
      Fluttertoast.showToast(msg: failureMessage);
    }
  }

  void _onIconTap() {
    HapticFeedback.lightImpact();
    Confetti.launch(
      context,
      options: const ConfettiOptions(particleCount: 150, spread: 70, y: 0.7),
    );
    _spin.registerClick();
    setState(() {});

    final clickCount = _spin.clickCount;
    final message = clickCount % 3 == 0
        ? '你已经点了 $clickCount 次了, 不累吗? '
        : _funQuotes[Random().nextInt(_funQuotes.length)];
    Fluttertoast.showToast(msg: message);
  }

  void _onIconLongPress() {
    HapticFeedback.heavyImpact();
    _spin.reset();
    setState(() {});
    if (!mounted) return;

    Fluttertoast.showToast(
      msg: '已停止旋转!',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
    Confetti.launch(
      context,
      options: const ConfettiOptions(particleCount: 150, spread: 70, y: 0.7),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          _buildHeader(context, colorScheme, textTheme),
          const SizedBox(height: 28),
          _buildInfoCard(
            context,
            title: '关于掌环',
            content: '掌环旨在为天津理工大学中环信息学院的同学们提供更便捷的校园生活体验. 本应用代码全部开源, 不包含任何恶意采集数据的行为. 所有数据来源均来自学校官网公开 API.',
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 16, bottom: 10),
            child: Text(
              '技术栈',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Wrap(
              alignment: .center,
              spacing: 8,
              runSpacing: 8,
              children: [
                ChipWidget(text: 'Flutter'),
                ChipWidget(text: 'Material Design 3 Expressive'),
                ChipWidget(text: 'Riverpod'),
                ChipWidget(text: 'InAppWebView'),
                ChipWidget(text: 'Shared Preferences'),
                ChipWidget(text: 'Http'),
              ],
            ),
          ),

          const SizedBox(height: 28),

          M3ESegmentedColumn(
            children: [
              _buildActionCard(
                context,
                icon: Mdi.coffeeOutline,
                title: '赞赏作者',
                subtitle: '微信 / 支付宝赞赏码',
              ),
              _buildActionCard(
                context,
                icon: Mdi.codeBraces,
                title: '项目源代码',
                subtitle: '在 GitHub 查看并参与开发',
              ),
              _buildActionCard(
                context,
                icon: Mdi.update,
                title: '检查更新',
                subtitle: '从 GitHub Release 检查新版本',
                isLoading: _isChecking,
              ),
            ],
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DonationPage()),
                  );
                  break;

                case 1:
                  _openUrl(_sourceCodeUrl, failureMessage: '无法打开项目页面');
                  break;

                case 2:
                  if (!_isChecking) {
                    _checkUpdate();
                  }
                  break;
              }
            },
          ),
          const SizedBox(height: 28),

          Center(
            child: Text(
              '© 2026 wzk0 & thdbd\nAll Rights Reserved.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final iconContainer = CircleAvatar(
      radius: 45,
      child: Image.asset('assets/images/icon.png', height: 60, width: 60),
    );

    return Column(
      children: [
        GestureDetector(
          onTap: _onIconTap,
          onLongPress: _onIconLongPress,
          child: _spin.isSpinning
              ? RotationTransition(turns: _spin.turns, child: iconContainer)
              : iconContainer,
        ),
        const SizedBox(height: 16),
        Text(
          '掌环 (new_zhic_tool)',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          '当前版本: $_currentVersion',
          style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return M3ESegmentedItem(
      padding: .fromLTRB(18, 14, 18, 14),
      elevation: 0,
      color: colorScheme.secondaryContainer,
      index: 1,
      position: .first,
      outerRadius: 12,
      innerRadius: 12,
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(content, style: textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool isLoading = false,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .secondaryContainer,
                child: Icon(icon),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall,
                      overflow: .ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall,
                      overflow: .ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        CircleAvatar(
          backgroundColor: Colors.transparent,
          child: isLoading ? M3ELoadingIndicator() : Icon(Mdi.chevronRight),
        ),
      ],
    );
  }
}
