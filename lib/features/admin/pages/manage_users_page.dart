// features/admin/pages/manage_users_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';

class ManageUsersPage extends ConsumerStatefulWidget {
  const ManageUsersPage({super.key});

  @override
  ConsumerState<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends ConsumerState<ManageUsersPage> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('All')),
                  ButtonSegment(value: 'exhibitor', label: Text('Exhibitors')),
                  ButtonSegment(value: 'organizer', label: Text('Organizers')),
                  ButtonSegment(value: 'admin', label: Text('Admins')),
                ],
                selected: {_selectedFilter},
                onSelectionChanged: (Set<String> selected) {
                  setState(() {
                    _selectedFilter = selected.first;
                  });
                },
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _selectedFilter == 'all'
            ? FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .snapshots()
            : FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: _selectedFilter)
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = UserModel.fromFirestore(users[index]);
              return _UserCard(user: user);
            },
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;

  const _UserCard({required this.user});

  Color _getRoleColor() {
    switch (user.role) {
      case UserRole.admin:
        return AppTheme.errorColor;
      case UserRole.organizer:
        return AppTheme.primaryColor;
      case UserRole.exhibitor:
        return AppTheme.successColor;
      case UserRole.guest:
        return AppTheme.textSecondary;
    }
  }

  IconData _getRoleIcon() {
    switch (user.role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.organizer:
        return Icons.business_center;
      case UserRole.exhibitor:
        return Icons.business;
      case UserRole.guest:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getRoleColor().withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getRoleIcon(), color: _getRoleColor()),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.role.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getRoleColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (user.companyName != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      user.companyName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Joined: ${DateFormat('MMM dd, yyyy').format(user.createdAt)}',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit Role'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                  SizedBox(width: 8),
                  Text('Delete User', style: TextStyle(color: AppTheme.errorColor)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'view':
                _showUserDetails(context);
                break;
              case 'edit':
                _showEditRoleDialog(context);
                break;
              case 'delete':
                _deleteUser(context);
                break;
            }
          },
        ),
      ),
    );
  }

  void _showUserDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', user.name),
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Role', user.role.name.toUpperCase()),
              if (user.companyName != null)
                _buildDetailRow('Company', user.companyName!),
              if (user.phoneNumber != null)
                _buildDetailRow('Phone', user.phoneNumber!),
              _buildDetailRow(
                'Joined',
                DateFormat('MMMM dd, yyyy').format(user.createdAt),
              ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditRoleDialog(BuildContext context) async {
    UserRole selectedRole = user.role;

    final result = await showDialog<UserRole>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit User Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Change role for ${user.name}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: UserRole.values
                    .where((role) => role != UserRole.guest)
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedRole),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result != user.role) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .update({'role': result.name});

        Fluttertoast.showToast(
          msg: 'User role updated successfully',
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

  Future<void> _deleteUser(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.name}? This action cannot be undone.',
        ),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Note: In production, you'd also need to delete the Firebase Auth account
        // This requires Firebase Admin SDK on the backend
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .delete();

        Fluttertoast.showToast(
          msg: 'User deleted successfully',
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