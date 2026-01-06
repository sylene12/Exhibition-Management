// features/exhibitor/pages/event_selection_page.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../auth/providers/auth_provider.dart';

class EventSelectionPage extends ConsumerStatefulWidget {
  const EventSelectionPage({super.key});

  @override
  ConsumerState<EventSelectionPage> createState() =>
      _EventSelectionPageState();
}

class _EventSelectionPageState
    extends ConsumerState<EventSelectionPage> {
  String _searchQuery = '';
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Exhibition'),
      ),
      body: Column(
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

    // 📄 LIST
    Expanded(
    child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('exhibitions')
        .where('isPublished', isEqualTo: true)
        .snapshots(),

    builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

    final allDocs = snapshot.data!.docs;

// 🔍 FILTER BASED ON SEARCH
      final exhibitions = allDocs
          .map((doc) => ExhibitionModel.fromFirestore(doc))
          .where((exhibition) {
        final status = exhibition.computedStatus;

        // Exhibitor hanya boleh pilih UPCOMING & ONGOING
        if (status == ExhibitionStatus.completed ||
            status == ExhibitionStatus.cancelled) {
          return false;
        }

        return exhibition.name.toLowerCase().contains(_searchQuery) ||
            exhibition.location.toLowerCase().contains(_searchQuery);
      })
          .toList();



      if (exhibitions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No exhibitions available for booking',
                    style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }


          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exhibitions.length,
            itemBuilder: (context, index) {
              final exhibition = exhibitions[index];
              return _EventCard(exhibition: exhibition);
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

class _EventCard extends StatelessWidget {

  final ExhibitionModel exhibition;

  const _EventCard({required this.exhibition});

  @override
  Widget build(BuildContext context) {
    final status = exhibition.computedStatus;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/exhibitor/floor-plan/${exhibition.id}'),
        borderRadius: BorderRadius.circular(12),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
              Text(
                exhibition.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/exhibitor/floor-plan/${exhibition.id}'),
                  icon: const Icon(Icons.map, size: 20),
                  label: const Text('View Floor Plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}