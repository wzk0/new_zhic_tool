import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/widget/web_view_page.dart';

class EvaluationPage extends StatelessWidget {
  const EvaluationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebViewPage(
      title: '评教',
      url: 'https://eams.tjzhic.edu.cn/student/for-std/extra-system/student-summation-forstudent/index',
    );
  }
}
