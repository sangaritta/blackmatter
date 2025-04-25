import 'package:equatable/equatable.dart';

abstract class ApiServiceState extends Equatable {
  const ApiServiceState();
  @override
  List<Object?> get props => [];
}

class ApiServiceInitial extends ApiServiceState {}
class ApiServiceLoading extends ApiServiceState {}
class ApiServiceSuccess extends ApiServiceState {}
class ApiServiceFailure extends ApiServiceState {
  final String error;
  const ApiServiceFailure(this.error);
  @override
  List<Object?> get props => [error];
}

// No need to store userId in state. State should only reflect the data and status.
