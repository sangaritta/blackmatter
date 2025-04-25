import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../services/api_service.dart';

// EVENTS
abstract class SongwriterEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CreateSongwriterRequested extends SongwriterEvent {
  final Map<String, dynamic> songwriterData;
  CreateSongwriterRequested(this.songwriterData);
  @override
  List<Object?> get props => [songwriterData];
}

// STATES
abstract class SongwriterState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SongwriterInitial extends SongwriterState {}
class SongwriterLoading extends SongwriterState {}
class SongwriterSuccess extends SongwriterState {}
class SongwriterFailure extends SongwriterState {
  final String error;
  SongwriterFailure(this.error);
  @override
  List<Object?> get props => [error];
}

// BLOC
class SongwriterBloc extends Bloc<SongwriterEvent, SongwriterState> {
  final ApiService apiService;
  SongwriterBloc({required this.apiService}) : super(SongwriterInitial()) {
    on<CreateSongwriterRequested>(_onCreateSongwriterRequested);
  }

  Future<void> _onCreateSongwriterRequested(
    CreateSongwriterRequested event,
    Emitter<SongwriterState> emit,
  ) async {
    emit(SongwriterLoading());
    try {
      await apiService.createSongwriter(event.songwriterData);
      emit(SongwriterSuccess());
    } catch (e) {
      emit(SongwriterFailure(e.toString()));
    }
  }
}
