import 'dart:math';

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

/// React Native / JavaScript style processor
/// Mimics JavaScript's functional programming approach
class ReactNativeStyleProcessor {
  final List<double> _redValues = [];
  final List<DateTime> _timestamps = [];
  
  static const int _sampleSize = 150;
  static const int _minSamples = 60;
  static const int _maxBpm = 200;
  static const int _minBpm = 45;

  void processFrame(double redValue) {
    _redValues.add(redValue);
    _timestamps.add(DateTime.now());

    // JS style: Maintain max length with slice-like behavior
    if (_redValues.length > _sampleSize) {
      _redValues.removeRange(0, _redValues.length - _sampleSize);
      _timestamps.removeRange(0, _timestamps.length - _sampleSize);
    }
  }

  HeartRateResult? calculateHeartRate() {
    if (_redValues.length < _minSamples) return null;

    // JavaScript/React Native style: Functional, immutable-style operations
    
    // 1. Detrend using reduce and map
    final detrended = _jsStyleDetrend(_redValues);
    
    // 2. Filter using lodash-style operations
    final filtered = _jsStyleBandpassFilter(detrended);
    
    // 3. Peak detection using array methods
    final bpm = _jsStylePeakDetection(filtered);
    
    if (bpm == null || bpm < _minBpm || bpm > _maxBpm) return null;

    // JS style confidence calculation
    final confidence = _jsStyleConfidence(filtered, bpm);

    return HeartRateResult(
      bpm: bpm.round(),
      confidence: confidence,
      timestamp: DateTime.now(),
    );
  }

  /// JavaScript Array.reduce style detrending
  List<double> _jsStyleDetrend(List<double> signal) {
    // Calculate mean using reduce (JS style)
    final mean = signal.fold<double>(0.0, (sum, val) => sum + val) / signal.length;
    
    // Map to detrended values (JS Array.map style)
    return signal.map((val) => val - mean).toList();
  }

  /// JavaScript style bandpass filter
  List<double> _jsStyleBandpassFilter(List<double> signal) {
    // Simulate lodash's chunk and map operations
    final windowSize = 7;
    
    return signal.asMap().entries.map((entry) {
      final i = entry.key;
      final val = entry.value;
      
      // Get window slice (JS style)
      final start = max(0, i - windowSize ~/ 2);
      final end = min(signal.length, i + windowSize ~/ 2 + 1);
      final window = signal.sublist(start, end);
      
      // Calculate average (reduce style)
      final avg = window.reduce((a, b) => a + b) / window.length;
      
      return val - avg;
    }).toList();
  }

  /// JavaScript Array methods style peak detection
  double? _jsStylePeakDetection(List<double> signal) {
    // Calculate threshold (JS functional style)
    final absValues = signal.map((v) => v.abs()).toList();
    final threshold = absValues.reduce((a, b) => a + b) / absValues.length * 0.4;
    
    // Find peaks using filter and array indices
    final peaks = <int>[];
    
    for (int i = 1; i < signal.length - 1; i++) {
      final isPeak = signal[i] > signal[i - 1] && 
                     signal[i] > signal[i + 1] && 
                     signal[i] > threshold;
      
      if (isPeak) peaks.add(i);
    }

    if (peaks.length < 2) return null;

    // Calculate intervals (JS Array.map with indices)
    final intervals = peaks.skip(1).toList().asMap().entries.map((entry) {
      final i = entry.key;
      return (peaks[i + 1] - peaks[i]).toDouble();
    }).toList();

    // Remove outliers (JS Array.filter style)
    final median = _jsStyleMedian(intervals);
    final filteredIntervals = intervals
        .where((interval) => (interval - median).abs() < median * 0.5)
        .toList();

    if (filteredIntervals.isEmpty) return null;

    // Average (reduce)
    final avgInterval = filteredIntervals.reduce((a, b) => a + b) / 
                       filteredIntervals.length;
    
    // Calculate BPM
    final timeSpan = _timestamps.last.difference(_timestamps.first).inMilliseconds / 1000.0;
    final fps = _timestamps.length / timeSpan;
    final secondsPerBeat = avgInterval / fps;
    
    return 60.0 / secondsPerBeat;
  }

  /// JavaScript style median calculation
  double _jsStyleMedian(List<double> arr) {
    // Spread operator and sort (JS style)
    final sorted = [...arr]..sort();
    final mid = sorted.length ~/ 2;
    
    // Ternary operator (JS style)
    return sorted.length.isEven
        ? (sorted[mid - 1] + sorted[mid]) / 2
        : sorted[mid];
  }

  /// JavaScript object-style confidence calculation
  double _jsStyleConfidence(List<double> signal, double bpm) {
    // Calculate SNR using functional methods
    final mean = signal.reduce((a, b) => a + b) / signal.length;
    final variance = signal
        .map((val) => pow(val - mean, 2))
        .reduce((a, b) => a + b) / signal.length;
    final stdDev = sqrt(variance);
    
    final snr = min(stdDev / (mean.abs() + 1), 1.0);
    
    // Check if in normal range (ternary operator style)
    final inNormalRange = (bpm >= 60 && bpm <= 100) ? 1.0 : 0.7;
    
    // Recent signal stability
    final recent = signal.length > 30 ? signal.sublist(signal.length - 30) : signal;
    final recentMean = recent.reduce((a, b) => a + b) / recent.length;
    final stability = 1.0 - min((recentMean - mean).abs() / (mean.abs() + 1), 1.0);
    
    // Weighted combination (JS object destructuring style concept)
    return snr * 0.4 + inNormalRange * 0.3 + stability * 0.3;
  }

  void reset() {
    _redValues.clear();
    _timestamps.clear();
  }

  int getSampleCount() => _redValues.length;
  bool hasEnoughSamples() => _redValues.length >= _minSamples;
}
