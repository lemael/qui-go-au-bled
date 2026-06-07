import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/transport_ad_entity.dart';
import '../providers/transport_ad_provider.dart';

class CreateAdScreen extends ConsumerStatefulWidget {
  const CreateAdScreen({super.key});

  @override
  ConsumerState<CreateAdScreen> createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends ConsumerState<CreateAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _departureController = TextEditingController();
  final _arrivalController = TextEditingController();
  final _maxWeightController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _flightDate;
  TimeOfDay? _flightTime;

  @override
  void dispose() {
    _departureController.dispose();
    _arrivalController.dispose();
    _maxWeightController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _flightDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _flightTime = picked);
  }

  Future<void> _createAd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_flightDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date de vol'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_flightTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une heure de vol'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final user = ref.read(currentUserNotifierProvider).value;
    if (user == null) return;

    final now = DateTime.now();
    final ad = TransportAdEntity(
      id: '',
      transporterId: user.id,
      transporterName: user.fullName,
      transporterPhotoUrl: user.photoUrl,
      transporterRating: user.averageRating,
      transporterReviews: user.totalReviews,
      departureCity: _departureController.text.trim(),
      arrivalCity: _arrivalController.text.trim(),
      flightDate: _flightDate!,
      flightTime:
          '${_flightTime!.hour.toString().padLeft(2, '0')}:${_flightTime!.minute.toString().padLeft(2, '0')}',
      maxWeightKg: double.parse(_maxWeightController.text),
      pricePerKg: double.parse(_priceController.text),
      description: _descriptionController.text.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final success =
        await ref.read(manageAdNotifierProvider.notifier).createAd(ad);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Annonce publiée avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      final error = ref.read(manageAdNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Erreur lors de la publication'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(manageAdNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Créer une annonce')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(title: 'Itinéraire'),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Ville de départ',
                hint: 'Paris',
                controller: _departureController,
                validator: (v) => Validators.required(v, 'La ville de départ'),
                prefixIcon: const Icon(Icons.flight_takeoff_rounded),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Ville d\'arrivée',
                hint: 'Alger',
                controller: _arrivalController,
                validator: (v) =>
                    Validators.required(v, 'La ville d\'arrivée'),
                prefixIcon: const Icon(Icons.flight_land_rounded),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Date & heure du vol'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateTimeSelector(
                      icon: Icons.calendar_today_outlined,
                      label: _flightDate == null
                          ? 'Date du vol'
                          : '${_flightDate!.day}/${_flightDate!.month}/${_flightDate!.year}',
                      onTap: _pickDate,
                      hasValue: _flightDate != null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateTimeSelector(
                      icon: Icons.access_time_rounded,
                      label: _flightTime == null
                          ? 'Heure'
                          : _flightTime!.format(context),
                      onTap: _pickTime,
                      hasValue: _flightTime != null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Tarification'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Poids max (kg)',
                      hint: '20',
                      controller: _maxWeightController,
                      keyboardType: TextInputType.number,
                      validator: Validators.weight,
                      prefixIcon: const Icon(Icons.scale_outlined),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Prix par kg (€)',
                      hint: '5',
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      validator: Validators.price,
                      prefixIcon: const Icon(Icons.euro_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Description'),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Description (optionnel)',
                hint: 'Types de colis acceptés, conditions...',
                controller: _descriptionController,
                maxLines: 4,
                maxLength: 500,
              ),
              const SizedBox(height: 32),
              AppButtonFull(
                label: 'Publier l\'annonce',
                onPressed: _createAd,
                isLoading: isLoading,
                icon: Icons.publish_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(color: AppColors.grey600, fontWeight: FontWeight.w600),
    );
  }
}

class _DateTimeSelector extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool hasValue;

  const _DateTimeSelector({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.hasValue,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? AppColors.primary : AppColors.grey200,
            width: hasValue ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: hasValue ? AppColors.primary : AppColors.grey400,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: hasValue ? AppColors.grey900 : AppColors.grey400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
