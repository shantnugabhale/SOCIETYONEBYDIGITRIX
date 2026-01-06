import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme/light_theme.dart';
import 'theme/dark_theme.dart';
import 'routes/app_routes.dart';
import 'views/splash/splash_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SocietyOne by Digitrix',
      debugShowCheckedModeBanner: false,
      theme: LightTheme.theme,
      darkTheme: DarkTheme.theme,
      themeMode: ThemeMode.light,
      initialRoute: '/',
      getPages: AppRoutes.routes,
      home: const SplashScreen(),
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
