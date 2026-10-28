import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gal/gal.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/debug.dart';
import 'package:new_zhic_tool/core/icon.dart';

/// 赞赏作者: 并排展示微信 / 支付宝收款码, 可分别保存到相册。
class DonationPage extends StatefulWidget {
  const DonationPage({super.key});

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  static const List<({String title, String asset, String fileName})> _codes = [
    (title: '微信', asset: 'assets/images/wechat.png', fileName: '掌环赞赏-微信'),
    (title: '支付宝', asset: 'assets/images/alipay.jpg', fileName: '掌环赞赏-支付宝'),
  ];

  /// 正在保存的图片资源, 用于只让对应按钮进入加载态。
  String? _savingAsset;

  Future<void> _saveToGallery({
    required String asset,
    required String fileName,
  }) async {
    if (_savingAsset != null) {
      return;
    }

    setState(() {
      _savingAsset = asset;
    });

    try {
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
        _showMessage('没有相册写入权限, 请在系统设置中授予');
        return;
      }

      final data = await rootBundle.load(asset);

      await Gal.putImageBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        name: fileName,
      );

      _showMessage('已保存到相册');
    } on GalException catch (e) {
      debugShow('保存赞赏码失败: $e');
      _showMessage(
        e.type == GalExceptionType.accessDenied
            ? '没有相册写入权限, 请在系统设置中授予'
            : '保存失败: ${e.type.message}',
      );
    } catch (e, stackTrace) {
      debugShow('保存赞赏码失败: $e');
      debugShow(stackTrace.toString());
      _showMessage('保存失败, 请稍后再试');
    } finally {
      if (mounted) {
        setState(() {
          _savingAsset = null;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    Fluttertoast.showToast(msg: message);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            '如果掌环帮到了你, 欢迎请俺喝杯咖啡☕',
            textAlign: TextAlign.center,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '保存后使用微信 / 支付宝扫一扫就行啦, 多谢!',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (final code in _codes) ...[
                Expanded(
                  child: _buildCodeCard(
                    context,
                    code: code,
                    isSaving: _savingAsset == code.asset,
                    isBusy: _savingAsset != null,
                  ),
                ),
                if (code != _codes.last) const SizedBox(width: 16),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCodeCard(
    BuildContext context, {
    required ({String title, String asset, String fileName}) code,
    required bool isSaving,
    required bool isBusy,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Mdi.qrcode, size: 18, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(code.title, style: textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            code.asset,
            fit: BoxFit.fitWidth,
            errorBuilder: (context, error, stackTrace) {
              return Text('图片加载失败', style: textTheme.bodySmall);
            },
          ),
        ),
        const SizedBox(height: 10),
        M3EButton(
          onPressed: isBusy
              ? null
              : () =>
                    _saveToGallery(asset: code.asset, fileName: code.fileName),
          style: .tonal,
          size: .xs,
          child: isSaving ? const M3ELoadingIndicator() : const Text('保存到相册'),
        ),
      ],
    );
  }
}
