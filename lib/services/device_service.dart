import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class DeviceData {
  final bool heartActive;
  final double heartLevel;
  final bool lungActive;
  final double lungLevel;
  final int timestamp;
  final String deviceId;

  DeviceData({
    required this.heartActive,
    required this.heartLevel,
    required this.lungActive,
    required this.lungLevel,
    required this.timestamp,
    required this.deviceId,
  });

  factory DeviceData.fromSnapshot(DataSnapshot snapshot, String deviceId) {
    final data = snapshot.value as Map<dynamic, dynamic>?;
    return DeviceData(
      heartActive: data?['heart_detect'] ?? false,
      heartLevel: (data?['heart_rms'] ?? 0.0).toDouble(),
      lungActive: data?['lung_detect'] ?? false,
      lungLevel: (data?['lung_rms'] ?? 0.0).toDouble(),
      timestamp: data?['ts'] ?? 0,
      deviceId: deviceId,
    );
  }

  bool get isActive => heartActive || lungActive;
  bool get isHeartMode => heartActive && !lungActive;
  bool get isLungMode => lungActive && !heartActive;
  
  int get frequency => heartActive ? (heartLevel * 1000).toInt() : (lungLevel * 1000).toInt();
}

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription? _deviceSubscription;

  // Listen to all devices
  Stream<List<DeviceData>> getDevicesStream() {
    return _database.child('devices').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <DeviceData>[];

      return data.entries.map((entry) {
        final deviceId = entry.key as String;
        final deviceSnapshot = event.snapshot.child('$deviceId/data');
        return DeviceData.fromSnapshot(deviceSnapshot, deviceId);
      }).toList();
    });
  }

  // Listen to a specific device
  Stream<DeviceData> getDeviceStream(String deviceId) {
    return _database.child('devices/$deviceId/data').onValue.map((event) {
      return DeviceData.fromSnapshot(event.snapshot, deviceId);
    });
  }

  // Check if any device is active (for connection check)
  Future<DeviceData?> findActiveDevice({Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final completer = Completer<DeviceData?>();
      StreamSubscription? subscription;

      // Set up timeout
      final timer = Timer(timeout, () {
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      // Listen for active device
      subscription = getDevicesStream().listen((devices) {
        final activeDevice = devices.firstWhere(
          (device) => device.isActive,
          orElse: () => DeviceData(
            heartActive: false,
            heartLevel: 0,
            lungActive: false,
            lungLevel: 0,
            timestamp: 0,
            deviceId: '',
          ),
        );

        if (activeDevice.isActive && !completer.isCompleted) {
          timer.cancel();
          subscription?.cancel();
          completer.complete(activeDevice);
        }
      });

      return await completer.future;
    } catch (e) {
      print('Error finding active device: $e');
      return null;
    }
  }

  // Update device data (for testing)
  Future<void> updateDevice(String deviceId, {
    bool? heartActive,
    int? heartLevel,
    bool? lungActive,
    int? lungLevel,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (heartActive != null) updates['heart_active'] = heartActive;
      if (heartLevel != null) updates['heart_level'] = heartLevel;
      if (lungActive != null) updates['lung_active'] = lungActive;
      if (lungLevel != null) updates['lung_level'] = lungLevel;
      updates['timestamp'] = ServerValue.timestamp;

      await _database.child('devices/$deviceId').update(updates);
    } catch (e) {
      print('Error updating device: $e');
      rethrow;
    }
  }

  void dispose() {
    _deviceSubscription?.cancel();
  }
}
