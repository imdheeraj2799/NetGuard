import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class SecurityLockDialog extends StatefulWidget {
  const SecurityLockDialog({
    super.key,
    required this.isSetupMode,
    this.onAuthenticated,
  });

  final bool isSetupMode;
  final VoidCallback? onAuthenticated;

  static Future<bool?> show(BuildContext context, {required bool isSetupMode}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: SecurityLockDialog(
          isSetupMode: isSetupMode,
          onAuthenticated: () => Navigator.of(ctx).pop(true),
        ),
      ),
    );
  }

  @override
  State<SecurityLockDialog> createState() => _SecurityLockDialogState();
}

class _SecurityLockDialogState extends State<SecurityLockDialog> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() => _localError = 'PIN must be at least 4 digits');
      return;
    }

    if (widget.isSetupMode) {
      final confirmPin = _confirmPinController.text.trim();
      if (pin != confirmPin) {
        setState(() => _localError = 'Passcodes do not match');
        return;
      }
      context.read<AuthBloc>().add(SetMasterPasscodeEvent(pin));
      widget.onAuthenticated?.call();
    } else {
      context.read<AuthBloc>().add(
        AuthenticateUserEvent(passcode: pin, useBiometrics: false),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess && !widget.isSetupMode) {
          widget.onAuthenticated?.call();
        }
        if (state is AuthFailure) {
          setState(() => _localError = state.message);
        }
      },
      builder: (context, state) {
        final isLockedOut = state is AuthLockedOut;

        return Dialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.isSetupMode ? Icons.key_outlined : Icons.lock_outline,
                      color: AppColors.accentBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.isSetupMode
                            ? 'SETUP MASTER PASSCODE'
                            : 'SECURITY VERIFICATION',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  widget.isSetupMode
                      ? 'Configure a master passcode to protect restrictions and network rules.'
                      : 'Enter your master passcode or verify biometrics to access settings.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  enabled: !isLockedOut,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      letterSpacing: 8,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.accentBlue),
                    ),
                  ),
                ),
                if (widget.isSetupMode) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Confirm ••••',
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.accentBlue),
                      ),
                    ),
                  ),
                ],
                if (_localError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _localError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                  ),
                ],
                if (state is AuthLockedOut) ...[
                  const SizedBox(height: 10),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.cardBorder),
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLockedOut ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          widget.isSetupMode ? 'SAVE' : 'UNLOCK',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!widget.isSetupMode && !isLockedOut) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(
                        const AuthenticateUserEvent(useBiometrics: true),
                      );
                    },
                    icon: const Icon(Icons.fingerprint, size: 20),
                    label: const Text(
                      'VERIFY WITH BIOMETRICS',
                      style: TextStyle(fontSize: 11, letterSpacing: 0.8),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
