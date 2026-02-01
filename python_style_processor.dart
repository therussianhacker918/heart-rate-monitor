import 'dart:math';
import 'package:flutter/foundation.dart';

class HeartRateResult {
  final int bpm;
  final double confidence;
  final DateTime timestamp;

  HeartRateResult({
    required this.bpm,
    required this.confidence,
    required this.timestamp,
  });
}

/// Python/Kivy style processor
/// Mimics NumPy-style operations and Python's approach
class PythonStyleProcessor {
  final List<double> _redValues = [];
  final List<DateTime> _timestamps = [];
  
  static const int _sampleSize = 150;
  static const int _minSamples = 60;
  static const int _maxBpm = 200;
  static const int _minBpm = 45;

  void processFrame(double redValue) {
    _redValues.add(redValue);
    _timestamps.add(DateTime.now());

    if (_redValues.length > _sampleSize) {
      _redValues.removeAt(0);
      _timestamps.removeAt(0);
    }
  }

  HeartRateResult? calculateHeartRate() {
    if (_redValues.length < _minSamples) return null;

    // Python/NumPy style: Heavy on list comprehensions and functional operations
    
    // 1. Detrend using numpy-style mean subtraction
    final mean = _redValues.reduce((a, b) => a + b) / _redValues.length;
    final detrended = _redValues.map((v) => v - mean).toList();
    
    // 2. Python style: Use simple moving average for filtering
    final filtered = _pythonStyleMovingAverage(detrended, 5);
    
    // 3. FFT-inspired peak detection (Python/scipy style)
    final bpm = _pythonStyleFFT(filtered);
    
    if (bpm == null || bpm < _minBpm || bpm > _maxBpm) return null;

    // Python style confidence (simple variance-based)
    final variance = _pythonStyleVariance(filtered);
    final confidence = _mapVarianceToConfidence(variance);

    return HeartRateResult(
      bpm: bpm.round(),
      confidence: confidence,
      timestamp: DateTime.now(),
    );
  }

  /// Python-style moving average (like numpy.convolve)
  List<double> _pythonStyleMovingAverage(List<double> data, int window) {
    final result = <double>[];
    for (int i = 0; i < data.length; i++) {
      final start = max(0, i - window ~/ 2);
      final end = min(data.length, i + window ~/ 2 + 1);
      final slice = data.sublist(start, end);
      final avg = slice.reduce((a, b) => a + b) / slice.length;
      result.add(avg);
    }
    return result;
  }

  /// Python/scipy style FFT simulation
  double? _pythonStyleFFT(List<double> signal) {
    // Simulate FFT by finding dominant frequency through autocorrelation
    // This is how Python's scipy.signal.find_peaks works conceptually
    
    final peaks = <int>[];
    final threshold = _pythonStyleVariance(signal).abs() * 0.3;
    
    // Find peaks (Python style with enumerate)
    for (int i = 1; i < signal.length - 1; i++) {
      if (signal[i] > signal[i - 1] && 
          signal[i] > signal[i + 1] && 
          signal[i].abs() > threshold) {
        peaks.add(i);
      }
    }

    if (peaks.length < 2) return null;

    // Calculate average interval (Python style)
    final intervals = <double>[];
    for (int i = 1; i < peaks.length; i++) {
      intervals.add((peaks[i] - peaks[i - 1]).toDouble());
    }

    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    
    // Convert to BPM
    final timeSpan = _timestamps.last.difference(_timestamps.first).inMilliseconds / 1000.0;
    final fps = _timestamps.length / timeSpan;
    final secondsPerBeat = avgInterval / fps;
    
    return 60.0 / secondsPerBeat;
  }

  /// Python-style variance calculation
  double _pythonStyleVariance(List<double> data) {
    final mean = data.reduce((a, b) => a + b) / data.length;
    final squaredDiffs = data.map((v) => pow(v - mean, 2)).toList();
    return squaredDiffs.reduce((a, b) => a + b) / data.length;
  }

  double _mapVarianceToConfidence(double variance) {
    // Python style: Simple linear mapping
    final normalized = min(variance / 100.0, 1.0);
    return max(0.0, min(1.0, normalized));
  }

  void reset() {
    _redValues.clear();
    _timestamps.clear();
  }

  int getSampleCount() => _redValues.length;
  bool hasEnoughSamples() => _redValues.length >= _minSamples;
}
