import 'dart:async';

import 'package:equatable/equatable.dart';

import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/platform/device_power.dart';
import '../../settings/domain/settings_repository.dart';
import '../domain/bonded_device.dart';
import '../domain/stream_settings.dart';
import '../domain/tft_connection_repository.dart';
import '../domain/tft_connection_state.dart';

class ConnectionViewState extends Equatable {
  const ConnectionViewState({
    this.connection = const TftConnectionState(),
    this.devices = const [],
    this.devicesError,
    this.isLoadingDevices = false,
    this.lastDeviceName,
    this.receiverFrame,
    this.settings = const StreamSettings(),
    this.logLines = const [],
    this.logPath,
    this.batteryUnrestricted,
  });

  final TftConnectionState connection;
  final List<BondedDevice> devices;

  /// Cihaz listesi okunamadıysa hata kodu.
  final String? devicesError;
  final bool isLoadingDevices;
  final String? lastDeviceName;

  /// Sahte göstergenin aldığı son kare (yalnızca sahte bağlantıda).
  final Uint8List? receiverFrame;

  /// Bir sonraki bağlantıda kullanılacak akış ayarları.
  final StreamSettings settings;
  final List<String> logLines;
  final String? logPath;

  /// Uygulama pil optimizasyonundan muaf mı; bilinmiyorsa `null`.
  final bool? batteryUnrestricted;

  ConnectionViewState copyWith({
    TftConnectionState? connection,
    List<BondedDevice>? devices,
    String? Function()? devicesError,
    bool? isLoadingDevices,
    String? lastDeviceName,
    Uint8List? Function()? receiverFrame,
    StreamSettings? settings,
    List<String>? logLines,
    String? logPath,
    bool? batteryUnrestricted,
  }) => ConnectionViewState(
    connection: connection ?? this.connection,
    devices: devices ?? this.devices,
    devicesError: devicesError != null ? devicesError() : this.devicesError,
    isLoadingDevices: isLoadingDevices ?? this.isLoadingDevices,
    lastDeviceName: lastDeviceName ?? this.lastDeviceName,
    receiverFrame: receiverFrame != null ? receiverFrame() : this.receiverFrame,
    settings: settings ?? this.settings,
    logLines: logLines ?? this.logLines,
    logPath: logPath ?? this.logPath,
    batteryUnrestricted: batteryUnrestricted ?? this.batteryUnrestricted,
  );

  @override
  List<Object?> get props => [
    connection,
    devices,
    devicesError,
    isLoadingDevices,
    lastDeviceName,
    receiverFrame,
    settings,
    logLines,
    logPath,
    batteryUnrestricted,
  ];
}

@injectable
class ConnectionCubit extends Cubit<ConnectionViewState> {
  ConnectionCubit(this._repository, this._settings, this._power)
    : super(
        ConnectionViewState(
          lastDeviceName: _settings.lastDeviceName,
          settings: const StreamSettings(source: FrameSourceKind.cockpit),
        ),
      ) {
    _subscription = _repository.watch().listen(_onConnection);
    _logTimer = Timer.periodic(const Duration(seconds: 1), (_) => refreshLog());
  }

  final DevicePower _power;
  Timer? _logTimer;

  void updateSettings(StreamSettings settings) =>
      emit(state.copyWith(settings: settings));

  Future<void> refreshLog() async {
    final log = await _repository.sessionLog();
    if (isClosed) return;
    emit(state.copyWith(logLines: log.lines, logPath: log.path));
  }

  Future<void> refreshBatteryStatus() async {
    final unrestricted = await _power.isIgnoringBatteryOptimizations();
    if (isClosed || unrestricted == null) return;
    emit(state.copyWith(batteryUnrestricted: unrestricted));
  }

  Future<void> openBatterySettings() => _power.openBatterySettings();

  final TftConnectionRepository _repository;
  final SettingsRepository _settings;
  late final StreamSubscription<TftConnectionState> _subscription;
  Timer? _receiverTimer;

  Future<void> loadDevices() async {
    emit(state.copyWith(isLoadingDevices: true, devicesError: () => null));
    try {
      final devices = await _repository.bondedDevices();
      if (isClosed) return;
      emit(state.copyWith(devices: devices, isLoadingDevices: false));
    } on BluetoothUnavailableException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          devices: const [],
          isLoadingDevices: false,
          devicesError: () => e.code,
        ),
      );
    }
  }

  Future<void> connect(BondedDevice device) async {
    await _settings.setLastDeviceName(device.name);
    emit(state.copyWith(lastDeviceName: device.name));
    await _repository.connect(
      device.address,
      autoReconnect: _settings.autoReconnect,
      settings: state.settings,
    );
  }

  Future<void> disconnect() => _repository.disconnect();

  Future<void> startStreaming() => _repository.startStreaming();

  Future<void> stopStreaming() => _repository.stopStreaming();

  void _onConnection(TftConnectionState connection) {
    emit(state.copyWith(connection: connection));
    // Sahte gösterge bağlıysa aldığı kareyi göster (gerçek cihazda hep null).
    final shouldPoll = connection.phase == TftConnectionPhase.streaming;
    if (shouldPoll && _receiverTimer == null) {
      _receiverTimer = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => _pollReceiver(),
      );
    } else if (!shouldPoll && _receiverTimer != null) {
      _receiverTimer?.cancel();
      _receiverTimer = null;
      if (!connection.phase.isLinkUp) {
        emit(state.copyWith(receiverFrame: () => null));
      }
    }
  }

  Future<void> _pollReceiver() async {
    final frame = await _repository.fakeReceiverFrame();
    if (isClosed || frame == null) return;
    emit(state.copyWith(receiverFrame: () => frame));
  }

  @override
  Future<void> close() async {
    _receiverTimer?.cancel();
    _logTimer?.cancel();
    await _subscription.cancel();
    return super.close();
  }
}
