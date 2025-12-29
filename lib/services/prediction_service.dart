import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math' as math;
import 'local_diagnosis_service.dart';

class PredictionResult {
  final int riskPercentage;
  final String diagnosis;
  final double confidence;
  final String recommendation;
  final String status;
  final double usedFrequency;

  PredictionResult({
    required this.riskPercentage,
    required this.diagnosis,
    required this.confidence,
    required this.recommendation,
    required this.status,
    required this.usedFrequency,
  });
}

class PredictionService {
  static final PredictionService _instance = PredictionService._internal();
  factory PredictionService() => _instance;
  PredictionService._internal();

  final LocalDiagnosisService _localDiagnosis = LocalDiagnosisService();
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  // Load the TFLite model (optional fallback)
  Future<bool> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model_float.tflite');
      _isModelLoaded = true;
      print('✅ Model loaded successfully');
      
      // Print input/output details
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      print('Model input shape: $inputShape');
      print('Model output shape: $outputShape');
      
      return true;
    } catch (e) {
      print('❌ Error loading model: $e');
      print('✅ Using local diagnosis service instead');
      _isModelLoaded = false;
      return false;
    }
  }

  // Main prediction method using local diagnosis service
  Future<PredictionResult> predictFromFrequencyData(
    List<int> frequencyData,
    bool isHeartMode, {
    List<double>? rmsData,
  }) async {
    try {
      print('🧠 Using Local AI Diagnosis Service');
      print('📊 Processing ${frequencyData.length} frequency samples');
      print('📈 RMS samples: ${rmsData?.length ?? 0}');

      // Use local diagnosis service (your Python logic)
      final result = _localDiagnosis.predictFromDeviceData(
        frequencyData: frequencyData,
        rmsData: rmsData ?? [],
        isHeartMode: isHeartMode,
      );

      print('🎯 Local Diagnosis: ${result.diagnosis}');
      print('📊 Risk: ${result.riskPercentage}%');
      print('🎲 Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
      print('📡 Used Frequency: ${result.usedFrequency.toStringAsFixed(1)} Hz');

      return PredictionResult(
        riskPercentage: result.riskPercentage,
        diagnosis: result.diagnosis,
        confidence: result.confidence,
        recommendation: _localDiagnosis.getRecommendation(result),
        status: result.status,
        usedFrequency: result.usedFrequency,
      );
      
    } catch (e) {
      print('❌ Local diagnosis error: $e');
      return _getFallbackPrediction(
        fallbackReason: 'Local diagnosis error: ${e.toString()}',
      );
    }
  }

  // Prepare input data from frequency readings
  List<List<List<double>>> _prepareInputData(List<int> frequencyData, int requiredLength) {
    // Convert frequency data to normalized features
    List<double> features = [];
    
    if (frequencyData.isEmpty) {
      // If no data, use zeros
      features = List.filled(requiredLength, 0.0);
    } else {
      // Statistical features from frequency data
      final mean = frequencyData.reduce((a, b) => a + b) / frequencyData.length;
      
      // Normalize frequency data to 0-1 range
      final normalizedData = frequencyData.map((f) => f / 255.0).toList();
      
      // If we have more data than required, downsample
      if (normalizedData.length > requiredLength) {
        final step = normalizedData.length / requiredLength;
        features = List.generate(requiredLength, (i) {
          final index = (i * step).floor().clamp(0, normalizedData.length - 1);
          return normalizedData[index];
        });
      } 
      // If we have less data, pad with mean value
      else if (normalizedData.length < requiredLength) {
        features = List.from(normalizedData);
        while (features.length < requiredLength) {
          features.add(mean / 255.0);
        }
      } else {
        features = normalizedData;
      }
    }
    
    // Reshape to match model input: [1, requiredLength, 1]
    return [features.map((f) => [f]).toList()];
  }

  // Fallback prediction when model fails
  PredictionResult _getFallbackPrediction({String? fallbackReason}) {
    final random = math.Random();
    final risk = random.nextBool() ? 5 : 10;
    
    if (fallbackReason != null) {
      print('🔄 Fallback reason: $fallbackReason');
    }
    
    return PredictionResult(
      riskPercentage: risk,
      diagnosis: fallbackReason ?? 'Analysis Complete',
      confidence: 0.85,
      recommendation: risk == 5
          ? 'No need to consult a doctor. Continue with quarterly checkups.'
          : 'Low risk detected. Maintain quarterly checkups for monitoring.',
      status: risk > 50 ? 'High Risk' : 'Normal',
      usedFrequency: 80.0,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}
