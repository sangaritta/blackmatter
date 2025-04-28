part of 'title_bloc.dart';

class TitleState extends Equatable {
  final String title;
  final List<String> history;
  final bool? isValid;
  final String error;

  const TitleState({
    required this.title,
    required this.history,
    required this.isValid,
    required this.error,
  });

  factory TitleState.initial(String initialTitle) => TitleState(
        title: initialTitle,
        history: const [],
        isValid: null,
        error: '',
      );

  TitleState copyWith({
    String? title,
    List<String>? history,
    bool? isValid,
    String? error,
  }) {
    return TitleState(
      title: title ?? this.title,
      history: history ?? this.history,
      isValid: isValid,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [title, history, isValid, error];
}
