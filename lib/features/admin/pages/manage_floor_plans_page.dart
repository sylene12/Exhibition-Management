// features/admin/pages/manage_floor_plans_page.dart
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';

class ManageFloorPlansPage extends ConsumerWidget {
  const ManageFloorPlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Floor Plan Management'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('exhibitions')
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
                  Icon(Icons.map, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No exhibitions available',
                    style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
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
              return _FloorPlanCard(exhibition: exhibition);
            },
          );
        },
      ),
    );
  }
}

class _FloorPlanCard extends StatelessWidget {
  final ExhibitionModel exhibition;

  const _FloorPlanCard({required this.exhibition});

  @override
  Widget build(BuildContext context) {
    final hasFloorPlan = exhibition.floorPlanUrl != null;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exhibition.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exhibition.location,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: hasFloorPlan
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasFloorPlan ? Icons.check_circle : Icons.warning,
                        size: 16,
                        color: hasFloorPlan
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasFloorPlan ? 'HAS PLAN' : 'NO PLAN',
                        style: TextStyle(
                          fontSize: 10,
                          color: hasFloorPlan
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Floor plan preview
            if (hasFloorPlan)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  exhibition.floorPlanUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[400]!,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No floor plan uploaded',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasFloorPlan) ...[
                  OutlinedButton.icon(
                    onPressed: () => _deleteFloorPlan(context),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  onPressed: () => _uploadFloorPlan(context),
                  icon: Icon(hasFloorPlan ? Icons.update : Icons.upload, size: 18),
                  label: Text(hasFloorPlan ? 'Update' : 'Upload'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFloorPlan(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading floor plan...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('floor_plans')
          .child('${exhibition.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(File(image.path));
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('exhibitions')
          .doc(exhibition.id)
          .update({'floorPlanUrl': downloadUrl});

      Navigator.pop(context); // Close loading dialog

      Fluttertoast.showToast(
        msg: 'Floor plan uploaded successfully',
        backgroundColor: AppTheme.successColor,
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  Future<void> _deleteFloorPlan(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Floor Plan'),
        content: const Text('Are you sure you want to remove this floor plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete from Storage
        if (exhibition.floorPlanUrl != null) {
          final storageRef = FirebaseStorage.instance.refFromURL(exhibition.floorPlanUrl!);
          await storageRef.delete();
        }

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('exhibitions')
            .doc(exhibition.id)
            .update({'floorPlanUrl': null});

        Fluttertoast.showToast(
          msg: 'Floor plan removed',
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