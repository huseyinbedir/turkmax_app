import 'notification_summary.dart';

/// En son bildirim özeti; gösterilecek bildirim yoksa `null` yayınlar.
///
/// Gerçek uygulama (Android NotificationListenerService) henüz yok.
abstract interface class NotificationRepository {
  Stream<NotificationSummary?> watch();
}
