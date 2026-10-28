import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

/// 内置浏览器页面: 统一标题、加载进度条与返回键行为。
///
/// 供图书馆、学信网、选课、评教、请假、教育考试等在线页面复用,
/// 避免每个页面重复实现同一套 WebView 逻辑。
class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key, required this.title, required this.url});

  final String title;

  final String url;

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? _webViewController;

  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final controller = _webViewController;
        if (controller != null && await controller.canGoBack()) {
          await controller.goBack();
        } else {
          if (context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          bottom: _progress < 1.0
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: M3ELinearProgressIndicator(value: _progress),
                )
              : null,
        ),
        body: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          onWebViewCreated: (controller) {
            _webViewController = controller;
          },
          onProgressChanged: (controller, progress) {
            if (!mounted) {
              return;
            }
            setState(() {
              _progress = progress / 100;
            });
          },
        ),
      ),
    );
  }
}
