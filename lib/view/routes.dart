
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/jw_import/jw_import_config_bloc.dart';
import 'package:schedu/bloc/jw_import/jw_import_webview_bloc.dart';
import 'package:schedu/view/login/login_page.dart';
import 'package:schedu/view/main/main_page.dart';
import 'package:schedu/view/jw_import/jw_import_config_page.dart';
import 'package:schedu/view/jw_import/jw_import_webview_page.dart';
import 'package:schedu/view/route_names.dart';

import '../bloc/daily_course/daily_course_bloc.dart';
import '../bloc/daily_course/daily_course_event.dart';
import '../bloc/weekly_course/weekly_course_bloc.dart';
import '../bloc/weekly_course/weekly_course_event.dart';
import '../repository/app_settings_store.dart';
import '../repository/course_repository.dart';

class Routes {
  static final routes = {
    RouteNames.LOGIN: (_) => const LoginPage(),
    RouteNames.REGISTER: (_) => const LoginPage(),
    RouteNames.FORGOT_PASSWORD: (_) => const LoginPage(),

    RouteNames.MAIN: (_) => MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DailyCourseBloc(
            context.read<CourseRepository>(),
            AppSettingsStore.instance,
          )..add(const RefreshDailyCourses()),
        ),
        BlocProvider(
          create: (context) => WeeklyCourseBloc(
            context.read<CourseRepository>(),
            AppSettingsStore.instance,
          )..add(const RefreshWeeklyCourses()),
        ),
      ],
      child: const MainPage(),
    ),

    RouteNames.JW_IMPORT_CONFIG: (_) => BlocProvider(
      create: (context) => JwImportConfigBloc(),
      child: const JwImportConfigPage(),
    ),
    RouteNames.JW_IMPORT_WEBVIEW: (_) => BlocProvider(
      create: (context) => JwImportWebviewBloc(context.read<CourseRepository>()),
      child: const JwImportWebviewPage(),
    ),
  };
}