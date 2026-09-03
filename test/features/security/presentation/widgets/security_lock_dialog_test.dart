import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/features/security/domain/entities/security_settings_entity.dart';
import 'package:net_guard/features/security/presentation/bloc/auth_bloc.dart';
import 'package:net_guard/features/security/presentation/bloc/auth_event.dart';
import 'package:net_guard/features/security/presentation/bloc/auth_state.dart';
import 'package:net_guard/features/security/presentation/widgets/security_lock_dialog.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(const AuthenticateUserEvent());
    registerFallbackValue(const SetMasterPasscodeEvent('0000'));
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthBloc.state).thenReturn(
      const AuthPromptRequired(biometricsEnabled: true, hasMasterPin: true),
    );
  });

  testWidgets('SecurityLockDialog renders verification mode correctly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const SecurityLockDialog(isSetupMode: false),
          ),
        ),
      ),
    );

    expect(find.text('SECURITY VERIFICATION'), findsOneWidget);
    expect(find.text('UNLOCK'), findsOneWidget);
    expect(find.text('VERIFY WITH BIOMETRICS'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('SecurityLockDialog renders setup mode and accepts confirm pin', (
    tester,
  ) async {
    when(() => mockAuthBloc.state).thenReturn(
      const AuthSuccess(
        settings: SecuritySettingsEntity(
          isBiometricsEnabled: false,
          hasMasterPasscode: false,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const SecurityLockDialog(isSetupMode: true),
          ),
        ),
      ),
    );

    expect(find.text('SETUP MASTER PASSCODE'), findsOneWidget);
    expect(find.text('SAVE'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).first, '1234');
    await tester.enterText(find.byType(TextField).last, '1234');
    await tester.tap(find.text('SAVE'));
    await tester.pump();

    verify(() => mockAuthBloc.add(any(that: isA<SetMasterPasscodeEvent>()))).called(1);
  });
}
