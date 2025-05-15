import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPwdController = TextEditingController();
  final _newPwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPwdController.dispose();
    _newPwdController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }

  InputDecoration buildInputDecoration({
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback toggleObscure,
  }) {
    OutlineInputBorder borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
      border: borderStyle,
      enabledBorder: borderStyle.copyWith(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: borderStyle.copyWith(
        borderSide: BorderSide(color: Colors.blue.shade700),
      ),
      hintStyle: const TextStyle(color: Colors.grey),
      labelStyle: TextStyle(color: Colors.grey.shade700),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 15.0,
        horizontal: 10.0,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscureText ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey,
        ),
        onPressed: toggleObscure,
      ),
    );
  }

  void _handleChangePassword() {
    final currentPwd = _currentPwdController.text.trim();
    final newPwd = _newPwdController.text.trim();
    final confirmPwd = _confirmPwdController.text.trim();

    if (currentPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.fixed,
        ),
      );
      return;
    }

    if (newPwd != confirmPwd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password and confirmation do not match.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.fixed,
        ),
      );
      return;
    }

    // TODO: Add your password change logic here (e.g., API call)

    // On success:
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password changed successfully!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.fixed,
      ),
    );

    // Optionally clear fields after success
    _currentPwdController.clear();
    _newPwdController.clear();
    _confirmPwdController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
          ),
          backgroundColor: const Color(0xFFF7FAFC),
          title: const Text(
            'Change Password',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FAFC), Color(0xFFC4EAFE)],
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        child: ListView(
          children: [
            const SizedBox(height: 35),

            // Avatar at the top
            Center(
              child: CircleAvatar(
                radius: 53,
                backgroundColor: Colors.blue,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage(
                    'assets/profile.png',
                  ), // Replace with your image asset or use an icon
                ),
              ),
            ),

            const SizedBox(height: 10),
            const Text(
              'Kadhan Dalilurahman',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Text(
              'ITB',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 30),

            TextFormField(
              controller: _currentPwdController,
              obscureText: _obscureCurrent,
              decoration: buildInputDecoration(
                label: 'Current Password',
                hint: 'Enter current password',
                obscureText: _obscureCurrent,
                toggleObscure: () {
                  setState(() {
                    _obscureCurrent = !_obscureCurrent;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _newPwdController,
              obscureText: _obscureNew,
              decoration: buildInputDecoration(
                label: 'New Password',
                hint: 'Enter new password',
                obscureText: _obscureNew,
                toggleObscure: () {
                  setState(() {
                    _obscureNew = !_obscureNew;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _confirmPwdController,
              obscureText: _obscureConfirm,
              decoration: buildInputDecoration(
                label: 'Confirm New Password',
                hint: 'Re-enter new password',
                obscureText: _obscureConfirm,
                toggleObscure: () {
                  setState(() {
                    _obscureConfirm = !_obscureConfirm;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _handleChangePassword,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.lock, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Change Password',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  'assets/smartfarm_logo.png',
                  width: 150,
                  height: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
