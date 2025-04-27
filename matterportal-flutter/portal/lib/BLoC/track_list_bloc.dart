import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:portal/Services/api_service.dart';

part 'track_list_event.dart';
part 'track_list_state.dart';

class TrackListBloc extends Bloc<TrackListEvent, TrackListState> {
  final String userId;
  final String projectId;
  final String productId;

  StreamSubscription<List<Map<String, dynamic>>>? _tracksSubscription;

  TrackListBloc({
    required this.userId,
    required this.projectId,
    required this.productId,
  }) : super(TrackListInitial()) {
    on<TrackListStarted>((event, emit) async {
      emit(TrackListLoading());
      await emit.onEach<List<Map<String, dynamic>>>(
        api.getTracksStream(userId, projectId, productId),
        onData: (tracks) => emit(TrackListLoaded(tracks: tracks)),
        onError: (error, stackTrace) => emit(TrackListError(error: error.toString())),
      );
    });
    on<TrackListReorderRequested>(_onReorderRequested);
    on<TrackListRefreshRequested>(_onRefreshRequested);
  }

  void _onStarted(TrackListStarted event, Emitter<TrackListState> emit) {
    // Legacy: not used with onEach-based handler
  }

  Future<void> _onReorderRequested(
      TrackListReorderRequested event, Emitter<TrackListState> emit) async {
    final currentState = state;
    if (currentState is TrackListLoaded) {
      final newOrder = List<Map<String, dynamic>>.from(currentState.tracks);
      final item = newOrder.removeAt(event.oldIndex);
      newOrder.insert(event.newIndex, item);
      final updates = <Map<String, dynamic>>[];
      for (int i = 0; i < newOrder.length; i++) {
        final track = Map<String, dynamic>.from(newOrder[i]);
        if (track['trackNumber'] != i + 1) {
          track['trackNumber'] = i + 1;
          updates.add(track);
        }
      }
      if (updates.isNotEmpty) {
        await api.updateMultipleTracks(userId, projectId, productId, updates);
      }
    }
  }

  void _onRefreshRequested(
      TrackListRefreshRequested event, Emitter<TrackListState> emit) {
    add(TrackListStarted());
  }

  @override
  Future<void> close() {
    _tracksSubscription?.cancel();
    return super.close();
  }
}
