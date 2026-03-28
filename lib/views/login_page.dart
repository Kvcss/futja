import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/form_validators.dart';
import '../viewmodels/auth_view_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authViewModel = context.read<AuthViewModel>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isRegisterMode) {
      await authViewModel.register(email, password);
    } else {
      await authViewModel.signIn(email, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'images/futja_logo.png',
                        height: 300,
                        width: 380,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const Text(
                      'SEJA BEM-VINDO!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isRegisterMode
                          ? 'Crie sua conta para começar a jogar.'
                          : 'Entre para continuar',
                      style: const TextStyle(
                        color: AppColors.greyText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: FormValidators.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: FormValidators.validatePassword,
                    ),
                    const SizedBox(height: 24),
                    if (authViewModel.errorMessage != null) ...[
                      Text(
                        authViewModel.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authViewModel.isLoading ? null : _submit,
                        child: authViewModel.isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(_isRegisterMode ? 'Cadastrar' : 'Entrar'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: AppColors.border,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'ou',
                            style: TextStyle(color: AppColors.greyText),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: AppColors.border,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Login com Google em desenvolvimento.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: const Text('Entrar com o Google'),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        const Text(
                          'Se ainda não possui uma conta',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.greyText,
                          ),
                        ),
                        TextButton(
                          onPressed: authViewModel.isLoading
                              ? null
                              : () {
                            setState(() {
                              _isRegisterMode = !_isRegisterMode;
                            });
                          },
                          child: Text(
                            _isRegisterMode ? 'Já tenho conta' : 'Cadastre-se',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}