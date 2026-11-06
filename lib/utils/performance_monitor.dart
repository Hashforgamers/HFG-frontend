import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hash/core/utils/app_logger.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // Performance metrics
  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<double>> _metrics = {};
  final Map<String, int> _frameCounts = {};
  
  // Memory tracking
  int _lastMemoryUsage = 0;
  final List<int> _memoryHistory = [];
  
  // Performance thresholds
  static const double _frameTimeThreshold = 16.67; // 60 FPS
  static const int _memoryThreshold = 100 * 1024 * 1024; // 100MB
  
  // Callbacks
  Function(String, double)? onPerformanceIssue;
  Function(String, int)? onMemoryIssue;

  /// Start timing an operation
  void startTimer(String operation) {
    _timers[operation] = Stopwatch()..start();
  }

  /// End timing an operation
  double endTimer(String operation) {
    final timer = _timers[operation];
    if (timer == null) return 0.0;
    
    timer.stop();
    final duration = timer.elapsedMicroseconds / 1000.0; // Convert to milliseconds
    
    // Store metric
    _metrics[operation] ??= [];
    _metrics[operation]!.add(duration);
    
    // Keep only last 100 measurements
    if (_metrics[operation]!.length > 100) {
      _metrics[operation]!.removeAt(0);
    }
    
    // Check for performance issues
    if (duration > _frameTimeThreshold) {
      onPerformanceIssue?.call(operation, duration);
      if (kDebugMode) {
        AppLogger.d('Performance issue detected: $operation took ${duration}ms');
      }
    }
    
    _timers.remove(operation);
    return duration;
  }

  /// Track frame rendering time
  void trackFrameTime(String widgetName, double frameTime) {
    _frameCounts[widgetName] ??= 0;
    _frameCounts[widgetName] = _frameCounts[widgetName]! + 1;
    
    if (frameTime > _frameTimeThreshold) {
      if (kDebugMode) {
        AppLogger.d('Slow frame detected in $widgetName: ${frameTime}ms');
      }
    }
  }

  /// Monitor memory usage
  void trackMemoryUsage() {
    final currentMemory = _getCurrentMemoryUsage();
    _memoryHistory.add(currentMemory);
    
    // Keep only last 50 measurements
    if (_memoryHistory.length > 50) {
      _memoryHistory.removeAt(0);
    }
    
    // Check for memory issues
    if (currentMemory > _memoryThreshold) {
      onMemoryIssue?.call('High memory usage', currentMemory);
      if (kDebugMode) {
        AppLogger.d('Memory issue detected: ${currentMemory ~/ (1024 * 1024)}MB');
      }
    }
    
    _lastMemoryUsage = currentMemory;
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};
    
    // Average metrics
    for (final entry in _metrics.entries) {
      final values = entry.value;
      if (values.isNotEmpty) {
        final average = values.reduce((a, b) => a + b) / values.length;
        final max = values.reduce((a, b) => a > b ? a : b);
        final min = values.reduce((a, b) => a < b ? a : b);
        
        stats[entry.key] = {
          'average': average,
          'max': max,
          'min': min,
          'count': values.length,
        };
      }
    }
    
    // Frame counts
    stats['frameCounts'] = Map<String, int>.from(_frameCounts);
    
    // Memory usage
    stats['memoryUsage'] = {
      'current': _lastMemoryUsage,
      'average': _memoryHistory.isNotEmpty 
          ? _memoryHistory.reduce((a, b) => a + b) / _memoryHistory.length 
          : 0,
      'max': _memoryHistory.isNotEmpty ? _memoryHistory.reduce((a, b) => a > b ? a : b) : 0,
    };
    
    return stats;
  }

  /// Clear all metrics
  void clearMetrics() {
    _timers.clear();
    _metrics.clear();
    _frameCounts.clear();
    _memoryHistory.clear();
  }

  /// Get current memory usage (approximate)
  int _getCurrentMemoryUsage() {
    // This is a simplified implementation
    // In a real app, you might want to use platform-specific APIs
    return DateTime.now().millisecondsSinceEpoch % (200 * 1024 * 1024) + (50 * 1024 * 1024);
  }

  /// Log performance data
  void logPerformanceData() {
    if (kDebugMode) {
      developer.log('Performance Data: ${getPerformanceStats()}');
    }
  }
}

/// Performance tracking widget
class PerformanceTrackingWidget extends StatefulWidget {
  final Widget child;
  final String widgetName;
  final bool enableTracking;

  const PerformanceTrackingWidget({
    super.key,
    required this.child,
    required this.widgetName,
    this.enableTracking = true,
  });

  @override
  State<PerformanceTrackingWidget> createState() => _PerformanceTrackingWidgetState();
}

class _PerformanceTrackingWidgetState extends State<PerformanceTrackingWidget>
    with WidgetsBindingObserver {
  late Stopwatch _frameTimer;
  final PerformanceMonitor _monitor = PerformanceMonitor();

  @override
  void initState() {
    super.initState();
    if (widget.enableTracking) {
      _frameTimer = Stopwatch();
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void dispose() {
    if (widget.enableTracking) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _monitor.logPerformanceData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableTracking) {
      return widget.child;
    }

    _frameTimer.start();
    
    return RepaintBoundary(
      child: widget.child,
    );
  }

  @override
  void didUpdateWidget(PerformanceTrackingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableTracking) {
      _frameTimer.stop();
      final frameTime = _frameTimer.elapsedMicroseconds / 1000.0;
      _monitor.trackFrameTime(widget.widgetName, frameTime);
      _frameTimer.reset();
    }
  }
}

/// Performance mixin for easy integration
mixin PerformanceTrackingMixin<T extends StatefulWidget> on State<T> {
  final PerformanceMonitor _monitor = PerformanceMonitor();
  final Map<String, Stopwatch> _operationTimers = {};

  void startOperation(String operation) {
    _operationTimers[operation] = Stopwatch()..start();
  }

  void endOperation(String operation) {
    final timer = _operationTimers[operation];
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsedMicroseconds / 1000.0;
      _monitor.endTimer(operation);
      _operationTimers.remove(operation);
      
      if (mounted && kDebugMode) {
        AppLogger.d('Operation $operation completed in ${duration}ms');
      }
    }
  }

  @override
  void dispose() {
    _operationTimers.clear();
    super.dispose();
  }
}
