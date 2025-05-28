import 'package:flutter/material.dart';
import 'settings.dart';
import 'notifications_loader.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF7FAFC), Color(0xFFC4EAFE)],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Top bar with settings, logo, notifications
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HoverCircleIcon(iconData: Icons.settings),
                        Image.asset(
                          'assets/smartfarm_logo.png',
                          height: 58,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported),
                        ),
                        HoverCircleIcon(iconData: Icons.notifications_none),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Title centered
                    Align(
                      alignment: Alignment.center,
                      child: const Text(
                        'Camera',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Display camera images section
                    _buildImageSection(
                      'Top Camera',
                      'assets/image1.png', // Replace with your image path
                    ),
                    const SizedBox(height: 15),
                    _buildImageSection(
                      'Bottom Camera',
                      'assets/image2.png', // Replace with your image path
                    ),
                    const SizedBox(height: 15),
                    _buildImageSection(
                      'User Camera',
                      'assets/image3.png', // Replace with your image path
                    ),
                    const SizedBox(height: 20),

                    // Take Photo Button
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: FilledButton(
                        onPressed: () {
                          // TODO: Implement take photo functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Successfully took photos!'),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Take Photo',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20), // Add space at the very bottom
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Function to build image sections
  Widget _buildImageSection(String title, String imagePath) {
    return Column(
      children: [
        // Section title
        Align(
          alignment: Alignment.center,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
          ),
        ),
        const SizedBox(height: 10),
        // Image container with rounded corners
        Container(
          height: 220, // Adjust the height as needed
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(31, 2, 0, 0),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath, // Image source
              fit: BoxFit.cover,
              width: double.infinity, // Make sure the image fills the container
            ),
          ),
        ),
      ],
    );
  }
}

class HoverCircleIcon extends StatefulWidget {
  final IconData iconData;

  const HoverCircleIcon({required this.iconData, super.key});

  @override
  State<HoverCircleIcon> createState() => _HoverCircleIconState();
}

class _HoverCircleIconState extends State<HoverCircleIcon> {
  final bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (widget.iconData == Icons.settings) {
          // Navigate to Settings page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        } else if (widget.iconData == Icons.notifications_none) {
          // Navigate to Notifications page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsLoaderPage(),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(50),
      splashColor: const Color.fromRGBO(0, 123, 255, 0.2),
      highlightColor: const Color.fromRGBO(0, 123, 255, 0.1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              _isPressed
                  ? const Color.fromARGB(255, 109, 109, 109)
                  : Colors.transparent,
        ),
        child: Icon(
          widget.iconData,
          size: 24,
          color:
              _isPressed
                  ? const Color.fromARGB(255, 255, 255, 255)
                  : const Color.fromARGB(221, 0, 0, 0),
        ),
      ),
    );
  }
}
