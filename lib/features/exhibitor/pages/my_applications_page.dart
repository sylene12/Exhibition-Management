// features/exhibitor/pages/my_applications_page.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../auth/providers/auth_provider.dart';

class MyApplicationsPage extends ConsumerWidget {
  const MyApplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('exhibitorId', isEqualTo: user.id)
            .orderBy('applicationDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs;

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 80, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text('No applications yet', 
                    style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = BookingModel.fromFirestore(bookings[index]);
              return _ApplicationCard(booking: booking);
            },
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final BookingModel booking;

  const _ApplicationCard({required this.booking});

  Color _getStatusColor() {
    switch (booking.status) {
      case ApplicationStatus.pending: return AppTheme.warningColor;
      case ApplicationStatus.approved: return AppTheme.successColor;
      case ApplicationStatus.rejected: return AppTheme.errorColor;
      case ApplicationStatus.cancelled: return AppTheme.textSecondary;
    }
  }

  IconData _getStatusIcon() {
    switch (booking.status) {
      case ApplicationStatus.pending: return Icons.hourglass_empty;
      case ApplicationStatus.approved: return Icons.check_circle;
      case ApplicationStatus.rejected: return Icons.cancel;
      case ApplicationStatus.cancelled: return Icons.block;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getStatusIcon(), color: _getStatusColor()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.companyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Applied: ${DateFormat('MMM dd, yyyy').format(booking.applicationDate)}',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      if (booking.preferredExhibitionDate != null)
                        Text(
                          'Booking date: ${DateFormat('MMM dd, yyyy').format(booking.preferredExhibitionDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Booths: ${booking.boothIds.length}',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            if (booking.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppTheme.errorColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.rejectionReason!,
                        style: TextStyle(fontSize: 12, color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showDetails(context),
                  child: const Text('View Details'),
                ),
                if (booking.status == ApplicationStatus.pending) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _showEditDialog(context),
                    child: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _cancelApplication(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Application Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Company', booking.companyName),
              _buildDetailRow('Status', booking.status.name.toUpperCase()),
              _buildDetailRow('Booths', booking.boothIds.length.toString()),
              _buildDetailRow('Applied', DateFormat('MMM dd, yyyy').format(booking.applicationDate)),
              const SizedBox(height: 12),
              const Text('Company Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(booking.companyDescription),
              const SizedBox(height: 12),
              const Text('Exhibit Profile:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(booking.exhibitProfile),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _cancelApplication(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Application'),
        content: const Text('Are you sure you want to cancel this application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(booking.id)
            .update({'status': ApplicationStatus.cancelled.name});
        
        // Update booth statuses back to available
        final batch = FirebaseFirestore.instance.batch();
        for (final boothId in booking.boothIds) {
          batch.update(
            FirebaseFirestore.instance.collection('booths').doc(boothId),
            {'status': BoothStatus.available.name}
          );
        }
        await batch.commit();

        if (context.mounted) {
          Fluttertoast.showToast(
            msg: 'Application cancelled',
            backgroundColor: AppTheme.successColor,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          backgroundColor: AppTheme.errorColor,
        );
      }
    }
  }

  void _showEditDialog(BuildContext context) {
    final companyNameCtrl =
    TextEditingController(text: booking.companyName);
    final companyDescCtrl =
    TextEditingController(text: booking.companyDescription);
    final exhibitProfileCtrl =
    TextEditingController(text: booking.exhibitProfile);

    final Map<String, bool> items =
    Map<String, bool>.from(booking.additionalItems);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Edit Application',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        TextField(
                          controller: companyNameCtrl,
                          decoration:
                          const InputDecoration(labelText: 'Company Name'),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: companyDescCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                              labelText: 'Company Description'),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: exhibitProfileCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                              labelText: 'Exhibit Profile'),
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 12),

                        const Text(
                          'Additional Services',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        ...items.keys.map((item) {
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item),
                            value: items[item],
                            onChanged: (value) {
                              setState(() {
                                items[item] = value ?? false;
                              });
                            },
                          );
                        }).toList(),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('bookings')
                                    .doc(booking.id)
                                    .update({
                                  'companyName':
                                  companyNameCtrl.text.trim(),
                                  'companyDescription':
                                  companyDescCtrl.text.trim(),
                                  'exhibitProfile':
                                  exhibitProfileCtrl.text.trim(),
                                  'additionalItems': items,
                                  'updatedAt':
                                  FieldValue.serverTimestamp(),
                                });

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  Fluttertoast.showToast(
                                    msg: 'Application updated',
                                    backgroundColor:
                                    AppTheme.successColor,
                                  );
                                }
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

  }

}

