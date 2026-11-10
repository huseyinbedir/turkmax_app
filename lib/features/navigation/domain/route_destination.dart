import 'package:equatable/equatable.dart';

/// Kullanıcının seçtiği varış noktası.
class RouteDestination extends Equatable {
  const RouteDestination({
    required this.title,
    this.subtitle,
    this.placeId,
    this.isSimulated = false,
  });

  final String title;
  final String? subtitle;

  /// Google Places kimliği; demo sonuçlarında `null`.
  final String? placeId;
  final bool isSimulated;

  @override
  List<Object?> get props => [title, subtitle, placeId, isSimulated];
}
