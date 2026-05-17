import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_env.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/history_repository.dart';
import 'data/repositories/home_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/symptom_repository.dart';
import 'data/repositories/treatment_repository.dart';
import 'data/services/supabase_service.dart';
import 'ui/features/auth/view_models/auth_view_model.dart';
import 'ui/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

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
        ProxyProvider<SupabaseService, ProfileRepository>(
          update: (_, supabase, __) => ProfileRepository(supabase),
        ),
        ProxyProvider<SupabaseService, TreatmentRepository>(
          update: (_, supabase, __) => TreatmentRepository(supabase),
        ),
        ProxyProvider<SupabaseService, HomeRepository>(
          update: (_, supabase, __) => HomeRepository(supabase),
        ),
        ProxyProvider<SupabaseService, HistoryRepository>(
          update: (_, supabase, __) => HistoryRepository(supabase),
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
