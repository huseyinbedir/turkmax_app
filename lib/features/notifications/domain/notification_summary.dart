import 'package:equatable/equatable.dart';

/// Cockpit'te gösterilen kısa bildirim özeti. Tam mesaj içeriği taşınmaz.
class NotificationSummary extends Equatable {
  const NotificationSummary({
    required this.appName,
    required this.title,
    this.preview,
    this.unreadCount = 1,
    this.isSimulated = false,
  });

  final String appName;
  final String title;

  /// Tek satırlık kısaltılmış özet.
  final String? preview;
  final int unreadCount;
  final bool isSimulated;

  @override
  List<Object?> get props => [
    appName,
    title,
    preview,
    unreadCount,
    isSimulated,
  ];
}
