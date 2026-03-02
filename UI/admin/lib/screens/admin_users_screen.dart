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
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

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
    super.dispose();
  }

  void _onScroll() {
    final provider = Provider.of<UserProvider>(context, listen: false);
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (provider.currentPage < provider.totalPages && !_isSearching) {
        provider.searchUsers(
          username: _getTextOrNull(_usernameController),
          email: _getTextOrNull(_emailController),
          firstName: _getTextOrNull(_firstNameController),
          lastName: _getTextOrNull(_lastNameController),
          page: provider.currentPage + 1,
        );
      }
    }
  }

  Future<void> _performSearch() async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _isSearching = true);
    await provider.searchUsers(
      username: _getTextOrNull(_usernameController),
      email: _getTextOrNull(_emailController),
      firstName: _getTextOrNull(_firstNameController),
      lastName: _getTextOrNull(_lastNameController),
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

  String? _getTextOrNull(TextEditingController controller) {
    return controller.text.isEmpty ? null : controller.text;
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
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CommonButtons.buildClearButton(onPressed: _clearSearch),
              const SizedBox(width: 12),
              CommonButtons.buildSearchButton(
                onPressed: _performSearch,
                isLoading: _isSearching,
              ),
              const SizedBox(width: 12),
              CommonButtons.buildAddButton(
                onPressed: _showAddUserDialog,
                label: 'Dodaj korisnika',
              ),
            ],
          ),
        ],
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
      decoration: SearchFieldDecoration.buildInputDecoration(
        labelText: label,
        icon: icon,
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
            _buildUserHeader(user),
            const Divider(height: 32),
            _buildUserInfo(user),
            const Spacer(),
            _buildUserActions(user, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(User user) {
    return Row(
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
    );
  }

  Widget _buildUserInfo(User user) {
    return Column(
      children: [
        _buildInfoRow(
          Icons.person_outline,
          'Ime',
          '${user.firstName ?? ''} ${user.lastName ?? ''}',
        ),
        _buildInfoRow(Icons.email, 'Email', user.email),
        _buildInfoRow(
          Icons.location_on_outlined,
          'Adresa',
          '${user.address ?? 'N/A'} ${user.city ?? 'N/A'}',
        ),
      ],
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
            value.trim().isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
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

  Widget _buildUserActions(User user, UserProvider provider) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showEditUserDialog(user, provider),
            icon: const Icon(Icons.edit, size: 16, color: Colors.white),
            label: const Text(
              'UREDI',
              style: TextStyle(color: Colors.white, fontSize: 11),
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
              user.isActive ? 'BLOKIRAJ' : 'AKTIVIRAJ',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: user.isActive ? Colors.red : Colors.green,
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
    final controllers = <String, TextEditingController>{
      'username': TextEditingController(),
      'email': TextEditingController(),
      'password': TextEditingController(),
      'passwordConfirm': TextEditingController(),
      'firstName': TextEditingController(),
      'lastName': TextEditingController(),
      'address': TextEditingController(),
      'city': TextEditingController(),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dodaj novog korisnika'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(controllers['username']!, 'Korisničko ime'),
              _buildDialogTextField(
                controllers['email']!,
                'Email',
                TextInputType.emailAddress,
              ),
              _buildDialogTextField(
                controllers['password']!,
                'Lozinka',
                TextInputType.text,
                true,
              ),
              _buildDialogTextField(
                controllers['passwordConfirm']!,
                'Potvrdi lozinku',
                TextInputType.text,
                true,
              ),
              _buildDialogTextField(controllers['firstName']!, 'Ime'),
              _buildDialogTextField(controllers['lastName']!, 'Prezime'),
              _buildDialogTextField(
                controllers['address']!,
                'Adresa (opcionalno)',
              ),
              _buildDialogTextField(controllers['city']!, 'Grad (opcionalno)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => _submitCreateUser(controllers),
            child: const Text('Kreiraj'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(
    TextEditingController controller,
    String label, [
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  void _submitCreateUser(Map<String, TextEditingController> controllers) {
    final password = controllers['password']!.text;
    final confirmPassword = controllers['passwordConfirm']!.text;

    if (password != confirmPassword) {
      SnackBarHelper.showError(context, 'Lozinke se ne poklapaju');
      return;
    }

    Navigator.pop(context);
    final provider = Provider.of<UserProvider>(context, listen: false);

    provider
        .createUser(
          username: controllers['username']!.text,
          email: controllers['email']!.text,
          password: password,
          passwordConfirm: confirmPassword,
          firstName: controllers['firstName']!.text,
          lastName: controllers['lastName']!.text,
          address: controllers['address']!.text.isEmpty
              ? null
              : controllers['address']!.text,
          city: controllers['city']!.text.isEmpty
              ? null
              : controllers['city']!.text,
        )
        .then((success) {
          if (mounted) {
            SnackBarHelper.showMessage(context, 'Korisnik je kreiran', success);
          }
        });
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
            _buildTextField(_emailController, 'Email'),
            _buildTextField(_firstNameController, 'Ime'),
            _buildTextField(_lastNameController, 'Prezime'),
            _buildTextField(_addressController, 'Adresa'),
            _buildTextField(_cityController, 'Grad'),
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

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
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
        SnackBarHelper.showMessage(context, 'Korisnik je ažuriran', success);
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
