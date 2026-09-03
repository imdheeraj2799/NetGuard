import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/domain_filter_bloc.dart';
import '../bloc/domain_filter_event.dart';

class AddDomainDialog extends StatefulWidget {
  const AddDomainDialog({super.key});

  static Future<void> show(BuildContext context) {
    final bloc = context.read<DomainFilterBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const AddDomainDialog(),
      ),
    );
  }

  @override
  State<AddDomainDialog> createState() => _AddDomainDialogState();
}

class _AddDomainDialogState extends State<AddDomainDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final domain = _controller.text.trim();
      context.read<DomainFilterBloc>().add(AddDomainEvent(domain));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rule created for $domain'),
          backgroundColor: AppColors.background,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'WEAVE DOMAIN RULE',
                  style: AppTextStyles.sectionHeader,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter a domain or wildcard to intercept and drop via local DNS resolver (e.g. youtube.com, *.tiktok.com).',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'e.g. youtube.com or *.reddit.com',
                prefixIcon: Icon(Icons.language, size: 20),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a valid domain';
                }
                final cleaned = value.trim().toLowerCase();
                if (!cleaned.contains('.') || cleaned.length < 3) {
                  return 'Domain must include a valid extension (e.g. .com)';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text(
                  'ADD RESTRICTION',
                  style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
