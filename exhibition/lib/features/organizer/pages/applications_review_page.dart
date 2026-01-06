// ============================================================================
// features/organizer/pages/applications_review_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../auth/providers/auth_provider.dart';

class ApplicationsReviewPage extends ConsumerStatefulWidget {
  const ApplicationsReviewPage({super.key});

  @override
  ConsumerState<ApplicationsReviewPage> createState() => _ApplicationsReviewPageState();
}

class _ApplicationsReviewPageState extends ConsumerState<ApplicationsReviewPage> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Applications'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'all', label: Text('All')),
                      ButtonSegment(value: 'pending', label: Text('Pending')),
                      ButtonSegment(value: 'approved', label: Text('Approved')),
                      ButtonSegment(value: 'rejected', label: Text('Rejected')),
                    ],
                    selected: {_selectedFilter},
                    onSelectionChanged: (Set<String> selected) {
                      setState(() {
                        _selectedFilter = selected.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _selectedFilter == 'all'
            ? FirebaseFirestore.instance
                .collection('bookings')
                .orderBy('applicationDate', descending: true)
                .snapshots()
            : FirebaseFirestore.instance
                .collection('bookings')
                .where('status', isEqualTo: _selectedFilter)
                .orderBy('applicationDate', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter to show only applications for organizer's exhibitions
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('exhibitions')
                .where('organizerId', isEqualTo: user?.id)
                .get(),
            builder: (context, exhibitionsSnapshot) {
              if (!exhibitionsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final organizerExhibitionIds = exhibitionsSnapshot.data!.docs
                  .map((doc) => doc.id)
                  .toSet();

              final allBookings = snapshot.data!.docs
                  .map((doc) => BookingModel.fromFirestore(doc))
                  .where((booking) => organizerExhibitionIds.contains(booking.exhibitionId))
                  .toList();

              if (allBookings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment,
                        size: 80,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No applications found',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: allBookings.length,
                itemBuilder: (context, index) {
                  return ApplicationReviewCard(
                    booking: allBookings[index],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ApplicationReviewCard extends StatelessWidget {
  final BookingModel booking;

  const ApplicationReviewCard({
    super.key,
    required this.booking,
  });

  Color _getStatusColor() {
    switch (booking.status) {
      case ApplicationStatus.pending:
        return AppTheme.warningColor;
      case ApplicationStatus.approved:
        return AppTheme.successColor;
      case ApplicationStatus.rejected:
        return AppTheme.errorColor;
      case ApplicationStatus.cancelled:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.business,
            color: _getStatusColor(),
          ),
        ),
        title: Text(
          booking.companyName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Applied: ${DateFormat('MMM dd, yyyy').format(booking.applicationDate)}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                booking.status.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exhibition Details
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('exhibitions')
                      .doc(booking.exhibitionId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final exhibition = ExhibitionModel.fromFirestore(snapshot.data!);

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exhibition.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Company Description
                _buildInfoSection(
                  'Company Description',
                  booking.companyDescription,
                  Icons.business,
                ),
                const SizedBox(height: 12),

                // Exhibit Profile
                _buildInfoSection(
                  'Exhibit Profile',
                  booking.exhibitProfile,
                  Icons.inventory,
                ),
                const SizedBox(height: 12),

                // Booths
                _buildBoothsList(),
                const SizedBox(height: 12),

                // Additional Items
                if (booking.additionalItems.values.any((v) => v)) ...[
                  const Text(
                    'Additional Services:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: booking.additionalItems.entries
                        .where((e) => e.value)
                        .map((entry) => Chip(
                              label: Text(
                                entry.key,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.1),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Rejection Reason (if rejected)
                if (booking.rejectionReason != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.errorColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rejection Reason:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                booking.rejectionReason!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                if (booking.status == ApplicationStatus.pending)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectDialog(context),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveApplication(context),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                // Cancel approved booking
                if (booking.status == ApplicationStatus.approved)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(context),
                      icon: const Icon(Icons.block),
                      label: const Text('Cancel Booking'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoothsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event_seat, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Selected Booths (${booking.boothIds.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('booths')
              .where(FieldPath.documentId, whereIn: booking.boothIds)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final booths = snapshot.data!.docs
                .map((doc) => BoothModel.fromFirestore(doc))
                .toList();

            final totalPrice = booths.fold<double>(0, (sum, b) => sum + b.price);

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  ...booths.map((booth) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Booth ${booth.boothNumber} (${booth.type})',
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              '\$${booth.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _approveApplication(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Application'),
        content: const Text('Approve this booth booking application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Update booking status
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(booking.id)
            .update({
          'status': ApplicationStatus.approved.name,
          'approvalDate': Timestamp.now(),
        });

        // Update booth statuses to booked
        final batch = FirebaseFirestore.instance.batch();
        for (final boothId in booking.boothIds) {
          batch.update(
            FirebaseFirestore.instance.collection('booths').doc(boothId),
            {'status': BoothStatus.booked.name},
          );
        }
        await batch.commit();

        Fluttertoast.showToast(
          msg: 'Application approved successfully',
          backgroundColor: AppTheme.successColor,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          backgroundColor: AppTheme.errorColor,
        );
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for rejection:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason',
                  hintText: 'Enter reason...',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, reasonController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        // Update booking status
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(booking.id)
            .update({
          'status': ApplicationStatus.rejected.name,
          'rejectionReason': result,
        });

        // Update booth statuses back to available
        final batch = FirebaseFirestore.instance.batch();
        for (final boothId in booking.boothIds) {
          batch.update(
            FirebaseFirestore.instance.collection('booths').doc(boothId),
            {'status': BoothStatus.available.name},
          );
        }
        await batch.commit();

        Fluttertoast.showToast(
          msg: 'Application rejected',
          backgroundColor: AppTheme.successColor,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          backgroundColor: AppTheme.errorColor,
        );
      }
    }
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for cancellation:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Cancellation Reason',
                  hintText: 'Enter reason...',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, reasonController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        // Update booking status
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(booking.id)
            .update({
          'status': ApplicationStatus.cancelled.name,
          'rejectionReason': result,
        });

        // Update booth statuses back to available
        final batch = FirebaseFirestore.instance.batch();
        for (final boothId in booking.boothIds) {
          batch.update(
            FirebaseFirestore.instance.collection('booths').doc(boothId),
            {'status': BoothStatus.available.name},
          );
        }
        await batch.commit();

        Fluttertoast.showToast(
          msg: 'Booking cancelled',
          backgroundColor: AppTheme.successColor,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          backgroundColor: AppTheme.errorColor,
        );
      }
    }
  }
}