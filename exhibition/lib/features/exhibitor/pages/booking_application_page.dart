// features/exhibitor/pages/booking_application_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../auth/providers/auth_provider.dart';

/// Booking Application Page
/// Form for exhibitors to submit booth booking applications
class BookingApplicationPage extends ConsumerStatefulWidget {
  final String exhibitionId;
  final List<String> selectedBooths;

  const BookingApplicationPage({
    super.key,
    required this.exhibitionId,
    required this.selectedBooths,
  });

  @override
  ConsumerState<BookingApplicationPage> createState() =>
      _BookingApplicationPageState();
}

class _BookingApplicationPageState
    extends ConsumerState<BookingApplicationPage> {
  DateTime? _preferredDate;
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _companyDescController = TextEditingController();
  final _exhibitProfileController = TextEditingController();

  final Map<String, bool> _additionalItems = {
    'Extra Furniture': false,
    'Promotional Spot': false,
    'Extended WiFi': false,
    'Storage Space': false,
    'Power Outlet (Extra)': false,
  };

  final Map<String, double> _additionalItemPrices = {
    'Extra Furniture': 50.0,
    'Promotional Spot': 100.0,
    'Extended WiFi': 20.0,
    'Storage Space': 80.0,
    'Power Outlet (Extra)': 20.0,
  };

  double _calculateAdditionalTotal() {
    double total = 0;
    _additionalItems.forEach((item, selected) {
      if (selected) {
        total += _additionalItemPrices[item] ?? 0;
      }
    });
    return total;
  }


  bool _isSubmitting = false;

  Future<void> _pickPreferredDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _preferredDate = picked;
      });
    }
  }



  @override
  void dispose() {
    _companyNameController.dispose();
    _companyDescController.dispose();
    _exhibitProfileController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    setState(() => _isSubmitting = true);
    if (!_formKey.currentState!.validate()) return;

    if (_preferredDate == null) {
      Fluttertoast.showToast(
        msg: 'Please select preferred exhibition date',
        backgroundColor: AppTheme.errorColor,
      );
      setState(() => _isSubmitting = false);
      return;
    }



    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final boothSnapshot = await FirebaseFirestore.instance
          .collection('booths')
          .where(FieldPath.documentId, whereIn: widget.selectedBooths)
          .get();

      final boothTotal = boothSnapshot.docs
          .map((doc) => BoothModel.fromFirestore(doc))
          .fold<double>(0, (sum, b) => sum + b.price);

      final additionalTotal = _calculateAdditionalTotal();

      final grandTotal = boothTotal + additionalTotal;

      // Create booking document
      final booking = BookingModel(
        id: const Uuid().v4(),
        exhibitorId: user.id,
        exhibitionId: widget.exhibitionId,
        boothIds: widget.selectedBooths,
        companyName: _companyNameController.text.trim(),
        companyDescription: _companyDescController.text.trim(),
        exhibitProfile: _exhibitProfileController.text.trim(),
        additionalItems: _additionalItems,
        totalAmount: grandTotal,
        status: ApplicationStatus.pending,
        applicationDate: DateTime.now(),
        preferredExhibitionDate: _preferredDate!,
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id)
          .set(booking.toFirestore());

      // Update booth statuses to pending
      final batch = FirebaseFirestore.instance.batch();
      for (final boothId in widget.selectedBooths) {
        final boothRef =
            FirebaseFirestore.instance.collection('booths').doc(boothId);
        batch.update(boothRef, {'status': BoothStatus.pending.name});
      }
      await batch.commit();

      if (!mounted) return;

      Fluttertoast.showToast(
        msg: 'Application submitted successfully!',
        backgroundColor: AppTheme.successColor,
      );

      context.go('/exhibitor');
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: AppTheme.errorColor,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booth Application'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Exhibition Info Card
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('exhibitions')
                  .doc(widget.exhibitionId)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final exhibition =
                    ExhibitionModel.fromFirestore(snapshot.data!);

                return Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exhibition.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          exhibition.location,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Selected Booths Summary
            Card(
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event_seat, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Selected Booths',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('booths')
                          .where(FieldPath.documentId,
                              whereIn: widget.selectedBooths)
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final booths = snapshot.data!.docs
                            .map((doc) => BoothModel.fromFirestore(doc))
                            .toList();

                        final boothTotal =
                        booths.fold<double>(0, (sum, b) => sum + b.price);

                        final additionalTotal = _calculateAdditionalTotal();
                        final grandTotal = boothTotal + additionalTotal;

                        return Column(
                          children: [
                            ...booths.map((booth) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Booth ${booth.boothNumber} (${booth.type})',
                                      ),
                                      Text(
                                        '\$${booth.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
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
                                const Text('Booth Total'),
                                Text('\$${boothTotal.toStringAsFixed(2)}'),
                              ],
                            ),

                            if (additionalTotal > 0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Additional Services'),
                                  Text(
                                    '\$${additionalTotal.toStringAsFixed(2)}',
                                    style: TextStyle(color: AppTheme.primaryColor),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Grand Total',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '\$${grandTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Company Information Section
            const Text(
              'Company Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Company Name
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Company Name *',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter company name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Company Description
            TextFormField(
              controller: _companyDescController,
              decoration: const InputDecoration(
                labelText: 'Company Description *',
                prefixIcon: Icon(Icons.description),
                hintText: 'Brief description of your company',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter company description';
                }
                if (value.length < 50) {
                  return 'Description should be at least 50 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Exhibition Information Section
            const Text(
              'Exhibition Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: _pickPreferredDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Preferred Exhibition Date *',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _preferredDate == null
                      ? 'Select date'
                      : DateFormat('dd MMM yyyy').format(_preferredDate!),
                  style: TextStyle(
                    color: _preferredDate == null
                        ? AppTheme.textSecondary
                        : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),


            // Exhibit Profile
            TextFormField(
              controller: _exhibitProfileController,
              decoration: const InputDecoration(
                labelText: 'What will you showcase? *',
                prefixIcon: Icon(Icons.inventory),
                hintText: 'Describe products/services you plan to exhibit',
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe what you will showcase';
                }
                if (value.length < 30) {
                  return 'Description should be at least 30 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Additional Items Section
            const Text(
              'Additional Services',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _additionalItems.keys.map((item) {
                    return CheckboxListTile(
                      title: Text(
                        '$item (\$${_additionalItemPrices[item]!.toStringAsFixed(2)})',
                      ),
                      value: _additionalItems[item],
                      onChanged: (value) {
                        setState(() {
                          _additionalItems[item] = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Terms and Conditions
            Card(
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Important Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Your application will be reviewed by the organizer\n'
                      '• You will be notified once a decision is made\n'
                      '• Payment will be required after approval\n'
                      '• You can modify your application while it is pending',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitApplication,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Application'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}