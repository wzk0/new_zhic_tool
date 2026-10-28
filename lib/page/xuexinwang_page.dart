import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/widget/web_view_page.dart';

class XuexinwangPage extends StatelessWidget {
  const XuexinwangPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebViewPage(
      title: '学信网',
      url: 'https://my.chsi.com.cn/archive/index.action',
    );
  }
}
