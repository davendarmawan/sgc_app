import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'services/liveCondition_service.dart';

class NotificationsPage extends StatefulWidget {
  final LiveConditionService liveConditionService;

  const NotificationsPage({
    super.key, 
    required this.liveConditionService,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late List<NotificationItem> _notifications;
  StreamSubscription<NotificationItem>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    // Get initial notifications from the service
    _notifications = List.from(widget.liveConditionService.notifications);
    _notifications.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    
    // Listen for new notifications
    _notificationSubscription = widget.liveConditionService.notificationStream.listen((newNotification) {
      if (mounted) {
        setState(() {
          _notifications.insert(0, newNotification);
        });
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Map<String, List<NotificationItem>> get _groupedNotifications {
    Map<String, List<NotificationItem>> map = {};
    for (var notif in _notifications) {
      final key = DateFormat('dd MMMM yyyy').format(notif.dateTime);
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(notif);
    }
    return map;
  }

  void _refreshNotifications() {
    setState(() {
      _notifications = List.from(widget.liveConditionService.notifications);
      _notifications.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications refreshed')),
    );
  }

  void _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      widget.liveConditionService.clearAllNotifications();
      setState(() {
        _notifications.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications cleared')),
      );
    }
  }

  void _deleteNotification(NotificationItem item) {
    widget.liveConditionService.removeNotification(item);
    setState(() {
      _notifications.remove(item);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasNotifications = _notifications.isNotEmpty;

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
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (hasNotifications) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_notifications.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            // Connection status indicator
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.liveConditionService.isConnected 
                        ? Colors.green 
                        : Colors.red,
                  ),
                ),
              ),
            ),
          ],
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
        child: SafeArea(
          child: Column(
            children: [
              // Connection status banner
              if (!widget.liveConditionService.isConnected)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.withOpacity(0.1),
                  child: const Text(
                    'Disconnected from live data stream',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              
              // Expanded list or no notification view
              Expanded(
                child: hasNotifications
                    ? _buildGroupedNotificationList()
                    : _buildNoNotificationView(),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_notifications.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _refreshNotifications,
                            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                            label: const Text(
                              'Refresh',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 2,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _clearAllNotifications,
                            icon: const Icon(Icons.delete_forever, color: Colors.white, size: 20),
                            label: const Text(
                              'Clear All',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                    ] else
                      SizedBox(
                        width: 150,
                        height: 100,
                        child: Image.asset(
                          'assets/smartfarm_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.agriculture, size: 40, color: Colors.green);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedNotificationList() {
    final grouped = _groupedNotifications;
    final dateKeys = grouped.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('dd MMMM yyyy').parse(a);
        final dateB = DateFormat('dd MMMM yyyy').parse(b);
        return dateB.compareTo(dateA);
      });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      itemCount: dateKeys.length,
      itemBuilder: (context, index) {
        final dateKey = dateKeys[index];
        final notificationsForDate = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                dateKey,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),

            // Notifications for this date
            ...notificationsForDate.map((notification) {
              final timeStr = DateFormat('HH:mm').format(notification.dateTime);

              return Dismissible(
                key: ValueKey(notification.dateTime.toIso8601String() + notification.header),
                direction: DismissDirection.horizontal,
                background: Container(
                  color: Colors.red.withOpacity(0.1),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                secondaryBackground: Container(
                  color: Colors.red.withOpacity(0.1),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                onDismissed: (_) => _deleteNotification(notification),
                child: Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time and priority indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            _getNotificationIcon(notification.header),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notification.header,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.info,
                          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _getNotificationIcon(String header) {
    IconData icon;
    Color color;
    
    if (header.contains('Door')) {
      icon = Icons.door_front_door;
      color = Colors.orange;
    } else if (header.contains('Temperature')) {
      icon = Icons.thermostat;
      color = Colors.red;
    } else if (header.contains('Humidity')) {
      icon = Icons.water_drop;
      color = Colors.blue;
    } else if (header.contains('CO2')) {
      icon = Icons.air;
      color = Colors.green;
    } else {
      icon = Icons.warning;
      color = Colors.amber;
    }
    
    return Icon(icon, color: color, size: 20);
  }

  Widget _buildNoNotificationView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/no_notification.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.notifications_off, size: 100, color: Colors.grey);
                  },
                ),
              ),
            ),
            const SizedBox(height: 23),
            const Text(
              "Currently, There's\nNo Notification!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.liveConditionService.isConnected 
                  ? 'System is monitoring conditions...'
                  : 'Waiting for connection...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 23),
            ElevatedButton.icon(
              onPressed: _refreshNotifications,
              icon: const Icon(Icons.refresh, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              label: const Text(
                'Refresh',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}