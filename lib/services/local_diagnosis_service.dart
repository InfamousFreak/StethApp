import 'dart:math' as math;

/// Input data model matching your hardware/Firebase
class SensorInput {
  final double heartRms;
  final double lungRms;
  final bool heartDetect;
  final bool lungDetect;
  final double dominantFreq;

  SensorInput({
    required this.heartRms,
    required this.lungRms,
    this.heartDetect = false,
    this.lungDetect = false,
    this.dominantFreq = 0.0,
  });
}

/// Diagnosis result model
class DiagnosisResult {
  final String diagnosis;
  final int riskPercentage;
  final String signalType;
  final double usedFrequency;
  final String status;
  final double confidence;

  DiagnosisResult({
    required this.diagnosis,
    required this.riskPercentage,
    required this.signalType,
    required this.usedFrequency,
    required this.status,
    required this.confidence,
  });

  @override
  String toString() {
    return 'DiagnosisResult(diagnosis: $diagnosis, risk: $riskPercentage%, '
           'type: $signalType, freq: $usedFrequency, status: $status)';
  }
}

/// Local AI Stethoscope Rule Engine
/// Implements the same logic as your Python FastAPI model
class LocalDiagnosisService {
  static final LocalDiagnosisService _instance = LocalDiagnosisService._internal();
  factory LocalDiagnosisService() => _instance;
  LocalDiagnosisService._internal();

  /// Main prediction method that processes sensor input
  DiagnosisResult predict(SensorInput data) {
    // A. Determine Signal Type & Fill Missing Freq
    String signalType = "heart";
    double fakeFreq = 80.0;
    
    if (data.lungDetect) {
      signalType = "lung";
      fakeFreq = 300.0;
    } else if (data.heartDetect) {
      signalType = "heart";
      fakeFreq = 80.0;
    }

    // B. Get Prediction & Risk Score
    // Uses the real freq if available, otherwise uses the "fake" one
    final freqToUse = data.dominantFreq > 0 ? data.dominantFreq : fakeFreq;
    final maxRms = math.max(data.heartRms, data.lungRms);
    final diagnosisResult = _getDiagnosis(freqToUse, maxRms, signalType);

    // C. Return Formatted Result
    final status = diagnosisResult.riskScore > 50 ? "High Risk" : "Normal";
    
    return DiagnosisResult(
      diagnosis: diagnosisResult.diagnosis,
      riskPercentage: diagnosisResult.riskScore,
      signalType: signalType,
      usedFrequency: freqToUse,
      status: status,
      confidence: _calculateConfidence(diagnosisResult.riskScore, maxRms, freqToUse),
    );
  }

  /// Convenience method for Flutter app integration
  /// Processes frequency data collected from device
  DiagnosisResult predictFromDeviceData({
    required List<int> frequencyData,
    required List<double> rmsData,
    required bool isHeartMode,
  }) {
    // Calculate average frequency and RMS from collected data
    final avgFreq = frequencyData.isNotEmpty 
        ? frequencyData.reduce((a, b) => a + b) / frequencyData.length.toDouble()
        : 0.0;
    
    final avgRms = rmsData.isNotEmpty 
        ? rmsData.reduce((a, b) => a + b) / rmsData.length
        : 0.0;

    // Create sensor input
    final sensorInput = SensorInput(
      heartRms: isHeartMode ? avgRms : 0.0,
      lungRms: !isHeartMode ? avgRms : 0.0,
      heartDetect: isHeartMode,
      lungDetect: !isHeartMode,
      dominantFreq: avgFreq,
    );

    return predict(sensorInput);
  }

  /// Core diagnosis logic with variable risk calculation
  _DiagnosisData _getDiagnosis(double freq, double rms, String signalType) {
    if (signalType == "lung") {
      return _analyzeLungCondition(freq, rms);
    } else {
      return _analyzeHeartCondition(freq, rms);
    }
  }

