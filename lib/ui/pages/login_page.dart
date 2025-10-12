import 'dart:async';

import 'package:flutter/material.dart';
import 'package:omada/core/supabase/supabase_instance.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/utils/form_validators.dart';
import 'package:omada/core/controllers/auth_controller.dart';
import 'package:omada/core/theme/design_tokens.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  late final StreamSubscription<AuthState> _authStateSubscription;

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = AuthController(supabase);
    _authStateSubscription = _auth.onAuthStateChange().listen((event) {
      final session = event.session;
      if (session != null && mounted) {
        Navigator.of(context).pushReplacementNamed('/app');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Navigation handled by auth state listener
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      final Map<String, dynamic> data = {};

      // Include username in metadata if provided
      if (username.isNotEmpty) {
        data['username'] = username;
      }

      await _auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: data.isNotEmpty ? data : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created successfully! Please check your email to verify.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? value) => FormValidators.emailRequired(value);

  String? _validatePassword(String? value) =>
      FormValidators.passwordMinLength(value, min: 6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(OmadaTokens.space24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App branding
                const SizedBox(height: OmadaTokens.space32),
                Text(
                  'Welcome to Omada',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: OmadaTokens.space8),
                Text(
                  _isSignUp ? 'Create your account' : 'Sign in to your account',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: OmadaTokens.space48),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: OmadaTokens.space16),

                // Username field (only for sign up)
                if (_isSignUp) ...[
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      helperText:
                          'If empty, a unique username will be generated',
                    ),
                    textInputAction: TextInputAction.next,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: OmadaTokens.space16),
                ],

                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  validator: _validatePassword,
                  enabled: !_isLoading,
                  onFieldSubmitted: (_) => _isSignUp ? _signUp() : _signIn(),
                ),
                const SizedBox(height: OmadaTokens.space12),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final email = _emailController.text.trim();
                            if (email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Enter your email first'),
                                ),
                              );
                              return;
                            }
                            try {
                              await Supabase.instance.client.auth
                                  .resetPasswordForEmail(
                                    email,
                                    redirectTo: 'myapp://reset',
                                  );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password reset link sent. Check your email.',
                                  ),
                                ),
                              );
                            } on AuthException catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              );
                            } catch (_) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Something went wrong. Please try again.',
                                  ),
                                ),
                              );
                            }
                          },
                    child: const Text('Forgot password?'),
                  ),
                ),

                const SizedBox(height: OmadaTokens.space24),

                // Submit button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_isSignUp ? _signUp : _signIn),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                ),
                const SizedBox(height: OmadaTokens.space16),

                // Toggle sign up/sign in
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                            // Clear form when switching
                            _emailController.clear();
                            _passwordController.clear();
                            _usernameController.clear();
                          });
                        },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign In'
                        : 'Don\'t have an account? Sign Up',
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
