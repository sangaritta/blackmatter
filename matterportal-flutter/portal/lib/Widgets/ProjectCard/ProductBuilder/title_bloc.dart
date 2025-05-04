import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'title_event.dart';
part 'title_state.dart';

/// Advanced BLoC for the Release Title field, easily extensible for validation, async, undo, etc.
class TitleBloc extends Bloc<TitleEvent, TitleState> {
  TitleBloc({required String initialTitle})
    : super(TitleState.initial(initialTitle)) {
    on<TitleChanged>(_onTitleChanged);
    on<TitleUndo>(_onTitleUndo);
    on<TitleValidate>(_onTitleValidate);
    // Add more event handlers here as needed
  }

  void _onTitleChanged(TitleChanged event, Emitter<TitleState> emit) {
    emit(
      state.copyWith(
        title: event.title,
        history: List.from(state.history)..add(state.title),
        isValid: null, // Reset validation status on change
        error: '',
      ),
    );
  }

  void _onTitleUndo(TitleUndo event, Emitter<TitleState> emit) {
    if (state.history.isNotEmpty) {
      final previous = state.history.last;
      emit(
        state.copyWith(
          title: previous,
          history: List.from(state.history)..removeLast(),
          isValid: null,
          error: '',
        ),
      );
    }
  }

  void _onTitleValidate(TitleValidate event, Emitter<TitleState> emit) {
    final isValid = event.validator(state.title);
    emit(
      state.copyWith(isValid: isValid, error: isValid ? '' : 'Invalid title'),
    );
  }
}
