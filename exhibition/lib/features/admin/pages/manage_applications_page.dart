// ============================================================================
// features/admin/pages/manage_applications_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';

class ManageApplicationsPage extends ConsumerStatefulWidget {
  const ManageApplicationsPage({super.key});

  @override
  ConsumerState<ManageApplicationsPage> createState() =>
      _ManageApplicationsPageState();
}

class _ManageApplicationsPageState
    extends ConsumerState<ManageApplicationsPage> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Applications'),
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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs
              .map((d) => BookingModel.fromFirestore(d))
              .toList();

          if (bookings.isEmpty) {
            return const Center(child: Text('No applications found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _AdminApplicationCard(booking: bookings[index]);
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// ADMIN CARD
// ============================================================================

class _AdminApplicationCard extends StatelessWidget {
  final BookingModel booking;

  const _AdminApplicationCard({required this.booking});

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

                // ADMIN ACTIONS
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Application'),
                    onPressed: () => _showEditDialog(context),
                  ),
                ),
                const SizedBox(height: 8),

                if (booking.status == ApplicationStatus.pending) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    onPressed: () =>
                        _updateStatus(ApplicationStatus.approved),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    onPressed: () =>
                        _updateStatus(ApplicationStatus.rejected),
                  ),
                ],

                const SizedBox(height: 8),

                if (booking.status != ApplicationStatus.cancelled)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel Booking'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                    ),
                    onPressed: () =>
                        _updateStatus(ApplicationStatus.cancelled),
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

  Future<void> _updateStatus(ApplicationStatus status) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(booking.id)
        .update({
      'status': status.name,
      'updatedAt': Timestamp.now(),
    });

    Fluttertoast.showToast(
      msg: 'Status updated to ${status.name}',
      backgroundColor: AppTheme.successColor,
    );
  }

  // ========================================================================
  // ADMIN EDIT
  // ========================================================================

  void _showEditDialog(BuildContext context) {
    final companyCtrl = TextEditingController(text: booking.companyName);
    final descCtrl =
    TextEditingController(text: booking.companyDescription);
    final profileCtrl =
    TextEditingController(text: booking.exhibitProfile);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Admin Edit Application',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: companyCtrl,
                decoration:
                const InputDecoration(labelText: 'Company Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Company Description'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: profileCtrl,
                maxLines: 3,
                decoration:
                const InputDecoration(labelText: 'Exhibit Profile'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(booking.id)
                          .update({
                        'companyName': companyCtrl.text,
                        'companyDescription': descCtrl.text,
                        'exhibitProfile': profileCtrl.text,
                        'updatedAt': Timestamp.now(),
                      });

                      Navigator.pop(context);
                      Fluttertoast.showToast(
                        msg: 'Application updated',
                        backgroundColor: AppTheme.successColor,
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
