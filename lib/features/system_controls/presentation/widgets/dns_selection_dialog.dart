import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dns_resolver_entity.dart';
import '../bloc/system_controls_bloc.dart';
import '../bloc/system_controls_event.dart';
import '../bloc/system_controls_state.dart';

class DnsSelectionDialog extends StatefulWidget {
  const DnsSelectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (dialogCtx) => BlocProvider.value(
        value: context.read<SystemControlsBloc>(),
        child: const DnsSelectionDialog(),
      ),
    );
  }

  @override
  State<DnsSelectionDialog> createState() => _DnsSelectionDialogState();
}

class _DnsSelectionDialogState extends State<DnsSelectionDialog> {
  String? _selectedId;
  final _customIpController = TextEditingController();
  bool _isCustomSelected = false;
  String? _validationError;

  @override
  void dispose() {
    _customIpController.dispose();
    super.dispose();
  }

  void _onSave(BuildContext context) {
    if (_isCustomSelected) {
      final ip = _customIpController.text.trim();
      final ipv4Regex = RegExp(
        r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$',
      );
      if (!ipv4Regex.hasMatch(ip)) {
        setState(() => _validationError = 'Enter a valid IPv4 address');
        return;
      }
      context.read<SystemControlsBloc>().add(SetCustomDnsIpEvent(ip));
    } else if (_selectedId != null) {
      final resolver = DnsResolverEntity.predefined.firstWhere(
        (r) => r.id == _selectedId,
        orElse: () => DnsResolverEntity.cloudflare,
      );
      context.read<SystemControlsBloc>().add(SelectDnsResolverEvent(resolver));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemControlsBloc, SystemControlsState>(
      builder: (context, state) {
        if (state is SystemControlsLoaded && _selectedId == null) {
          _selectedId = state.currentResolver.id;
          _isCustomSelected = state.currentResolver.isCustom;
          if (_isCustomSelected) {
            _customIpController.text = state.currentResolver.primaryIp;
          }
        }

        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: const Text(
            'SELECT DNS RESOLVER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...DnsResolverEntity.predefined.map((resolver) {
                  final isChosen =
                      !_isCustomSelected && _selectedId == resolver.id;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedId = resolver.id;
                        _isCustomSelected = false;
                        _validationError = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isChosen
                            ? const Color(0xFF1E2D45)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isChosen
                              ? AppColors.accentBlue
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isChosen
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isChosen
                                ? AppColors.accentBlue
                                : AppColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  resolver.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${resolver.primaryIp} • ${resolver.secondaryIp}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                // CUSTOM OPTION
                InkWell(
                  onTap: () {
                    setState(() {
                      _isCustomSelected = true;
                      _selectedId = 'custom';
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _isCustomSelected
                          ? const Color(0xFF1E2D45)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _isCustomSelected
                            ? AppColors.accentBlue
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCustomSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: _isCustomSelected
                              ? AppColors.accentBlue
                              : AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Custom IPv4 Resolver',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isCustomSelected) ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: _customIpController,
                    keyboardType: TextInputType.datetime,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. 9.9.9.9 (Quad9)',
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            const BorderSide(color: AppColors.accentBlue),
                      ),
                    ),
                  ),
                ],
                if (_validationError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _validationError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => _onSave(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'APPLY',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }
}
