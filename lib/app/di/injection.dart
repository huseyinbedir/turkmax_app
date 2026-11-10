import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'environments.dart';
import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies({String environment = kEnvDevice}) =>
    getIt.init(environment: environment);
