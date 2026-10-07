import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';

/// Used by both customer and staff accounts — the embedded BAI@google.com
/// staff login is a normal email/password account, so it changes its
/// password the exact same way a customer does.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _auth = AuthService();
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureCurrent = true, _obscureNew = true, _obscureConfirm = true;
  bool _loading = false;

  Future<void> _save() async {
    if (!_auth.canChangePassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This account uses Google Sign-In — change your password in your Google Account.'),
      ));
      return;
    }
    if (_newPass.text.length < 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('New password must be at least 6 characters')));
      return;
    }
    if (_newPass.text != _confirm.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('New passwords do not match')));
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.changePassword(_current.text, _newPass.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update password: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _pwField(String hint, TextEditingController c, bool obscure, VoidCallback toggle) {
    return TextField(
      controller: c,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password'), backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _pwField('Current password', _current, _obscureCurrent,
                () => setState(() => _obscureCurrent = !_obscureCurrent)),
            const SizedBox(height: 10),
            _pwField('New password', _newPass, _obscureNew,
                () => setState(() => _obscureNew = !_obscureNew)),
            const SizedBox(height: 10),
            _pwField('Confirm new password', _confirm, _obscureConfirm,
                () => setState(() => _obscureConfirm = !_obscureConfirm)),
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BaiColors.mint,
                foregroundColor: BaiColors.ink,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}