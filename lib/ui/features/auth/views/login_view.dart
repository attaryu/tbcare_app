import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _performLogin() {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    final authViewModel = context.read<AuthViewModel>();
    authViewModel.login(_emailController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final mediaQuery = MediaQuery.of(context);
    final totalMinHeight =
        mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        72;

    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 28.0,
              vertical: 36.0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: totalMinHeight > 0 ? totalMinHeight : 500,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bagian Atas & Tengah: Logo, Judul, Form
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      // Ilustrasi / Logo TBCare dengan soft shadow glow
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColor.primaryLight.withOpacity(0.7),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColor.primary.withOpacity(0.15),
                                blurRadius: 24,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.volunteer_activism,
                            size: 52,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'TBCare',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColor.darkGray,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Empowering Adherence through\nCollaborative Support',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColor.neutralGray,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Input Email
                      AppTextField(
                        label: 'Email',
                        hint: 'Masukkan email terdaftar',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !authViewModel.isLoading,
                      ),
                      const SizedBox(height: 24),

                      // Input Password
                      AppTextField(
                        label: 'Password',
                        hint: 'Masukkan password',
                        controller: _passwordController,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _performLogin(),
                        enabled: !authViewModel.isLoading,
                      ),
                    ],
                  ),

                  // Bagian Bawah: Pesan Error (Animated), Tombol Masuk, & Link Daftar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: authViewModel.error != null
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColor.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColor.error.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: AppColor.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          authViewModel.error!,
                                          style: const TextStyle(
                                            color: AppColor.error,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      AppButton(
                        text: 'Masuk',
                        isLoading: authViewModel.isLoading,
                        onPressed: _performLogin,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Belum punya akun? ',
                            style: TextStyle(
                              color: AppColor.darkGray,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.go('/register');
                            },
                            child: const Text(
                              'Daftar di sini',
                              style: TextStyle(
                                color: AppColor.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
