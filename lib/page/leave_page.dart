import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/widget/web_view_page.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  @override
  void initState() {
    super.initState();
    Fluttertoast.showToast(msg: '初始密码: tjzhic2015', toastLength: .LENGTH_LONG);
  }

  @override
  Widget build(BuildContext context) {
    return const WebViewPage(
      title: '请假',
      url: 'http://work.tjzhic.edu.cn:7565/dormitory/index',
    );
  }
}
