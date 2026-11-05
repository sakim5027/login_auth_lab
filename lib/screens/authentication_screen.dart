import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  // Form key from professor's starter code.
  final _formKey = GlobalKey<FormState>();

  // Controllers to read the email and password.
  final _email = TextEditingController();
  final _password = TextEditingController();

  // Firebase Authentication service.
  final AuthService _authService = AuthService();

  // Screen state.
  bool _isRegistering = false;
  bool _saving = false;
  String? _saveError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // Register or sign in.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      final email = _email.text.trim();
      final password = _password.text;

      if (_isRegistering) {
        // Create a new Firebase account.
        await _authService.register(email, password);
      } else {
        // Sign in to an existing Firebase account.
        await _authService.signIn(email, password);
      }

      // AuthGate automatically opens ProfileScreen.
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        if (error.code == 'email-already-in-use') {
          _saveError = 'This email is already registered.';
        } else if (error.code == 'weak-password') {
          _saveError = 'Please choose a stronger password.';
        } else if (error.code == 'invalid-email') {
          _saveError = 'Enter a valid email address.';
        } else if (error.code == 'invalid-credential' ||
            error.code == 'wrong-password' ||
            error.code == 'user-not-found') {
          _saveError = 'Invalid email or password.';
        } else if (error.code == 'too-many-requests') {
          _saveError = 'Too many attempts. Please try again later.';
        } else {
          _saveError = 'Authentication failed (${error.code}).';
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saveError = 'Something went wrong. Please try again.';
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
    return Scaffold(
      appBar: AppBar(title: Text(_isRegistering ? 'Register' : 'Sign In')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isRegistering ? 'Create an Account' : 'Welcome Back!',
                  style: const TextStyle(fontSize: 24),
                ),

                const SizedBox(height: 20),

                // Professor's original email field.
                TextFormField(
                  controller: _email,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }

                    if (!value.contains('@')) {
                      return 'Enter a valid email address';
                    }

                    return null;
                  },
                ),

                // Professor's original password field.
                TextFormField(
                  controller: _password,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // Display Firebase error messages.
                if (_saveError != null)
                  Text(_saveError!, style: const TextStyle(color: Colors.red)),

                const SizedBox(height: 15),

                // Professor's original Continue button.
                ElevatedButton(
                  onPressed: _saving
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _submit();
                          }
                        },
                  child: const Text('Continue'),
                ),

                const SizedBox(height: 10),

                // Switch between Sign In and Register.
                TextButton(
                  onPressed: _saving
                      ? null
                      : () {
                          setState(() {
                            _isRegistering = !_isRegistering;
                            _saveError = null;
                          });
                        },
                  child: Text(
                    _isRegistering
                        ? 'Already have an account? Sign In'
                        : 'New user? Register',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
