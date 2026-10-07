import 'package:flutter/material.dart';
import 'admin_panel_screen.dart';

// Client-side password only. Fine for a capstone demo, but anyone who
// decompiles the APK can read it. For a real product, replace this with a
// separate Firebase account that has an 'admin' role.
const String _adminPassword = 'ADMINPANEL000';

/// Asks for the admin password, then opens the Admin Panel if it matches.
Future<void> openAdminGate(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => const _AdminPasswordDialog(),
  );
  if (!context.mounted || ok == null) return;

  if (ok) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong password')));
  }
}

class _AdminPasswordDialog extends StatefulWidget {
  const _AdminPasswordDialog();

  @override
  State<_AdminPasswordDialog> createState() => _AdminPasswordDialogState();
}

class _AdminPasswordDialogState extends State<_AdminPasswordDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text == _adminPassword);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Admin access'),
      content: TextField(
        controller: _controller,
        obscureText: _obscure,
        autofocus: true,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: 'Password',
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: _submit, child: const Text('Enter')),
      ],
    );
  }
}