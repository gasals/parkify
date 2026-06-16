import 'package:admin/widgets/admin_dialog_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../providers/notification_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/common_widgets.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends State<AdminNotificationsScreen> {
  static const Map<int, String> _notificationTypeLabels = {
    _NotificationTypes.reservationConfirmed: 'Uspjeh rezervacije',
    _NotificationTypes.reservationReminder: 'Podsjetnik',
    _NotificationTypes.paymentSuccess: 'Plaćanje',
    _NotificationTypes.paymentFailure: 'Greška',
    _NotificationTypes.availabilityNotice: 'Parking zona',
    _NotificationTypes.specialOffer: 'Ponuda',
    _NotificationTypes.reservationCancelled: 'Otkazivanje',
    _NotificationTypes.checkInReminder: 'Prijava',
    _NotificationTypes.parkingFull: 'Blokada',
  };

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _userSearchCtrl = TextEditingController();
  User? _selectedUser;
  bool? _filterRead;
  int? _filterType;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NotificationProvider>(context, listen: false)
            .fetchNotifications();
        Provider.of<UserProvider>(context, listen: false).searchUsers();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _userSearchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNextPage(userId: _selectedUser?.id, isRead: _filterRead);
    }
  }

  void _applyFilter(bool? isRead) {
    setState(() => _filterRead = isRead);
    Provider.of<NotificationProvider>(context, listen: false)
        .fetchNotifications(userId: _selectedUser?.id, isRead: isRead);
  }

  Future<void> _performSearch() async {
    await Provider.of<NotificationProvider>(context, listen: false)
        .fetchNotifications(userId: _selectedUser?.id, isRead: _filterRead);
  }

  Future<void> _clearFilters() async {
    setState(() {
      _selectedUser = null;
      _filterRead = null;
      _filterType = null;
    });
    _userSearchCtrl.clear();
    await Provider.of<NotificationProvider>(context, listen: false)
        .fetchNotifications();
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
            PageHeader.build(title: 'Notifikacije'),
            const SizedBox(height: 24),
            _buildToolbar(),
            const SizedBox(height: 24),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: SearchContainerStyle.buildDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildUserAutocomplete()),
              const SizedBox(width: 12),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int?>(
                  initialValue: _filterType,
                  isExpanded: true,
                  decoration: SearchFieldDecoration.buildInputDecoration(
                    labelText: 'Tip notifikacije',
                    icon: Icons.notifications_active_outlined,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Svi tipovi', style: TextStyle(fontSize: 13)),
                    ),
                    ..._notificationTypeLabels.entries.map(
                      (entry) => DropdownMenuItem<int?>(
                        value: entry.key,
                        child: Text(entry.value, style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _filterType = value),
                ),
              ),
              const SizedBox(width: 12),
              CommonButtons.buildClearButton(onPressed: _clearFilters),
              const SizedBox(width: 12),
              CommonButtons.buildSearchButton(
                onPressed: _performSearch,
                isLoading: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _FilterPill(label: 'Sve', selected: _filterRead == null, onTap: () => _applyFilter(null)),
              const SizedBox(width: 8),
              _FilterPill(label: 'Nepročitane', selected: _filterRead == false, onTap: () => _applyFilter(false), color: kDanger),
              const SizedBox(width: 8),
              _FilterPill(label: 'Pročitane', selected: _filterRead == true, onTap: () => _applyFilter(true), color: kSuccess),
              const Spacer(),
              CommonButtons.buildAddButton(
                onPressed: () => _showSendDialog(toAll: false),
                label: 'Pošalji korisniku',
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showSendDialog(toAll: true),
                icon: const Icon(Icons.campaign_outlined, size: 18, color: Colors.white),
                label: const Text('Pošalji svima',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSuccess,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserAutocomplete() {
    return Consumer<UserProvider>(
      builder: (context, provider, _) => Autocomplete<User>(
        optionsBuilder: (value) {
          if (value.text.isEmpty) return const Iterable<User>.empty();
          return provider.users.where((user) =>
              user.username.toLowerCase().contains(value.text.toLowerCase()) ||
              user.email.toLowerCase().contains(value.text.toLowerCase()));
        },
        displayStringForOption: (user) => '${user.username} (${user.email})',
        onSelected: (user) {
          _userSearchCtrl.text = '${user.username} (${user.email})';
          setState(() => _selectedUser = user);
        },
        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
          controller.text = _userSearchCtrl.text;
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
          return TextField(
            controller: controller,
            focusNode: focusNode,
            onEditingComplete: onEditingComplete,
            onChanged: (value) async {
              _userSearchCtrl.text = value;
              if (_selectedUser != null &&
                  value != '${_selectedUser!.username} (${_selectedUser!.email})') {
                setState(() => _selectedUser = null);
              }
              if (value.isNotEmpty) {
                await provider.searchUsers(username: value, pageSize: 1000);
              }
            },
            decoration: SearchFieldDecoration.buildInputDecoration(
              labelText: 'Korisnik',
              icon: Icons.person_outline,
            ),
          );
        },
      ),
    );
  }

  Widget _buildList() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final visibleNotifications = _filterType == null
            ? provider.notifications
            : provider.notifications
                .where((notification) => notification.type == _filterType)
                .toList();

        if (provider.isLoading && provider.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (visibleNotifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('Nema notifikacija za odabrane filtere',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              ],
            ),
          );
        }
        return GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 2.0,
          ),
          itemCount:
              visibleNotifications.length + (provider.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == visibleNotifications.length) {
              return const Center(child: CircularProgressIndicator());
            }
            final userProvider = context.read<UserProvider>();
            final user = userProvider.users.cast<User?>().firstWhere(
                  (item) => item?.id == visibleNotifications[index].userId,
                  orElse: () => null,
                );
            final username = user?.username ?? 'Korisnik #${visibleNotifications[index].userId}';
            return _NotificationCard(
              notification: visibleNotifications[index],
              username: username,
            );
          },
        );
      },
    );
  }

  void _showSendDialog({required bool toAll}) {
    showDialog(context: context,
        builder: (_) => _SendNotificationDialog(toAll: toAll));
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final String username;
  const _NotificationCard({required this.notification, required this.username});

  static const Map<int, ({IconData icon, Color color})> _typeData = {
    _NotificationTypes.reservationConfirmed: (icon: Icons.check_circle_outline, color: Color(0xFF10B981)),
    _NotificationTypes.reservationReminder: (icon: Icons.alarm_outlined, color: Color(0xFFF59E0B)),
    _NotificationTypes.paymentSuccess: (icon: Icons.payment_outlined, color: Color(0xFF3B82F6)),
    _NotificationTypes.paymentFailure: (icon: Icons.error_outline, color: Color(0xFFEF4444)),
    _NotificationTypes.availabilityNotice: (icon: Icons.local_parking, color: Color(0xFF6366F1)),
    _NotificationTypes.specialOffer: (icon: Icons.local_offer_outlined, color: Color(0xFFF59E0B)),
    _NotificationTypes.reservationCancelled: (icon: Icons.cancel_outlined, color: Color(0xFFEF4444)),
    _NotificationTypes.checkInReminder: (icon: Icons.login_outlined, color: Color(0xFF14B8A6)),
    _NotificationTypes.parkingFull: (icon: Icons.block_outlined, color: Colors.grey),
  };

  @override
  Widget build(BuildContext context) {
    final td = _typeData[notification.type] ??
      (icon: Icons.notifications_outlined, color: Colors.grey);
    final tIcon = td.icon;
    final tColor = td.color;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: notification.isRead
              ? Colors.grey[200]!
              : tColor.withOpacity(0.3),
          width: notification.isRead ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(tIcon, color: tColor, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.w500
                          : FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _ChannelBadge(channel: notification.channel),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                notification.message,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.person_outline, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(username,
                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ]),
                Row(children: [
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: notification.isRead
                          ? Colors.grey[300]
                          : kDanger,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(_fmtDate(notification.created),
                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

class _ChannelBadge extends StatelessWidget {
  final int channel;
  const _ChannelBadge({required this.channel});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (channel) {
      2 => ('Email', const Color(0xFF3B82F6)),
      3 => ('Oboje', const Color(0xFF8B5CF6)),
      _ => ('In-App', kPrimary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = kPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: selected ? 0 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : color)),
      ),
    );
  }
}

// ─── Send Notification Dialog ─────────────────────────────────────────────────

class _SendNotificationDialog extends StatefulWidget {
  final bool toAll;
  const _SendNotificationDialog({required this.toAll});

  @override
  State<_SendNotificationDialog> createState() =>
      _SendNotificationDialogState();
}

class _SendNotificationDialogState
    extends State<_SendNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _messageCtrl = TextEditingController();

  int _selectedType = _NotificationTypes.reservationConfirmed;
  int _selectedChannel = _NotificationChannels.inApp;
  int? _selectedUserId;
  bool _isLoading = false;

  static const _types = [
    (_NotificationTypes.reservationConfirmed, 'Potvrda rezervacije', Icons.check_circle_outline),
    (_NotificationTypes.reservationReminder, 'Podsjetnik za rezervaciju', Icons.alarm_outlined),
    (_NotificationTypes.paymentSuccess, 'Plaćanje uspješno', Icons.payment_outlined),
    (_NotificationTypes.paymentFailure, 'Plaćanje neuspješno', Icons.error_outline),
    (_NotificationTypes.availabilityNotice, 'Obavijest o dostupnosti', Icons.local_parking),
    (_NotificationTypes.specialOffer, 'Posebna ponuda', Icons.local_offer_outlined),
    (_NotificationTypes.reservationCancelled, 'Otkazana rezervacija', Icons.cancel_outlined),
    (_NotificationTypes.checkInReminder, 'Check-in podsjetnik', Icons.login_outlined),
    (_NotificationTypes.parkingFull, 'Parking pun', Icons.block_outlined),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerColor =
        widget.toAll ? kSuccess : kPrimary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminDialogHeader(
              icon: widget.toAll
                  ? Icons.campaign_outlined
                  : Icons.send_outlined,
              title: widget.toAll
                  ? 'Pošalji svim korisnicima'
                  : 'Pošalji korisniku',
              color: headerColor,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    if (!widget.toAll) ...[
                      _label('Korisnik'),
                      const SizedBox(height: 8),
                      _buildUserDropdown(),
                      const SizedBox(height: 20),
                    ],
                    _label('Naslov'),
                    const SizedBox(height: 8),
                    AdminFormField(
                        controller: _titleCtrl,
                        label: 'Naslov notifikacije',
                      icon: Icons.title,
                      enabled: !_isLoading,
                      validator: _validateTitle),
                    const SizedBox(height: 20),
                    _label('Poruka'),
                    const SizedBox(height: 8),
                    AdminFormField(
                        controller: _messageCtrl,
                        label: 'Tekst poruke',
                        icon: Icons.message_outlined,
                      maxLines: 4,
                      enabled: !_isLoading,
                      validator: _validateMessage),
                    const SizedBox(height: 20),
                    _label('Tip notifikacije'),
                    const SizedBox(height: 8),
                    _buildTypeGrid(),
                    const SizedBox(height: 20),
                    _label('Kanal slanja'),
                    const SizedBox(height: 8),
                    _buildChannelSelector(),
                    if (_selectedChannel != _NotificationChannels.inApp) ...[
                      const SizedBox(height: 12),
                      _buildEmailNote(),
                    ],
                    ],
                  ),
                ),
              ),
            ),
            AdminDialogFooter(children: [
              const AdminCancelButton(),
              const SizedBox(width: 12),
              AdminPrimaryButton(
                label: _isLoading ? 'Slanje...' : 'Pošalji',
                icon: Icons.send,
                isLoading: _isLoading,
                color: headerColor,
                onPressed: _submit,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151)));

  Widget _buildUserDropdown() {
    return Consumer<UserProvider>(
      builder: (context, provider, _) => AdminDropdownField<int>(
        value: _selectedUserId,
        label: 'Odaberi korisnika',
        icon: Icons.person_outline,
        items: provider.users.map((u) => u.id).toList(),
        validator: widget.toAll
            ? null
            : (value) {
                if (value == null) {
                  return 'Odaberite korisnika kojem šaljete notifikaciju';
                }
                return null;
              },
        labelBuilder: (id) {
          final u = provider.users.firstWhere((u) => u.id == id);
          return '${u.firstName ?? ''} ${u.lastName ?? ''} · ${u.email}';
        },
        onChanged: (v) => setState(() => _selectedUserId = v),
      ),
    );
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Naslov je obavezan';
    }
    if (value.trim().length < 3 || value.trim().length > 120) {
      return 'Naslov mora imati 3-120 znakova';
    }
    return null;
  }

  String? _validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Poruka je obavezna';
    }
    if (value.trim().length < 5 || value.trim().length > 1000) {
      return 'Poruka mora imati 5-1000 znakova';
    }
    return null;
  }

  Widget _buildTypeGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _types.map((t) {
        final sel = _selectedType == t.$1;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = t.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? kPrimary : kPrimary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kPrimary, width: sel ? 0 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.$3, size: 14,
                    color: sel ? Colors.white : kPrimary),
                const SizedBox(width: 6),
                Text(t.$2,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: sel ? Colors.white : kPrimary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChannelSelector() {
    return Row(
      children: [
        _ChannelOption(value: _NotificationChannels.inApp, label: 'In-App', icon: Icons.phone_android, selected: _selectedChannel == _NotificationChannels.inApp, onTap: () => setState(() => _selectedChannel = _NotificationChannels.inApp)),
        const SizedBox(width: 8),
        _ChannelOption(value: _NotificationChannels.email, label: 'Email', icon: Icons.email_outlined, selected: _selectedChannel == _NotificationChannels.email, onTap: () => setState(() => _selectedChannel = _NotificationChannels.email)),
        const SizedBox(width: 8),
        _ChannelOption(value: _NotificationChannels.both, label: 'Oboje', icon: Icons.all_inclusive, selected: _selectedChannel == _NotificationChannels.both, onTap: () => setState(() => _selectedChannel = _NotificationChannels.both)),
      ],
    );
  }

  Widget _buildEmailNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: kWarning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Email za "Posebne ponude" neće biti poslan korisnicima koji '
              'imaju isključen NotifyAboutOffers u preferencama.',
              style: TextStyle(fontSize: 11, color: Colors.amber[800]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    final ok = widget.toAll
        ? await provider.sendToAll(
            title: _titleCtrl.text.trim(),
            message: _messageCtrl.text.trim(),
            type: _selectedType,
            channel: _selectedChannel,
          )
        : await provider.sendToUser(
            userId: _selectedUserId!,
            title: _titleCtrl.text.trim(),
            message: _messageCtrl.text.trim(),
            type: _selectedType,
            channel: _selectedChannel,
          );

    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) {
        Navigator.pop(context);
        AdminSnackBar.show(
          context,
          widget.toAll
              ? 'Notifikacija poslana svim korisnicima!'
              : 'Notifikacija poslana!',
          true,
        );
        provider.fetchNotifications();
      } else {
        AdminSnackBar.error(context, 'Greška pri slanju. Pokušaj ponovo.');
      }
    }
  }
}

class _ChannelOption extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChannelOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? kPrimary : kPrimary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kPrimary, width: selected ? 0 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20,
                  color: selected ? Colors.white : kPrimary),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : kPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationChannels {
  static const int inApp = 1;
  static const int email = 2;
  static const int both = 3;
}

class _NotificationTypes {
  static const int reservationConfirmed = 1;
  static const int reservationReminder = 2;
  static const int paymentSuccess = 3;
  static const int paymentFailure = 4;
  static const int availabilityNotice = 5;
  static const int specialOffer = 6;
  static const int reservationCancelled = 7;
  static const int checkInReminder = 8;
  static const int parkingFull = 9;
}