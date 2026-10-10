import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _green = Color(
    0xFF1D4ED8,
  ); // main blue (change to your logo color)
  static const _mint = Color(0xFFDCE7FF); // light blue circle

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _remember = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // ---- Validators ----
  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter your password';
    if (v.length < 6) return 'Password must be at least 6 characters';
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
      floatingLabelStyle: const TextStyle(color: _green),
      enabledBorder: border(Colors.grey.shade400),
      focusedBorder: border(_green, 2),
      errorBorder: border(Colors.red.shade600),
      focusedErrorBorder: border(Colors.red.shade600, 2),
    );
  }

  void _signIn() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      debugPrint('Sign in: ${_email.text.trim()}');
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
                color: _mint,
                shape: BoxShape.circle,
              ),
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
                      'Sign in\nto your\naccount',
                      style: TextStyle(
                        fontSize: 44,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        color: _green,
                      ),
                    ),
                    const SizedBox(height: 40),
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
                      obscureText: _hidden,
                      textInputAction: TextInputAction.done,

                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _signIn(),
                      decoration: _field('Password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(() => _hidden = !_hidden),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _remember,
                          activeColor: _green,
                          onChanged: (v) =>
                              setState(() => _remember = v ?? false),
                        ),
                        const Text('Remember me'),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(foregroundColor: _green),
                          child: const Text('Forgot password?'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _signIn,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(foregroundColor: _green),
                        child: const Text('Create a new account'),
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
