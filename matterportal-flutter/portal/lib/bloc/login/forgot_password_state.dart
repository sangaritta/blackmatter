import 'package:equatable/equatable.dart';

class ForgotPasswordState extends Equatable {
  final String email;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const ForgotPasswordState({
    this.email = '',
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  ForgotPasswordState copyWith({
    String? email,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [email, isLoading, errorMessage, isSuccess];
}
