import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(
          80,
        ), // Reduced height of the AppBar
        child: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context); // Go back to the previous screen
            },
          ),
          backgroundColor: Color(0xFFF7FAFC),
          title: const Text(
            'Settings',
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
            colors: [
              Color(0xFFF7FAFC),
              Color(0xFFC4EAFE),
            ], // Gradient from white to blue
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          children: [
            // Profile Section
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Centering CircleAvatar with a border
                Center(
                  child: CircleAvatar(
                    radius: 53,
                    backgroundColor: Colors.blue,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(
                        'assets/profile.png',
                      ), // Replace with your profile image
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
                ),
              ],
            ),
            const SizedBox(height: 40),

            // List of Settings Options
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Handle Edit Profile action
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Handle Change Password action
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Night-Day Hour Settings'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Handle Night-Day Hour Settings action
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Device Settings'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Handle Device Settings action
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Log Out Section
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () {
                  // Handle Log Out action
                },
                child: const Text(
                  'Log Out',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              ),
            ),

            // SmartFarm Logo Container at the Bottom
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  'assets/smartfarm_logo.png', // Replace with your logo file
                  width: 150, // Adjust width as needed
                  height: 100, // Adjust height as needed
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
