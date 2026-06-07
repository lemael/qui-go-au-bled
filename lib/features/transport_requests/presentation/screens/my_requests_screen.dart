import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../transport_request_provider.dart';

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserNotifierProvider).value;
    final isTransporter = user?.isTransporter ?? false;

    return DefaultTabController(
      length: isTransporter ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes demandes'),
          bottom: isTransporter
              ? const TabBar(
                  tabs: [
                    Tab(text: 'Reçues'),
                    Tab(text: 'Envoyées'),
                  ],
                )
              : null,
        ),
        body: isTransporter
            ? const TabBarView(
                children: [
                  _IncomingRequestsList(),
                  _SentRequestsList(),
                ],
              )
            : const _SentRequestsList(),
      ),
    );
  }
}

class _IncomingRequestsList extends ConsumerWidget {
  const _IncomingRequestsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(incomingRequestsProvider);

    return requestsAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => ErrorDisplayWidget(message: e.toString()),
      data: (requests) {
        if (requests.isEmpty) {
          return const EmptyStateWidget(
            title: 'Aucune demande reçue',
            subtitle: 'Vos demandes de transport apparaîtront ici.',
            icon: Icons.inbox_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final req = requests[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            req.clientName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                req.clientName,
                                style:
                                    Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                DateFormatter.relativeTime(req.createdAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.grey500),
                              ),
                            ],
                          ),
                        ),
                        _RequestStatusBadge(status: req.status.name),
                      ],
                    ),
                    if (req.message != null && req.message!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        req.message!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.grey600),
                      ),
                    ],
                    if (req.isPending) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                              ),
                              onPressed: () async {
                                await ref
                                    .read(requestNotifierProvider.notifier)
                                    .rejectRequest(req.id);
                              },
                              child: const Text('Refuser'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await ref
                                    .read(requestNotifierProvider.notifier)
                                    .acceptRequest(req.id);
                              },
                              child: const Text('Accepter'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SentRequestsList extends ConsumerWidget {
  const _SentRequestsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myClientRequestsProvider);

    return requestsAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => ErrorDisplayWidget(message: e.toString()),
      data: (requests) {
        if (requests.isEmpty) {
          return const EmptyStateWidget(
            title: 'Aucune demande envoyée',
            subtitle:
                'Trouvez un transporteur et envoyez votre première demande.',
            icon: Icons.send_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final req = requests[index];
            return Card(
              child: ListTile(
                title: Text('À: ${req.transporterName}'),
                subtitle: Text(DateFormatter.relativeTime(req.createdAt)),
                trailing: _RequestStatusBadge(status: req.status.name),
                onTap: () =>
                    context.push('/my-requests/${req.id}'),
              ),
            );
          },
        );
      },
    );
  }
}

class _RequestStatusBadge extends StatelessWidget {
  final String status;
  const _RequestStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status.toLowerCase()) {
      case 'accepted':
        color = AppColors.success;
        label = 'Accepté';
        break;
      case 'rejected':
        color = AppColors.error;
        label = 'Refusé';
        break;
      default:
        color = AppColors.warning;
        label = 'En attente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
