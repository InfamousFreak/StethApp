# Firebase Integration Update Summary

## Changes Made

### 1. Firebase Configuration
- **New Database**: Using Firebase Realtime Database (`scope-ff203-default-rtdb.firebaseio.com`)
- **Package Added**: `firebase_database: ^11.1.4` to `pubspec.yaml`

### 2. New Device Service (`lib/services/device_service.dart`)
Created a service to handle real-time device data from Firebase:

**DeviceData Model**:
- `heartActive`: boolean - whether heart mode is active
- `heartLevel`: int - heart frequency/level (0-255)
- `lungActive`: boolean - whether lung mode is active  
- `lungLevel`: int - lung frequency/level (0-255)
- `timestamp`: int - Unix timestamp
- `deviceId`: string - unique device identifier

**Key Methods**:
- `getDevicesStream()`: Listen to all devices in real-time
- `getDeviceStream(deviceId)`: Listen to specific device
- `findActiveDevice()`: 5-second timeout to find active device
- `updateDevice()`: Update device data (for testing)

### 3. Updated Home Page (`lib/home_page.dart`)

**Connection Flow**:
1. User clicks "Connect via WiFi"
2. App searches for active device (5-second timeout)
3. If device found and active:
   - Auto-detects position (heart/lung) based on `heart_active` or `lung_active`
   - Shows success toast with detected mode
   - Automatically proceeds to listening phase
4. If no device found:
   - Shows warning toast
   - Returns to initial screen

**Real-time Data Collection**:
- Listens to device stream during 25-second listening period
- Collects frequency data (`heart_level` or `lung_level`) in `_frequencyData` array
- Keeps last 100 readings for waveform reconstruction

**Waveform Reconstruction**:
The `MedicalWaveformPainter` now uses real frequency data:

**Heart Mode** (from `heart_level`):
- Converts frequency (0-255) to BPM (60-120)
- Reconstructs ECG-like QRS complex pattern
- Adjusts beat rate based on frequency
- Modulates amplitude by signal strength

**Lung Mode** (from `lung_level`):
- Converts frequency (0-255) to breathing rate (12-20 breaths/min)
- Reconstructs inhale/exhale cycles
- Adjusts breath timing based on frequency
- Modulates amplitude by signal strength

**Fallback**: If no frequency data available, uses simulated patterns (as before)

### 4. Firebase Database Structure Expected

```json
{
  "devices": {
    "{deviceId}": {
      "heart_active": false,
      "heart_level": 0,
      "lung_active": false,
      "lung_level": 0,
      "timestamp": 6304
    }
  }
}
```

## How It Works

### Connection Phase (5 seconds)
1. App listens for any device where `heart_active` OR `lung_active` is `true`
2. Once found, determines mode:
   - If only `heart_active` = true → Heart mode
   - If only `lung_active` = true → Lung mode
   - If both or neither → Let user choose position
3. Proceeds automatically to listening phase

### Listening Phase (25 seconds)
1. Subscribes to device updates
2. Collects frequency data every time device updates
3. Waveform appears after 5 seconds (as before)
4. Waveform is reconstructed from real frequency readings
5. After 25 seconds, stops listening and shows results (5% or 10% risk)

## Next Steps for Full Integration

### When You Provide the ML Model:
The prediction logic is currently in the `_showResults()` method (random 5-10%). Replace with:

```dart
void _showResults() async {
  // Use collected frequency data for prediction
  final prediction = await _runModelPrediction(_frequencyData);
  
  setState(() {
    _riskPercentage = prediction.riskPercentage; // From model
    _currentStep = ConnectionStep.results;
  });
}
```

### Testing the Connection:
You can manually test by updating Firebase:

```dart
// Turn on heart mode
await DeviceService().updateDevice(
  'deviceId123',
  heartActive: true,
  heartLevel: 180, // Some frequency value
  lungActive: false,
  lungLevel: 0,
);
```

## Files Modified
1. `/pubspec.yaml` - Added firebase_database
2. `/lib/services/device_service.dart` - New file
3. `/lib/home_page.dart` - Updated connection and waveform logic

## Next Action Required
Provide the TensorFlow Lite model and I'll integrate it to replace the current 5-10% random prediction with real ML inference based on the frequency data collected.