  /// Advanced lung condition analysis with variable risk
  _DiagnosisData _analyzeLungCondition(double freq, double rms) {
    // BASE RISK CALCULATION
    double baseRisk = 5.0; // Start with normal baseline
    String diagnosis = "Normal";
    
    // FREQUENCY-BASED RISK ANALYSIS
    if (freq == 0) {
      // No frequency data - rely on RMS analysis
      if (rms < 0.01) {
        baseRisk = 3 + (rms * 200); // 3-5% for very low RMS
        diagnosis = "Normal";
      } else if (rms > 0.05) {
        baseRisk = 70 + (rms * 300); // 70-85% for high RMS (COPD)
        diagnosis = "COPD";
      } else {
        baseRisk = 35 + (rms * 200); // 35-45% for moderate RMS (Asthma)
        diagnosis = "Asthma";
      }
    } else {
      // Frequency data available - comprehensive analysis
      if (freq < 150) {
        // Low frequency range
        if (rms < 0.01) {
          baseRisk = 2 + (freq / 50) + (rms * 100); // 2-8% progressive
          diagnosis = "Normal";
        } else {
          baseRisk = 25 + (freq / 10) + (rms * 300); // 25-50% 
          diagnosis = "Mild Respiratory Abnormality";
        }
      } else if (freq >= 150 && freq < 200) {
        // Transition zone
        baseRisk = 8 + ((freq - 150) / 10) + (rms * 400); // 8-25%
        diagnosis = rms > 0.03 ? "Respiratory Concern" : "Borderline Normal";
      } else if (freq >= 200 && freq <= 400) {
        // High frequency - likely pathological
        double freqFactor = ((freq - 200) / 200) * 30; // 0-30% based on freq
        double rmsFactor = rms * 500; // RMS contribution
        baseRisk = 60 + freqFactor + rmsFactor; // 60-95%
        
        if (freq < 300) {
          diagnosis = "Pneumonia";
        } else {
          diagnosis = rms > 0.04 ? "Severe Pneumonia" : "Pneumonia";
        }
      } else if (freq > 400) {
        // Very high frequency - TB territory
        double severity = math.min((freq - 400) / 100, 2.0); // Severity multiplier
        baseRisk = 80 + (severity * 10) + (rms * 600); // 80-98%
        diagnosis = severity > 1.0 ? "Advanced Tuberculosis" : "Tuberculosis";
      }
      
      // COPD override for high RMS regardless of frequency
      if (rms > 0.06) {
        baseRisk = 75 + (rms * 400); // 75-95%
        diagnosis = rms > 0.08 ? "Severe COPD" : "COPD";
      }
    }
    
    // Clamp risk to realistic medical range (1-98%)
    final finalRisk = math.max(1, math.min(98, baseRisk.round()));
    return _DiagnosisData(diagnosis, finalRisk);
  }

