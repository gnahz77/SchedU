import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:schedu/bloc/settings/settings_bloc.dart';
import 'package:schedu/bloc/settings/settings_event.dart';
import 'package:schedu/bloc/settings/settings_state.dart';
import 'package:schedu/bloc/course/course_bloc.dart';
import 'package:schedu/bloc/daily_course/daily_course_bloc.dart';
import 'package:schedu/bloc/daily_course/daily_course_event.dart';
import 'package:schedu/bloc/weekly_course/weekly_course_bloc.dart';
import 'package:schedu/bloc/weekly_course/weekly_course_event.dart';
import 'package:schedu/gen/assets.gen.dart';
import 'package:schedu/repository/course_repository.dart';
import 'package:schedu/repository/settings_manager.dart';
import 'package:schedu/style/theme.dart';
import 'package:schedu/view/route_names.dart';
import 'package:schedu/view/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _edgeToEdge();

  // 注册License
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(Assets.libLicense);
    final separator = '\n${'-' * 80}\n';
    // 将许可证内容分割并按块注册：每块首行为库名称，剩余为许可证内容
    final parts = license.split(separator);
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final lines = trimmed.split('\n');
      final packageName = lines.first.trim();
      final licenseText = lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';
      if (licenseText.isEmpty) continue;
      yield LicenseEntryWithLineBreaks([packageName], licenseText);
    }
  });
  
  runApp(const MyApp());
}

_edgeToEdge() async {
  if (Platform.isAndroid) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CourseRepository>(
          create: (_) => CourseRepositoryImpl(),
        )
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => SettingsBloc(SettingsManager.instance)..add(LoadSettings()),
          ),
          BlocProvider(
            create: (context) => CourseBloc(context.read<CourseRepository>()),
          ),
          BlocProvider(
            create: (context) => DailyCourseBloc(
              context.read<CourseRepository>(),
              SettingsManager.instance,
            )..add(const LoadDailyCourses()),
          ),
          BlocProvider(
            create: (context) => WeeklyCourseBloc(
              context.read<CourseRepository>(),
              SettingsManager.instance,
            )..add(const RefreshWeeklyCourses()),
          ),
        ],
        child: BlocBuilder<SettingsBloc, SettingsState>(
          buildWhen: (previous, current) => previous.themeMode != current.themeMode,
          builder: (context, state) {
            return MaterialApp(
              title: 'SchedU',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: state.themeMode,
              locale: const Locale('zh', 'CN'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('zh', 'CN'),
              ],
              initialRoute: RouteNames.MAIN,
              routes: Routes.routes,
            );
          },
        ),
      ),
    );
  }
}