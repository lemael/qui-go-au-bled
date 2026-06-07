import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../transport_order_provider.dart';

class CancelOrderScreen extends ConsumerStatefulWidget {
  final String orderId;
  const CancelOrderScreen({super.key, required this.orderId});

  @override
  ConsumerState<CancelOrderScreen> createState() => _CancelOrderScreenState();
}

class _CancelOrderScreenState extends ConsumerState<CancelOrderScreen> {
  String? _selectedReason;
  final _otherController = TextEditingController();

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un motif d\'annulation'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final reason = _selectedReason == 'Autre'
        ? _otherController.text.trim().isEmpty
            ? 'Autre'
            : _otherController.text.trim()
        : _selectedReason!;

    final user = ref.read(currentUserNotifierProvider).value;
    if (user == null) return;

    final success = await ref.read(orderNotifierProvider.notifier).cancelOrder(
          orderId: widget.orderId,
          authorId: user.id,
          authorName: user.fullName,
          reason: reason,
        );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transport annulé'),
          backgroundColor: AppColors.warning,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(orderNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Annuler le transport')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              'Motif d\'annulation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Veuillez indiquer la raison de l\'annulation. Cette information sera visible par les deux parties.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.grey500),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  ...AppStrings.cancellationReasons.map((reason) {
                    return RadioListTile<String>(
                      title: Text(reason),
                      value: reason,
                      groupValue: _selectedReason,
                      onChanged: (v) => setState(() => _selectedReason = v),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: _selectedReason == 'Autre'
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: TextFormField(
                              controller: _otherController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Précisez le motif',
                                hintText: 'Décrivez la raison...',
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppButtonFull(
              label: 'Confirmer l\'annulation',
              onPressed: _cancel,
              isLoading: isLoading,
              backgroundColor: AppColors.error,
              icon: Icons.cancel_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
