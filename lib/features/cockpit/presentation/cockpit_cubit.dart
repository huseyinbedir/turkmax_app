import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../connection/domain/tft_connection_repository.dart';
import '../../device_status/domain/device_status_repository.dart';
import '../../media/domain/media_repository.dart';
import '../../navigation/domain/navigation_provider.dart';
import '../../notifications/domain/notification_repository.dart';
import 'cockpit_state.dart';

/// Yalnızca ekran kompozisyonunu yönetir: feature kaynaklarını tek bir
/// [CockpitState] içinde birleştirir. İş mantığı ilgili feature'dadır.
@injectable
class CockpitCubit extends Cubit<CockpitState> {
  CockpitCubit(
    this._navigation,
    this._deviceStatus,
    this._connection,
    this._media,
    this._notifications,
  ) : super(CockpitState(now: DateTime.now()));

  final NavigationProvider _navigation;
  final DeviceStatusRepository _deviceStatus;
  final TftConnectionRepository _connection;
  final MediaRepository _media;
  final NotificationRepository _notifications;

  final _subscriptions = <StreamSubscription<void>>[];
  Timer? _clock;

  void start() {
    if (_subscriptions.isNotEmpty) return;
    _subscriptions.addAll([
      _navigation.watch().listen((v) => emit(state.copyWith(navigation: v))),
      _deviceStatus.watch().listen((v) => emit(state.copyWith(device: v))),
      _connection.watch().listen((v) => emit(state.copyWith(connection: v))),
      _media.watch().listen((v) => emit(state.copyWith(media: () => v))),
      _notifications.watch().listen(
        (v) => emit(state.copyWith(notification: () => v)),
      ),
    ]);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      // Topbar dakika çözünürlüğünde; gereksiz yeniden çizimden kaçın.
      if (now.minute != state.now.minute || now.hour != state.now.hour) {
        emit(state.copyWith(now: now));
      }
    });
  }

  @override
  Future<void> close() async {
    _clock?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
