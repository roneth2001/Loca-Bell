import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locabel/screens/home.dart';
import 'package:locabel/services/alarm_service.dart';
import 'package:locabel/services/location_service.dart';
import 'package:locabel/services/storage_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();

  await StorageService.instance.init();
  await LocationService.instance.init();
  await AlarmService.instance.init();
  
  LocationService.instance.setNavigatorKey(navigatorKey);
  runApp(const MyApp());
}

// Initialize the background service
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // Create notification channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'location_service_channel',
    'Location Service',
    description: 'This channel is used for location tracking notifications',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'location_service_channel',
      initialNotificationTitle: 'Location Service',
      initialNotificationContent: 'Tracking location in background',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  // Start location tracking
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          // Update notification with current location
          service.setForegroundNotificationInfo(
            title: "Location Service",
            content: "Lat: ${position.latitude.toStringAsFixed(6)}, "
                "Lng: ${position.longitude.toStringAsFixed(6)}",
          );

          // Send location data to UI
          service.invoke(
            'update',
            {
              "latitude": position.latitude,
              "longitude": position.longitude,
              "timestamp": DateTime.now().toIso8601String(),
            },
          );

          print('Location: ${position.latitude}, ${position.longitude}');
        } catch (e) {
          print('Error getting location: $e');
        }
      }
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Background Location Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      navigatorKey: navigatorKey,
      home: const HomeScreen(),
    );
  }
}