// features/exhibitor/pages/floor_plan_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';

/// Interactive Floor Plan Page
/// Allows exhibitors to select booths visually from a floor map
class FloorPlanPage extends ConsumerStatefulWidget {
  final String exhibitionId;

  const FloorPlanPage({
    super.key,
    required this.exhibitionId,
  });

  @override
  ConsumerState<FloorPlanPage> createState() => _FloorPlanPageState();
}

class _FloorPlanPageState extends ConsumerState<FloorPlanPage> {
  final Set<String> _selectedBoothIds = {};
  double _totalPrice = 0.0;

  void _toggleBoothSelection(BoothModel booth) {
    if (booth.status != BoothStatus.available) {
      Fluttertoast.showToast(
        msg: 'This booth is not available',
        backgroundColor: AppTheme.errorColor,
      );
      return;
    }

    setState(() {
      if (_selectedBoothIds.contains(booth.id)) {
        _selectedBoothIds.remove(booth.id);
        _totalPrice -= booth.price;
      } else {
        _selectedBoothIds.add(booth.id);
        _totalPrice += booth.price;
      }
    });
  }

  void _proceedToApplication() {
    if (_selectedBoothIds.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please select at least one booth',
        backgroundColor: AppTheme.warningColor,
      );
      return;
    }

    context.push(
      '/exhibitor/booking-application',
      extra: {
        'exhibitionId': widget.exhibitionId,
        'selectedBooths': _selectedBoothIds.toList(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Booths'),
        actions: [
          if (_selectedBoothIds.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedBoothIds.length} Selected',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('booths')
            .where('exhibitionId', isEqualTo: widget.exhibitionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final booths = snapshot.data!.docs
              .map((doc) => BoothModel.fromFirestore(doc))
              .toList();

          if (booths.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No booths available',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Legend
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem('Available', AppTheme.boothAvailable),
                    _buildLegendItem('Booked', AppTheme.boothBooked),
                    _buildLegendItem('Selected', AppTheme.boothSelected),
                    _buildLegendItem('Pending', AppTheme.boothPending),
                  ],
                ),
              ),

              // Floor Plan Grid
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: BoothGridLayout(
                    booths: booths,
                    selectedBoothIds: _selectedBoothIds,
                    onBoothTap: _toggleBoothSelection,
                  ),
                ),
              ),

              // Selection Summary
              if (_selectedBoothIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_selectedBoothIds.length} Booth(s) Selected',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total: \$${_totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: _proceedToApplication,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Continue'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

/// Booth Grid Layout Widget
/// Displays booths in a grid format representing the floor plan
class BoothGridLayout extends StatelessWidget {
  final List<BoothModel> booths;
  final Set<String> selectedBoothIds;
  final Function(BoothModel) onBoothTap;

  const BoothGridLayout({
    super.key,
    required this.booths,
    required this.selectedBoothIds,
    required this.onBoothTap,
  });

  @override
  Widget build(BuildContext context) {
    // Group booths by type for better organization
    final standardBooths = booths.where((b) => b.type == 'Standard').toList();
    final premiumBooths = booths.where((b) => b.type == 'Premium').toList();
    final vipBooths = booths.where((b) => b.type == 'VIP').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (vipBooths.isNotEmpty) ...[
          const Text(
            'VIP Booths',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildBoothSection(vipBooths),
          const SizedBox(height: 24),
        ],
        if (premiumBooths.isNotEmpty) ...[
          const Text(
            'Premium Booths',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildBoothSection(premiumBooths),
          const SizedBox(height: 24),
        ],
        if (standardBooths.isNotEmpty) ...[
          const Text(
            'Standard Booths',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildBoothSection(standardBooths),
        ],
      ],
    );
  }

  Widget _buildBoothSection(List<BoothModel> sectionBooths) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: sectionBooths.length,
      itemBuilder: (context, index) {
        final booth = sectionBooths[index];
        final isSelected = selectedBoothIds.contains(booth.id);

        return BoothCard(
          booth: booth,
          isSelected: isSelected,
          onTap: () => onBoothTap(booth),
        );
      },
    );
  }
}

/// Booth Card Widget
/// Individual booth display with status and selection
class BoothCard extends StatelessWidget {
  final BoothModel booth;
  final bool isSelected;
  final VoidCallback onTap;

  const BoothCard({
    super.key,
    required this.booth,
    required this.isSelected,
    required this.onTap,
  });

  Color _getBoothColor() {
    if (isSelected) return AppTheme.boothSelected;

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
    final isAvailable = booth.status == BoothStatus.available;

    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      onLongPress: () => _showBoothDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: _getBoothColor(),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.boothSelected.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    booth.boothNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${booth.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: AppTheme.boothSelected,
                  ),
                ),
              ),
            if (!isAvailable)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    size: 16,
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBoothDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booth ${booth.boothNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', booth.type),
            _buildDetailRow('Size', '${booth.sizeSqm}m²'),
            _buildDetailRow('Price', '\$${booth.price.toStringAsFixed(2)}'),
            _buildDetailRow('Status', booth.status.name.toUpperCase()),
            const SizedBox(height: 16),
            const Text(
              'Amenities:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...booth.amenities.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        entry.value ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: entry.value
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
                      const SizedBox(width: 8),
                      Text(entry.key),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (booth.status == BoothStatus.available)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onTap();
              },
              child: Text(isSelected ? 'Deselect' : 'Select'),
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
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(value),
        ],
      ),
    );
  }
}