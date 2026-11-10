import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../domain/route_destination.dart';
import '../domain/place_search_repository.dart';

enum SearchStatus { idle, loading, results, empty, failure }

class DestinationSearchState extends Equatable {
  const DestinationSearchState({
    this.status = SearchStatus.idle,
    this.results = const [],
    this.errorDetail,
  });

  final SearchStatus status;
  final List<RouteDestination> results;
  final String? errorDetail;

  @override
  List<Object?> get props => [status, results, errorDetail];
}

@injectable
class DestinationSearchCubit extends Cubit<DestinationSearchState> {
  DestinationSearchCubit(this._repository)
    : super(const DestinationSearchState());

  final PlaceSearchRepository _repository;

  /// Gereksiz (ve ücretli) istekleri azaltmak için.
  static const debounce = Duration(milliseconds: 400);
  static const minQueryLength = 3;

  final String _sessionToken = _newToken();
  Timer? _timer;
  int _generation = 0;

  void queryChanged(String raw) {
    final query = raw.trim();
    _timer?.cancel();
    _generation++;
    if (query.length < minQueryLength) {
      emit(const DestinationSearchState());
      return;
    }
    final generation = _generation;
    _timer = Timer(debounce, () => _search(query, generation));
  }

  Future<void> _search(String query, int generation) async {
    emit(const DestinationSearchState(status: SearchStatus.loading));
    try {
      final results = await _repository.search(
        query,
        sessionToken: _sessionToken,
      );
      if (isClosed || generation != _generation) return;
      emit(
        DestinationSearchState(
          status: results.isEmpty ? SearchStatus.empty : SearchStatus.results,
          results: results,
        ),
      );
    } on PlaceSearchException catch (e) {
      if (isClosed || generation != _generation) return;
      emit(
        DestinationSearchState(
          status: SearchStatus.failure,
          errorDetail: e.message,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  static String _newToken() {
    final random = Random.secure();
    return List.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
  }
}
