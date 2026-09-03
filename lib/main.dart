import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/analytics/presentation/bloc/analytics_bloc.dart';
import 'features/analytics/presentation/bloc/analytics_event.dart';
import 'features/app_blocker/presentation/bloc/app_blocker_bloc.dart';
import 'features/app_blocker/presentation/bloc/app_blocker_event.dart';
import 'features/app_blocker/presentation/pages/access_control_page.dart';
import 'features/domain_filter/presentation/bloc/domain_filter_bloc.dart';
import 'features/domain_filter/presentation/bloc/domain_filter_event.dart';
import 'features/schedule/presentation/bloc/schedule_bloc.dart';
import 'features/schedule/presentation/bloc/schedule_event.dart';
import 'features/security/presentation/bloc/auth_bloc.dart';
import 'features/security/presentation/bloc/auth_event.dart';
import 'features/system_controls/presentation/bloc/system_controls_bloc.dart';
import 'features/system_controls/presentation/bloc/system_controls_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDependencies();
  runApp(const NetGuardApp());
}

class NetGuardApp extends StatelessWidget {
  const NetGuardApp({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => serviceLocator<AppBlockerBloc>()
          ..add(const LoadInstalledAppsEvent()),
      ),
      BlocProvider(
        create: (_) => serviceLocator<DomainFilterBloc>()
          ..add(const LoadDomainsEvent()),
      ),
      BlocProvider(
        create: (_) => serviceLocator<ScheduleBloc>()
          ..add(const LoadSchedulesEvent()),
      ),
      BlocProvider(
        create: (_) => serviceLocator<AnalyticsBloc>()
          ..add(const LoadAnalyticsEvent()),
      ),
      BlocProvider(
        create: (_) => serviceLocator<AuthBloc>()
          ..add(const CheckAuthStatusEvent()),
      ),
      BlocProvider(
        create: (_) => serviceLocator<SystemControlsBloc>()
          ..add(const LoadSystemControlsEvent()),
      ),
    ],
    child: MaterialApp(
      title: 'NetGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AccessControlPage(),
    ),
  );
}
