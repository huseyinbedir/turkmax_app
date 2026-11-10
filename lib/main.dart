import 'package:flutter/material.dart';

import 'app/di/injection.dart';
import 'app/turkmax_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const TurkMaxApp());
}
