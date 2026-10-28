import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/debug.dart';
import 'package:share_plus/share_plus.dart';

/// 把 [key] 绑定的 [RenderRepaintBoundary] 截图为 PNG 并调用系统分享。
///
/// 返回 false 表示当前没有可截图的边界(页面尚未渲染完成或 key 未绑定),
/// 调用方可以据此给出提示。
Future<bool> shareBoundaryImage(
  BuildContext context,
  GlobalKey key, {
  required String fileName,
  String? title,
  String? subject,
  String? text,
}) async {
  await WidgetsBinding.instance.endOfFrame;

  if (!context.mounted) {
    return false;
  }

  final renderObject = key.currentContext?.findRenderObject();

  if (renderObject is! RenderRepaintBoundary) {
    debugShow('分享失败: $fileName 尚未绑定 RepaintBoundary');
    return false;
  }

  final image = await renderObject.toImage(pixelRatio: 3.0);

  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      debugShow('分享失败: $fileName 截图编码为空');
      return false;
    }

    final bytes = byteData.buffer.asUint8List();

    if (!context.mounted) {
      return false;
    }

    final renderBox = context.findRenderObject();

    await SharePlus.instance.share(
      ShareParams(
        title: title,
        subject: subject,
        text: text,
        files: [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
        fileNameOverrides: [fileName],
        sharePositionOrigin: renderBox is RenderBox
            ? renderBox.localToGlobal(Offset.zero) & renderBox.size
            : null,
      ),
    );

    return true;
  } finally {
    image.dispose();
  }
}
