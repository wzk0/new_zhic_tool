import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/widget/web_view_page.dart';

class CourseSelectionPage extends StatelessWidget {
  const CourseSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebViewPage(
      title: '选课',
      url: 'https://eams.tjzhic.edu.cn/student/for-std/course-select',
    );
  }
}
