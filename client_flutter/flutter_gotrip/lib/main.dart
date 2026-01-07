import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'page/login_page.dart';
import 'page/register_page.dart';
import 'page/role_page.dart';
import 'screen/user_home.dart';
import 'screen/driver_home.dart';
import 'screen/merchant_home.dart';
import 'services/api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assests/env/.env");
  runApp(const GoTripApp());
}

class GoTripApp extends StatelessWidget {
  const GoTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bool loggedIn = Api.isLoggedIn();
    final String? role = Api.getRole();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoTrip',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: loggedIn
          ? (role == "driver"
              ? "/driver_home"
              : role == "merchant"
                  ? "/merchant_home"
                  : "/user_home")
          : '/',
      routes: {
        '/': (context) => RoleSelectPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/user_home': (context) => const UserHome(),
        '/driver_home': (context) => const DriverHome(),
        '/merchant_home': (context) => const MerchantHome(),
      },
    );
  }
}
