import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:schedu/model/course_bloc.dart';
import 'package:schedu/model/course_event.dart';
import 'package:schedu/repository/course_repository.dart';
import 'package:schedu/repository/settings_manager.dart';
import 'package:schedu/style/theme.dart';
import 'package:schedu/view/route_names.dart';
import 'package:schedu/view/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化设置管理器
  await SettingsManager.instance.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final bloc = CourseBloc(CourseRepositoryImpl());
            // 启动时加载所有课程数据
            bloc.add(const LoadCourses());
            return bloc;
          },
        ),
      ],
      child: MaterialApp(
        title: 'SchedU',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        locale: Locale('zh', 'CN'),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
        const Locale('zh', 'CH'),
        ],
        initialRoute: RouteNames.MAIN,
        routes: Routes.routes,
      ),
    );
  }
}