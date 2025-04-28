part of 'title_bloc.dart';

abstract class TitleEvent extends Equatable {
  const TitleEvent();
  @override
  List<Object?> get props => [];
}

class TitleChanged extends TitleEvent {
  final String title;
  const TitleChanged(this.title);
  @override
  List<Object?> get props => [title];
}

class TitleUndo extends TitleEvent {
  const TitleUndo();
}

class TitleValidate extends TitleEvent {
  final bool Function(String) validator;
  const TitleValidate(this.validator);
  @override
  List<Object?> get props => [validator];
}
