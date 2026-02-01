import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:torch_light/torch_light.dart';
import 'dart:async';
import 'dart:math';

// Import all three processors
import 'python_style_processor.dart';
import 'react_native_style_processor.dart';
import 'flutter_style_processor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ComparisonApp());
}

class ComparisonApp extends StatelessWidget {
  const ComparisonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heart Rate Comparison',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0a0e27),
      ),
      home: const ComparisonScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  CameraController? _cameraController;
  bool _isMeasuring = false;
  
  // Three different processors
  final PythonStyleProcessor _pythonProcessor = PythonStyleProcessor();
  final ReactNativeStyleProcessor _rnProcessor = ReactNativeStyleProcessor();
  final FlutterStyleProcessor _flutterProcessor = FlutterStyleProcessor();
  
  // Results from each
  HeartRateResult? _pythonResult;
  HeartRateResult? _rnResult;
  HeartRateResult? _flutterResult;
  
  Timer? _measurementTimer;
  int _frameCount = 0;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await Permission.camera.request();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      _showError('Camera initialization failed: $e');
    }
  }

  Future<void> _startMeasurement() async {
    await _initializeCamera();
    
    setState(() {
      _isMeasuring = true;
      _pythonResult = null;
      _rnResult = null;
      _flutterResult = null;
      _frameCount = 0;
      _startTime = DateTime.now();
    });

    // Enable torch
    try {
      await TorchLight.enableTorch();
    } catch (e) {
      print('Torch error: $e');
    }

    // Reset all processors
    _pythonProcessor.reset();
    _rnProcessor.reset();
    _flutterProcessor.reset();

    // Process frames
    _measurementTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) => _processFrame(),
    );
  }

  Future<void> _stopMeasurement() async {
    _measurementTimer?.cancel();

    try {
      await TorchLight.disableTorch();
    } catch (e) {
      print('Torch error: $e');
    }

    await _cameraController?.dispose();
    _cameraController = null;

    setState(() {
      _isMeasuring = false;
    });
  }

  Future<void> _processFrame() async {
    if (!_isMeasuring || _cameraController == null) return;

    _frameCount++;
    
    // Simulate image data (in real app, extract from camera frame)
    final simulatedRedValue = _simulateRedChannel();
    
    // Process with all three algorithms
    _pythonProcessor.processFrame(simulatedRedValue);
    _rnProcessor.processFrame(simulatedRedValue);
    _flutterProcessor.processFrame(simulatedRedValue);

    // Calculate results from each
    if (_pythonProcessor.hasEnoughSamples()) {
      final result = _pythonProcessor.calculateHeartRate();
      if (result != null) {
        setState(() => _pythonResult = result);
      }
    }

    if (_rnProcessor.hasEnoughSamples()) {
      final result = _rnProcessor.calculateHeartRate();
      if (result != null) {
        setState(() => _rnResult = result);
      }
    }

    if (_flutterProcessor.hasEnoughSamples()) {
      final result = _flutterProcessor.calculateHeartRate();
      if (result != null) {
        setState(() => _flutterResult = result);
      }
    }
  }

  double _simulateRedChannel() {
    // Simulate realistic PPG signal
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final heartRate = 75.0; // Simulate ~75 BPM
    final signal = sin(2 * pi * (heartRate / 60.0) * time);
    final baseline = 128.0;
    final amplitude = 15.0;
    final noise = (Random().nextDouble() - 0.5) * 5.0;
    
    return baseline + signal * amplitude + noise;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _measurementTimer?.cancel();
    _cameraController?.dispose();
    TorchLight.disableTorch().catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCamera(),
            Expanded(child: _buildComparison()),
            _buildControls(),
            _buildStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.blue.shade700],
        ),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.science, size: 28),
              SizedBox(width: 10),
              Text(
                'Algorithm Comparison',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Python vs React Native vs Flutter',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildCamera() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: _cameraController?.value.isInitialized == true
            ? CameraPreview(_cameraController!)
            : Center(
                child: Text(
                  _isMeasuring ? 'Initializing...' : 'Camera ready',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
      ),
    );
  }

  Widget _buildComparison() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            'LIVE COMPARISON',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          
          // Python style
          _buildResultCard(
            '🐍 Python/Kivy Style',
            _pythonResult,
            Colors.blue,
            'NumPy-inspired algorithm',
          ),
          
          const SizedBox(height: 15),
          
          // React Native style
          _buildResultCard(
            '⚛️ React Native Style',
            _rnResult,
            Colors.cyan,
            'JavaScript-inspired algorithm',
          ),
          
          const SizedBox(height: 15),
          
          // Flutter style
          _buildResultCard(
            '💙 Flutter/Dart Style',
            _flutterResult,
            Colors.purple,
            'Dart-optimized algorithm',
          ),
          
          const SizedBox(height: 20),
          
          // Comparison summary
          if (_pythonResult != null && _rnResult != null && _flutterResult != null)
            _buildComparisonSummary(),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    String title,
    HeartRateResult? result,
    Color color,
    String description,
  ) {
    final bpm = result?.bpm ?? 0;
    final confidence = result?.confidence ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                result != null ? '$bpm' : '--',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'BPM',
                style: TextStyle(fontSize: 14, color: color),
              ),
              if (result != null) ...[
                const SizedBox(height: 4),
                _buildConfidenceBadge(confidence, color),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence, Color color) {
    String label;
    if (confidence >= 0.8) {
      label = 'High';
    } else if (confidence >= 0.5) {
      label = 'Medium';
    } else {
      label = 'Low';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }

  Widget _buildComparisonSummary() {
    final python = _pythonResult!.bpm;
    final rn = _rnResult!.bpm;
    final flutter = _flutterResult!.bpm;
    
    final average = ((python + rn + flutter) / 3).round();
    final maxDiff = [
      (python - average).abs(),
      (rn - average).abs(),
      (flutter - average).abs(),
    ].reduce(max);
    
    final agreement = maxDiff <= 3 ? 'Excellent' : maxDiff <= 5 ? 'Good' : 'Variable';
    final agreementColor = maxDiff <= 3 ? Colors.green : maxDiff <= 5 ? Colors.orange : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: agreementColor.withOpacity(0.1),
        border: Border.all(color: agreementColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📊 Analysis',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: agreementColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  agreement,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Average', '$average BPM'),
              _buildStatItem('Max Diff', '±$maxDiff BPM'),
              _buildStatItem('Range', '${[python, rn, flutter].reduce(min)}-${[python, rn, flutter].reduce(max)}'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            maxDiff <= 3
                ? '✅ All algorithms agree closely'
                : maxDiff <= 5
                    ? '⚠️ Algorithms show some variance'
                    : '❌ Significant disagreement between algorithms',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: _isMeasuring ? _stopMeasurement : _startMeasurement,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isMeasuring ? Colors.red : Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_isMeasuring ? Icons.stop : Icons.play_arrow, size: 28),
              const SizedBox(width: 10),
              Text(
                _isMeasuring ? 'Stop Comparison' : 'Start Comparison',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomStat('Frames', '$_frameCount'),
          _buildBottomStat(
            'Duration',
            _startTime != null
                ? '${DateTime.now().difference(_startTime!).inSeconds}s'
                : '0s',
          ),
          _buildBottomStat(
            'Status',
            _isMeasuring ? 'Measuring' : 'Idle',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Heart rate result class
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
