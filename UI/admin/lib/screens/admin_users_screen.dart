import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addUsernameController = TextEditingController();
  final TextEditingController _addEmailController = TextEditingController();
  final TextEditingController _addPasswordController = TextEditingController();
  final TextEditingController _addPasswordConfirmController =
      TextEditingController();
  final TextEditingController _addFirstNameController = TextEditingController();
  final TextEditingController _addLastNameController = TextEditingController();
  final TextEditingController _addAddressController = TextEditingController();
  final TextEditingController _addCityController = TextEditingController();

  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).searchUsers();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addUsernameController.dispose();
    _addEmailController.dispose();
    _addPasswordController.dispose();
    _addPasswordConfirmController.dispose();
    _addFirstNameController.dispose();
    _addLastNameController.dispose();
    _addAddressController.dispose();
    _addCityController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = Provider.of<UserProvider>(context, listen: false);
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (provider.currentPage < provider.totalPages && !_isSearching) {
        provider.searchUsers(
          username: _usernameController.text.isEmpty
              ? null
              : _usernameController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          firstName: _firstNameController.text.isEmpty
              ? null
              : _firstNameController.text,
          lastName: _lastNameController.text.isEmpty
              ? null
              : _lastNameController.text,
          page: provider.currentPage + 1,
        );
      }
    }
  }

  Future<void> _performSearch() async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _isSearching = true);
    await provider.searchUsers(
      username: _usernameController.text.isEmpty
          ? null
          : _usernameController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      firstName: _firstNameController.text.isEmpty
          ? null
          : _firstNameController.text,
      lastName: _lastNameController.text.isEmpty
          ? null
          : _lastNameController.text,
    );
    setState(() => _isSearching = false);
  }

  void _clearSearch() {
    _usernameController.clear();
    _emailController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Svi korisnici',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSearchField(
                          _usernameController,
                          'Username',
                          Icons.alternate_email,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSearchField(
                          _emailController,
                          'Email',
                          Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSearchField(
                          _firstNameController,
                          'Ime',
                          Icons.person_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSearchField(
                          _lastNameController,
                          'Prezime',
                          Icons.person_outline,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Očisti filtre'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isSearching ? null : _performSearch,
                        icon: _isSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.search,
                                size: 18,
                                color: Colors.white,
                              ),
                        label: const Text(
                          'Pretraži',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showAddUserDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Dodaj korisnika'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: Consumer<UserProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.users.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.users.isEmpty) {
                    return const Center(
                      child: Text('Nema pronađenih korisnika.'),
                    );
                  }

                  return GridView.builder(
                    controller: _scrollController,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 2,
                        ),
                    itemCount:
                        provider.users.length + (provider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.users.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return _buildUserTile(provider.users[index], provider);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  child: Text(
                    _getInitials(user),
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(user.isActive),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(
              Icons.person_outline,
              "Ime",
              "${user.firstName ?? ''} ${user.lastName ?? ''}",
            ),
            _buildInfoRow(Icons.email, "Email", user.email),
            _buildInfoRow(
              Icons.location_on_outlined,
              "Adresa",
              "${user.address ?? 'N/A'} ${user.city ?? 'N/A'}",
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditUserDialog(user, provider),
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                    label: const Text(
                      'UREDI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleUserActive(user, provider),
                    icon: Icon(
                      user.isActive ? Icons.lock_outline : Icons.lock_open,
                      size: 16,
                    ),
                    label: Text(
                      user.isActive ? 'DEAKTIVIRAJ' : 'AKTIVIRAJ',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: user.isActive
                          ? Colors.red
                          : Colors.green,
                      side: BorderSide(
                        color: user.isActive ? Colors.red : Colors.green,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Widget _buildSearchField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Aktivan' : 'Neaktivan',
        style: TextStyle(
          color: isActive ? Colors.green[700] : Colors.red[700],
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6366F1)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const Spacer(),
          Text(
            value.trim().isEmpty ? "-" : value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _getInitials(User user) {
    final first = user.firstName?.isNotEmpty == true ? user.firstName![0] : '';
    final last = user.lastName?.isNotEmpty == true ? user.lastName![0] : '';
    return (first + last).toUpperCase();
  }

  void _showEditUserDialog(User user, UserProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _EditUserDialog(user: user, provider: provider),
    );
  }

  void _toggleUserActive(User user, UserProvider provider) {
    provider.toggleUserActive(userId: user.id, isActive: !user.isActive);
  }

  void _showAddUserDialog() {
    _addUsernameController.clear();
    _addEmailController.clear();
    _addPasswordController.clear();
    _addPasswordConfirmController.clear();
    _addFirstNameController.clear();
    _addLastNameController.clear();
    _addAddressController.clear();
    _addCityController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dodaj novog korisnika'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _addUsernameController,
                decoration: const InputDecoration(labelText: 'Korisničko ime'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addEmailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addPasswordController,
                decoration: const InputDecoration(labelText: 'Lozinka'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addPasswordConfirmController,
                decoration: const InputDecoration(labelText: 'Potvrdi lozinku'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addFirstNameController,
                decoration: const InputDecoration(labelText: 'Ime'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addLastNameController,
                decoration: const InputDecoration(labelText: 'Prezime'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addAddressController,
                decoration: const InputDecoration(
                  labelText: 'Adresa (opcionalno)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addCityController,
                decoration: const InputDecoration(
                  labelText: 'Grad (opcionalno)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_addPasswordController.text !=
                  _addPasswordConfirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lozinke se ne poklapaju'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              final provider = Provider.of<UserProvider>(
                context,
                listen: false,
              );

              final success = await provider.createUser(
                username: _addUsernameController.text,
                email: _addEmailController.text,
                password: _addPasswordController.text,
                passwordConfirm: _addPasswordConfirmController.text,
                firstName: _addFirstNameController.text,
                lastName: _addLastNameController.text,
                address: _addAddressController.text.isEmpty
                    ? null
                    : _addAddressController.text,
                city: _addCityController.text.isEmpty
                    ? null
                    : _addCityController.text,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Korisnik je kreiran' : 'Greška pri kreiranju',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Kreiraj'),
          ),
        ],
      ),
    );
  }
}

class _EditUserDialog extends StatefulWidget {
  final User user;
  final UserProvider provider;

  const _EditUserDialog({required this.user, required this.provider});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user.email);
    _firstNameController = TextEditingController(
      text: widget.user.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.user.lastName ?? '',
    );
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _cityController = TextEditingController(text: widget.user.city ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Uredi korisnika'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Ime',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Prezime',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresa',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'Grad',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Otkaži'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveUser,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Spremi'),
        ),
      ],
    );
  }

  Future<void> _saveUser() async {
    setState(() => _isLoading = true);
    try {
      final success = await widget.provider.updateUser(
        userId: widget.user.id,
        email: _emailController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        address: _addressController.text,
        city: _cityController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Korisnik je ažuriran' : 'Greška pri ažuriranju',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          Navigator.pop(context);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
