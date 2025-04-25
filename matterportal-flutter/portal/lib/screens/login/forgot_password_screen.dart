import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:portal/bloc/login/forgot_password_bloc.dart';
import 'package:portal/bloc/login/forgot_password_event.dart';
import 'package:portal/bloc/login/forgot_password_state.dart';
import 'package:portal/screens/login/starry_night_background.dart';
import 'package:portal/services/auth_service.dart';
import 'package:portal/widgets/common/loading_indicator.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ForgotPasswordBloc(authService: AuthService.instance),
      child: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password reset email sent.')),
            );
            Navigator.of(context).pop();
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<ForgotPasswordBloc>();
          return Scaffold(
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                const Positioned.fill(child: StarryNightBackground()),
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      return Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color.fromRGBO(13, 16, 38, 0.60),
                                  Color.fromRGBO(24, 28, 54, 0.45),
                                  Color.fromRGBO(34, 38, 76, 0.30),
                                ],
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(32)),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                child: Container(
                                  width: isMobile ? constraints.maxWidth * 0.95 : 400,
                                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 32),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.13, red: 255, green: 255, blue: 255),
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.19, red: 255, green: 255, blue: 255),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.13, red: 0, green: 0, blue: 0),
                                        blurRadius: 36,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 16),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 18.0),
                                        child: Center(
                                          child: Text(
                                            "Forgot Password",
                                            style: TextStyle(
                                              fontFamily: 'Bold',
                                              fontSize: 18,
                                              color: Colors.white.withValues(alpha: 0.95, red: 255, green: 255, blue: 255),
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      _buildTextField(
                                        controller: emailCtrl,
                                        label: 'Email',
                                        keyboardType: TextInputType.emailAddress,
                                        onSubmitted: (val) => bloc.add(ForgotPasswordEmailChanged(val)),
                                      ),
                                      const SizedBox(height: 18),
                                      ElevatedButton(
                                        onPressed: state.isLoading
                                            ? null
                                            : () {
                                                bloc.add(ForgotPasswordEmailChanged(emailCtrl.text));
                                                bloc.add(ForgotPasswordSubmitted());
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1A237E),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                        ),
                                        child: state.isLoading
                                            ? const LoadingIndicator(size: 24, color: Colors.white)
                                            : const Text(
                                                "Send Reset Email",
                                                style: TextStyle(
                                                  fontFamily: 'Bold',
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                  letterSpacing: 1.1,
                                                ),
                                              ),
                                      ),
                                      if (state.errorMessage != null) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          state.errorMessage!,
                                          style: const TextStyle(color: Colors.red),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                'BlackMatter Portal${_appVersion != null ? ' v$_appVersion' : ''}',
                                style: TextStyle(
                                  fontFamily: 'SemiBold',
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.80, red: 255, green: 255, blue: 255),
                                  letterSpacing: 1.05,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.18, red: 0, green: 0, blue: 0),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    TextInputType? keyboardType,
    Function(String)? onSubmitted,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14, red: 255, green: 255, blue: 255),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18, red: 255, green: 255, blue: 255), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12, red: 0, green: 0, blue: 0),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: onSubmitted,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'SemiBold',
          fontSize: 16,
          letterSpacing: 1.05,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.10, red: 255, green: 255, blue: 255),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          labelText: ' $label',
          labelStyle: TextStyle(
            fontFamily: 'SemiBold',
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.85, red: 255, green: 255, blue: 255),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }
}
