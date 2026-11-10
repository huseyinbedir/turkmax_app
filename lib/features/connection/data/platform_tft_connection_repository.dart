import 'dart:async';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/di/environments.dart';
import '../../../core/platform/channel_names.dart';
import '../domain/bonded_device.dart';
import '../domain/stream_settings.dart';
import '../domain/tft_connection_repository.dart';
import '../domain/tft_connection_state.dart';

@LazySingleton(as: TftConnectionRepository, env: [kEnvDevice])
class PlatformTftConnectionRepository implements TftConnectionRepository {
  PlatformTftConnectionRepository();

  static const _methods = MethodChannel(ChannelNames.connection);
  static const _events = EventChannel(ChannelNames.connectionEvents);

  final _controller = StreamController<TftConnectionState>.broadcast();
  StreamSubscription<TftConnectionState>? _platformSubscription;
  TftConnectionState _last = const TftConnectionState();

  /// Bir EventChannel aynı anda tek dinleyiciyi destekler; bu yüzden platforma
  /// yalnızca bir kez abone olunur ve durum tüm dinleyicilere buradan dağıtılır.
  /// Yeni dinleyici son durumu hemen alır.
  @override
  Stream<TftConnectionState> watch() {
    _platformSubscription ??= _events
        .receiveBroadcastStream()
        .map(
          (event) => TftConnectionState.fromMap(event as Map<Object?, Object?>),
        )
        .listen(
          (state) {
            _last = state;
            _controller.add(state);
          },
          onError: (Object _) {
            // Kanal yoksa (ör. iOS henüz yok) "bağlı değil" olarak kalır.
          },
        );
    return Stream.multi((listener) {
      listener.add(_last);
      final subscription = _controller.stream.listen(listener.add);
      listener.onCancel = subscription.cancel;
    });
  }

  @override
  Future<List<BondedDevice>> bondedDevices() async {
    // Android 12+ için çalışma zamanı izni; eski sürümlerde hemen verilir.
    final permission = await Permission.bluetoothConnect.request();
    if (!permission.isGranted) {
      throw const BluetoothUnavailableException('PERMISSION_DENIED');
    }
    try {
      final devices = await _methods.invokeListMethod<Map<Object?, Object?>>(
        'getBondedDevices',
      );
      return [
        for (final device in devices ?? const <Map<Object?, Object?>>[])
          BondedDevice(
            name: device['name']! as String,
            address: device['address']! as String,
            likelyCcu: device['likelyCcu'] as bool? ?? false,
          ),
      ];
    } on PlatformException catch (e) {
      throw BluetoothUnavailableException(e.code);
    }
  }

  @override
  Future<void> connect(
    String deviceAddress, {
    required bool autoReconnect,
    StreamSettings settings = const StreamSettings(),
  }) => _methods.invokeMethod<void>('connect', {
    'address': deviceAddress,
    'autoReconnect': autoReconnect,
    ...settings.toMap(),
  });

  @override
  Future<({List<String> lines, String? path})> sessionLog() async {
    final map = await _methods.invokeMapMethod<String, Object?>(
      'getSessionLog',
    );
    return (
      lines: (map?['lines'] as List?)?.cast<String>() ?? const <String>[],
      path: map?['path'] as String?,
    );
  }

  @override
  Future<void> disconnect() => _methods.invokeMethod<void>('disconnect');

  @override
  Future<void> startStreaming() =>
      _methods.invokeMethod<void>('startStreaming');

  @override
  Future<void> stopStreaming() => _methods.invokeMethod<void>('stopStreaming');

  @override
  Future<Uint8List?> fakeReceiverFrame() async {
    final map = await _methods.invokeMapMethod<String, Object?>(
      'getFakeCcuFrame',
    );
    return map?['jpeg'] as Uint8List?;
  }
}
