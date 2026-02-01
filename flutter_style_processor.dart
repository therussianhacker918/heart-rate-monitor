import 'dart:math';
import 'dart:typed_data';

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

/// Flutter/Dart optimized processor
/// Uses Dart's strengths: strong typing, null safety, efficient collections
class FlutterStyleProcessor {
  // Use typed lists for better performance
  final List<double> _redValues = <double>[];
  final List<DateTime> _timestamps = <DateTime>[];
  
  static const int _sampleSize = 150;
  static const int _minSamples = 60;
  static const int _maxBpm = 200;
  static const int _minBpm = 45;
  
  // Cache for performance
  double? _lastMean;
  int _lastCalculationLength = 0;

  void processFrame(double redValue) {
    _redValues.add(redValue);
    _timestamps.add(DateTime.now());

    // Efficient list management
    while (_redValues.length > _sampleSize) {
      _redValues.removeAt(0);
      _timestamps.removeAt(0);
    }
    
    // Invalidate cache
    _lastMean = null;
  }

  HeartRateResult? calculateHeartRate() {
    if (_redValues.length < _minSamples) return null;

    // Dart style: Efficient, type-safe operations with caching
    
    // 1. Detrend with caching
    final detrended = _dartStyleDetrend();
    
    // 2. Efficient bandpass filter using typed data
    final filtered = _dartStyleBandpassFilter(detrended);
    
    // 3. Optimized peak detection
    final bpm = _dartStylePeakDetection(filtered);
    
    if (bpm == null || bpm < _minBpm || bpm > _maxBpm) return null;

    // Efficient confidence calculation
    final confidence = _dartStyleConfidence(filtered, bpm);

    return HeartRateResult(
      bpm: bpm.round(),
      confidence: confidence,
      timestamp: DateTime.now(),
    );
  }

  /// Dart-optimized detrending with caching
  List<double> _dartStyleDetrend() {
    // Use cached mean if available
    if (_lastMean == null || _lastCalculationLength != _redValues.length) {
      _lastMean = _redValues.reduce((a, b) => a + b) / _redValues.length;
      _lastCalculationLength = _redValues.length;
    }
    
    final mean = _lastMean!;
    
    // Preallocate list for efficiency
    final result = List<double>.filled(_redValues.length, 0.0);
    
    for (int i = 0; i < _redValues.length; i++) {
      result[i] = _redValues[i] - mean;
    }
    
    return result;
  }

  /// Dart-optimized bandpass filter
  List<double> _dartStyleBandpassFilter(List<double> signal) {
    const windowSize = 7;
    final length = signal.length;
    
    // Preallocate result
    final result = List<double>.filled(length, 0.0);
    
    // Efficient windowing
    for (int i = 0; i < length; i++) {
      final start = max(0, i - windowSize ~/ 2);
      final end = min(length, i + windowSize ~/ 2 + 1);
      
      // Calculate sum efficiently
      double sum = 0.0;
      for (int j = start; j < end; j++) {
        sum += signal[j];
      }
      
      final avg = sum / (end - start);
      result[i] = signal[i] - avg;
    }
    
    return result;
  }

  /// Dart-optimized peak detection with early returns
  double? _dartStylePeakDetection(List<double> signal) {
    // Efficient threshold calculation
    double absSum = 0.0;
    for (final val in signal) {
      absSum += val.abs();
    }
    final threshold = (absSum / signal.length) * 0.45;
    
    // Preallocate peak list
    final peaks = <int>[];
    
    // Efficient peak finding
    for (int i = 1; i < signal.length - 1; i++) {
      if (signal[i] > signal[i - 1] && 
          signal[i] > signal[i + 1] && 
          signal[i] > threshold) {
        peaks.add(i);
      }
    }

    if (peaks.length < 2) return null;

    // Calculate intervals efficiently
    final intervals = <double>[];
    for (int i = 1; i < peaks.length; i++) {
      intervals.add((peaks[i] - peaks[i - 1]).toDouble());
    }

    // Efficient median calculation
    final median = _dartStyleMedian(intervals);
    
    // Filter outliers
    final validIntervals = <double>[];
    for (final interval in intervals) {
      if ((interval - median).abs() < median * 0.5) {
        validIntervals.add(interval);
      }
    }

    if (validIntervals.isEmpty) return null;

    // Calculate average
    double sum = 0.0;
    for (final interval in validIntervals) {
      sum += interval;
    }
    final avgInterval = sum / validIntervals.length;
    
    // BPM calculation
    final timeSpan = _timestamps.last.difference(_timestamps.first).inMilliseconds / 1000.0;
    final fps = _timestamps.length / timeSpan;
    final secondsPerBeat = avgInterval / fps;
    
    return 60.0 / secondsPerBeat;
  }

  /// Dart-optimized median with in-place sorting
  double _dartStyleMedian(List<double> values) {
    // Sort in-place for efficiency
    values.sort();
    
    final mid = values.length ~/ 2;
    
    return values.length.isEven
        ? (values[mid - 1] + values[mid]) / 2.0
        : values[mid];
  }

  /// Dart-optimized confidence calculation
  double _dartStyleConfidence(List<double> signal, double bpm) {
    // Single pass for mean and variance
    double sum = 0.0;
    for (final val in signal) {
      sum += val;
    }
    final mean = sum / signal.length;
    
    double varianceSum = 0.0;
    for (final val in signal) {
      final diff = val - mean;
      varianceSum += diff * diff;
    }
    final variance = varianceSum / signal.length;
    final stdDev = sqrt(variance);
    
    // SNR calculation
    final snr = min(stdDev / (mean.abs() + 1.0), 1.0);
    
    // Normal range check
    final inNormalRange = (bpm >= 60 && bpm <= 100) ? 1.0 : 0.7;
    
    // Stability check on recent samples
    final recentCount = min(30, signal.length);
    final recentStart = signal.length - recentCount;
    
    double recentSum = 0.0;
    for (int i = recentStart; i < signal.length; i++) {
      recentSum += signal[i];
    }
    final recentMean = recentSum / recentCount;
    
    final stability = 1.0 - min((recentMean - mean).abs() / (mean.abs() + 1.0), 1.0);
    
    // Weighted combination
    return snr * 0.4 + inNormalRange * 0.3 + stability * 0.3;
  }

  void reset() {
    _redValues.clear();
    _timestamps.clear();
    _lastMean = null;
    _lastCalculationLength = 0;
  }

  int getSampleCount() => _redValues.length;
  bool hasEnoughSamples() => _redValues.length >= _minSamples;
}
