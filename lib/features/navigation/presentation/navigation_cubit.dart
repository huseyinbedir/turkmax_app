import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../domain/route_destination.dart';
import '../domain/navigation_provider.dart';
import '../domain/navigation_state.dart';

/// Telefon arayüzünün navigasyon komutları ve durumu.
@injectable
class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit(this._provider)
    : super(const NavigationState.idle(isReady: false)) {
    _subscription = _provider.watch().listen(emit);
  }

  final NavigationProvider _provider;
  late final StreamSubscription<NavigationState> _subscription;

  Future<void> prepare() => _provider.prepare();

  Future<void> start(RouteDestination destination, {bool simulate = false}) =>
      _provider.startNavigation(destination, simulate: simulate);

  Future<void> stop() => _provider.stopNavigation();

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