  /// Advanced heart condition analysis with variable risk
  _DiagnosisData _analyzeHeartCondition(double freq, double rms) {
    double baseRisk = 5.0; // Normal baseline
    String diagnosis = "Normal";
    
    if (freq == 0) {
      // No frequency data - RMS-only analysis
      if (rms < 0.03) {
        baseRisk = 2 + (rms * 200); // 2-8% for low RMS
        diagnosis = "Normal";
      } else if (rms < 0.08) {
        baseRisk = 15 + (rms * 400); // 15-47% moderate risk
        diagnosis = "Heart Irregularity";
      } else {
        baseRisk = 70 + (rms * 350); // 70-98% high RMS
        diagnosis = rms > 0.12 ? "Severe Heart Abnormality" : "Heart Abnormality";
      }
    } else {
      // Frequency data available
      if (freq >= 60 && freq <= 100) {
        // Normal heart rate range
        if (rms < 0.03) {
          baseRisk = 1 + ((100 - freq) / 20) + (rms * 150); // 1-8%
          diagnosis = "Normal";
        } else if (rms < 0.06) {
          baseRisk = 12 + (rms * 300); // 12-30%
          diagnosis = "Mild Heart Concern";
        } else {
          baseRisk = 35 + (rms * 400); // 35-59%
          diagnosis = "Heart Rhythm Abnormality";
        }
      } else if (freq < 60) {
        // Bradycardia territory
        double bradyFactor = (60 - freq) / 2; // Severity based on how low
        baseRisk = 15 + bradyFactor + (rms * 500); // 15-70%
        diagnosis = freq < 45 ? "Severe Bradycardia" : "Bradycardia";
      } else if (freq > 100 && freq <= 150) {
        // Mild tachycardia
        double tachyFactor = (freq - 100) / 5; // Severity factor
        baseRisk = 10 + tachyFactor + (rms * 400); // 10-60%
        diagnosis = freq > 130 ? "Tachycardia" : "Elevated Heart Rate";
      } else if (freq > 150) {
        // Severe tachycardia or abnormal
        double severity = (freq - 150) / 10;
        baseRisk = 45 + severity + (rms * 600); // 45-90%
        diagnosis = freq > 200 ? "Critical Heart Abnormality" : "Severe Tachycardia";
      } else if (freq < 20 || freq > 250) {
        // Extremely abnormal readings
        baseRisk = 80 + (rms * 500); // 80-95%
        diagnosis = "Critical Heart Condition";
      }
      
      // High RMS override
      if (rms > 0.10) {
        baseRisk = math.max(baseRisk, 70 + (rms * 400)); // Ensure high risk for high RMS
        diagnosis = "Severe Heart Abnormality";
      }
    }
    
    // Clamp to medical range
    final finalRisk = math.max(1, math.min(98, baseRisk.round()));
    return _DiagnosisData(diagnosis, finalRisk);
  }

  /// Calculate dynamic confidence based on signal quality and data consistency
  double _calculateConfidence(int riskScore, double rms, double freq) {
    double confidence = 0.5; // Base confidence
    
    // Data quality indicators
    if (freq > 0) {
      confidence += 0.15; // Frequency data available
      
      // Reasonable frequency ranges increase confidence
      if ((freq >= 60 && freq <= 150) || (freq >= 100 && freq <= 500)) {
        confidence += 0.1;
      }
    }
    
    // RMS signal strength indicators
    if (rms > 0.005) confidence += 0.1; // Detectable signal
    if (rms > 0.01) confidence += 0.1;  // Good signal strength
    if (rms > 0.03 && rms < 0.15) confidence += 0.1; // Strong but not saturated
    
    // Risk-based confidence adjustments
    if (riskScore <= 10 || riskScore >= 80) {
      confidence += 0.1; // Clear normal or clear abnormal cases
    } else if (riskScore >= 20 && riskScore <= 70) {
      confidence += 0.05; // Moderate confidence in intermediate cases
    }
    
    // Penalize extreme or unrealistic values
    if (freq > 1000 || rms > 0.5) {
      confidence -= 0.2; // Likely sensor error
    }
    
    return math.max(0.3, math.min(0.95, confidence)); // Clamp between 30-95%
  }

  /// Get detailed medical recommendation based on risk level and diagnosis
  String getRecommendation(DiagnosisResult result) {
    final risk = result.riskPercentage;
    final diagnosis = result.diagnosis.toLowerCase();
    
    // Risk-based recommendations
    if (risk <= 5) {
      return 'Excellent! No concerns detected. Continue with annual health checkups.';
    } else if (risk <= 15) {
      return 'Good health indicators. Consider semi-annual checkups for monitoring.';
    } else if (risk <= 30) {
      return 'Mild concerns detected. Recommend consultation with healthcare provider within 1-2 weeks.';
    } else if (risk <= 50) {
      return 'Moderate risk detected. Please schedule medical consultation within 3-5 days.';
    } else if (risk <= 70) {
      return 'Significant abnormalities detected. Seek medical attention within 1-2 days.';
    } else if (risk <= 85) {
      return 'High risk condition identified. Please consult healthcare professional immediately.';
    } else {
      return 'Critical condition detected. Seek immediate emergency medical attention.';
    }
  }
}

/// Internal helper class
class _DiagnosisData {
  final String diagnosis;
  final int riskScore;
  
  _DiagnosisData(this.diagnosis, this.riskScore);
}
