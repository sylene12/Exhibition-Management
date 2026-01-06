import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class DashboardRedirectPage extends StatefulWidget {
  const DashboardRedirectPage({super.key});

  @override
  State<DashboardRedirectPage> createState() => _DashboardRedirectPageState();
}

class _DashboardRedirectPageState extends State<DashboardRedirectPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      context.go('/');
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final role = doc.data()?['role'];

    switch (role) {
      case 'admin':
        context.go('/admin');
        break;
      case 'organizer':
        context.go('/organizer');
        break;
      case 'exhibitor':
        context.go('/exhibitor');
        break;
      default:
        context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
