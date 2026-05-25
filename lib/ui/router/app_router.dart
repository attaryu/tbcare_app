import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tbcare_app/data/models/symptom_model.dart';

import '../../core/shell/main_shell.dart';
import '../../data/models/treatment_period_model.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/home_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/symptom_repository.dart';
import '../../data/repositories/treatment_repository.dart';
import '../../data/repositories/medication_schedule_repository.dart';
import '../features/auth/view_models/auth_view_model.dart';
import '../features/auth/views/login_view.dart';
import '../features/auth/views/register_view.dart';
import '../features/history/view_models/history_view_model.dart';
import '../features/history/views/history_view.dart';
import '../features/home/view_models/home_view_model.dart';
import '../features/home/views/home_view.dart';
import '../features/profile/view_models/profile_view_model.dart';
import '../features/profile/views/profile_view.dart';
import '../features/symptoms/view_models/symptom_view_model.dart';
import '../features/symptoms/views/symptom_form_view.dart';
import '../features/symptoms/views/symptom_list_view.dart';
import '../features/treatment/view_models/treatment_view_model.dart';
import '../features/treatment/views/treatment_form_view.dart';
import '../features/treatment/views/treatment_view.dart';
import '../features/medication_schedule/view_models/medication_schedule_view_model.dart';
import '../features/medication_schedule/views/medication_schedule_view.dart';
import '../../data/services/supabase_service.dart';
import '../features/home/view_models/confirm_medication_view_model.dart';
import '../features/home/views/confirm_medication_view.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter config(AuthViewModel authViewModel) {
    return GoRouter(
      initialLocation: '/',
      navigatorKey: _rootNavigatorKey,
      refreshListenable: authViewModel,
      redirect: (context, state) {
        final isAuthenticated = authViewModel.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';
        final isRegistering = state.matchedLocation == '/register';

        if (!isAuthenticated && !isLoggingIn && !isRegistering) {
          return '/login';
        }
        if (isAuthenticated && (isLoggingIn || isRegistering)) {
          return '/';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginView()),
        GoRoute(path: '/register', builder: (context, state) => const RegisterView()),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) {
                    final userId = authViewModel.currentUser?.id;
                    if (userId == null) {
                      return const Scaffold(
                        body: Center(child: Text('Sesi berakhir')),
                      );
                    }
                    return ChangeNotifierProvider(
                      create: (_) => HomeViewModel(
                        repository: context.read<HomeRepository>(),
                        userId: userId,
                      ),
                      child: const HomeView(),
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'confirm-medication',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final extras = state.extra as Map<String, dynamic>;
                        final scheduleId = extras['scheduleId'] as int;
                        final medName = extras['medName'] as String;
                        final scheduleTime = extras['scheduleTime'] as String;
                        final homeViewModel = extras['homeViewModel'] as HomeViewModel;

                        return ChangeNotifierProvider(
                          create: (_) => ConfirmMedicationViewModel(
                            homeViewModel: homeViewModel,
                            scheduleId: scheduleId,
                            medName: medName,
                            scheduleTime: scheduleTime,
                            supabaseService: context.read<SupabaseService>(),
                          ),
                          child: const ConfirmMedicationView(),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/history',
                  builder: (context, state) {
                    final userId = authViewModel.currentUser?.id;
                    if (userId == null) {
                      return const Scaffold(
                        body: Center(child: Text('Sesi berakhir')),
                      );
                    }
                    return ChangeNotifierProvider(
                      create: (_) => HistoryViewModel(
                        repository: context.read<HistoryRepository>(),
                        userId: userId,
                      ),
                      child: const HistoryView(),
                    );
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/symptoms',
                  builder: (context, state) {
                    final userId = authViewModel.currentUser?.id;
                    if (userId == null)
                      return const Scaffold(
                        body: Center(child: Text('Error: Sesi berakhir')),
                      );

                    return FutureBuilder<int?>(
                      future: context
                          .read<SymptomRepository>()
                          .getActiveTreatmentPeriodId(userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (snapshot.hasError || snapshot.data == null) {
                          return Scaffold(
                            body: Center(
                              child: Text(
                                'Error: Tidak ada periode pengobatan aktif.\n${snapshot.error}',
                              ),
                            ),
                          );
                        }

                        return ChangeNotifierProvider(
                          create: (_) => SymptomViewModel(
                            repository: context.read<SymptomRepository>(),
                            treatmentPeriodId: snapshot.data!,
                          ),
                          child: Consumer<SymptomViewModel>(
                            builder: (context, viewModel, _) =>
                                SymptomListView(viewModel: viewModel),
                          ),
                        );
                      },
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'add',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final viewModel = state.extra as SymptomViewModel;
                        return SymptomFormView(viewModel: viewModel);
                      },
                    ),
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final extras = state.extra as Map<String, dynamic>;
                        final viewModel =
                            extras['viewModel'] as SymptomViewModel;
                        final log = extras['log'] as SymptomLog;
                        return SymptomFormView(viewModel: viewModel, log: log);
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) {
                    final userId = authViewModel.currentUser?.id;
                    if (userId == null) {
                      return const Scaffold(
                        body: Center(child: Text('Sesi berakhir')),
                      );
                    }
                    return ChangeNotifierProvider(
                      create: (_) => ProfileViewModel(
                        repository: context.read<ProfileRepository>(),
                        userId: userId,
                      ),
                      child: const ProfileView(),
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'medication-schedules',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final userId = authViewModel.currentUser?.id;
                        if (userId == null) {
                          return const Scaffold(
                            body: Center(child: Text('Sesi berakhir')),
                          );
                        }
                        return ChangeNotifierProvider(
                          create: (_) => MedicationScheduleViewModel(
                            repository: context.read<MedicationScheduleRepository>(),
                            userId: userId,
                          ),
                          child: Consumer<MedicationScheduleViewModel>(
                            builder: (context, viewModel, _) =>
                                MedicationScheduleView(viewModel: viewModel),
                          ),
                        );
                      },
                    ),
                    GoRoute(
                      path: 'treatment-periods',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final userId = authViewModel.currentUser?.id;
                        if (userId == null) {
                          return const Scaffold(
                            body: Center(child: Text('Sesi berakhir')),
                          );
                        }
                        return ChangeNotifierProvider(
                          create: (_) => TreatmentViewModel(
                            repository: context.read<TreatmentRepository>(),
                            userId: userId,
                          ),
                          child: const TreatmentView(),
                        );
                      },
                      routes: [
                        GoRoute(
                          path: 'add',
                          parentNavigatorKey: _rootNavigatorKey,
                          builder: (context, state) {
                            final viewModel = state.extra as TreatmentViewModel;
                            return TreatmentFormView(viewModel: viewModel);
                          },
                        ),
                        GoRoute(
                          path: 'edit',
                          parentNavigatorKey: _rootNavigatorKey,
                          builder: (context, state) {
                            final extras = state.extra as Map<String, dynamic>;
                            final viewModel = extras['viewModel'] as TreatmentViewModel;
                            final period = extras['period'] as TreatmentPeriodModel;
                            return TreatmentFormView(
                              viewModel: viewModel,
                              existingPeriod: period,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
