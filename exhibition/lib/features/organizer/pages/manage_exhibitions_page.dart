// lib/features/organizer/pages/manage_exhibitions_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../auth/providers/auth_provider.dart';

class ManageExhibitionsPage extends ConsumerWidget {
  const ManageExhibitionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Exhibitions'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExhibitionDialog(context, user?.id, null),
        icon: const Icon(Icons.add),
        label: const Text('New Exhibition'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('exhibitions')
            .where('organizerId', isEqualTo: user?.id)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final exhibitions = snapshot.data!.docs;

          if (exhibitions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No exhibitions yet',
                    style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first exhibition',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exhibitions.length,
            itemBuilder: (context, index) {
              final exhibition = ExhibitionModel.fromFirestore(exhibitions[index]);
              return _ExhibitionCard(exhibition: exhibition);
            },
          );
        },
      ),
    );
  }
}

class _ExhibitionCard extends StatelessWidget {
  final ExhibitionModel exhibition;

  const _ExhibitionCard({required this.exhibition});

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
                Expanded(
                  child: Text(
                    exhibition.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: exhibition.isPublished,
                  onChanged: (value) => _togglePublish(context, value),
                  activeColor: AppTheme.successColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(exhibition.location, style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('MMM dd').format(exhibition.startDate)} - ${DateFormat('MMM dd, yyyy').format(exhibition.endDate)}',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => context.push('/organizer/booths/${exhibition.id}'),
                  icon: const Icon(Icons.event_seat, size: 18),
                  label: const Text('Booths'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showExhibitionDialog(context, exhibition.organizerId, exhibition),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _deleteExhibition(context),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePublish(BuildContext context, bool value) async {
    try {
      await FirebaseFirestore.instance
          .collection('exhibitions')
          .doc(exhibition.id)
          .update({'isPublished': value});
      
      Fluttertoast.showToast(
        msg: value ? 'Exhibition published' : 'Exhibition unpublished',
        backgroundColor: AppTheme.successColor,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  Future<void> _deleteExhibition(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exhibition'),
        content: const Text('Are you sure? This will also delete all associated booths.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
        final booths = await FirebaseFirestore.instance
            .collection('booths')
            .where('exhibitionId', isEqualTo: exhibition.id)
            .get();
        
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in booths.docs) {
          batch.delete(doc.reference);
        }
        
        batch.delete(
          FirebaseFirestore.instance.collection('exhibitions').doc(exhibition.id)
        );
        
        await batch.commit();

        Fluttertoast.showToast(
          msg: 'Exhibition deleted',
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

void _showExhibitionDialog(BuildContext context, String? organizerId, ExhibitionModel? exhibition) {
  final nameController = TextEditingController(text: exhibition?.name);
  final descController = TextEditingController(text: exhibition?.description);
  final locationController = TextEditingController(text: exhibition?.location);
  final formKey = GlobalKey<FormState>();
  
  DateTime startDate = exhibition?.startDate ?? DateTime.now();
  DateTime endDate = exhibition?.endDate ?? DateTime.now().add(const Duration(days: 7));

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(exhibition == null ? 'New Exhibition' : 'Edit Exhibition'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Exhibition Name *'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  maxLines: 3,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location *'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Start Date'),
                        subtitle: Text(DateFormat('MMM dd, yyyy').format(startDate)),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              startDate = date;
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('End Date'),
                        subtitle: Text(DateFormat('MMM dd, yyyy').format(endDate)),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              endDate = date;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final data = {
                    'name': nameController.text.trim(),
                    'description': descController.text.trim(),
                    'location': locationController.text.trim(),
                    'startDate': Timestamp.fromDate(startDate),
                    'endDate': Timestamp.fromDate(endDate),
                    'organizerId': organizerId,
                    'status': ExhibitionStatus.upcoming.name,
                    'isPublished': exhibition?.isPublished ?? false,
                    'createdAt': exhibition?.createdAt != null 
                        ? Timestamp.fromDate(exhibition!.createdAt)
                        : Timestamp.now(),
                  };

                  if (exhibition == null) {
                    await FirebaseFirestore.instance
                        .collection('exhibitions')
                        .add(data);
                    Fluttertoast.showToast(msg: 'Exhibition created', backgroundColor: AppTheme.successColor);
                  } else {
                    await FirebaseFirestore.instance
                        .collection('exhibitions')
                        .doc(exhibition.id)
                        .update(data);
                    Fluttertoast.showToast(msg: 'Exhibition updated', backgroundColor: AppTheme.successColor);
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