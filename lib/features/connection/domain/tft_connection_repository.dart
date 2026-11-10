import 'dart:typed_data';

import 'bonded_device.dart';
import 'stream_settings.dart';
import 'tft_connection_state.dart';

/// Eşleşmiş cihazlar okunamadığında.
class BluetoothUnavailableException implements Exception {
  const BluetoothUnavailableException(this.code);

  /// `PERMISSION_DENIED`, `BLUETOOTH_OFF` veya `NO_BLUETOOTH`.
  final String code;

  @override
  String toString() => 'BluetoothUnavailableException($code)';
}

/// Motosiklet bağlantısının Flutter tarafındaki görünümü.
///
/// Protokol paketleri burada üretilmez; yalnızca niyet (bağlan/kes/yayınla)
/// iletilir ve durum dinlenir. Tüm NaviLite işleri native `NaviLiteTransport`
/// arkasındadır.
abstract interface class TftConnectionRepository {
  Stream<TftConnectionState> watch();

  /// Telefonla eşleşmiş cihazlar; olası CCU'lar başta.
  Future<List<BondedDevice>> bondedDevices();

  /// Eşleşmiş cihaza bağlanmayı ister. Sonuç [watch] üzerinden gelir.
  Future<void> connect(
    String deviceAddress, {
    required bool autoReconnect,
    StreamSettings settings = const StreamSettings(),
  });

  /// Kullanıcının bağlantıyı kesme talebi; otomatik yeniden bağlanmayı da
  /// durdurur.
  Future<void> disconnect();

  Future<void> startStreaming();

  Future<void> stopStreaming();

  /// Bağlantı günlüğünün son satırları ve (varsa) günlük dosyasının yolu.
  Future<({List<String> lines, String? path})> sessionLog();

  /// Sahte göstergenin aldığı son kare (debug alıcısı); yoksa `null`.
  Future<Uint8List?> fakeReceiverFrame();
}
