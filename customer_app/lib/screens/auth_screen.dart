import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String get _formattedPhone {
    final phone = _phoneController.text.trim();
    if (phone.startsWith('+')) return phone;
    return '+91$phone';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final phone = _formattedPhone;
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    try {
      if (_isLogin) {
        final user = await AuthService().loginUser(phone, password);
        if (user == null) {
          setState(() {
            _error = 'Invalid credentials or user not found.';
            _isLoading = false;
          });
          return;
        }
      } else {
        await AuthService().registerUser(
          name: name,
          mobile: phone,
          password: password,
        );
      }
      
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
      
    } catch (e) {
      if (!mounted) return;
      
      // Basic translation of Postgrest errors (e.g., unique constraint violation for phone)
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('unique') || errorStr.contains('already registered') || errorStr.contains('duplicate')) {
         setState(() {
           _error = 'Phone number is already registered. Please login.';
         });
      } else {
        setState(() {
          _error = 'An unexpected error occurred. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, color: Theme.of(context).primaryColor, size: 64),
                const SizedBox(height: 24),
                Text(
                  _isLogin ? 'Welcome Back' : 'Create Account',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Login to continue' : 'Sign up to get started',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                
                // Full Name Field (Sign Up Only)
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Mobile Number Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    hintText: '10-digit number',
                    prefixText: '+91 ',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter mobile number';
                    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                      return 'Enter valid 10-digit number';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.password, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter password';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                if (_error != null) ...[
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 12),
                ],
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(_isLogin ? 'Login' : 'Sign Up'),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Toggle Login / Sign Up
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _error = null;
                      _formKey.currentState?.reset();
                      _nameController.clear();
                      _phoneController.clear();
                      _passwordController.clear();
                    });
                  },
                  child: Text(
                    _isLogin
                        ? 'Don\'t have an account? Sign Up'
                        : 'Already have an account? Login',
                    style: TextStyle(color: Theme.of(context).primaryColor),
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
