import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/validators.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../routing/app_router.dart';
import '../../routing/route_names.dart';
import '../../widgets/auth_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _phone = TextEditingController();
  final _profileName = TextEditingController(); // company_name or business_name
  UserRole _role = UserRole.customer;
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _phone.dispose();
    _profileName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      username: _username.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      role: _role,
      phone: _phone.text.trim(),
      companyName: _role == UserRole.customer ? _profileName.text.trim() : "",
      businessName: _role == UserRole.supplier ? _profileName.text.trim() : "",
    );
    if (!mounted) return;
    if (ok) {
      if (_role == UserRole.supplier && !(auth.user?.isApproved ?? true)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Account created. A supplier account needs admin approval before you can submit quotations."),
        ));
      }
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.homeRouteFor(_role), (route) => false,
      );
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  const AuthHeader(title: "Create account", subtitle: "Join AutoPartsLink in a minute"),
                  Positioned(
                    top: 4, left: 4,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("I am a...", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SegmentedButton<UserRole>(
                    segments: const [
                      ButtonSegment(value: UserRole.customer, label: Text("Customer"), icon: Icon(Icons.person_outline)),
                      ButtonSegment(value: UserRole.supplier, label: Text("Supplier"), icon: Icon(Icons.storefront_outlined)),
                    ],
                    selected: {_role},
                    onSelectionChanged: (s) => setState(() => _role = s.first),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _username,
                    decoration: const InputDecoration(labelText: "Display name", prefixIcon: Icon(Icons.badge_outlined)),
                    validator: (v) => Validators.required(v, field: "Display name"),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined)),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Phone (optional)", prefixIcon: Icon(Icons.phone_outlined)),
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _profileName,
                    decoration: InputDecoration(
                      labelText: _role == UserRole.supplier ? "Business name" : "Company name (optional)",
                      prefixIcon: const Icon(Icons.apartment_outlined),
                      helperText: _role == UserRole.supplier ? "You can also set this up later from your profile" : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmPassword,
                    obscureText: _obscure,
                    decoration: const InputDecoration(labelText: "Confirm password", prefixIcon: Icon(Icons.lock_outline)),
                    validator: (v) => Validators.confirmPassword(v, _password.text),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: auth.loading ? null : _submit,
                    child: auth.loading
                        ? const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Create Account"),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed(RouteNames.login),
                    child: const Text("Already have an account? Log in"),
                  ),
                ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
