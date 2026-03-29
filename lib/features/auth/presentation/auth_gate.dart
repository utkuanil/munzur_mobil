import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _repo = AuthRepository();
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _goOnce('/login');
        return;
      }

      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null) {
        _goOnce('/login');
        return;
      }

      if (!refreshedUser.emailVerified) {
        final email = Uri.encodeComponent(refreshedUser.email ?? '');
        _goOnce('/verify-email?email=$email');
        return;
      }

      await _repo.activateIfVerified();
      _goOnce('/home');
    } catch (_) {
      _goOnce('/login');
    }
  }

  void _goOnce(String route) {
    if (_navigated || !mounted) return;
    _navigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}