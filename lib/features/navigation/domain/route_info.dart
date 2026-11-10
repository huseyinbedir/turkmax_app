import 'package:equatable/equatable.dart';

/// Aktif rotanın özet bilgileri.
class RouteInfo extends Equatable {
  const RouteInfo({
    required this.destinationName,
    required this.remainingDistanceMeters,
    required this.remainingDuration,
  });

  final String destinationName;
  final int remainingDistanceMeters;
  final Duration remainingDuration;

  /// Tahmini varış zamanı; [now] anına göre hesaplanır.
  DateTime etaFrom(DateTime now) => now.add(remainingDuration);

  @override
  List<Object?> get props => [
    destinationName,
    remainingDistanceMeters,
    remainingDuration,
  ];
}
