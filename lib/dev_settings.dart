import 'package:flutter/material.dart';

class DevSettingsPage extends StatefulWidget {
  const DevSettingsPage({super.key});

  @override
  State<DevSettingsPage> createState() => _DevSettingsPageState();
}

class _DevSettingsPageState extends State<DevSettingsPage> {
  // Sample approved devices list
  List<Map<String, dynamic>> approvedDevices = [];

  // Sample requested devices list
  List<Map<String, dynamic>> requestedDevices = [
    {'id': 1, 'name': 'PGC - Kementan'},
    {'id': 2, 'name': 'PGC - ITB'},
    {'id': 3, 'name': 'PGC - UI'},
    {'id': 4, 'name': 'PGC - Unpad'},
    {'id': 5, 'name': 'PGC - IPB'},
  ];

  Map<String, dynamic>? selectedDevice;
  Map<String, dynamic>? selectedRequestedDevice;

  @override
  void initState() {
    super.initState();
    if (approvedDevices.isNotEmpty) {
      selectedDevice = approvedDevices[0];
    }
    if (requestedDevices.isNotEmpty) {
      selectedRequestedDevice = requestedDevices[0];
    }
  }

  void _saveSelectedDevice() {
    if (selectedDevice != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Device ${selectedDevice!['id']} | ${selectedDevice!['name']} selected.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _sendRequestAccess() {
    if (selectedRequestedDevice != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request sent for device ${selectedRequestedDevice!['id']} | ${selectedRequestedDevice!['name']}.',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  InputDecoration buildDropdownDecoration({required String label}) {
    OutlineInputBorder borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey),
    );

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 15.0,
        horizontal: 12.0,
      ),
      border: borderStyle,
      enabledBorder: borderStyle.copyWith(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: borderStyle.copyWith(
        borderSide: BorderSide(color: Colors.blue),
      ),
      filled: true,
      fillColor: Colors.white,
      // DropdownButtonFormField will handle the dropdown icon
    );
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
            'Device Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black54),
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
          children: [
            const SizedBox(height: 30),

            // Avatar and user info (optional, you can customize or remove)
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

            const SizedBox(height: 20),

            // Change Device Section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.devices, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          'Change Device',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Dropdown styled like TextFormField
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedDevice,
                      decoration: buildDropdownDecoration(
                        label: 'Select Approved Device',
                      ),
                      items:
                          approvedDevices.isNotEmpty
                              ? approvedDevices
                                  .map(
                                    (device) => DropdownMenuItem(
                                      value: device,
                                      child: Text(
                                        '${device['id']} | ${device['name']}',
                                      ),
                                    ),
                                  )
                                  .toList()
                              : [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('No devices available'),
                                ),
                              ],
                      onChanged: (value) {
                        setState(() {
                          selectedDevice = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size.fromHeight(40),
                      ),
                      onPressed:
                          approvedDevices.isNotEmpty
                              ? _saveSelectedDevice
                              : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.save, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Request Device Access Section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.key, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          'Request Device Access',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedRequestedDevice,
                      decoration: buildDropdownDecoration(
                        label: 'Select Requested Device',
                      ),
                      items:
                          requestedDevices.isNotEmpty
                              ? requestedDevices
                                  .map(
                                    (device) => DropdownMenuItem(
                                      value: device,
                                      child: Text(
                                        '${device['id']} | ${device['name']}',
                                      ),
                                    ),
                                  )
                                  .toList()
                              : [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('No devices available'),
                                ),
                              ],
                      onChanged: (value) {
                        setState(() {
                          selectedRequestedDevice = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size.fromHeight(40),
                      ),
                      onPressed:
                          requestedDevices.isNotEmpty
                              ? _sendRequestAccess
                              : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.send, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Send Request',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Optional: Add your logo or footer here if needed
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

            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
