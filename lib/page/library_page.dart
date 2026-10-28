import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/widget/web_view_page.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebViewPage(
      title: '图书馆',
      url: 'http://work.tjzhic.edu.cn:7567/Mobile/index',
    );
  }
}
