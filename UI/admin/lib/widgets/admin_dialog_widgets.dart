import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ZAJEDNIČKI ADMIN DIALOG WIDGETI
// Koristiti u svim admin ekranima za unificirani izgled formi i dijaloga.
// ─────────────────────────────────────────────────────────────────────────────

const kPrimary = Color(0xFF6366F1);
const kSuccess = Color(0xFF10B981);
const kDanger  = Color(0xFFEF4444);
const kWarning = Color(0xFFF59E0B);

// ── Header dijaloga ───────────────────────────────────────────────────────────
class AdminDialogHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const AdminDialogHeader({
    required this.icon,
    required this.title,
    this.color = kPrimary,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }
}

// ── Footer dijaloga ───────────────────────────────────────────────────────────
class AdminDialogFooter extends StatelessWidget {
  final List<Widget> children;

  const AdminDialogFooter({required this.children, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: children,
      ),
    );
  }
}

// ── Input polje forme ─────────────────────────────────────────────────────────
class AdminFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputType keyboardType;
  final int maxLines;
  final bool obscureText;
  final String? hint;

  const AdminFormField({
    required this.controller,
    required this.label,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.obscureText = false,
    this.hint,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: Colors.grey[500])
            : null,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

// ── Dropdown polje forme ──────────────────────────────────────────────────────
class AdminDropdownField<T> extends StatelessWidget {
  final T? value;
  final String label;
  final IconData? icon;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  const AdminDropdownField({
    required this.value,
    required this.label,
    this.icon,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      decoration: InputDecoration(
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: Colors.grey[500])
            : null,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
      isExpanded: true,
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(labelBuilder(item),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ── Primarne akcija dugme ─────────────────────────────────────────────────────
class AdminPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool enabled;
  final Color color;

  const AdminPrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.color = kPrimary,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: (!enabled || isLoading) ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withOpacity(0.5),
        elevation: 0,
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ── Otkaži dugme ──────────────────────────────────────────────────────────────
class AdminCancelButton extends StatelessWidget {
  final String label;
  const AdminCancelButton({this.label = 'Otkaži', Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(label, style: TextStyle(color: Colors.grey[600])),
    );
  }
}

// ── Status badge (soft, pill oblik) ───────────────────────────────────────────
class AdminStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const AdminStatusBadge({
    required this.label,
    required this.color,
    this.icon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ── Confirm dialog ────────────────────────────────────────────────────────────
class AdminConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const AdminConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.confirmColor = kDanger,
    required this.onConfirm,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminDialogHeader(
              icon: Icons.help_outline,
              title: title,
              color: confirmColor,
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(message,
                  style:
                      TextStyle(color: Colors.grey[700], fontSize: 14)),
            ),
            AdminDialogFooter(children: [
              const AdminCancelButton(),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(confirmLabel,
                    style: const TextStyle(color: Colors.white)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Snackbar helper ───────────────────────────────────────────────────────────
class AdminSnackBar {
  static void show(BuildContext context, String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error_outline,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(message),
        ],
      ),
      backgroundColor: success ? kSuccess : kDanger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  static void error(BuildContext context, String message) {
    show(context, message, false);
  }
}
