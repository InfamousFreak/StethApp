import 'local_diagnosis_service.dart';

/// Test utility for verifying the integrated local diagnosis service
class DiagnosisTestSuite {
  static final LocalDiagnosisService _service = LocalDiagnosisService();

  /// Run comprehensive tests covering all diagnosis scenarios
  static void runAllTests() {
    print('\n🧪 RUNNING LOCAL DIAGNOSIS TEST SUITE\n');
    
    _testHeartConditions();
    _testLungConditions();
    _testEdgeCases();
    
    print('\n✅ ALL DIAGNOSIS TESTS COMPLETED\n');
  }

  /// Test heart-related diagnosis scenarios with variable risk
  static void _testHeartConditions() {
    print('❤️ TESTING HEART CONDITIONS (Variable Risk):');
    
    // Perfect normal heart
    var result = _service.predict(SensorInput(
      heartRms: 0.015,
      lungRms: 0.0,
      heartDetect: true,
      lungDetect: false,
      dominantFreq: 75.0, // Perfect heart rate
    ));
    print('  Perfect Normal: ${result.diagnosis} - ${result.riskPercentage}%');
    
    // Mild concern
    result = _service.predict(SensorInput(
      heartRms: 0.04,
      lungRms: 0.0,
      heartDetect: true,
      lungDetect: false,
      dominantFreq: 95.0,
    ));
    print('  Mild Concern: ${result.diagnosis} - ${result.riskPercentage}%');
    
    // Bradycardia
    result = _service.predict(SensorInput(
      heartRms: 0.03,
      lungRms: 0.0,
      heartDetect: true,
      lungDetect: false,
      dominantFreq: 45.0, // Low heart rate
    ));
    print('  Bradycardia: ${result.diagnosis} - ${result.riskPercentage}%');
    
    // Tachycardia
    result = _service.predict(SensorInput(
      heartRms: 0.05,
      lungRms: 0.0,
      heartDetect: true,
      lungDetect: false,
      dominantFreq: 165.0, // High heart rate
    ));
    print('  Tachycardia: ${result.diagnosis} - ${result.riskPercentage}%');
    
    // Severe abnormality
    result = _service.predict(SensorInput(
      heartRms: 0.12,
      lungRms: 0.0,
      heartDetect: true,
      lungDetect: false,
      dominantFreq: 220.0,
    ));
    print('  Severe Abnormal: ${result.diagnosis} - ${result.riskPercentage}%');
    print('');
  }

  /// Test lung-related diagnosis scenarios with variable risk
  static void _testLungConditions() {
    print('🫁 TESTING LUNG CONDITIONS (Variable Risk):');
    
    // Perfect normal lungs
    var result = _service.predict(SensorInput(
      heartRms: 0.0,
      lungRms: 0.008,
      heartDetect: false,
      lungDetect: true,
      dominantFreq: 120.0, // Low frequency
    ));
    print('  Perfect Normal: ${result.diagnosis} - ${result.riskPercentage}%');
    
    // Borderline normal
    result = _service.predict(SensorInput(
      heartRms: 0.0,
      lungRms: 0.018,
      heartDetect: false,
      lungDetect: true,
      dominantFreq: 175.0,
    ));
    print('  Borderline: ${result.diagnosis} - ${result.riskPercentage}%');
    
    // Early pneumonia
    result = _service.predict(SensorInput(
      heartRms: 0.0,
      lungRms: 0.025,
      heartDetect: false,
      lungDetect: true,
      dominantFreq: 250.0,
    ));
    print('  Early Pneumonia: ${result.diagnosis} - ${result.riskPercentage}%');
    
    // Severe pneumonia
    result = _service.predict(SensorInput(
      heartRms: 0.0,
      lungRms: 0.055,
      heartDetect: false,
      lungDetect: true,
      dominantFreq: 350.0,
    ));
    print('  Severe Pneumonia: ${result.diagnosis} - ${result.riskPercentage}%');
    
    // Tuberculosis
    result = _service.predict(SensorInput(
      heartRms: 0.0,
      lungRms: 0.045,
      heartDetect: false,
      lungDetect: true,
      dominantFreq: 480.0,
    ));
    print('  Tuberculosis: ${result.diagnosis} - ${result.riskPercentage}%');
    
    // COPD
    result = _service.predict(SensorInput(
      heartRms: 0.0,
      lungRms: 0.08,
      heartDetect: false,
      lungDetect: true,
      dominantFreq: 200.0,
    ));
    print('  COPD: ${result.diagnosis} - ${result.riskPercentage}%');
    print('');
  }

  /// Test edge cases and fallback scenarios
  static void _testEdgeCases() {
    print('⚠️ TESTING EDGE CASES:');
    
    // No detection flags
    var result = _service.predict(SensorInput(
      heartRms: 0.05,
      lungRms: 0.02,
      heartDetect: false,
      lungDetect: false,
      dominantFreq: 100.0,
    ));
    print('  No Detection: ${result.diagnosis} - ${result.riskPercentage}%');
    
    // Zero frequency with low RMS
    result = _service.predict(SensorInput(
      heartRms: 0.005,
      lungRms: 0.0,
      heartDetect: true,
      lungDetect: false,
      dominantFreq: 0.0,
    ));
    print('  Zero Freq Normal: ${result.diagnosis} - ${result.riskPercentage}%');
    
    // Test with device data method
    result = _service.predictFromDeviceData(
      frequencyData: [180, 185, 175, 190, 182],
      rmsData: [0.02, 0.025, 0.018, 0.03, 0.022],
      isHeartMode: true,
    );
    print('  Device Data Test: ${result.diagnosis} - ${result.riskPercentage}%');
    print('');
  }

  /// Test specific scenario with detailed output
  static DiagnosisResult testScenario({
    required String name,
    required double heartRms,
    required double lungRms,
    required bool heartDetect,
    required bool lungDetect,
    required double dominantFreq,
  }) {
    final result = _service.predict(SensorInput(
      heartRms: heartRms,
      lungRms: lungRms,
      heartDetect: heartDetect,
      lungDetect: lungDetect,
      dominantFreq: dominantFreq,
    ));
    
    print('🔬 TEST SCENARIO: $name');
    print('   Input: Heart RMS=${heartRms}, Lung RMS=${lungRms}, Freq=${dominantFreq}Hz');
    print('   Output: ${result.diagnosis} (${result.riskPercentage}% risk)');
    print('   Status: ${result.status}');
    print('   Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
    print('   Recommendation: ${_service.getRecommendation(result)}');
    print('');
    
    return result;
  }
}
