part of 'track_list_bloc.dart';

abstract class TrackListEvent extends Equatable {
  const TrackListEvent();

  @override
  List<Object?> get props => [];
}

class TrackListStarted extends TrackListEvent {}

class TrackListReorderRequested extends TrackListEvent {
  final int oldIndex;
  final int newIndex;

  const TrackListReorderRequested({required this.oldIndex, required this.newIndex});

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class TrackListRefreshRequested extends TrackListEvent {}
