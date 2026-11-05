import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  // Controller for the new password.
  final _newPassword = TextEditingController();

  bool _saving = false;
  String? _saveError;

  @override
  void dispose() {
    _newPassword.dispose();
    super.dispose();
  }

  // Change the user's password.
  Future<void> _changePassword() async {
    final newPassword = _newPassword.text;

    if (newPassword.length < 6) {
      setState(() {
        _saveError = 'Password must be at least 6 characters';
      });
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      await _authService.changePassword(newPassword);

      if (!mounted) return;

      // Clear the password field after success.
      _newPassword.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        if (error.code == 'requires-recent-login') {
          _saveError = 'Please sign out and sign in again before changing your password.';
        } else {
          _saveError = 'Password update failed (${error.code}).';
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saveError = 'Password update failed. Please try again.';
      });
    } finally {
      if (mounted) {
        _newPassword.clear();

        setState(() {
          _saving = false;
        });
      }
    }
  }

  // Sign out the user.
  Future<void> _signOut() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      await _authService.signOut();

      // AuthGate automatically shows AuthenticationScreen.
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _saveError = 'Sign out failed (${error.code}).';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saveError = 'Sign out failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle, size: 80),

              const SizedBox(height: 20),

              const Text('Welcome!', style: TextStyle(fontSize: 24)),

              const SizedBox(height: 20),

              Text('Email: ${user?.email ?? "Unavailable"}'),

              const SizedBox(height: 10),

              Text('User ID: ${user?.uid ?? "Unavailable"}'),

              const SizedBox(height: 30),

              const Text('Change Password', style: TextStyle(fontSize: 20)),

              const SizedBox(height: 15),

              // New password only.
              TextField(
                controller: _newPassword,
                enabled: !_saving,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),

              const SizedBox(height: 15),

              // Display error messages.
              if (_saveError != null)
                Text(_saveError!, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: _saving ? null : _changePassword,
                child: const Text('Update Password'),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saving ? null : _signOut,
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
