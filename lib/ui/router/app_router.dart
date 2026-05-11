import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/shell/main_shell.dart';
import '../../data/repositories/symptom_repository.dart';
import '../features/auth/view_models/auth_view_model.dart';
import '../features/auth/views/login_view.dart';
import '../features/home/views/home_view.dart';
import '../features/profile/views/profile_view.dart';
import '../features/symptoms/view_models/symptom_view_model.dart';
import '../features/symptoms/views/symptom_list_view.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter config(AuthViewModel authViewModel) {
    return GoRouter(
      initialLocation: '/symptoms',
      navigatorKey: _rootNavigatorKey,
      refreshListenable: authViewModel,
      redirect: (context, state) {
        final isAuthenticated = authViewModel.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';

        if (!isAuthenticated && !isLoggingIn) {
          return '/login';
        }
        if (isAuthenticated && isLoggingIn) {
          return '/symptoms';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginView(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const HomeView(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/symptoms',
                  builder: (context, state) {
                    final userId = authViewModel.currentUser?.id;
                    if (userId == null) return const Scaffold(body: Center(child: Text('Error: Sesi berakhir')));
                    
                    return FutureBuilder<int?>(
                      future: context.read<SymptomRepository>().getActiveTreatmentPeriodId(userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Scaffold(body: Center(child: CircularProgressIndicator()));
                        }
                        
                        if (snapshot.hasError || snapshot.data == null) {
                          return Scaffold(
                            body: Center(
                              child: Text('Error: Tidak ada periode pengobatan aktif.\n${snapshot.error}'),
                            ),
                          );
                        }
                        
                        return ChangeNotifierProvider(
                          create: (_) => SymptomViewModel(
                            repository: context.read<SymptomRepository>(),
                            treatmentPeriodId: snapshot.data!,
                          ),
                          child: Consumer<SymptomViewModel>(
                            builder: (context, viewModel, _) => SymptomListView(viewModel: viewModel),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileView(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
