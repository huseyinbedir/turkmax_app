import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

import 'channel_names.dart';

/// Google Maps Platform yapılandırması. Anahtar Dart koduna gömülmez; native
/// manifestten (Secrets Gradle Plugin) okunur.
class MapsConfig extends Equatable {
  const MapsConfig({
    required this.apiKey,
    required this.packageName,
    required this.certSha1,
  });

  const MapsConfig.none() : apiKey = null, packageName = null, certSha1 = null;

  final String? apiKey;
  final String? packageName;

  /// İmza sertifikasının SHA-1 özeti (büyük harf, ayraçsız). Android kısıtlı
  /// anahtarla REST çağrısı yaparken gerekir.
  final String? certSha1;

  bool get hasApiKey => apiKey != null && apiKey!.isNotEmpty;

  static Future<MapsConfig> load() async {
    try {
      final map = await const MethodChannel(ChannelNames.system)
          .invokeMapMethod<String, Object?>('getMapsConfig');
      if (map == null) return const MapsConfig.none();
      return MapsConfig(
        apiKey: map['apiKey'] as String?,
        packageName: map['packageName'] as String?,
        certSha1: map['certSha1'] as String?,
      );
    } on MissingPluginException {
      return const MapsConfig.none();
    } on PlatformException {
      return const MapsConfig.none();
    }
  }

  @override
  List<Object?> get props => [apiKey, packageName, certSha1];
}
