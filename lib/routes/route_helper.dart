import 'package:farm_app/screens/home_screen.dart';
import 'package:farm_app/screens/manage_your_farm.dart';

import 'package:farm_app/screens/sign_in_screen.dart';
import 'package:farm_app/screens/sign_up_screen.dart';
import 'package:farm_app/screens/welcome_screen.dart';
import 'package:get/get.dart';

class RouteHelper {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signUp = '/signUp';
  static const String home = '/home';
  static const String farmManagment = '/farm-Managment';
  // static const String landManagement = '/land-management';
  // static const String inventory = '/inventory';
  // static const String activityMonitor = '/activity-monitor';

  static List<GetPage> routes = [
    GetPage(name: welcome, page: () => WelcomeScreen()),
    GetPage(name: login, page: () => LoginScreen()),
    GetPage(name: signUp, page: () => SignUpScreen()),
    GetPage(name: home, page: () => HomeScreen()),
    GetPage(name: farmManagment, page: () => ManageYourFarm()),
    // GetPage(name: landManagement, page: () => LandManagementScreen()),
    // GetPage(name: inventory, page: () => InventoryScreen()),
    // GetPage(name: activityMonitor, page: () => ActivityMonitorScreen()),
  ];
}
