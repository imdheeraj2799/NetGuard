abstract class AuthEvent {
  const AuthEvent();
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class AuthenticateUserEvent extends AuthEvent {
  const AuthenticateUserEvent({
    this.passcode,
    this.useBiometrics = true,
  });

  final String? passcode;
  final bool useBiometrics;
}

class SetMasterPasscodeEvent extends AuthEvent {
  const SetMasterPasscodeEvent(this.passcode);

  final String passcode;
}

class ToggleBiometricsEvent extends AuthEvent {
  const ToggleBiometricsEvent(this.isEnabled);

  final bool isEnabled;
}

class LockAppEvent extends AuthEvent {
  const LockAppEvent();
}
