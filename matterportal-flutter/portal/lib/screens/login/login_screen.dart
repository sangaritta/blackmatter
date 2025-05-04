import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:portal/bloc/login/login_bloc.dart';
import 'package:portal/bloc/login/login_event.dart';
import 'package:portal/bloc/login/login_state.dart';
import 'package:portal/screens/login/starry_night_background.dart';
import 'package:portal/screens/login/forgot_password_screen.dart';
import 'package:portal/services/auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:portal/widgets/common/loading_indicator.dart';
import 'package:portal/screens/login/open_homepage_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  String _appVersion = '1.1.0';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(authService: AuthenticationService()),
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state.isSuccess) {
            context.go('/home');
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          final bloc = context.read<LoginBloc>();
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
                              borderRadius: BorderRadius.all(
                                Radius.circular(32),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 18,
                                  sigmaY: 18,
                                ),
                                child: Container(
                                  width:
                                      isMobile
                                          ? constraints.maxWidth * 0.95
                                          : 400,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 36,
                                    horizontal: 32,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(13),
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(19),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(13),
                                        blurRadius: 36,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 16),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 18.0,
                                        ),
                                        child: Center(
                                          child: AnimatedScale(
                                            scale: state.isLoading ? 0.95 : 1.0,
                                            duration: const Duration(
                                              milliseconds: 400,
                                            ),
                                            curve: Curves.easeInOut,
                                            child: SizedBox(
                                              height: 70,
                                              child: Image.asset(
                                                "assets/images/ico.png",
                                                fit: BoxFit.contain,
                                                filterQuality:
                                                    FilterQuality.high,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      AnimatedOpacity(
                                        opacity: state.isLoading ? 0.7 : 1.0,
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        curve: Curves.easeInOut,
                                        child: Text(
                                          'Sign In',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Regular',
                                            fontSize: 28,
                                            color: Colors.white,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 500,
                                        ),
                                        switchInCurve: Curves.easeInOut,
                                        switchOutCurve: Curves.easeInOut,
                                        child:
                                            state.isLoading
                                                ? const Center(
                                                  key: ValueKey('loading'),
                                                  child: LoadingIndicator(
                                                    key: ValueKey('loading'),
                                                    size: 32,
                                                  ),
                                                )
                                                : Column(
                                                  key: const ValueKey('form'),
                                                  children: [
                                                    _buildTextField(
                                                      controller: emailCtrl,
                                                      label: 'Email',
                                                      keyboardType:
                                                          TextInputType
                                                              .emailAddress,
                                                      autofillHints: const [
                                                        AutofillHints.email,
                                                      ],
                                                    ),
                                                    const SizedBox(height: 18),
                                                    _buildTextField(
                                                      controller: passCtrl,
                                                      label: 'Password',
                                                      isPassword: true,
                                                      autofillHints: const [
                                                        AutofillHints.password,
                                                      ],
                                                      onSubmitted: (_) {
                                                        // Update email and password in bloc before submitting
                                                        bloc.add(LoginEmailChanged(emailCtrl.text));
                                                        bloc.add(LoginPasswordChanged(passCtrl.text));
                                                        bloc.add(LoginSubmitted());
                                                      },
                                                    ),
                                                    const SizedBox(height: 18),
                                                    Center(
                                                      child: TextButton(
                                                        onPressed: () {
                                                          context.go('/forgot-password');
                                                        },
                                                        child: Text(
                                                          'Forgot Password?',
                                                          style: TextStyle(
                                                            fontFamily: 'SemiBold',
                                                            fontSize: 15,
                                                            color: Colors.white.withAlpha(200),
                                                            letterSpacing: 1.05,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Container(
                                                      height: 50,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              24,
                                                            ),
                                                        gradient:
                                                            const LinearGradient(
                                                              colors: [
                                                                Color(
                                                                  0xFF4361EE,
                                                                ),
                                                                Color(
                                                                  0xFF7209B7,
                                                                ),
                                                              ],
                                                              begin:
                                                                  Alignment
                                                                      .topLeft,
                                                              end:
                                                                  Alignment
                                                                      .bottomRight,
                                                            ),
                                                      ),
                                                      child: ElevatedButton(
                                                        onPressed:
                                                            state.isLoading
                                                                ? null
                                                                : () {
                                                                  bloc.add(
                                                                    LoginEmailChanged(
                                                                      emailCtrl
                                                                          .text,
                                                                    ),
                                                                  );
                                                                  bloc.add(
                                                                    LoginPasswordChanged(
                                                                      passCtrl
                                                                          .text,
                                                                    ),
                                                                  );
                                                                  bloc.add(
                                                                    LoginSubmitted(),
                                                                  );
                                                                },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          shadowColor:
                                                              Colors
                                                                  .transparent,
                                                          foregroundColor:
                                                              Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  24,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          "Sign In",
                                                          style: TextStyle(
                                                            fontFamily: 'Bold',
                                                            fontSize: 18,
                                                            color: Colors.white,
                                                            letterSpacing: 1.1,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                      ),
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
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Text(
                                'BlackMatter Portal $_appVersion',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Regular',
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (kIsWeb)
                  Positioned(
                    top: 24,
                    left: 24,
                    child: OpenHomepageButton(),
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
    List<String>? autofillHints,
    Function(String)? onSubmitted,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withAlpha(18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
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
        autofillHints: autofillHints,
        textInputAction:
            isPassword ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: onSubmitted,
        style: TextStyle(
          fontFamily: 'Regular',
          fontSize: 16,
          color: Colors.white,
          letterSpacing: 1.05,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withAlpha(10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          labelText: ' $label',
          labelStyle: TextStyle(
            fontFamily: 'Regular',
            fontSize: 15,
            color: Colors.white,
          ),
          hintStyle: TextStyle(
            fontFamily: 'Regular',
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }
}
