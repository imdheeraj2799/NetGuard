// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/authenticate_user_usecase.dart';
import '../../domain/usecases/get_security_settings_usecase.dart';
import '../../domain/usecases/set_master_passcode_usecase.dart';
import '../../domain/usecases/toggle_biometrics_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthenticateUserUseCase authenticateUser,
    required SetMasterPasscodeUseCase setMasterPasscode,
    required ToggleBiometricsUseCase toggleBiometrics,
    required GetSecuritySettingsUseCase getSecuritySettings,
  })  : _authenticateUser = authenticateUser,
        _setMasterPasscode = setMasterPasscode,
        _toggleBiometrics = toggleBiometrics,
        _getSecuritySettings = getSecuritySettings,
        super(const AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<AuthenticateUserEvent>(_onAuthenticateUser);
    on<SetMasterPasscodeEvent>(_onSetMasterPasscode);
    on<ToggleBiometricsEvent>(_onToggleBiometrics);
    on<LockAppEvent>(_onLockApp);
  }

  final AuthenticateUserUseCase _authenticateUser;
  final SetMasterPasscodeUseCase _setMasterPasscode;
  final ToggleBiometricsUseCase _toggleBiometrics;
  final GetSecuritySettingsUseCase _getSecuritySettings;

  int _failedAttempts = 0;
  static const _maxAttempts = 5;

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    final settingsEither = await _getSecuritySettings(NoParams());
    settingsEither.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (settings) {
        if (settings.isBiometricsEnabled || settings.hasMasterPasscode) {
          emit(
            AuthPromptRequired(
              biometricsEnabled: settings.isBiometricsEnabled,
              hasMasterPin: settings.hasMasterPasscode,
            ),
          );
        } else {
          emit(AuthSuccess(settings: settings));
        }
      },
    );
  }

  Future<void> _onAuthenticateUser(
    AuthenticateUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (_failedAttempts >= _maxAttempts) {
      emit(
        const AuthLockedOut(
          'Maximum attempts exceeded. NetGuard is temporarily locked out.',
        ),
      );
      return;
    }

    final result = await _authenticateUser(
      AuthenticateUserParams(
        passcode: event.passcode,
        useBiometrics: event.useBiometrics,
      ),
    );

    await result.fold(
      (failure) async {
        _failedAttempts++;
        if (_failedAttempts >= _maxAttempts) {
          emit(
            const AuthLockedOut(
              'Maximum attempts exceeded. NetGuard is temporarily locked out.',
            ),
          );
        } else {
          emit(
            AuthFailure(
              message: failure.message,
              attemptsRemaining: _maxAttempts - _failedAttempts,
            ),
          );
        }
      },
      (success) async {
        if (success) {
          _failedAttempts = 0;
          final settingsEither = await _getSecuritySettings(NoParams());
          settingsEither.fold(
            (failure) => emit(AuthFailure(message: failure.message)),
            (settings) => emit(AuthSuccess(settings: settings)),
          );
        } else {
          _failedAttempts++;
          if (_failedAttempts >= _maxAttempts) {
            emit(
              const AuthLockedOut(
                'Maximum attempts exceeded. NetGuard is temporarily locked out.',
              ),
            );
          } else {
            emit(
              AuthFailure(
                message: 'Invalid credentials. Please try again.',
                attemptsRemaining: _maxAttempts - _failedAttempts,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _onSetMasterPasscode(
    SetMasterPasscodeEvent event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _setMasterPasscode(
      SetMasterPasscodeParams(passcode: event.passcode),
    );

    await result.fold(
      (failure) async => emit(AuthFailure(message: failure.message)),
      (_) async {
        final settingsEither = await _getSecuritySettings(NoParams());
        settingsEither.fold(
          (failure) => emit(AuthFailure(message: failure.message)),
          (settings) => emit(AuthSuccess(settings: settings)),
        );
      },
    );
  }

  Future<void> _onToggleBiometrics(
    ToggleBiometricsEvent event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _toggleBiometrics(
      ToggleBiometricsParams(isEnabled: event.isEnabled),
    );

    await result.fold(
      (failure) async => emit(AuthFailure(message: failure.message)),
      (_) async {
        final settingsEither = await _getSecuritySettings(NoParams());
        settingsEither.fold(
          (failure) => emit(AuthFailure(message: failure.message)),
          (settings) => emit(AuthSuccess(settings: settings)),
        );
      },
    );
  }

  Future<void> _onLockApp(
    LockAppEvent event,
    Emitter<AuthState> emit,
  ) async {
    final settingsEither = await _getSecuritySettings(NoParams());
    settingsEither.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (settings) {
        if (settings.isBiometricsEnabled || settings.hasMasterPasscode) {
          emit(
            AuthPromptRequired(
              biometricsEnabled: settings.isBiometricsEnabled,
              hasMasterPin: settings.hasMasterPasscode,
            ),
          );
        } else {
          emit(AuthSuccess(settings: settings));
        }
      },
    );
  }
}
