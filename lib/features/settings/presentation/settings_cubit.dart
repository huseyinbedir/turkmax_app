import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../domain/settings_repository.dart';

@injectable
class SettingsCubit extends Cubit<bool> {
  SettingsCubit(this._repository) : super(_repository.autoReconnect);

  final SettingsRepository _repository;

  Future<void> setAutoReconnect(bool value) async {
    await _repository.setAutoReconnect(value);
    emit(value);
  }
}
