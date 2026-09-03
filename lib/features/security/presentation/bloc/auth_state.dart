import '../../domain/entities/security_settings_entity.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthPromptRequired extends AuthState {
  const AuthPromptRequired({
    required this.biometricsEnabled,
    required this.hasMasterPin,
  });

  final bool biometricsEnabled;
  final bool hasMasterPin;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthPromptRequired &&
          runtimeType == other.runtimeType &&
          biometricsEnabled == other.biometricsEnabled &&
          hasMasterPin == other.hasMasterPin;

  @override
  int get hashCode => biometricsEnabled.hashCode ^ hasMasterPin.hashCode;
}

class AuthSuccess extends AuthState {
  const AuthSuccess({required this.settings});

  final SecuritySettingsEntity settings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSuccess &&
          runtimeType == other.runtimeType &&
          settings == other.settings;

  @override
  int get hashCode => settings.hashCode;
}

class AuthFailure extends AuthState {
  const AuthFailure({
    required this.message,
    this.attemptsRemaining = 5,
  });

  final String message;
  final int attemptsRemaining;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthFailure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          attemptsRemaining == other.attemptsRemaining;

  @override
  int get hashCode => message.hashCode ^ attemptsRemaining.hashCode;
}

class AuthLockedOut extends AuthState {
  const AuthLockedOut(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthLockedOut &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
