import 'package:equatable/equatable.dart';

/// Sağlayıcıdan bağımsız manevra türleri.
enum ManeuverType {
  straight,
  slightLeft,
  left,
  sharpLeft,
  slightRight,
  right,
  sharpRight,
  uTurn,
  roundabout,
  arrive,
  unknown,
}

/// Bir sonraki dönüş yönlendirmesi.
class ManeuverInfo extends Equatable {
  const ManeuverInfo({
    required this.type,
    required this.distanceMeters,
    this.roadName,
  });

  final ManeuverType type;

  /// Manevraya kalan mesafe (metre).
  final int distanceMeters;

  /// Manevradan sonra girilecek yol; sağlayıcı vermiyorsa `null`.
  final String? roadName;

  @override
  List<Object?> get props => [type, distanceMeters, roadName];
}
