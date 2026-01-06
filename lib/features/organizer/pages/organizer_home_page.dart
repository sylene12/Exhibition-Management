  // lib/features/organizer/pages/organizer_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../auth/providers/auth_provider.dart';

class OrganizerHomePage extends ConsumerWidget {
  const OrganizerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizer Dashboard'),
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.name ?? "Organizer"}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your exhibitions and booth applications',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.event,
                    title: 'Exhibitions',
                    color: AppTheme.primaryColor,
                    onTap: () => context.push('/organizer/exhibitions'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.assignment,
                    title: 'Applications',
                    color: AppTheme.accentColor,
                    onTap: () => context.push('/organizer/applications'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Statistics
            const Text(
              'Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (user != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('exhibitions')
                    .where('organizerId', isEqualTo: user.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final exhibitions = snapshot.data!.docs;
                  final published = exhibitions.where((e) => 
                    (e.data() as Map)['isPublished'] == true).length;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              count: exhibitions.length,
                              label: 'Total Events',
                              color: AppTheme.primaryColor,
                              icon: Icons.event,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              count: published,
                              label: 'Published',
                              color: AppTheme.successColor,
                              icon: Icons.public,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('bookings')
                            .snapshots(),
                        builder: (context, bookingSnapshot) {
                          if (!bookingSnapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          final allBookings = bookingSnapshot.data!.docs;
                          final pending = allBookings.where((b) => 
                            (b.data() as Map)['status'] == 'pending').length;

                          return Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  count: pending,
                                  label: 'Pending Apps',
                                  color: AppTheme.warningColor,
                                  icon: Icons.hourglass_empty,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  count: allBookings.length,
                                  label: 'Total Apps',
                                  color: AppTheme.accentColor,
                                  icon: Icons.assignment,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
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
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 28,
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
    );
  }
}