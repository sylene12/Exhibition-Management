// features/guest/pages/guest_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';

/// Guest Home Page
/// Displays list of published exhibitions accessible without login
class GuestHomePage extends ConsumerStatefulWidget {
  const GuestHomePage({super.key});

  @override
  ConsumerState<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends ConsumerState<GuestHomePage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exhibition Booth'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/login'),
            icon: const Icon(Icons.login, color: Colors.white),
            label: const Text('Login', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body:Column(
          children: [
      // 🔍 SEARCH BAR
      Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search exhibition or location',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    ),

    // 🔽 LIST
    Expanded(
    child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('exhibitions')
        .where('isPublished', isEqualTo: true)
        .orderBy('startDate', descending: false)
        .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

    final allDocs = snapshot.data?.docs ?? [];

    final exhibitions = allDocs.where((doc) {
    final exhibition = ExhibitionModel.fromFirestore(doc);
    return exhibition.name.toLowerCase().contains(_searchQuery) ||
    exhibition.location.toLowerCase().contains(_searchQuery);
    }).toList();


    if (exhibitions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No exhibitions available',
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
            itemCount: exhibitions.length,
            itemBuilder: (context, index) {
              final exhibition = ExhibitionModel.fromFirestore(exhibitions[index]);
              return ExhibitionCard(
                exhibition: exhibition,
                onTap: () => context.push('/exhibition/${exhibition.id}'),
              );


            },
          );
        },

      ),
    ),
    ],
      ),
    );

  }
}

/// Exhibition Card Widget
/// Displays exhibition summary with status badge
class ExhibitionCard extends StatelessWidget {
  final ExhibitionModel exhibition;
  final VoidCallback onTap;

  const ExhibitionCard({
    super.key,
    required this.exhibition,
    required this.onTap,
  });

  Color _getStatusColor(ExhibitionStatus status) {
    switch (status) {
      case ExhibitionStatus.upcoming:
        return AppTheme.primaryColor;
      case ExhibitionStatus.ongoing:
        return AppTheme.successColor;
      case ExhibitionStatus.completed:
        return AppTheme.textSecondary;
      case ExhibitionStatus.cancelled:
        return AppTheme.errorColor;
    }
  }


  @override
  Widget build(BuildContext context) {
    final status = exhibition.computedStatus;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.name.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    exhibition.location,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${dateFormat.format(exhibition.startDate)} - ${dateFormat.format(exhibition.endDate)}',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                exhibition.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('View Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}