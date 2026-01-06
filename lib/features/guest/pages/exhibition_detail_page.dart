// features/guest/pages/exhibition_detail_page.dart

/// Exhibition Detail Page
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
/// Shows detailed information about an exhibition including floor plan
class ExhibitionDetailPage extends ConsumerWidget {
  final String exhibitionId;

  const ExhibitionDetailPage({
    super.key,
    required this.exhibitionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exhibition Details'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('exhibitions')
            .doc(exhibitionId)
            .snapshots(),
        builder: (context, exhibitionSnapshot) {
          if (exhibitionSnapshot.hasError) {
            return Center(child: Text('Error: ${exhibitionSnapshot.error}'));
          }

          if (!exhibitionSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final exhibition = ExhibitionModel.fromFirestore(
            exhibitionSnapshot.data!,
          );

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exhibition Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exhibition.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        exhibition.location,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Range
                      _buildInfoCard(
                        icon: Icons.calendar_month,
                        title: 'Event Duration',
                        content:
                            '${DateFormat('MMM dd, yyyy').format(exhibition.startDate)} - ${DateFormat('MMM dd, yyyy').format(exhibition.endDate)}',
                      ),

                      // Description
                      _buildInfoCard(
                        icon: Icons.description,
                        title: 'About',
                        content: exhibition.description,
                      ),

                      // Floor Plan Section
                      const SizedBox(height: 24),
                      const Text(
                        'Floor Plan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Booths List
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('booths')
                            .where('exhibitionId', isEqualTo: exhibitionId)
                            .snapshots(),
                        builder: (context, boothSnapshot) {
                          if (!boothSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final booths = boothSnapshot.data!.docs;

                          if (booths.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'No booths available yet',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: booths.length,
                            itemBuilder: (context, index) {
                              final booth = BoothModel.fromFirestore(booths[index]);
                              return BoothInfoCard(booth: booth);
                            },
                          );
                        },
                      ),

                      // Login Prompt
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 48,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Want to book a booth?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Register or login to select and book booths',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => context.push('/register'),
                                    child: const Text('Register'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => context.push('/login'),
                                    child: const Text('Login'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(color: AppTheme.textSecondary),
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

/// Booth Info Card Widget
class BoothInfoCard extends StatelessWidget {
  final BoothModel booth;

  const BoothInfoCard({super.key, required this.booth});

  Color _getStatusColor() {
    switch (booth.status) {
      case BoothStatus.available:
        return AppTheme.boothAvailable;
      case BoothStatus.booked:
        return AppTheme.boothBooked;
      case BoothStatus.pending:
        return AppTheme.boothPending;
      case BoothStatus.unavailable:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 60,
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Booth ${booth.boothNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        booth.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${booth.type} • ${booth.sizeSqm}m²',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${booth.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
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