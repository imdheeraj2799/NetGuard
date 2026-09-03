import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/usecase/usecase.dart';
import 'package:net_guard/features/security/domain/entities/security_settings_entity.dart';
import 'package:net_guard/features/security/domain/usecases/authenticate_user_usecase.dart';
import 'package:net_guard/features/security/domain/usecases/get_security_settings_usecase.dart';
import 'package:net_guard/features/security/domain/usecases/set_master_passcode_usecase.dart';
import 'package:net_guard/features/security/domain/usecases/toggle_biometrics_usecase.dart';
import 'package:net_guard/features/security/presentation/bloc/auth_bloc.dart';
import 'package:net_guard/features/security/presentation/bloc/auth_event.dart';
import 'package:net_guard/features/security/presentation/bloc/auth_state.dart';

class MockAuthenticateUserUseCase extends Mock
    implements AuthenticateUserUseCase {}

class MockSetMasterPasscodeUseCase extends Mock
    implements SetMasterPasscodeUseCase {}

class MockToggleBiometricsUseCase extends Mock
    implements ToggleBiometricsUseCase {}

class MockGetSecuritySettingsUseCase extends Mock
    implements GetSecuritySettingsUseCase {}

void main() {
  late MockAuthenticateUserUseCase mockAuth;
  late MockSetMasterPasscodeUseCase mockSetPass;
  late MockToggleBiometricsUseCase mockToggleBio;
  late MockGetSecuritySettingsUseCase mockGetSettings;
  late AuthBloc bloc;

  setUpAll(() {
    registerFallbackValue(const AuthenticateUserParams());
    registerFallbackValue(const SetMasterPasscodeParams(passcode: '0000'));
    registerFallbackValue(const ToggleBiometricsParams(isEnabled: false));
    registerFallbackValue(NoParams());
  });

  setUp(() {
    mockAuth = MockAuthenticateUserUseCase();
    mockSetPass = MockSetMasterPasscodeUseCase();
    mockToggleBio = MockToggleBiometricsUseCase();
    mockGetSettings = MockGetSecuritySettingsUseCase();

    bloc = AuthBloc(
      authenticateUser: mockAuth,
      setMasterPasscode: mockSetPass,
      toggleBiometrics: mockToggleBio,
      getSecuritySettings: mockGetSettings,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('AuthBloc Tests', () {
    test('initial state is AuthInitial', () {
      expect(bloc.state, const AuthInitial());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthSuccess] on CheckAuthStatusEvent when neither biometrics nor PIN enabled',
      build: () {
        when(() => mockGetSettings(any())).thenAnswer(
          (_) async => const Right(
            SecuritySettingsEntity(
              isBiometricsEnabled: false,
              hasMasterPasscode: false,
            ),
          ),
        );
        return bloc;
      },
      act: (b) => b.add(const CheckAuthStatusEvent()),
      expect: () => [
        const AuthSuccess(
          settings: SecuritySettingsEntity(
            isBiometricsEnabled: false,
            hasMasterPasscode: false,
          ),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthPromptRequired] on CheckAuthStatusEvent when security configured',
      build: () {
        when(() => mockGetSettings(any())).thenAnswer(
          (_) async => const Right(
            SecuritySettingsEntity(
              isBiometricsEnabled: true,
              hasMasterPasscode: true,
            ),
          ),
        );
        return bloc;
      },
      act: (b) => b.add(const CheckAuthStatusEvent()),
      expect: () => [
        const AuthPromptRequired(biometricsEnabled: true, hasMasterPin: true),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthSuccess] when AuthenticateUserEvent succeeds',
      build: () {
        when(() => mockAuth(any())).thenAnswer((_) async => const Right(true));
        when(() => mockGetSettings(any())).thenAnswer(
          (_) async => const Right(
            SecuritySettingsEntity(
              isBiometricsEnabled: true,
              hasMasterPasscode: true,
            ),
          ),
        );
        return bloc;
      },
      act: (b) => b.add(const AuthenticateUserEvent(passcode: '1234')),
      expect: () => [
        const AuthSuccess(
          settings: SecuritySettingsEntity(
            isBiometricsEnabled: true,
            hasMasterPasscode: true,
          ),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthFailure] when AuthenticateUserEvent has invalid passcode',
      build: () {
        when(() => mockAuth(any())).thenAnswer((_) async => const Right(false));
        return bloc;
      },
      act: (b) => b.add(const AuthenticateUserEvent(passcode: '0000')),
      expect: () => [
        const AuthFailure(
          message: 'Invalid credentials. Please try again.',
          attemptsRemaining: 4,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthSuccess] when SetMasterPasscodeEvent succeeds',
      build: () {
        when(() => mockSetPass(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetSettings(any())).thenAnswer(
          (_) async => const Right(
            SecuritySettingsEntity(
              isBiometricsEnabled: false,
              hasMasterPasscode: true,
            ),
          ),
        );
        return bloc;
      },
      act: (b) => b.add(const SetMasterPasscodeEvent('5555')),
      expect: () => [
        const AuthSuccess(
          settings: SecuritySettingsEntity(
            isBiometricsEnabled: false,
            hasMasterPasscode: true,
          ),
        ),
      ],
    );
  });
}
