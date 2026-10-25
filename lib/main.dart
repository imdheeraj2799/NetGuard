import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/app_blocker/presentation/bloc/app_blocker_bloc.dart';
import 'features/app_blocker/presentation/bloc/app_blocker_event.dart';
import 'features/app_blocker/presentation/bloc/schedule_bloc.dart';
import 'features/app_blocker/presentation/bloc/schedule_event.dart';
import 'features/app_blocker/presentation/pages/dashboard_page.dart';
import 'features/temporary_internet_pause/presentation/bloc/temporary_pause_bloc.dart';
import 'features/temporary_internet_pause/presentation/bloc/temporary_pause_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
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
        create: (_) => serviceLocator<ScheduleBloc>()
          ..add(const LoadSchedulesEvent()),
      ),
      BlocProvider(
        create: (_) => serviceLocator<TemporaryPauseBloc>()
          ..add(const LoadTemporaryPausesEvent()),
      ),
    ],
    child: MaterialApp(
      title: 'NetGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardPage(),
    ),
  );
}
