// lib/features/organizer/pages/manage_booths_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';

class ManageBoothsPage extends ConsumerWidget {
  final String exhibitionId;

  const ManageBoothsPage({super.key, required this.exhibitionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Booths')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBoothDialog(context, exhibitionId, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Booth'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('booths')
            .where('exhibitionId', isEqualTo: exhibitionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final booths = snapshot.data!.docs;

          if (booths.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_seat, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text('No booths yet', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: booths.length,
            itemBuilder: (context, index) {
              final booth = BoothModel.fromFirestore(booths[index]);
              return _BoothCard(booth: booth, exhibitionId: exhibitionId);
            },
          );
        },
      ),
    );
  }
}

class _BoothCard extends StatelessWidget {
  final BoothModel booth;
  final String exhibitionId;

  const _BoothCard({required this.booth, required this.exhibitionId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              booth.boothNumber,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getStatusColor(),
              ),
            ),
          ),
        ),
        title: Text('${booth.type} - ${booth.sizeSqm}m²'),
        subtitle: Text('\$${booth.price.toStringAsFixed(2)} • ${booth.status.name}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showBoothDialog(context, exhibitionId, booth),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              onPressed: () => _deleteBooth(context),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (booth.status) {
      case BoothStatus.available: return AppTheme.boothAvailable;
      case BoothStatus.booked: return AppTheme.boothBooked;
      case BoothStatus.pending: return AppTheme.boothPending;
      case BoothStatus.unavailable: return AppTheme.textSecondary;
    }
  }

  Future<void> _deleteBooth(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Booth'),
        content: const Text('Are you sure you want to delete this booth?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('booths').doc(booth.id).delete();
        Fluttertoast.showToast(msg: 'Booth deleted', backgroundColor: AppTheme.successColor);
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error: ${e.toString()}', backgroundColor: AppTheme.errorColor);
      }
    }
  }
}

void _showBoothDialog(BuildContext context, String exhibitionId, BoothModel? booth) {
  final numberController = TextEditingController(text: booth?.boothNumber);
  final priceController = TextEditingController(text: booth?.price.toString());
  final sizeController = TextEditingController(text: booth?.sizeSqm.toString());
  final formKey = GlobalKey<FormState>();
  
  String type = booth?.type ?? 'Standard';
  final amenities = booth?.amenities ?? {'WiFi': false, 'Power': false, 'Water': false};

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(booth == null ? 'Add Booth' : 'Edit Booth'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: numberController,
                  decoration: const InputDecoration(labelText: 'Booth Number *'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['Standard', 'Premium', 'VIP'].map((t) => 
                    DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => type = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: sizeController,
                  decoration: const InputDecoration(labelText: 'Size (m²) *'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price *'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                ...amenities.keys.map((key) => CheckboxListTile(
                  title: Text(key),
                  value: amenities[key],
                  onChanged: (v) => setState(() => amenities[key] = v ?? false),
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final data = {
                    'exhibitionId': exhibitionId,
                    'boothNumber': numberController.text.trim(),
                    'type': type,
                    'sizeSqm': double.parse(sizeController.text),
                    'price': double.parse(priceController.text),
                    'status': booth?.status.name ?? BoothStatus.available.name,
                    'amenities': amenities,
                  };

                  if (booth == null) {
                    await FirebaseFirestore.instance.collection('booths').add(data);
                    Fluttertoast.showToast(msg: 'Booth created', backgroundColor: AppTheme.successColor);
                  } else {
                    await FirebaseFirestore.instance.collection('booths').doc(booth.id).update(data);
                    Fluttertoast.showToast(msg: 'Booth updated', backgroundColor: AppTheme.successColor);
                  }
                  Navigator.pop(dialogContext);
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Error: ${e.toString()}', backgroundColor: AppTheme.errorColor);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}