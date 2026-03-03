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
  final _usernameCtrl   = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
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
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
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
          Row(
            children: [
              Expanded(child: TextField(controller: _usernameCtrl, decoration: SearchFieldDecoration.buildInputDecoration(labelText: 'Username', icon: Icons.alternate_email))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _emailCtrl, decoration: SearchFieldDecoration.buildInputDecoration(labelText: 'Email', icon: Icons.email_outlined))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _firstNameCtrl, decoration: SearchFieldDecoration.buildInputDecoration(labelText: 'Ime', icon: Icons.person_outline))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _lastNameCtrl, decoration: SearchFieldDecoration.buildInputDecoration(labelText: 'Prezime', icon: Icons.person_outline))),
            ],
          ),
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
            crossAxisCount: 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 2,
          ),
          itemCount: provider.users.length + (provider.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.users.length) {
              return const Center(child: CircularProgressIndicator());
            }
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
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: kPrimary.withOpacity(0.1),
                  child: Text(
                    _initials(user),
                    style: const TextStyle(
                        color: kPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.username,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(user.email,
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                AdminStatusBadge(
                  label: user.isActive ? 'Aktivan' : 'Neaktivan',
                  color: user.isActive ? Colors.green : Colors.red,
                  icon: user.isActive
                      ? Icons.check_circle
                      : Icons.cancel_outlined,
                ),
              ],
            ),
            const Divider(height: 32),
            // Info
            _infoRow(Icons.person_outline, 'Ime',
                '${user.firstName ?? ''} ${user.lastName ?? ''}'),
            _infoRow(Icons.email, 'Email', user.email),
            _infoRow(Icons.location_on_outlined, 'Adresa',
                '${user.address ?? 'N/A'} ${user.city ?? ''}'),
            const Spacer(),
            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditUserDialog(user, provider),
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                    label: const Text('UREDI',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        provider.toggleUserActive(userId: user.id, isActive: !user.isActive),
                    icon: Icon(
                        user.isActive ? Icons.lock_outline : Icons.lock_open,
                        size: 16),
                    label: Text(user.isActive ? 'BLOKIRAJ' : 'AKTIVIRAJ',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          user.isActive ? Colors.red : Colors.green,
                      side: BorderSide(
                          color: user.isActive ? Colors.red : Colors.green),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kPrimary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const Spacer(),
          Text(value.trim().isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _initials(User user) {
    final f = user.firstName?.isNotEmpty == true ? user.firstName![0] : '';
    final l = user.lastName?.isNotEmpty == true ? user.lastName![0] : '';
    return (f + l).toUpperCase();
  }

  void _showEditUserDialog(User user, UserProvider provider) {
    showDialog(
        context: context,
        builder: (_) => _EditUserDialog(user: user, provider: provider));
  }

  void _showAddUserDialog() {
    showDialog(
        context: context,
        builder: (_) => _AddUserDialog(
              onConfirm: (data) async {
                final ok = await Provider.of<UserProvider>(context, listen: false)
                    .createUser(
                  username: data['username'],
                  email: data['email'],
                  password: data['password'],
                  passwordConfirm: data['passwordConfirm'],
                  firstName: data['firstName'],
                  lastName: data['lastName'],
                  address: data['address'],
                  city: data['city'],
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
  final _c = <String, TextEditingController>{
    for (final k in ['username', 'email', 'password', 'passwordConfirm',
        'firstName', 'lastName', 'address', 'city'])
      k: TextEditingController()
  };
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in _c.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 560,
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
                    Expanded(child: AdminFormField(controller: _c['username']!, label: 'Korisničko ime', icon: Icons.alternate_email)),
                    const SizedBox(width: 12),
                    Expanded(child: AdminFormField(controller: _c['email']!, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: AdminFormField(controller: _c['password']!, label: 'Lozinka', icon: Icons.lock_outline, obscureText: true)),
                    const SizedBox(width: 12),
                    Expanded(child: AdminFormField(controller: _c['passwordConfirm']!, label: 'Potvrdi lozinku', icon: Icons.lock_outline, obscureText: true)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: AdminFormField(controller: _c['firstName']!, label: 'Ime', icon: Icons.person_outline)),
                    const SizedBox(width: 12),
                    Expanded(child: AdminFormField(controller: _c['lastName']!, label: 'Prezime', icon: Icons.person_outline)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: AdminFormField(controller: _c['address']!, label: 'Adresa (opcionalno)', icon: Icons.location_on_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: AdminFormField(controller: _c['city']!, label: 'Grad (opcionalno)', icon: Icons.location_city)),
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
    );
  }

  Future<void> _submit() async {
    final pass = _c['password']!.text;
    final confirm = _c['passwordConfirm']!.text;
    if (_c['username']!.text.trim().isEmpty) { AdminSnackBar.error(context, 'Username je obavezan.'); return; }
    if (_c['email']!.text.trim().isEmpty) { AdminSnackBar.error(context, 'Email je obavezan.'); return; }
    if (pass.isEmpty) { AdminSnackBar.error(context, 'Lozinka je obavezna.'); return; }
    if (pass != confirm) { AdminSnackBar.error(context, 'Lozinke se ne poklapaju.'); return; }

    setState(() => _isLoading = true);
    Navigator.pop(context);
    await widget.onConfirm({
      'username': _c['username']!.text.trim(),
      'email': _c['email']!.text.trim(),
      'password': pass,
      'passwordConfirm': confirm,
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
  late final _emailCtrl = TextEditingController(text: widget.user.email);
  late final _firstCtrl = TextEditingController(text: widget.user.firstName ?? '');
  late final _lastCtrl  = TextEditingController(text: widget.user.lastName ?? '');
  late final _addrCtrl  = TextEditingController(text: widget.user.address ?? '');
  late final _cityCtrl  = TextEditingController(text: widget.user.city ?? '');
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose(); _firstCtrl.dispose(); _lastCtrl.dispose();
    _addrCtrl.dispose(); _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AdminDialogHeader(
                icon: Icons.edit_outlined, title: 'Uredi korisnika'),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                AdminFormField(controller: _emailCtrl, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: AdminFormField(controller: _firstCtrl, label: 'Ime', icon: Icons.person_outline)),
                  const SizedBox(width: 12),
                  Expanded(child: AdminFormField(controller: _lastCtrl, label: 'Prezime', icon: Icons.person_outline)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: AdminFormField(controller: _addrCtrl, label: 'Adresa', icon: Icons.location_on_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: AdminFormField(controller: _cityCtrl, label: 'Grad', icon: Icons.location_city)),
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
    );
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final ok = await widget.provider.updateUser(
      userId: widget.user.id,
      email: _emailCtrl.text,
      firstName: _firstCtrl.text,
      lastName: _lastCtrl.text,
      address: _addrCtrl.text,
      city: _cityCtrl.text,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      AdminSnackBar.show(context, 'Korisnik je ažuriran', ok);
      if (ok) Navigator.pop(context);
    }
  }
}