import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';
import '../../../../core/theme/app_color.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Selamat Datang',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColor.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Silakan login untuk melanjutkan',
                style: TextStyle(color: AppColor.neutralGray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              if (authViewModel.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    authViewModel.error!,
                    style: const TextStyle(color: AppColor.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: authViewModel.isLoading
                    ? null
                    : () {
                        authViewModel.login(
                          _emailController.text,
                          _passwordController.text,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: AppColor.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: authViewModel.isLoading
                    ? const CircularProgressIndicator(color: AppColor.white)
                    : const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
