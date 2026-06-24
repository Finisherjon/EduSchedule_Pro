import 'package:edu_schedule_pro/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EduScheduleApp());
    await tester.pump();
  });
}
