import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'notifications.dart'; // Adjust the import path to where NotificationItem and NotificationsPage are defined

class NotificationsLoaderPage extends StatelessWidget {
  const NotificationsLoaderPage({super.key});

  // Function to load and parse notifications JSON from assets
  Future<List<NotificationItem>> loadNotificationsFromAsset() async {
    final String jsonString = await rootBundle.loadString(
      'assets/json/notifications.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => NotificationItem.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NotificationItem>>(
      future: loadNotificationsFromAsset(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading spinner while waiting for data
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          // Show an error message if loading failed
          return Scaffold(
            body: Center(
              child: Text('Error loading notifications: ${snapshot.error}'),
            ),
          );
        } else {
          // Data loaded successfully, pass notifications to NotificationsPage
          final notifications = snapshot.data ?? [];
          return NotificationsPage(notifications: notifications);
        }
      },
    );
  }
}
