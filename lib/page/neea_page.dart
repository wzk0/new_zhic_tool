import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/icon.dart';

class NeeaPage extends StatelessWidget {
  const NeeaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> data = [
      {
        'name': '全国大学英语四、六级考试',
        'enname': 'CET',
        'url': 'https://cet.neea.edu.cn/cet/',
        'icon': Mdi.translate,
      },
      {
        'name': '全国计算机等级考试',
        'enname': 'NCRE',
        'url': 'https://ncre.neea.edu.cn/results/',
        'icon': Mdi.laptop,
      },
      {
        'name': '中小学教师资格考试',
        'enname': 'NTCE',
        'url': 'https://ntce.neea.edu.cn/ntce/',
        'icon': Mdi.humanMaleBoard,
      },
      {
        'name': '全国英语等级考试',
        'enname': 'PETS',
        'url': 'https://pets.neea.edu.cn/results/',
        'icon': Mdi.translate,
      },
      {
        'name': '全国外语水平考试',
        'enname': 'WSK',
        'url': 'https://wsk.neea.edu.cn/results/',
        'icon': Mdi.translate,
      },
      {
        'name': '全国计算机应用水平考试',
        'enname': 'NIT',
        'url': 'https://nit.neea.edu.cn/cert/',
        'icon': Mdi.laptop,
      },
    ];

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: M3ESegmentedList(
          itemCount: data.length,
          onTap: (index) {
            final item = data[index];
            _openWebView(
              context,
              title: item['name'] as String? ?? '',
              url: item['url'] as String? ?? '',
            );
          },
          itemBuilder: (context, index) {
            final item = data[index];
            return _NeeaItemWidget(
              name: item['name'] as String? ?? '',
              enname: item['enname'] as String? ?? '',
              icon: item['icon'] as IconData? ?? Mdi.informationOutline,
            );
          },
        ),
      ),
    );
  }

  void _openWebView(
    BuildContext context, {
    required String title,
    required String url,
  }) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NeeaWebPage(title: title, url: url),
      ),
    );
  }
}

class _NeeaItemWidget extends StatelessWidget {
  const _NeeaItemWidget({
    required this.name,
    required this.enname,
    required this.icon,
  });

  final String name;
  final String enname;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: colorScheme.secondaryContainer,
          child: Icon(icon, color: colorScheme.onSecondaryContainer),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                enname,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        Icon(Mdi.chevronRight, color: colorScheme.outline),
      ],
    );
  }
}

class _NeeaWebPage extends StatefulWidget {
  const _NeeaWebPage({required this.title, required this.url});

  final String title;
  final String url;

  @override
  State<_NeeaWebPage> createState() => _NeeaWebPageState();
}

class _NeeaWebPageState extends State<_NeeaWebPage> {
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
