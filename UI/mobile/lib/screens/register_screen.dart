import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_strings.dart';
import '../constants/app_colors.dart';
import '../models/request_models.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  static final _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
  static final _usernameRegex = RegExp(r'^[A-Za-z0-9_\.]{3,30}$');
  static final _nameRegex = RegExp(r"^[A-Za-zÀ-žA-Ža-ž\s'\-]{2,50}$");
  static final _upperCase = RegExp(r'[A-Z]');
  static final _digit = RegExp(r'\d');
  static final _specialChar = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]');

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Korisničko ime je obavezno';
    if (!_usernameRegex.hasMatch(v.trim())) {
      return 'Korisničko ime mora imati 3-30 znakova i može sadržavati slova, brojeve, _ i .';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email je obavezan';
    if (!_emailRegex.hasMatch(v.trim())) {
      return 'Unesite validan email u formatu: korisnik@domena.tld';
    }
    return null;
  }

  String? _validateName(String? v, String fieldName) {
    if (v == null || v.trim().isEmpty) return '$fieldName je obavezno';
    if (!_nameRegex.hasMatch(v.trim())) {
      return '$fieldName smije sadržavati samo slova, razmak, apostrof i crticu (2-50 znakova)';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Lozinka je obavezna';
    if (v.length < 8) return 'Lozinka mora imati najmanje 8 znakova';
    if (!_upperCase.hasMatch(v)) return 'Lozinka mora imati najmanje jedno veliko slovo (A-Z)';
    if (!_digit.hasMatch(v)) return 'Lozinka mora imati najmanje jedan broj (0-9)';
    if (!_specialChar.hasMatch(v)) return 'Lozinka mora imati najmanje jedan poseban znak (npr. !@#)';
    return null;
  }

  String? _validatePasswordConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Potvrda lozinke je obavezna';
    if (v != _passwordController.text) return 'Potvrda lozinke mora biti identična lozinci';
    return null;
  }

  String? _validateOptionalCity(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length < 2) return 'Naziv grada mora imati najmanje 2 znaka';
    return null;
  }

  void _register(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      UserRegistrationRequest(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        address: _addressController.text.isEmpty
            ? null
            : _addressController.text.trim(),
        city: _cityController.text.isEmpty ? null : _cityController.text.trim(),
        password: _passwordController.text,
        passwordConfirm: _passwordConfirmController.text,
      ),
    );

    if (success) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Registracija neuspješna.',
          ),
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    bool? obscureToggle,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (_) {
        if (controller == _passwordController &&
            _passwordConfirmController.text.isNotEmpty) {
          _formKey.currentState?.validate();
        }
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  (obscureToggle ?? true)
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.primary,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                    const SizedBox(height: 48),

                    Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      AppStrings.register,
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    _buildTextField(
                      controller: _usernameController,
                      label: AppStrings.username,
                      icon: Icons.person,
                      validator: _validateUsername,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _firstNameController,
                            label: 'Ime',
                            icon: Icons.badge,
                            validator: (value) => _validateName(value, 'Ime'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _lastNameController,
                            label: 'Prezime',
                            icon: Icons.badge_outlined,
                            validator: (value) => _validateName(value, 'Prezime'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _addressController,
                      label: 'Adresa (opciono)',
                      icon: Icons.home,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _cityController,
                      label: 'Grad (opciono)',
                      icon: Icons.location_city,
                      validator: _validateOptionalCity,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _passwordController,
                      label: AppStrings.password,
                      icon: Icons.lock,
                      validator: _validatePassword,
                      obscureText: _obscurePassword,
                      obscureToggle: _obscurePassword,
                      onToggleObscure: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _passwordConfirmController,
                      label: 'Potvrdi lozinku',
                      icon: Icons.lock_outline,
                      validator: _validatePasswordConfirm,
                      obscureText: _obscurePasswordConfirm,
                      obscureToggle: _obscurePasswordConfirm,
                      onToggleObscure: () {
                        setState(
                          () => _obscurePasswordConfirm =
                              !_obscurePasswordConfirm,
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: authProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: () => _register(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                AppStrings.register,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Već imate račun? '),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            AppStrings.login,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
