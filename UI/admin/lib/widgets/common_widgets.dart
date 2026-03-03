import 'package:flutter/material.dart';

class SearchFieldDecoration {
  static InputDecoration buildInputDecoration({
    required String labelText,
    required IconData icon,
  }) => InputDecoration(
    labelText: labelText,
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
  );
}

class SearchContainerStyle {
  static BoxDecoration buildDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class CommonButtons {
  static Widget buildSearchButton({
    required VoidCallback onPressed,
    required bool isLoading,
  }) => ElevatedButton.icon(
    onPressed: isLoading ? null : onPressed,
    icon: isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Icon(Icons.search, size: 18),
    label: const Text('Pretraži'),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6366F1),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  static Widget buildClearButton({required VoidCallback onPressed}) =>
      TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.refresh),
        label: const Text('Očisti'),
        style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
      );

  static Widget buildAddButton({
    required VoidCallback onPressed,
    required String label,
  }) => ElevatedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.add, size: 18),
    label: Text(label),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

class SnackBarHelper {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  static void showMessage(
    BuildContext context,
    String message,
    bool isSuccess,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }
}

class PageHeader {
  static Widget build({required String title}) => Text(
    title,
    style: const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1E293B),
    ),
  );
}
