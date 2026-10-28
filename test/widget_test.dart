import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/icon.dart';
import 'package:new_zhic_tool/model/course.dart';
import 'package:new_zhic_tool/model/student_info.dart';
import 'package:new_zhic_tool/widget/empty_page.dart';

void main() {
  group('Course.normalized', () {
    test('超出总节次的课程会被裁剪到有效范围', () {
      const course = Course(
        id: 'C001',
        name: '高等数学',
        room: 'A101',
        weekday: 3,
        startUnit: 13,
        endUnit: 15,
        classType: '必修',
        credits: 4,
        building: '一教',
        startTime: '19:25',
        endTime: '21:00',
      );

      final normalized = course.normalized(totalUnits: 12);

      expect(normalized, isNotNull);
      expect(normalized!.startUnit, 12);
      expect(normalized.endUnit, 12);
    });

    test('空白的课程名与地点会使用兜底文案', () {
      const course = Course(
        id: 'C002',
        name: '  ',
        room: '',
        weekday: 1,
        startUnit: 1,
        endUnit: 2,
        classType: '选修',
        credits: 2,
        building: '二教',
        startTime: '08:00',
        endTime: '09:25',
      );

      final normalized = course.normalized();

      expect(normalized!.name, '未知课程');
      expect(normalized.room, '未知地点');
    });
  });

  test('StudentInfo.avatarText 取姓名末位', () {
    const student = StudentInfo(name: '张三');
    expect(student.avatarText, '三');
    expect(const StudentInfo().avatarText, '?');
  });

  testWidgets('EmptyPage 显示提示文案', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EmptyPage(text: '暂无数据', icon: Mdi.informationOutline),
      ),
    );

    expect(find.text('暂无数据'), findsOneWidget);
  });
}
