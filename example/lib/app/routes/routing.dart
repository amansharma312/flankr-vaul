import 'package:flankr_vaul_example/app/modules/demos/screens/demos_screen.dart';
import 'package:flutter/widgets.dart';

abstract final class Routing {
  static const String home = '/';

  static final Map<String, WidgetBuilder> routes = {
    home: (context) => const DemosScreen(),
  };
}
