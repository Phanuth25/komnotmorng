import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komnotmorng2/viewmodels/register_vm.dart';
import 'package:komnotmorng2/views/widgets/auth_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  final RegisterViewModel registerVm = Get.find<RegisterViewModel>();

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  // ---------- Validators (run when "Create account" is pressed) ----------
  // Rules follow the users table: name VARCHAR(100), email VARCHAR(255).

  String? validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your name';
    if (v.length > 100) return 'Name must be 100 characters or less';
    return null;
  }

  String? validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email';
    if (v.length > 255) return 'Email must be 255 characters or less';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter a password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password.text) return 'Passwords do not match';
    return null;
  }

  // ---------- Action ----------

  Future<void> register() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) return;

    final scheme = Theme.of(context).colorScheme;
    // the server hashes the password into users.password_hash
    await registerVm.register(
      name.text.trim(),
      email.text.trim(),
      password.text,
    );

    final code = registerVm.statusCode.value;
    final error = registerVm.errorMessage.value;

    if (code == '201') {
      Get.snackbar(
        'Success',
        registerVm.successMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: scheme.primaryContainer,
        colorText: scheme.onPrimaryContainer,
      );
      Get.offNamed('/LoginScreen');
    } else if (code == '409') {
      Get.snackbar(
        'Email Already Exists',
        error.isEmpty ? 'This email is already registered.' : error,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: scheme.errorContainer,
        colorText: scheme.onErrorContainer,
      );
    } else {
      Get.snackbar(
        'Error',
        error.isEmpty ? 'Something went wrong. Please try again.' : error,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: scheme.errorContainer,
        colorText: scheme.onErrorContainer,
      );
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Create\nyour\naccount',
      children: [
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: name,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: validateName,
                decoration: authDecoration(context, 'Full name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: validateEmail,
                decoration: authDecoration(context, 'Email'),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: password,
                label: 'Password',
                validator: validatePassword,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: confirm,
                label: 'Confirm password',
                validator: validateConfirm,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => register(),
              ),
              const SizedBox(height: 28),
              Obx(
                () => AuthButton(
                  label: 'Create account',
                  onPressed: register,
                  loading: registerVm.isLoading.value,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: const Text('Already have an account? Sign in'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}