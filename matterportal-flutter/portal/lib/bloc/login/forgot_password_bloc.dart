import 'package:flutter_bloc/flutter_bloc.dart';
import 'forgot_password_event.dart';
import 'forgot_password_state.dart';
import 'package:portal/services/auth_service.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final AuthService authService;
  ForgotPasswordBloc({required this.authService}) : super(const ForgotPasswordState()) {
    on<ForgotPasswordEmailChanged>((event, emit) {
      emit(state.copyWith(email: event.email, errorMessage: null));
    });
    on<ForgotPasswordSubmitted>(_onForgotPasswordSubmitted);
  }

  Future<void> _onForgotPasswordSubmitted(ForgotPasswordSubmitted event, Emitter<ForgotPasswordState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await authService.resetPassword(state.email);
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
