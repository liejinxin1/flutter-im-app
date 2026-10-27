import 'package:flutter/material.dart';

import 'ui/core/system_ui/app_system_ui.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSystemUi.configure();
  runApp(const AgoraImApp());
}
