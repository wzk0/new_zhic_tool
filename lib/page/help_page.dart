import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/icon.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> data = [
      {
        'title': '如何上传题库',
        'body': Text(
          '一共有两种方法: \n1. 直接发给我(可以通过邮箱的方式: thdbd@qq.com);\n2. 注册一个 Gitee账号( gitee.com ), fork https://gitee.com/thdbd/zhanghuan_data 这个仓库, 在 tiku 文件夹下放入要上传的题库文件, 随后运行 update.py 即可 push.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        'icon': Mdi.uploadOutline,
      },
      {
        'title': '为何页面一直在加载',
        'body': Text(
          '由于教务系统的 cookies 的有效时间不长, 通常隔一阵子打开掌环后 cookies 就会失效, 会出现一直加载的情况. 此时只需在首页右上角下拉菜单中选择 "以上次登录学号重新登入" 即可.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        'icon': Mdi.networkOutline,
      },
      {
        'title': '关于掌环的主题色',
        'body': Text(
          '是根据系统壁纸自动取色生成 (Android 12+). 如果想要更换主色调, 可以先换个壁纸.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        'icon': Mdi.informationOutline,
      },
      {
        'title': 'Bug 反馈',
        'body': Text(
          '同样有两种方式: \n1. 在 Github 上提交 issue, 仓库 wzk0/new_zhic_tool\n2. 以各种方式联系上我.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        'icon': Mdi.bugOutline,
      },
    ];

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: M3EExpandableCardColumn(
          allowMultipleExpanded: true,
          style: M3EExpandableStyle(
            headerPadding: const EdgeInsets.symmetric(
              horizontal: 16.00,
              vertical: 12.00,
            ),
            bodyPadding: const EdgeInsets.symmetric(
              horizontal: 16.00,
              vertical: 12.00,
            ),
            expandIcon: const Icon(Icons.expand_more_rounded),
            haptic: M3EHapticFeedback.light,
            enableFeedback: true,
            expandTooltip: '展开帮助',
            collapseTooltip: '收起帮助',
          ),
          data: data.map((item) {
            final colorScheme = Theme.of(context).colorScheme;
            return M3EExpandableData(
              subtitleStyle: [?Theme.of(context).textTheme.bodySmall],
              leading: CircleAvatar(
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(
                  item['icon'] as IconData? ?? Mdi.informationOutline,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              title: item['title'] as String? ?? '',
              subtitle: '展开以查看',
              body: item['body'] as Widget,
            );
          }).toList(),
        ),
      ),
    );
  }
}
