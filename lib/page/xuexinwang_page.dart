import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

class XuexinwangPage extends StatefulWidget {
  const XuexinwangPage({super.key});

  @override
  State<XuexinwangPage> createState() => _XuexinwangPageState();
}

class _XuexinwangPageState extends State<XuexinwangPage> {
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
          title: const Text('学信网'),
          bottom: _progress < 1.0
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: M3ELinearProgressIndicator(value: _progress),
                )
              : null,
        ),
        body: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri("https://my.chsi.com.cn/archive/index.action"),
          ),
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
