import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Controllers without initial text
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _institutionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Email Validation regex
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Phone Validation (allow optional + followed by digits)
  bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[0-9]+$'); // Optional + followed by digits
    return phoneRegex.hasMatch(phone);
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    InputDecoration buildInputDecoration({
      required String label,
      required String hint,
      IconData? icon,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        border: borderStyle,
        enabledBorder: borderStyle.copyWith(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: borderStyle.copyWith(
          borderSide: BorderSide(color: Colors.blue.shade700),
        ),
        hintStyle: TextStyle(color: Colors.grey),
        labelStyle: TextStyle(color: Colors.grey.shade700),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15.0,
          horizontal: 10.0,
        ),
      );
    }

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
            'Edit Profile',
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
            Center(
              child: CircleAvatar(
                radius: 33,
                backgroundColor: Colors.blue,
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/profile.png'),
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _usernameController,
              decoration: buildInputDecoration(
                label: 'Username',
                hint: 'Enter new username',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _fullNameController,
              decoration: buildInputDecoration(
                label: 'Full Name',
                hint: 'Enter new full name',
                icon: Icons.person,
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _institutionController,
              decoration: buildInputDecoration(
                label: 'Institution',
                hint: 'Enter new institution',
                icon: Icons.school_outlined,
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: buildInputDecoration(
                label: 'Email',
                hint: 'Enter new email address',
                icon: Icons.email_outlined,
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: buildInputDecoration(
                label: 'Phone',
                hint: 'Enter new phone number',
                icon: Icons.phone_outlined,
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
              onPressed: () {
                // Check if any field is empty
                if (_usernameController.text.isEmpty ||
                    _fullNameController.text.isEmpty ||
                    _institutionController.text.isEmpty ||
                    _emailController.text.isEmpty ||
                    _phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields.'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.fixed,
                    ),
                  );
                }
                // Validate Email
                else if (!isValidEmail(_emailController.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email address.'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.fixed,
                    ),
                  );
                }
                // Validate Phone Number (optional + followed by digits)
                else if (!isValidPhone(_phoneController.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid phone number.'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.fixed,
                    ),
                  );
                } else {
                  // Save profile logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile saved successfully!'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.fixed,
                    ),
                  );
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.save, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Save Profile',
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
