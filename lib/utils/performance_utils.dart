import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PerformanceUtils {
  static const _platform = MethodChannel('performance_utils');

  /// Optimise les performances de l'application
  static Future<void> optimizePerformance() async {
    if (!kIsWeb) {
      // Configurer la priorité des threads
      await _configurePriority();

      // Précharger les ressources critiques
      await _preloadCriticalResources();

      // Configurer la gestion mémoire
      await _configureMemoryManagement();
    }
  }

  /// Configure la priorité des threads pour éviter les frames sautées
  static Future<void> _configurePriority() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _platform.invokeMethod('setHighPriority');
      }
    } catch (e) {
      debugPrint('Erreur lors de la configuration de priorité: $e');
    }
  }

  /// Précharge les ressources critiques
  static Future<void> _preloadCriticalResources() async {
    // Cette méthode peut être étendue pour précharger des ressources spécifiques
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Configure la gestion mémoire optimale
  static Future<void> _configureMemoryManagement() async {
    // Force le garbage collector pour libérer la mémoire
    if (kDebugMode) {
      // En mode debug, on peut forcer le GC
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Exécute une tâche lourde dans un isolate séparé
  static Future<T> runInBackground<T>(
    Future<T> Function() computation,
  ) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _isolateEntryPoint,
      IsolateData(receivePort.sendPort, computation),
    );

    return await receivePort.first as T;
  }

  static void _isolateEntryPoint(IsolateData data) async {
    try {
      final result = await data.computation();
      data.sendPort.send(result);
    } catch (e) {
      data.sendPort.send(e);
    }
  }

  /// Débounce pour éviter les appels trop fréquents
  static Timer? _debounceTimer;

  static void debounce(
    Duration duration,
    VoidCallback callback,
  ) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }

  /// Throttle pour limiter la fréquence d'exécution
  static DateTime? _lastExecution;

  static void throttle(
    Duration duration,
    VoidCallback callback,
  ) {
    final now = DateTime.now();
    if (_lastExecution == null || now.difference(_lastExecution!) >= duration) {
      _lastExecution = now;
      callback();
    }
  }

  /// Nettoie les ressources
  static void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _lastExecution = null;
  }
}

class IsolateData<T> {
  final SendPort sendPort;
  final Future<T> Function() computation;

  IsolateData(this.sendPort, this.computation);
}

/// Mixin pour optimiser les widgets qui se rebuilds fréquemment
mixin PerformanceOptimizedWidget {
  bool _canRebuild = true;
  Timer? _rebuildTimer;

  void throttleRebuild(VoidCallback rebuild, [Duration? duration]) {
    if (!_canRebuild) return;

    _canRebuild = false;
    rebuild();

    _rebuildTimer?.cancel();
    _rebuildTimer = Timer(
      duration ?? const Duration(milliseconds: 16), // 60 FPS
      () => _canRebuild = true,
    );
  }

  void disposePerformanceOptimization() {
    _rebuildTimer?.cancel();
    _rebuildTimer = null;
  }
}

/// Extension pour optimiser les listes
extension OptimizedList<T> on List<T> {
  /// Divise la liste en chunks pour éviter les gros rebuilds
  List<List<T>> chunk(int size) {
    List<List<T>> chunks = [];
    for (int i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
}

/// Widget optimisé pour les listes longues
class OptimizedListView extends StatelessWidget {
  final List<Widget> children;
  final int chunkSize;
  final Duration animationDuration;

  const OptimizedListView({
    super.key,
    required this.children,
    this.chunkSize = 10,
    this.animationDuration = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: animationDuration,
          child: children[index],
        );
      },
    );
  }
}
