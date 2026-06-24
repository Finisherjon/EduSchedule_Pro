import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/repositories/class_group_repository.dart';
import 'core/repositories/custom_holiday_repository.dart';
import 'core/repositories/schedule_repository.dart';
import 'core/providers/class_group_provider.dart';
import 'core/providers/custom_holiday_provider.dart';
import 'core/providers/schedule_provider.dart';
import 'pages/splash/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Hive.initFlutter();
  await ClassGroupRepository.init();
  await ScheduleRepository.init();
  await CustomHolidayRepository.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClassGroupProvider()..loadAll()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()..loadAll()),
        ChangeNotifierProvider(create: (_) => CustomHolidayProvider()),
      ],
      child: const EduScheduleApp(),
    ),
  );
}

class EduScheduleApp extends StatelessWidget {
  const EduScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduSchedule Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashPage(),
    );
  }
}
