import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../domain/notification_repository.dart';
import '../domain/notification_summary.dart';

@LazySingleton(as: NotificationRepository)
class FakeNotificationRepository implements NotificationRepository {
  const FakeNotificationRepository();

  @override
  Stream<NotificationSummary?> watch() => Stream.value(
    // Demo verisi yalnızca geliştirici derlemesinde; diğerlerinde kart boş kalır.
    !kDebugMode
        ? null
        : const NotificationSummary(
            appName: 'Mesajlar',
            title: 'Demo Kişi',
            preview: 'Bu bir demo bildirimidir',
            unreadCount: 2,
            isSimulated: true,
          ),
  );
}
