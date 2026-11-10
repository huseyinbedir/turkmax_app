// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:turkmax/app/di/platform_module.dart' as _i208;
import 'package:turkmax/core/platform/device_power.dart' as _i838;
import 'package:turkmax/core/platform/maps_config.dart' as _i204;
import 'package:turkmax/features/cockpit/presentation/cockpit_cubit.dart'
    as _i370;
import 'package:turkmax/features/connection/data/fake_tft_connection_repository.dart'
    as _i586;
import 'package:turkmax/features/connection/data/platform_tft_connection_repository.dart'
    as _i317;
import 'package:turkmax/features/connection/domain/tft_connection_repository.dart'
    as _i402;
import 'package:turkmax/features/connection/presentation/connection_cubit.dart'
    as _i1063;
import 'package:turkmax/features/device_status/data/fake_device_status_repository.dart'
    as _i156;
import 'package:turkmax/features/device_status/data/platform_device_status_repository.dart'
    as _i247;
import 'package:turkmax/features/device_status/domain/device_status_repository.dart'
    as _i445;
import 'package:turkmax/features/diagnostics/data/fake_diagnostics_repository.dart'
    as _i319;
import 'package:turkmax/features/diagnostics/data/platform_diagnostics_repository.dart'
    as _i488;
import 'package:turkmax/features/diagnostics/domain/diagnostics_repository.dart'
    as _i764;
import 'package:turkmax/features/diagnostics/presentation/diagnostics_cubit.dart'
    as _i104;
import 'package:turkmax/features/media/data/fake_media_repository.dart'
    as _i742;
import 'package:turkmax/features/media/domain/media_repository.dart' as _i917;
import 'package:turkmax/features/navigation/domain/navigation_provider.dart'
    as _i655;
import 'package:turkmax/features/navigation/domain/place_search_repository.dart'
    as _i483;
import 'package:turkmax/features/navigation/presentation/destination_search_cubit.dart'
    as _i766;
import 'package:turkmax/features/navigation/presentation/navigation_cubit.dart'
    as _i553;
import 'package:turkmax/features/notifications/data/fake_notification_repository.dart'
    as _i741;
import 'package:turkmax/features/notifications/domain/notification_repository.dart'
    as _i639;
import 'package:turkmax/features/settings/data/prefs_settings_repository.dart'
    as _i310;
import 'package:turkmax/features/settings/domain/settings_repository.dart'
    as _i308;
import 'package:turkmax/features/settings/presentation/settings_cubit.dart'
    as _i318;
import 'package:turkmax/features/streaming/data/cockpit_frame_publisher.dart'
    as _i740;
import 'package:turkmax/features/streaming/data/fake_cockpit_frame_source.dart'
    as _i117;
import 'package:turkmax/features/streaming/data/platform_synthetic_frame_source.dart'
    as _i604;
import 'package:turkmax/features/streaming/domain/cockpit_frame_source.dart'
    as _i172;

const String _device = 'device';
const String _fake = 'fake';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final platformModule = _$PlatformModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => platformModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i838.DevicePower>(() => const _i838.DevicePower());
    gh.lazySingleton<_i740.CockpitFramePublisher>(
      () => _i740.CockpitFramePublisher(),
    );
    gh.lazySingleton<_i764.DiagnosticsRepository>(
      () => const _i488.PlatformDiagnosticsRepository(),
      registerFor: {_device},
    );
    gh.lazySingleton<_i639.NotificationRepository>(
      () => const _i741.FakeNotificationRepository(),
    );
    gh.lazySingleton<_i172.CockpitFrameSource>(
      () => const _i604.PlatformSyntheticFrameSource(),
      registerFor: {_device},
    );
    await gh.factoryAsync<_i204.MapsConfig>(
      () => platformModule.mapsConfig,
      registerFor: {_device},
      preResolve: true,
    );
    gh.lazySingleton<_i402.TftConnectionRepository>(
      () => _i317.PlatformTftConnectionRepository(),
      registerFor: {_device},
    );
    gh.lazySingleton<_i445.DeviceStatusRepository>(
      () => const _i247.PlatformDeviceStatusRepository(),
      registerFor: {_device},
    );
    gh.lazySingleton<_i917.MediaRepository>(
      () => const _i742.FakeMediaRepository(),
    );
    gh.lazySingleton<_i308.SettingsRepository>(
      () => _i310.PrefsSettingsRepository(gh<_i460.SharedPreferences>()),
    );
    gh.factory<_i204.MapsConfig>(
      () => platformModule.fakeMapsConfig,
      registerFor: {_fake},
    );
    gh.factory<_i318.SettingsCubit>(
      () => _i318.SettingsCubit(gh<_i308.SettingsRepository>()),
    );
    gh.lazySingleton<_i402.TftConnectionRepository>(
      () => _i586.FakeTftConnectionRepository(),
      registerFor: {_fake},
    );
    gh.lazySingleton<_i764.DiagnosticsRepository>(
      () => const _i319.FakeDiagnosticsRepository(),
      registerFor: {_fake},
    );
    gh.factory<_i1063.ConnectionCubit>(
      () => _i1063.ConnectionCubit(
        gh<_i402.TftConnectionRepository>(),
        gh<_i308.SettingsRepository>(),
        gh<_i838.DevicePower>(),
      ),
    );
    gh.lazySingleton<_i445.DeviceStatusRepository>(
      () => const _i156.FakeDeviceStatusRepository(),
      registerFor: {_fake},
    );
    gh.lazySingleton<_i172.CockpitFrameSource>(
      () => const _i117.FakeCockpitFrameSource(),
      registerFor: {_fake},
    );
    gh.factory<_i104.DiagnosticsCubit>(
      () => _i104.DiagnosticsCubit(
        gh<_i764.DiagnosticsRepository>(),
        gh<_i172.CockpitFrameSource>(),
      ),
    );
    gh.lazySingleton<_i655.NavigationProvider>(
      () => platformModule.navigationProvider(gh<_i204.MapsConfig>()),
    );
    gh.lazySingleton<_i483.PlaceSearchRepository>(
      () => platformModule.placeSearchRepository(gh<_i204.MapsConfig>()),
    );
    gh.factory<_i553.NavigationCubit>(
      () => _i553.NavigationCubit(gh<_i655.NavigationProvider>()),
    );
    gh.factory<_i370.CockpitCubit>(
      () => _i370.CockpitCubit(
        gh<_i655.NavigationProvider>(),
        gh<_i445.DeviceStatusRepository>(),
        gh<_i402.TftConnectionRepository>(),
        gh<_i917.MediaRepository>(),
        gh<_i639.NotificationRepository>(),
      ),
    );
    gh.factory<_i766.DestinationSearchCubit>(
      () => _i766.DestinationSearchCubit(gh<_i483.PlaceSearchRepository>()),
    );
    return this;
  }
}

class _$PlatformModule extends _i208.PlatformModule {}
