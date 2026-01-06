// features/admin/pages/admin_home_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class AdminHomePage extends ConsumerWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
              context.go('/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.secondaryColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Administrator',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome, ${user?.name ?? "Admin"}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _ManagementCard(
                  icon: Icons.event,
                  title: 'Exhibitions',
                  color: AppTheme.primaryColor,
                  onTap: () => context.push('/admin/exhibitions'),
                ),
                _ManagementCard(
                  icon: Icons.people,
                  title: 'Users',
                  color: AppTheme.accentColor,
                  onTap: () => context.push('/admin/users'),
                ),
                _ManagementCard(
                  icon: Icons.map,
                  title: 'Floor Plans',
                  color: AppTheme.successColor,
                  onTap: () => context.push('/admin/floor-plans'),
                ),
                _ManagementCard(
                  icon: Icons.assessment,
                  title: 'Applications',
                  color: AppTheme.warningColor,
                  onTap: () => context.push('/admin/applications')
                    // Future implementation
                ),
              ],
            ),
            const SizedBox(height: 24),

            // System Statistics
            const Text(
              'System Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Statistics Cards
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, userSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('exhibitions')
                      .snapshots(),
                  builder: (context, exhibitionSnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('booths')
                          .snapshots(),
                      builder: (context, boothSnapshot) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('bookings')
                              .snapshots(),
                          builder: (context, bookingSnapshot) {
                            final users = userSnapshot.data?.docs ?? [];
                            final exhibitions = exhibitionSnapshot.data?.docs ?? [];
                            final booths = boothSnapshot.data?.docs ?? [];
                            final bookings = bookingSnapshot.data?.docs ?? [];

                            final exhibitors = users.where((u) =>
                              (u.data() as Map)['role'] == 'exhibitor').length;
                            final organizers = users.where((u) =>
                              (u.data() as Map)['role'] == 'organizer').length;
                            // counts (published/pending removed — compute when needed)

                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StatCard(
                                        count: users.length,
                                        label: 'Total Users',
                                        color: AppTheme.primaryColor,
                                        icon: Icons.people,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _StatCard(
                                        count: exhibitions.length,
                                        label: 'Exhibitions',
                                        color: AppTheme.accentColor,
                                        icon: Icons.event,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StatCard(
                                        count: exhibitors,
                                        label: 'Exhibitors',
                                        color: AppTheme.successColor,
                                        icon: Icons.business,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _StatCard(
                                        count: organizers,
                                        label: 'Organizers',
                                        color: AppTheme.warningColor,
                                        icon: Icons.admin_panel_settings,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StatCard(
                                        count: booths.length,
                                        label: 'Total Booths',
                                        color: Colors.blue,
                                        icon: Icons.event_seat,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _StatCard(
                                        count: bookings.length,
                                        label: 'Bookings',
                                        color: Colors.purple,
                                        icon: Icons.assignment,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withAlpha((0.1 * 255).round()),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}