import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _blue = Color(0xFF1D4ED8); // same blue as login
  static const _lightBlue = Color(0xFFDCE7FF);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // ---- Validators (run only when "Create account" is pressed) ----
  // Rules follow the users table: name VARCHAR(100), email VARCHAR(255).
  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your name';
    if (v.length > 100) return 'Name must be 100 characters or less';
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email';
    if (v.length > 255) return 'Email must be 255 characters or less';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter a password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _password.text) return 'Passwords do not match';
    return null;
  }

  InputDecoration _field(String label) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      floatingLabelStyle: const TextStyle(color: _blue),
      enabledBorder: border(Colors.grey.shade400),
      focusedBorder: border(_blue, 2),
      errorBorder: border(Colors.red.shade600),
      focusedErrorBorder: border(Colors.red.shade600, 2),
    );
  }

  Widget _eye(bool hidden, VoidCallback onTap) {
    return IconButton(
      icon: Icon(hidden
          ? Icons.visibility_off_outlined
          : Icons.visibility_outlined),
      onPressed: onTap,
    );
  }

  void _register() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      // the server should hash it into users.password_hash.
      // role ('user'), status ('active') and timestamps use DB defaults.
      debugPrint('Register: ${_name.text.trim()} / ${_email.text.trim()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                  color: _lightBlue, shape: BoxShape.circle),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 80, 28, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create\nyour\naccount',
                      style: TextStyle(
                        fontSize: 44,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        color: _blue,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _name,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: _validateName,
                      decoration: _field('Full name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      decoration: _field('Email'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      textInputAction: TextInputAction.next,
                      validator: _validatePassword,
                      decoration: _field('Password').copyWith(
                        suffixIcon: _eye(_hidePassword,
                            () => setState(() => _hidePassword = !_hidePassword)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _hideConfirm,
                      textInputAction: TextInputAction.done,
                      validator: _validateConfirm,
                      onFieldSubmitted: (_) => _register(),
                      decoration: _field('Confirm password').copyWith(
                        suffixIcon: _eye(_hideConfirm,
                            () => setState(() => _hideConfirm = !_hideConfirm)),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _register,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Create account',
                                style: TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w600)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.maybePop(context),
                        style: TextButton.styleFrom(foregroundColor: _blue),
                        child: const Text('Already have an account? Sign in'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}