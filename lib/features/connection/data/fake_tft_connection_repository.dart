import 'dart:async';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import '../../../app/di/environments.dart';
import '../domain/bonded_device.dart';
import '../domain/stream_settings.dart';
import '../domain/tft_connection_repository.dart';
import '../domain/tft_connection_state.dart';

/// Testler için bellek içi bağlantı; gerçek Bluetooth kullanmaz.
@LazySingleton(as: TftConnectionRepository, env: [kEnvFake])
class FakeTftConnectionRepository implements TftConnectionRepository {
  FakeTftConnectionRepository();

  final _controller = StreamController<TftConnectionState>.broadcast();
  TftConnectionState _state = const TftConnectionState();

  @override
  Stream<TftConnectionState> watch() => Stream.multi((listener) {
    listener.add(_state);
    final subscription = _controller.stream.listen(listener.add);
    listener.onCancel = subscription.cancel;
  });

  @override
  Future<List<BondedDevice>> bondedDevices() async => const [
    BondedDevice(
      name: 'YCCU_TEST',
      address: '00:11:22:33:44:55',
      likelyCcu: true,
    ),
    BondedDevice(name: 'Kulaklık', address: 'AA:BB:CC:DD:EE:FF'),
  ];

  @override
  Future<void> connect(
    String deviceAddress, {
    required bool autoReconnect,
    StreamSettings settings = const StreamSettings(),
  }) async => _set(
    TftConnectionState(
      phase: TftConnectionPhase.ready,
      deviceName: 'YCCU_TEST',
      partNumber: '006-B3952-03',
      frameWidth: 480,
      frameHeight: settings.frameHeight ?? 234,
    ),
  );

  @override
  Future<void> disconnect() async => _set(const TftConnectionState());

  @override
  Future<void> startStreaming() async => _set(
    TftConnectionState(
      phase: TftConnectionPhase.streaming,
      deviceName: _state.deviceName,
      partNumber: _state.partNumber,
      frameWidth: _state.frameWidth,
      frameHeight: _state.frameHeight,
      stats: const StreamingStats(
        framesSent: 30,
        framesAcked: 30,
        fps: 12.5,
        averageAckMs: 70,
        lastJpegBytes: 5000,
        quality: 40,
      ),
    ),
  );

  @override
  Future<void> stopStreaming() async => _set(
    TftConnectionState(
      phase: TftConnectionPhase.ready,
      deviceName: _state.deviceName,
      partNumber: _state.partNumber,
      frameWidth: _state.frameWidth,
      frameHeight: _state.frameHeight,
    ),
  );

  @override
  Future<({List<String> lines, String? path})> sessionLog() async =>
      (lines: const ['12:00:00.000 [CONN] fake log line'], path: null);

  @override
  Future<Uint8List?> fakeReceiverFrame() async => null;

  void _set(TftConnectionState state) {
    _state = state;
    _controller.add(state);
  }
}
