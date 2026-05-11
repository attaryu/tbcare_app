import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_env.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/symptom_repository.dart';
import 'data/services/supabase_service.dart';
import 'ui/features/auth/view_models/auth_view_model.dart';
import 'ui/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SupabaseService>(
          create: (_) => SupabaseService.instance,
        ),
        ProxyProvider<SupabaseService, SymptomRepository>(
          update: (_, supabase, __) => SymptomRepository(supabase),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(context.read<SupabaseService>()),
        ),
      ],
      child: Consumer<AuthViewModel>(
        builder: (context, authViewModel, _) => MaterialApp.router(
          title: 'TB Care',
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.config(authViewModel),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
