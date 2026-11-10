import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../streaming/domain/cockpit_frame_source.dart';
import '../domain/diagnostics_repository.dart';
import 'diagnostics_state.dart';

@injectable
class DiagnosticsCubit extends Cubit<DiagnosticsState> {
  DiagnosticsCubit(this._repository, this._frameSource)
    : super(const DiagnosticsState());

  final DiagnosticsRepository _repository;
  final CockpitFrameSource _frameSource;

  Future<void> load() async {
    final info = await _repository.platformInfo();
    if (isClosed) return;
    emit(DiagnosticsState(isLoading: false, platformInfo: info));
  }

  Future<void> captureFrame() async {
    emit(state.copyWith(frameStatus: FrameTestStatus.capturing));
    try {
      final frame = await _frameSource.captureFrame();
      if (isClosed) return;
      emit(state.copyWith(frameStatus: FrameTestStatus.success, frame: frame));
    } on Exception {
      if (isClosed) return;
      emit(state.copyWith(frameStatus: FrameTestStatus.failure));
    }
  }
}
