import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:schedu/bloc/settings/settings_bloc.dart';
import 'package:schedu/bloc/settings/settings_event.dart';
import 'package:schedu/bloc/settings/settings_state.dart';
import 'package:schedu/bloc/course/course_bloc.dart';
import 'package:schedu/repository/course_repository.dart';
import 'package:schedu/repository/settings_manager.dart';
import 'package:schedu/style/theme.dart';
import 'package:schedu/view/route_names.dart';
import 'package:schedu/view/routes.dart';
import 'bloc/course/course_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _edgeToEdge();
  
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SettingsBloc(SettingsManager.instance)..add(LoadSettings()),
        ),
        BlocProvider(
          create: (context) {
            final bloc = CourseBloc(CourseRepositoryImpl());
            // 启动时加载所有课程数据
            bloc.add(const LoadCourses());
            return bloc;
          },
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
    );
  }
}