
import 'package:schedu/view/login/login_page.dart';
import 'package:schedu/view/main/main_page.dart';
import 'package:schedu/view/route_names.dart';

class Routes {
  static final routes = {
    RouteNames.LOGIN: (_) => const LoginPage(),
    RouteNames.REGISTER: (_) => const LoginPage(),
    RouteNames.FORGOT_PASSWORD: (_) => const LoginPage(),

    RouteNames.MAIN: (_) => const MainPage(),
  };
}