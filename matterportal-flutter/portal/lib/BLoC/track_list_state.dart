part of 'track_list_bloc.dart';

abstract class TrackListState extends Equatable {
  const TrackListState();

  @override
  List<Object?> get props => [];
}

class TrackListInitial extends TrackListState {}

class TrackListLoading extends TrackListState {}

class TrackListLoaded extends TrackListState {
  final List<Map<String, dynamic>> tracks;
  const TrackListLoaded({required this.tracks});

  @override
  List<Object?> get props => [tracks];
}

class TrackListError extends TrackListState {
  final String error;
  const TrackListError({required this.error});

  @override
  List<Object?> get props => [error];
}
