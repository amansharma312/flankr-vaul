import 'package:flankr_vaul_example/app/resources/styles_manager.dart';
import 'package:flankr_vaul_example/app/routes/routing.dart';
import 'package:flutter/material.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flankr_vaul',
      debugShowCheckedModeBanner: false,
      theme: StylesManager.light,
      darkTheme: StylesManager.dark,
      initialRoute: Routing.home,
      routes: Routing.routes,
    );
  }
}
