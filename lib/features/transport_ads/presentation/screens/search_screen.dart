import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/transport_ad_provider.dart';
import '../widgets/ad_card_widget.dart';
import '../widgets/search_filter_widget.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _departureController = TextEditingController();
  final _arrivalController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _departureController.dispose();
    _arrivalController.dispose();
    super.dispose();
  }

  void _search() {
    ref.read(adSearchNotifierProvider.notifier).search(
          departureCity: _departureController.text.trim(),
          arrivalCity: _arrivalController.text.trim(),
          flightDate: _selectedDate,
        );
  }

  void _clear() {
    _departureController.clear();
    _arrivalController.clear();
    setState(() => _selectedDate = null);
    ref.read(adSearchNotifierProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(adSearchNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher un transporteur')),
      body: Column(
        children: [
          SearchFilterWidget(
            departureController: _departureController,
            arrivalController: _arrivalController,
            selectedDate: _selectedDate,
            onDateSelected: (date) => setState(() => _selectedDate = date),
            onSearch: _search,
            onClear: _clear,
          ),
          const Divider(height: 1),
          Expanded(
            child: searchState.when(
              loading: () => const LoadingWidget(message: 'Recherche...'),
              error: (e, _) => ErrorDisplayWidget(message: e.toString()),
              data: (ads) {
                if (ads.isEmpty &&
                    (_departureController.text.isEmpty &&
                        _arrivalController.text.isEmpty &&
                        _selectedDate == null)) {
                  return const EmptyStateWidget(
                    title: 'Lancez une recherche',
                    subtitle:
                        'Entrez votre destination pour trouver un transporteur.',
                    icon: Icons.search_rounded,
                  );
                }
                if (ads.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'Aucun résultat',
                    subtitle:
                        'Essayez avec d\'autres critères de recherche.',
                    icon: Icons.search_off_rounded,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: ads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => AdCardWidget(
                    ad: ads[index],
                    onTap: () => context.push('/ads/${ads[index].id}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
