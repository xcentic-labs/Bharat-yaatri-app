import 'dart:convert';
import 'dart:io';
import 'package:cabproject/bottom_nav.dart';
import 'package:cabproject/screens/full_screen_alert.dart';
import 'package:cabproject/screens/login.dart';
import 'package:cabproject/screens/notification/notification.dart';
import 'package:cabproject/screens/profile_screen.dart';
import 'package:cabproject/screens/splash_screen.dart';
import 'package:cabproject/screens/intro_screen.dart';
import 'package:cabproject/screens/permission_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Secure Storage for Background Data
final FlutterSecureStorage secureStorage = FlutterSecureStorage();

/// **Background Notification Handler (Must be a top-level function)**
@pragma("vm:entry-point")
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('🔥 Background message received: ${message.data}');
  }

  if (message.data.isNotEmpty) {
    final String? messageString = message.data['message'];

    if (messageString != null) {
      final Map<String, dynamic> messageData = jsonDecode(messageString);

      final service = FlutterBackgroundService();
      service.invoke("show_overlay", messageData);
    } else {
      print('❌ Invalid message data: ${message.data}');
    }
  }
}


/// **Overlay Window Handler**
@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> messageData = {
    "carModel": "Unknown Car",
    "from": "Unknown Location",
    "to": "Unknown Destination",
    "description": "No details provided"
  };

  // Listen for data using overlayListener
  FlutterOverlayWindow.overlayListener.listen((event) {
    if (event != null && event.isNotEmpty) {
      try {
        messageData = jsonDecode(event);
      } catch (e) {
        print('❌ Error decoding overlay content.');
      }
    }

    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CarAlertOverlay(
        carModel: messageData['carModel'] ?? 'Unknown Car',
        from: messageData['from'] ?? 'Unknown Location',
        to: messageData['to'] ?? 'Unknown Destination',
        description: messageData['description'] ?? 'No details provided',
      ),
    ));
  });
}

Future<void> requestNotificationPermission() async {
  if (Platform.isAndroid) {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }
}

// Keep this function but we won't call it from main() anymore
Future<void> requestOverlayPermission() async {
  bool? permission = await FlutterOverlayWindow.isPermissionGranted();
  if (permission != true) {
    await FlutterOverlayWindow.requestPermission();
  }
}

Future<void> requestLocationPermission() async {
  var status = await Permission.location.status;
  if (!status.isGranted) {
    await Permission.location.request();
  }
}

/// **Initialize Local Notifications**
Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse response) async {
      if (response.payload != null) {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
      }
    },
  );
}

/// **Handle Navigation from Notifications**
void _handleNotificationNavigation(Map<String, dynamic> data) {
  final String? messageString = data['message'];
  if (messageString != null) {
    final Map<String, dynamic> messageData = jsonDecode(messageString);
    showDialog(
      context: navigatorKey.currentState!.context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return FullScreenAlert(
          carModel: messageData['carModel'] ?? '',
          from: messageData['from'] ?? '',
          to: messageData['to'] ?? '',
          description: messageData['description'] ?? '',
        );
      },
    );
  }
}

/// **Start Background Service**
Future<void> startBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: backgroundServiceFunction,
      autoStart: true,
      isForegroundMode: true,
      autoStartOnBoot: true,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: backgroundServiceFunction,
    ),
  );

  service.startService();
}

/// **Background Service Logic**
@pragma("vm:entry-point")
void backgroundServiceFunction(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "🚨  Notification Service",
      content: "Running in background...",
    );
  }

  service.on("show_overlay").listen((event) async {
    final Map<String, dynamic>? messageData = event as Map<String, dynamic>?;

    if (messageData != null) {
      // Show the overlay first
      await FlutterOverlayWindow.showOverlay(
        overlayTitle: "🚨 Emergency Alert",
        overlayContent: "", // This can be empty, as we'll pass data later
        enableDrag: false,
        flag: OverlayFlag.defaultFlag,
        positionGravity: PositionGravity.auto,
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
        startPosition: const OverlayPosition(0, 0),
      );

      // Share the data with the overlay
      await FlutterOverlayWindow.shareData(jsonEncode(messageData));
    }
  });
}

/// **Main Function**
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await initializeNotifications();
  await requestNotificationPermission();
  await requestLocationPermission();
  // REMOVED: await requestOverlayPermission(); -- We'll move this to the LoginPage
  await startBackgroundService();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground message received: ${message.data}');
    }
    if (message.data.isNotEmpty) {
      _handleNotificationNavigation(message.data);
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/intro': (context) => const IntroScreen(),
        '/home': (context) => LoginPage(),
        '/main': (context) => BottomNav(),
        '/profileScreen': (context) => ProfileScreen(),
        '/login': (context) => LoginPage(),
        '/permissionScreen': (context) => const PermissionScreen(),
      },
    );
  }
}