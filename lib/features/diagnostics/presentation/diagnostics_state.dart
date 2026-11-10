import 'package:equatable/equatable.dart';

import '../../streaming/domain/cockpit_frame.dart';
import '../domain/platform_info.dart';

enum FrameTestStatus { idle, capturing, success, failure }

class DiagnosticsState extends Equatable {
  const DiagnosticsState({
    this.isLoading = true,
    this.platformInfo,
    this.frameStatus = FrameTestStatus.idle,
    this.frame,
  });

  final bool isLoading;
  final PlatformInfo? platformInfo;
  final FrameTestStatus frameStatus;
  final CockpitFrame? frame;

  bool get isNativeBridgeAvailable => platformInfo != null;

  DiagnosticsState copyWith({
    bool? isLoading,
    PlatformInfo? platformInfo,
    FrameTestStatus? frameStatus,
    CockpitFrame? frame,
  }) => DiagnosticsState(
    isLoading: isLoading ?? this.isLoading,
    platformInfo: platformInfo ?? this.platformInfo,
    frameStatus: frameStatus ?? this.frameStatus,
    frame: frame ?? this.frame,
  );

  @override
  List<Object?> get props => [isLoading, platformInfo, frameStatus, frame];
}
