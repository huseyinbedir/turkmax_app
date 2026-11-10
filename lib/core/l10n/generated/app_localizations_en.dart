// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TurkMax';

  @override
  String get homeCockpitPreview => 'TFT preview (480×234)';

  @override
  String get homeConnectionTitle => 'Motorcycle connection';

  @override
  String get homeDiagnostics => 'Diagnostics';

  @override
  String get homeSettings => 'Settings';

  @override
  String get demoBadge => 'DEMO';

  @override
  String get demoDataNotice =>
      'The route, notification and music shown are demo data.';

  @override
  String get syntheticMapLabel => 'SYNTHETIC MAP';

  @override
  String get connectionDisconnected => 'Not connected';

  @override
  String get connectionConnecting => 'Connecting';

  @override
  String get connectionAuthenticating => 'Authenticating';

  @override
  String get connectionReady => 'Ready';

  @override
  String get connectionStreaming => 'Streaming';

  @override
  String get connectionReconnecting => 'Reconnecting';

  @override
  String get connectionFailed => 'Connection error';

  @override
  String get navIdle => 'No route';

  @override
  String get navArrived => 'You have arrived';

  @override
  String get navRerouting => 'Recalculating route';

  @override
  String navEta(String time) {
    return 'ETA $time';
  }

  @override
  String get notificationsEmpty => 'No new notifications';

  @override
  String get mediaEmpty => 'Nothing playing';

  @override
  String get diagnosticsTitle => 'Diagnostics';

  @override
  String get diagnosticsPlatform => 'Platform';

  @override
  String get diagnosticsNativeBridge => 'Native bridge';

  @override
  String get diagnosticsNativeBridgeOk => 'Working';

  @override
  String get diagnosticsNativeBridgeUnavailable => 'Unavailable';

  @override
  String get diagnosticsFrameTitle => 'Synthetic frame test';

  @override
  String get diagnosticsFrameCapture => 'Generate frame';

  @override
  String diagnosticsFrameInfo(int width, int height, int bytes, String millis) {
    return '$width×$height · $bytes bytes · $millis ms';
  }

  @override
  String get diagnosticsFrameError => 'Could not generate frame';

  @override
  String get diagnosticsHardwareNotice =>
      'Nothing has been verified on a real motorcycle yet.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAutoReconnect => 'Auto reconnect';

  @override
  String get settingsAutoReconnectHint =>
      'Tries to reconnect to the motorcycle when the link drops.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutBody =>
      'TurkMax is not affiliated with Yamaha Motor or Google.';

  @override
  String get navRouting => 'Calculating route';

  @override
  String get mapUnavailable => 'Map not ready';

  @override
  String get searchHint => 'Address or place name';

  @override
  String get searchPrompt => 'Type a destination (at least 3 letters).';

  @override
  String get searchEmpty => 'No results.';

  @override
  String get searchFailed => 'Search failed. Check your internet connection.';

  @override
  String get navCardTitle => 'Navigation';

  @override
  String get navWhereTo => 'Where to?';

  @override
  String get navStop => 'End navigation';

  @override
  String get navRetry => 'Try again';

  @override
  String get navPreparing => 'Preparing navigation…';

  @override
  String navTo(String name) {
    return 'Destination: $name';
  }

  @override
  String navRemaining(String distance, String duration) {
    return '$distance · $duration';
  }

  @override
  String get navSimulate => 'Simulate route (developer)';

  @override
  String get navSimulatedNotice => 'Location is simulated; not a real ride.';

  @override
  String get navErrorTerms =>
      'You must accept Google\'s terms to use navigation.';

  @override
  String get navErrorPermission =>
      'Location permission is required for navigation.';

  @override
  String get navErrorLocation =>
      'Could not determine your location. Make sure GPS is on.';

  @override
  String get navErrorNetwork =>
      'No internet connection or the routing service did not respond.';

  @override
  String get navErrorNoRoute => 'No route found to this destination.';

  @override
  String get navErrorApiKey =>
      'The maps service could not start. Check the API key and enabled APIs.';

  @override
  String get navErrorQuota => 'Maps usage quota exceeded.';

  @override
  String get navErrorUnknown => 'Could not start navigation.';

  @override
  String get demoDataNoticePartial =>
      'The notification and music shown are demo data.';

  @override
  String get connectionDisconnect => 'Disconnect';

  @override
  String get connectionConnect => 'Connect';

  @override
  String get connectionStartStreaming => 'Start streaming';

  @override
  String get connectionStopStreaming => 'Stop streaming';

  @override
  String get connectionPairedDevices => 'Paired devices';

  @override
  String get connectionRefresh => 'Refresh';

  @override
  String get connectionNoDevices =>
      'No paired devices. Pair the motorcycle in the phone\'s Bluetooth settings first.';

  @override
  String get connectionLikelyCcu => 'May be a Yamaha display';

  @override
  String get connectionFakeDeviceHint =>
      'Test without a motorcycle (developer)';

  @override
  String get connectionReceiverTitle => 'Image received by the fake display';

  @override
  String connectionLastDevice(String name) {
    return 'Last connection: $name';
  }

  @override
  String connectionStats(String fps, String ackMs, int quality, String kb) {
    return '$fps FPS · ACK $ackMs ms · quality $quality · $kb KB';
  }

  @override
  String connectionFrameCounts(int acked, int sent, int timeouts) {
    return '$acked/$sent frames acknowledged · $timeouts timeouts';
  }

  @override
  String get connectionErrorConnect =>
      'Could not connect. Make sure the ignition is on and the motorcycle is nearby. Close Garmin StreetCross or MyRide if open; only one app can use the link at a time.';

  @override
  String get connectionErrorHandshakeTimeout =>
      'The display did not respond. Turn the ignition off and on, then try again.';

  @override
  String get connectionErrorHandshake =>
      'Verification with the display could not be completed.';

  @override
  String get connectionErrorLinkLost => 'Connection lost.';

  @override
  String get connectionErrorPermission => 'Bluetooth permission is required.';

  @override
  String get connectionErrorBluetoothOff =>
      'Bluetooth is off. Turn it on and refresh.';

  @override
  String get connectionErrorNoBluetooth => 'This device has no Bluetooth.';

  @override
  String connectionErrorUnknown(String code) {
    return 'Connection error ($code).';
  }

  @override
  String get connectionUnverifiedNotice =>
      'Not yet verified on a real motorcycle. Results are recorded in the connection log.';

  @override
  String get streamSettingsTitle => 'Streaming settings';

  @override
  String get streamSettingsHint => 'Applies to the next connection.';

  @override
  String get streamSettingsLocked => 'Disconnect first to change.';

  @override
  String get streamSettingsSource => 'Image source';

  @override
  String get streamSettingsSourceCockpit => 'Cockpit (map)';

  @override
  String get streamSettingsSourceSynthetic => 'Test card';

  @override
  String get streamSettingsCockpitNotice =>
      'The map is drawn in the background and keeps updating while the app is in the background.';

  @override
  String get streamSettingsResolution => 'Resolution';

  @override
  String get streamSettingsAuto => 'Auto';

  @override
  String get streamSettingsQuality => 'JPEG quality';

  @override
  String get streamSettingsFps => 'Max FPS';

  @override
  String get streamSettingsNavStatus => 'Send NAV_STATUS active';

  @override
  String get streamSettingsNavStatusHint =>
      'Try this if the display draws nothing.';

  @override
  String get powerTitle => 'Battery optimisation';

  @override
  String get powerUnrestricted =>
      'No restriction. Suitable for background streaming.';

  @override
  String get powerRestricted =>
      'The system may stop the app in the background. Tap to open settings and remove the restriction for TurkMax.';

  @override
  String get logTitle => 'Connection log';

  @override
  String get logCopy => 'Copy';

  @override
  String get logCopied => 'Log copied to clipboard';

  @override
  String get logEmpty => 'No entries yet.';

  @override
  String logSavedTo(String path) {
    return 'File: $path';
  }
}
