import 'package:flutter/services.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/icon.dart';
import 'package:new_zhic_tool/widget/web_view_page.dart';

class NeeaPage extends StatelessWidget {
  const NeeaPage({super.key});

  static const List<({String name, String enname, String url, IconData icon})>
  _items = [
    (
      name: '全国大学英语四、六级考试',
      enname: 'CET',
      url: 'https://cet.neea.edu.cn/cet/',
      icon: Mdi.translate,
    ),
    (
      name: '全国计算机等级考试',
      enname: 'NCRE',
      url: 'https://ncre.neea.edu.cn/results/',
      icon: Mdi.laptop,
    ),
    (
      name: '中小学教师资格考试',
      enname: 'NTCE',
      url: 'https://ntce.neea.edu.cn/ntce/',
      icon: Mdi.humanMaleBoard,
    ),
    (
      name: '全国英语等级考试',
      enname: 'PETS',
      url: 'https://pets.neea.edu.cn/results/',
      icon: Mdi.translate,
    ),
    (
      name: '全国外语水平考试',
      enname: 'WSK',
      url: 'https://wsk.neea.edu.cn/results/',
      icon: Mdi.translate,
    ),
    (
      name: '全国计算机应用水平考试',
      enname: 'NIT',
      url: 'https://nit.neea.edu.cn/cert/',
      icon: Mdi.laptop,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: M3ESegmentedList(
          itemCount: _items.length,
          onTap: (index) {
            final item = _items[index];
            _openWebView(context, title: item.name, url: item.url);
          },
          itemBuilder: (context, index) {
            final item = _items[index];
            return _NeeaItemWidget(
              name: item.name,
              enname: item.enname,
              icon: item.icon,
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
        builder: (_) => WebViewPage(title: title, url: url),
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
