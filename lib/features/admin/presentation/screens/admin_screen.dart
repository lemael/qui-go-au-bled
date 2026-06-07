import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../transport_ads/domain/entities/transport_ad_entity.dart';
import '../admin_provider.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(adminProvider.notifier);
      notifier.loadStats();
      notifier.loadPendingAds();
      notifier.loadUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Annonces',
              icon: Badge(
                isLabelVisible: (state.stats['pendingAds'] ?? 0) > 0,
                label: Text('${state.stats['pendingAds'] ?? 0}'),
                child: const Icon(Icons.approval_outlined),
              ),
            ),
            const Tab(
              text: 'Utilisateurs',
              icon: Icon(Icons.people_outlined),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _StatsBar(stats: state.stats),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PendingAdsTab(
                  ads: state.pendingAds,
                  isLoading: state.isLoading,
                  onApprove: (id) => _approve(id),
                  onReject: (id) => _reject(id),
                ),
                _UsersTab(
                  users: state.users,
                  isLoading: state.isLoading,
                  onDelete: (id) => _deleteUser(id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(String adId) async {
    final ok = await ref.read(adminProvider.notifier).approveAd(adId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Annonce approuvée et publiée ✓' : 'Erreur lors de l\'approbation'),
      backgroundColor: ok ? Colors.green : Colors.red,
    ));
  }

  Future<void> _reject(String adId) async {
    final reason = await _showRejectDialog();
    if (reason == null) return;
    final ok = await ref.read(adminProvider.notifier).rejectAd(adId, reason: reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Annonce rejetée' : 'Erreur'),
      backgroundColor: ok ? Colors.orange : Colors.red,
    ));
  }

  Future<String?> _showRejectDialog() async {
    String reason = '';
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter l\'annonce'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Motif du rejet (optionnel)',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => reason = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, reason),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet utilisateur ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref.read(adminProvider.notifier).deleteUser(userId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Utilisateur supprimé' : 'Erreur'),
      backgroundColor: ok ? Colors.green : Colors.red,
    ));
  }
}

// ─── Stats Bar ────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withOpacity(0.05),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(label: 'Utilisateurs', value: stats['totalUsers'] ?? 0, icon: Icons.people),
          _StatChip(label: 'Annonces actives', value: stats['activeAds'] ?? 0, icon: Icons.check_circle),
          _StatChip(
            label: 'En attente',
            value: stats['pendingAds'] ?? 0,
            icon: Icons.pending,
            color: Colors.orange,
          ),
          _StatChip(label: 'Commandes', value: stats['totalOrders'] ?? 0, icon: Icons.shopping_bag),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color? color;
  const _StatChip({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: c, size: 20),
        Text('$value', style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

// ─── Pending Ads Tab ──────────────────────────────────────────────────────────

class _PendingAdsTab extends StatelessWidget {
  final List<TransportAdEntity> ads;
  final bool isLoading;
  final void Function(String) onApprove;
  final void Function(String) onReject;

  const _PendingAdsTab({
    required this.ads,
    required this.isLoading,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (ads.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 12),
            Text('Aucune annonce en attente', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: ads.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) => _AdCard(ad: ads[i], onApprove: onApprove, onReject: onReject),
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  final TransportAdEntity ad;
  final void Function(String) onApprove;
  final void Function(String) onReject;

  const _AdCard({required this.ad, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flight_takeoff, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${ad.departureCity} → ${ad.arrivalCity}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(ad.transporterName, style: const TextStyle(fontSize: 13)),
                const Spacer(),
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(df.format(ad.flightDate), style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('${ad.maxWeightKg} kg', style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 12),
                Text('${ad.pricePerKg} €/kg', style: const TextStyle(fontSize: 13)),
              ],
            ),
            if (ad.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                ad.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onReject(ad.id),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Rejeter'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => onApprove(ad.id),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approuver'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Users Tab ────────────────────────────────────────────────────────────────

class _UsersTab extends StatelessWidget {
  final List<UserEntity> users;
  final bool isLoading;
  final void Function(String) onDelete;

  const _UsersTab({required this.users, required this.isLoading, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (users.isEmpty) {
      return const Center(child: Text('Aucun utilisateur'));
    }
    final nonAdmins = users.where((u) => !u.isAdmin).toList();
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: nonAdmins.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) => _UserTile(user: nonAdmins[i], onDelete: onDelete),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserEntity user;
  final void Function(String) onDelete;

  const _UserTile({required this.user, required this.onDelete});

  String _roleLabel(UserRole r) {
    switch (r) {
      case UserRole.transporter:
        return 'Transporteur';
      case UserRole.client:
        return 'Client';
      case UserRole.both:
        return 'Client & Transporteur';
      case UserRole.admin:
        return 'Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: CircleAvatar(
        backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
        child: user.photoUrl == null ? Text(user.fullName[0].toUpperCase()) : null,
      ),
      title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.email, style: const TextStyle(fontSize: 12)),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_roleLabel(user.role), style: TextStyle(fontSize: 11, color: AppColors.primary)),
              ),
              const SizedBox(width: 6),
              if (user.totalReviews > 0)
                Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    Text(' ${user.averageRating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11)),
                  ],
                ),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () => onDelete(user.id),
        tooltip: 'Supprimer',
      ),
    );
  }
}
