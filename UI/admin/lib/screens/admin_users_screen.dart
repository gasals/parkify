import 'package:admin/widgets/admin_dialog_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../widgets/common_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final ScrollController _scrollController = ScrollController();
  final _usernameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Provider.of<UserProvider>(context, listen: false).searchUsers();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _usernameCtrl.dispose(); _emailCtrl.dispose();
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final p = Provider.of<UserProvider>(context, listen: false);
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (p.currentPage < p.totalPages && !_isSearching) {
        p.searchUsers(
          username: _v(_usernameCtrl), email: _v(_emailCtrl),
          firstName: _v(_firstNameCtrl), lastName: _v(_lastNameCtrl),
          page: p.currentPage + 1,
        );
      }
    }
  }

  Future<void> _performSearch() async {
    setState(() => _isSearching = true);
    await Provider.of<UserProvider>(context, listen: false).searchUsers(
      username: _v(_usernameCtrl), email: _v(_emailCtrl),
      firstName: _v(_firstNameCtrl), lastName: _v(_lastNameCtrl),
    );
    setState(() => _isSearching = false);
  }

  void _clearSearch() {
    _usernameCtrl.clear(); _emailCtrl.clear();
    _firstNameCtrl.clear(); _lastNameCtrl.clear();
    _performSearch();
  }

  String? _v(TextEditingController c) => c.text.isEmpty ? null : c.text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader.build(title: 'Svi korisnici'),
            const SizedBox(height: 24),
            _buildSearchContainer(),
            const SizedBox(height: 24),
            Expanded(child: _buildUsersList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchContainer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: SearchContainerStyle.buildDecoration(),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: TextField(controller: _usernameCtrl, decoration: SearchFieldDecoration.buildInputDecoration(labelText: 'Username', icon: Icons.alternate_email))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _emailCtrl, decoration: SearchFieldDecoration.buildInputDecoration(labelText: 'Email', icon: Icons.email_outlined))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _firstNameCtrl, decoration: SearchFieldDecoration.buildInputDecoration(labelText: 'Ime', icon: Icons.person_outline))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _lastNameCtrl, decoration: SearchFieldDecoration.buildInputDecoration(labelText: 'Prezime', icon: Icons.person_outline))),
          ]),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CommonButtons.buildClearButton(onPressed: _clearSearch),
              const SizedBox(width: 12),
              CommonButtons.buildSearchButton(onPressed: _performSearch, isLoading: _isSearching),
              const SizedBox(width: 12),
              CommonButtons.buildAddButton(onPressed: _showAddUserDialog, label: 'Dodaj korisnika'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.users.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.users.isEmpty) {
          return const Center(child: Text('Nema pronađenih korisnika.'));
        }
        return GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 2,
          ),
          itemCount: provider.users.length + (provider.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.users.length) return const Center(child: CircularProgressIndicator());
            return _buildUserTile(provider.users[index], provider);
          },
        );
      },
    );
  }

  Widget _buildUserTile(User user, UserProvider provider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: kPrimary.withOpacity(0.1),
                child: Text(_initials(user),
                    style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.username,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(user.email,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ],
              )),
              AdminStatusBadge(
                label: user.isActive ? 'Aktivan' : 'Neaktivan',
                color: user.isActive ? Colors.green : Colors.red,
                icon: user.isActive ? Icons.check_circle : Icons.cancel_outlined,
              ),
            ]),
            const Divider(height: 32),
            _infoRow(Icons.person_outline, 'Ime', '${user.firstName ?? ''} ${user.lastName ?? ''}'),
            _infoRow(Icons.email, 'Email', user.email),
            _infoRow(Icons.location_on_outlined, 'Adresa', '${user.address ?? 'N/A'} ${user.city ?? ''}'),
            const Spacer(),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showEditUserDialog(user, provider),
                  icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                  label: const Text('UREDI', style: TextStyle(color: Colors.white, fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => provider.toggleUserActive(userId: user.id, isActive: !user.isActive),
                  icon: Icon(user.isActive ? Icons.lock_outline : Icons.lock_open, size: 16),
                  label: Text(user.isActive ? 'BLOKIRAJ' : 'AKTIVIRAJ',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: user.isActive ? Colors.red : Colors.green,
                    side: BorderSide(color: user.isActive ? Colors.red : Colors.green),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: kPrimary),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const Spacer(),
        Text(value.trim().isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  String _initials(User user) {
    final f = user.firstName?.isNotEmpty == true ? user.firstName![0] : '';
    final l = user.lastName?.isNotEmpty == true ? user.lastName![0] : '';
    return (f + l).toUpperCase();
  }

  void _showEditUserDialog(User user, UserProvider provider) {
    showDialog(context: context,
        builder: (_) => _EditUserDialog(user: user, provider: provider));
  }

  void _showAddUserDialog() {
    showDialog(
        context: context,
        builder: (_) => _AddUserDialog(
              onConfirm: (data) async {
                final ok = await Provider.of<UserProvider>(context, listen: false).createUser(
                  username: data['username'], email: data['email'],
                  password: data['password'], passwordConfirm: data['passwordConfirm'],
                  firstName: data['firstName'], lastName: data['lastName'],
                  address: data['address'], city: data['city'],
                );
                if (mounted) AdminSnackBar.show(context, 'Korisnik je kreiran', ok);
              },
            ));
  }
}

// ─── Add User Dialog ───────────────────────────────────────────────────────────

class _AddUserDialog extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onConfirm;
  const _AddUserDialog({required this.onConfirm});

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();

  final _c = <String, TextEditingController>{
    for (final k in ['username', 'email', 'password', 'passwordConfirm',
        'firstName', 'lastName', 'address', 'city'])
      k: TextEditingController()
  };
  bool _isLoading = false;

  static final _emailRegex    = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
  static final _usernameRegex = RegExp(r'^[A-Za-z0-9_\.]{3,30}$');
  static final _nameRegex     = RegExp(r"^[A-Za-zÀ-žA-Ža-ž\s'\-]{2,50}$");
  static final _upperCase     = RegExp(r'[A-Z]');
  static final _digit         = RegExp(r'\d');
  static final _specialChar   = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]');

  @override
  void dispose() {
    for (final c in _c.values) c.dispose();
    super.dispose();
  }

  String? _reqUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Korisničko ime je obavezno';
    if (!_usernameRegex.hasMatch(v.trim())) return 'Dozvoljena su slova, brojevi, _ i . (3–30 znakova)';
    return null;
  }

  String? _reqEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email je obavezan';
    if (!_emailRegex.hasMatch(v.trim())) return 'Unesite ispravan email';
    return null;
  }

  String? _reqPassword(String? v) {
    if (v == null || v.isEmpty) return 'Lozinka je obavezna';
    if (v.length < 8) return 'Najmanje 8 znakova';
    if (!_upperCase.hasMatch(v)) return 'Najmanje jedno veliko slovo';
    if (!_digit.hasMatch(v)) return 'Najmanje jedan broj';
    if (!_specialChar.hasMatch(v)) return 'Najmanje jedan poseban znak';
    return null;
  }

  String? _reqConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Potvrda lozinke je obavezna';
    if (v != _c['password']!.text) return 'Lozinke se ne podudaraju';
    return null;
  }

  String? _reqName(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label je obavezno';
    if (!_nameRegex.hasMatch(v.trim())) return '$label sadrži nedozvoljene znakove (2–50 znakova)';
    return null;
  }

  String? _optCity(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length < 2) return 'Naziv grada mora imati najmanje 2 znaka';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AdminDialogHeader(
                  icon: Icons.person_add_outlined,
                  title: 'Dodaj novog korisnika'),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: _field('username', 'Korisničko ime', Icons.alternate_email, validator: _reqUsername)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('email', 'Email', Icons.email_outlined, keyboard: TextInputType.emailAddress, validator: _reqEmail)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _field('password', 'Lozinka', Icons.lock_outline, obscure: true, validator: _reqPassword,
                          onChange: (_) { if (_c['passwordConfirm']!.text.isNotEmpty) _formKey.currentState?.validate(); })),
                      const SizedBox(width: 12),
                      Expanded(child: _field('passwordConfirm', 'Potvrdi lozinku', Icons.lock_outline, obscure: true, validator: _reqConfirm)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _field('firstName', 'Ime', Icons.person_outline, validator: (v) => _reqName(v, 'Ime'))),
                      const SizedBox(width: 12),
                      Expanded(child: _field('lastName', 'Prezime', Icons.person_outline, validator: (v) => _reqName(v, 'Prezime'))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _field('address', 'Adresa (opcionalno)', Icons.location_on_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('city', 'Grad (opcionalno)', Icons.location_city, validator: _optCity)),
                    ]),
                  ]),
                ),
              ),
              AdminDialogFooter(children: [
                const AdminCancelButton(),
                const SizedBox(width: 12),
                AdminPrimaryButton(
                  label: _isLoading ? 'Kreiranje...' : 'Kreiraj korisnika',
                  icon: Icons.person_add,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String key,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    String? Function(String?)? validator,
    void Function(String)? onChange,
  }) {
    return TextFormField(
      controller: _c[key],
      keyboardType: keyboard,
      obscureText: obscure,
      enabled: !_isLoading,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: onChange,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    Navigator.pop(context);
    await widget.onConfirm({
      'username': _c['username']!.text.trim(),
      'email': _c['email']!.text.trim(),
      'password': _c['password']!.text,
      'passwordConfirm': _c['passwordConfirm']!.text,
      'firstName': _c['firstName']!.text.trim(),
      'lastName': _c['lastName']!.text.trim(),
      'address': _c['address']!.text.isEmpty ? null : _c['address']!.text.trim(),
      'city': _c['city']!.text.isEmpty ? null : _c['city']!.text.trim(),
    });
  }
}

// ─── Edit User Dialog ──────────────────────────────────────────────────────────

class _EditUserDialog extends StatefulWidget {
  final User user;
  final UserProvider provider;
  const _EditUserDialog({required this.user, required this.provider});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();

  late final _emailCtrl = TextEditingController(text: widget.user.email);
  late final _firstCtrl = TextEditingController(text: widget.user.firstName ?? '');
  late final _lastCtrl  = TextEditingController(text: widget.user.lastName ?? '');
  late final _addrCtrl  = TextEditingController(text: widget.user.address ?? '');
  late final _cityCtrl  = TextEditingController(text: widget.user.city ?? '');
  bool _isLoading = false;

  static final _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
  static final _nameRegex  = RegExp(r"^[A-Za-zÀ-žA-Ža-ž\s'\-]{2,50}$");

  @override
  void dispose() {
    _emailCtrl.dispose(); _firstCtrl.dispose(); _lastCtrl.dispose();
    _addrCtrl.dispose(); _cityCtrl.dispose();
    super.dispose();
  }

  String? _reqEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email je obavezan';
    if (!_emailRegex.hasMatch(v.trim())) return 'Unesite ispravan email';
    return null;
  }

  String? _reqName(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label je obavezno';
    if (!_nameRegex.hasMatch(v.trim())) return '$label sadrži nedozvoljene znakove';
    return null;
  }

  String? _optCity(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length < 2) return 'Naziv grada mora imati najmanje 2 znaka';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AdminDialogHeader(
                  icon: Icons.edit_outlined, title: 'Uredi korisnika'),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  _formField(_emailCtrl, 'Email', Icons.email_outlined,
                      keyboard: TextInputType.emailAddress,
                      validator: _reqEmail),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _formField(_firstCtrl, 'Ime', Icons.person_outline,
                        validator: (v) => _reqName(v, 'Ime'))),
                    const SizedBox(width: 12),
                    Expanded(child: _formField(_lastCtrl, 'Prezime', Icons.person_outline,
                        validator: (v) => _reqName(v, 'Prezime'))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _formField(_addrCtrl, 'Adresa', Icons.location_on_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _formField(_cityCtrl, 'Grad', Icons.location_city,
                        validator: _optCity)),
                  ]),
                ]),
              ),
              AdminDialogFooter(children: [
                const AdminCancelButton(),
                const SizedBox(width: 12),
                AdminPrimaryButton(
                  label: _isLoading ? 'Sprema...' : 'Spremi izmjene',
                  icon: Icons.save_outlined,
                  isLoading: _isLoading,
                  onPressed: _save,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      enabled: !_isLoading,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final ok = await widget.provider.updateUser(
      userId: widget.user.id,
      email: _emailCtrl.text.trim(),
      firstName: _firstCtrl.text.trim(),
      lastName: _lastCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => _isLoading = false);
      AdminSnackBar.show(context, 'Korisnik je ažuriran', ok);
      if (ok) Navigator.pop(context);
    }
  }
}