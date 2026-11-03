import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komnotmorng2/viewmodels/login_vm.dart';
import 'package:komnotmorng2/views/widgets/auth_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final remember = true.obs;
  final signedIn = false.obs; // keeps the button locked until Home opens
  final LoginViewModel loginVm = Get.isRegistered<LoginViewModel>()
      ? Get.find<LoginViewModel>()
      : Get.put(LoginViewModel());

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  // ---------- Validators ----------

  String? validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter your password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // ---------- Action ----------

  Future<void> signIn() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) return;

    final scheme = Theme.of(context).colorScheme;
    await loginVm.login(email.text.trim(), password.text);

    if (loginVm.statusCode.value == '200') {
      signedIn.value = true;
      Get.snackbar(
        'Login Successful',
        loginVm.successMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: scheme.primaryContainer,
        colorText: scheme.onPrimaryContainer,
      );
      Future.delayed(const Duration(seconds: 1), () {
        Get.toNamed('/HomeScreen');
      });
    } else {
      Get.snackbar(
        'Login Failed',
        loginVm.errorMessage.value,
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
      title: 'Sign in\nto your\naccount',
      children: [
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => signIn(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        title: const Text('Remember me'),
                        value: remember.value,
                        onChanged: (v) => remember.value = v ?? false,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Obx(
                () => AuthButton(
                  label: 'Sign in',
                  onPressed: signIn,
                  loading: loginVm.isLoading.value || signedIn.value,
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: TextButton(
                  onPressed: () => Get.toNamed('/RegisterScreen'),
                  child: const Text('Create a new account'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}