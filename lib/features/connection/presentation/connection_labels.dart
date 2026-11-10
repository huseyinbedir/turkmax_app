import '../../../core/l10n/generated/app_localizations.dart';
import '../domain/tft_connection_state.dart';

String connectionPhaseLabel(AppLocalizations l10n, TftConnectionPhase phase) =>
    switch (phase) {
      TftConnectionPhase.disconnected => l10n.connectionDisconnected,
      TftConnectionPhase.connecting => l10n.connectionConnecting,
      TftConnectionPhase.authenticating => l10n.connectionAuthenticating,
      TftConnectionPhase.ready => l10n.connectionReady,
      TftConnectionPhase.streaming => l10n.connectionStreaming,
      TftConnectionPhase.reconnecting => l10n.connectionReconnecting,
      TftConnectionPhase.failed => l10n.connectionFailed,
    };

/// Native hata kodunu kullanıcıya anlaşılır metne çevirir.
String connectionErrorText(AppLocalizations l10n, String code) =>
    switch (code) {
      'CONNECT_FAILED' => l10n.connectionErrorConnect,
      'HANDSHAKE_TIMEOUT' => l10n.connectionErrorHandshakeTimeout,
      'HANDSHAKE_FAILED' => l10n.connectionErrorHandshake,
      'LINK_LOST' => l10n.connectionErrorLinkLost,
      'PERMISSION_DENIED' => l10n.connectionErrorPermission,
      'BLUETOOTH_OFF' => l10n.connectionErrorBluetoothOff,
      'NO_BLUETOOTH' => l10n.connectionErrorNoBluetooth,
      _ => l10n.connectionErrorUnknown(code),
    };
