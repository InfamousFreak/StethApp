import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TestFirebasePage extends StatefulWidget {
  const TestFirebasePage({Key? key}) : super(key: key);

  @override
  State<TestFirebasePage> createState() => _TestFirebasePageState();
}

class _TestFirebasePageState extends State<TestFirebasePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? _allDevices;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAllDevices();
  }

  Future<void> _fetchAllDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final snapshot = await _database.child('devices/device123/sensor_data').get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _allDevices = Map<String, dynamic>.from(
            data.map((key, value) => MapEntry(
              key.toString(), 
              Map<String, dynamic>.from(value as Map)
            ))
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No sensor data found in database';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Data Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAllDevices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _allDevices == null || _allDevices!.isEmpty
                  ? const Center(
                      child: Text(
                        'No devices found',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: _allDevices!.entries.map((entry) {
                        final sensorId = entry.key;
                        final sensorData = entry.value;
                        
                        return _buildSensorCard(sensorId, sensorData);
                      }).toList(),
                    ),
    );
  }

  Widget _buildSensorCard(String sensorId, Map<String, dynamic> data) {
    // Display raw data as-is
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sensor Data Entry',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildDataRow('Sensor ID', sensorId),
            const SizedBox(height: 16),
            Text(
              'All Data Fields',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...data.entries.map((entry) {
              return _buildDataRow(
                entry.key.toString(),
                entry.value.toString(),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: valueColor ?? Colors.black87,
                fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
