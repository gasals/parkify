import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';

class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({Key? key}) : super(key: key);

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _passwordController;
  late TextEditingController _passwordConfirmController;

  bool _showPassword = false;
  bool _showPasswordConfirm = false;
  bool _isLoading = false;

  static final _upperCase  = RegExp(r'[A-Z]');
  static final _digit      = RegExp(r'\d');
  static final _specialChar = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]');

  @override
  void initState() {
    super.initState();
    _passwordController        = TextEditingController();
    _passwordConfirmController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Lozinka je obavezna';
    if (v.length < 8) return 'Lozinka mora imati najmanje 8 znakova';
    if (!_upperCase.hasMatch(v)) return 'Lozinka mora sadržavati najmanje jedno veliko slovo';
    if (!_digit.hasMatch(v)) return 'Lozinka mora sadržavati najmanje jedan broj';
    if (!_specialChar.hasMatch(v)) return 'Lozinka mora sadržavati najmanje jedan poseban znak';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Potvrda lozinke je obavezna';
    if (v != _passwordController.text) return 'Lozinke se ne podudaraju';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Promijeni lozinku',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: Navigator.of(context).pop,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Zahtjevi za lozinku:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('• Najmanje 8 znakova', style: TextStyle(fontSize: 11)),
                    Text('• Najmanje jedno veliko slovo', style: TextStyle(fontSize: 11)),
                    Text('• Najmanje jedan broj', style: TextStyle(fontSize: 11)),
                    Text('• Najmanje jedan poseban znak (!@#\$...)', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                enabled: !_isLoading,
                validator: _validatePassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (_) {
                  if (_passwordConfirmController.text.isNotEmpty) {
                    _formKey.currentState?.validate();
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Nova lozinka',
                  prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.primary,
                    ),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordConfirmController,
                obscureText: !_showPasswordConfirm,
                enabled: !_isLoading,
                validator: _validateConfirm,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: 'Potvrdi lozinku',
                  prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPasswordConfirm ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.primary,
                    ),
                    onPressed: () =>
                        setState(() => _showPasswordConfirm = !_showPasswordConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : Navigator.of(context).pop,
                      child: const Text('Otkaži'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white)),
                            )
                          : const Text('Promijeni', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.changePassword(
        password: _passwordController.text,
        passwordConfirm: _passwordConfirmController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Lozinka uspješno promijenjena'
              : 'Došlo je do greške. Pokušajte ponovno.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ));
        if (success) Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Došlo je do greške. Pokušajte ponovno.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}