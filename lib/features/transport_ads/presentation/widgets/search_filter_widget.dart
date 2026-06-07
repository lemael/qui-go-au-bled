import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

class SearchFilterWidget extends StatelessWidget {
  final TextEditingController departureController;
  final TextEditingController arrivalController;
  final DateTime? selectedDate;
  final void Function(DateTime) onDateSelected;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const SearchFilterWidget({
    super.key,
    required this.departureController,
    required this.arrivalController,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: departureController,
                  decoration: const InputDecoration(
                    labelText: 'Départ',
                    hintText: 'Paris',
                    prefixIcon: Icon(Icons.flight_takeoff_rounded),
                    isDense: true,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.grey400,
                  size: 20,
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: arrivalController,
                  decoration: const InputDecoration(
                    labelText: 'Arrivée',
                    hintText: 'Alger',
                    prefixIcon: Icon(Icons.flight_land_rounded),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) onDateSelected(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedDate != null
                      ? AppColors.primary
                      : AppColors.grey200,
                  width: selectedDate != null ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: selectedDate != null
                        ? AppColors.primary
                        : AppColors.grey400,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedDate == null
                        ? 'Date du vol (optionnel)'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    style: TextStyle(
                      color: selectedDate != null
                          ? AppColors.grey900
                          : AppColors.grey400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Rechercher',
                  onPressed: onSearch,
                  icon: Icons.search_rounded,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.clear_rounded),
                tooltip: 'Effacer',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
