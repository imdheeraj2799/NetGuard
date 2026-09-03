import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../security/presentation/bloc/auth_bloc.dart';
import '../../../security/presentation/bloc/auth_event.dart';
import '../../../security/presentation/bloc/auth_state.dart';
import '../../../security/presentation/widgets/security_lock_dialog.dart';
import '../../../system_controls/presentation/bloc/system_controls_bloc.dart';
import '../../../system_controls/presentation/bloc/system_controls_state.dart';
import '../../../system_controls/presentation/widgets/dns_selection_dialog.dart';
import '../widgets/netgate_header.dart';
import '../widgets/protocol_footer.dart';
import '../widgets/settings_group_card.dart';
import '../widgets/settings_tile.dart';

class ShieldSettingsPage extends StatefulWidget {
  const ShieldSettingsPage({super.key});

  @override
  State<ShieldSettingsPage> createState() => _ShieldSettingsPageState();
}

class _ShieldSettingsPageState extends State<ShieldSettingsPage> {
  bool _vpnBypass = false;
  bool _adminOverride = false;
  bool _hasCheckedLock = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedLock) {
      _hasCheckedLock = true;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthPromptRequired) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final success = await SecurityLockDialog.show(
            context,
            isSetupMode: false,
          );
          if (success != true && mounted) {
            Navigator.of(context).maybePop();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            NetgateHeader(
              category: 'NETGATE // SECURITY',
              title: 'Shield Settings',
              activeDashIndex: 3,
              trailingAction: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  // ACCESS CONTROL
                  const Text('ACCESS CONTROL', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 10),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                      final isBioEnabled = authState is AuthSuccess
                          ? authState.settings.isBiometricsEnabled
                          : false;
                      final hasPin = authState is AuthSuccess
                          ? authState.settings.hasMasterPasscode
                          : false;

                      return SettingsGroupCard(
                        children: [
                          SettingsTile(
                            icon: Icons.lock_outline,
                            title: 'Master Password',
                            subtitle: hasPin
                                ? 'Passcode configured'
                                : 'Protect your restrictions',
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onTap: () {
                              SecurityLockDialog.show(context, isSetupMode: true);
                            },
                          ),
                          SettingsTile(
                            icon: Icons.fingerprint,
                            title: 'Biometric Lock',
                            subtitle: 'Use FaceID or TouchID',
                            trailing: _buildSwitch(
                              value: isBioEnabled,
                              onChanged: (v) {
                                context.read<AuthBloc>().add(
                                  ToggleBiometricsEvent(v),
                                );
                              },
                            ),
                          ),
                          SettingsTile(
                            icon: Icons.timer_outlined,
                            title: 'Auto-Lock',
                            subtitle: 'Lock after 5 minutes',
                            trailing: const Text(
                              '5m',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Auto-lock duration: 5m'),
                                  backgroundColor: AppColors.cardBackground,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // NETWORK & PRIVACY
                  const Text('NETWORK & PRIVACY', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 10),
                  BlocBuilder<SystemControlsBloc, SystemControlsState>(
                    builder: (context, dnsState) {
                      String dnsSubtitle = '1.1.1.1 (Cloudflare)';
                      if (dnsState is SystemControlsLoaded) {
                        final r = dnsState.currentResolver;
                        dnsSubtitle = r.isCustom
                            ? '${r.primaryIp} (Custom)'
                            : '${r.primaryIp} (${r.name})';
                      }

                      return SettingsGroupCard(
                        children: [
                          SettingsTile(
                            icon: Icons.vpn_lock_outlined,
                            title: 'VPN Bypass',
                            subtitle: 'Restrict traffic even through VPN',
                            trailing: _buildSwitch(
                              value: _vpnBypass,
                              onChanged: (v) => setState(() => _vpnBypass = v),
                            ),
                          ),
                          SettingsTile(
                            icon: Icons.dns_outlined,
                            title: 'Custom DNS',
                            subtitle: dnsSubtitle,
                            trailing: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                            onTap: () => DnsSelectionDialog.show(context),
                          ),
                          SettingsTile(
                            icon: Icons.security_outlined,
                            title: 'Admin Override',
                            subtitle: 'Allow emergency access',
                            trailing: _buildSwitch(
                              value: _adminOverride,
                              onChanged: (v) => setState(() => _adminOverride = v),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // SYSTEM
                  const Text('SYSTEM', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 10),
                  SettingsGroupCard(
                    children: [
                      SettingsTile(
                        icon: Icons.history,
                        title: 'Clear Restriction Logs',
                        subtitle: 'Delete all history',
                        trailing: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Restriction logs cleared'),
                                backgroundColor: AppColors.cardBackground,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SettingsTile(
                        icon: Icons.info_outline,
                        title: 'Sashiko Protocol',
                        subtitle: 'v2.4.0-stable',
                        trailing: Icon(
                          Icons.verified_user_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const ProtocolFooter(
              text: 'ENCRYPTED END-TO-END',
              icon: Icons.shield_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Transform.scale(
      scale: 0.85,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: const Color(0xFF6B7E98),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFF2C394F),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
