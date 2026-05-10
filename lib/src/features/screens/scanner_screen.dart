import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../app_state.dart';
import '../widgets/common.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _camera;
  Future<void>? _initFuture;
  bool _hasCamera = false;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (kIsWeb) {
      // The camera plugin on web requires an HTTPS host; skip and fall back.
      setState(() => _hasCamera = false);
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _hasCamera = false);
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _initFuture = controller.initialize();
      await _initFuture;
      if (!mounted) return;
      setState(() {
        _camera = controller;
        _hasCamera = true;
      });
    } catch (_) {
      if (mounted) setState(() => _hasCamera = false);
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze() async {
    final state = context.read<AppState>();
    setState(() => _scanning = true);
    try {
      if (_camera != null && _camera!.value.isInitialized) {
        await _camera!.takePicture();
      }
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await state.runScan();
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scan = state.latestScan;
    final concerns = (scan?['concerns'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    final dateStr = scan?['scan_date']?.toString();
    final scannedLabel =
        dateStr != null ? _formatScanDate(dateStr) : 'No scan yet';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI analysis',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    'Face scanner',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            const CircleIconButton(
              icon: Icons.history,
              shadow: false,
              background: AppTheme.softGray,
            ),
          ],
        ),
        const SizedBox(height: 20),

        _CameraStage(
          controller: _camera,
          hasCamera: _hasCamera,
          scanning: _scanning,
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: SoftCard(
                color: AppTheme.beige,
                shadow: false,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SKIN TYPE',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (scan?['skin_type'] ?? 'Unknown').toString(),
                      style: const TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SoftCard(
                color: AppTheme.softGray,
                shadow: false,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LAST SCAN',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scannedLabel,
                      style: const TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        const SectionLabel('Detected concerns'),
        if (concerns.isEmpty)
          SoftCard(
            color: Colors.white,
            shadow: false,
            child: const Text(
              'Run a scan to see your skin analysis.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          )
        else
          Column(
            children: [
              for (final c in concerns)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SoftCard(
                    color: Colors.white,
                    shadow: false,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const TintedIconBadge(
                          icon: Icons.bubble_chart_outlined,
                          tint: AppTheme.peach,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _capitalize(c),
                                style: const TextStyle(
                                  color: AppTheme.charcoal,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                'Tap to see causes and recommended steps',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 18),

        PillButton(
          label: _scanning ? 'Analyzing…' : 'Run new scan',
          icon: _scanning ? null : Icons.center_focus_strong_outlined,
          onPressed: _scanning ? null : _captureAndAnalyze,
        ),
      ],
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _CameraStage extends StatelessWidget {
  const _CameraStage({
    required this.controller,
    required this.hasCamera,
    required this.scanning,
  });

  final CameraController? controller;
  final bool hasCamera;
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasCamera && controller != null && controller!.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller!.value.previewSize?.height ?? 1,
                  height: controller!.value.previewSize?.width ?? 1,
                  child: CameraPreview(controller!),
                ),
              )
            else
              const _CameraGradient(),
            const _FaceOverlay(),
            Positioned(
              left: 14,
              top: 14,
              child: GlassPill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB7E1CB),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasCamera ? 'Live preview' : 'Preview mode',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              right: 14,
              top: 14,
              child: GlassPill(
                child: Text(
                  'Auto-detect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            if (scanning) const _ScanningHalo(),
          ],
        ),
      ),
    );
  }
}

class _CameraGradient extends StatelessWidget {
  const _CameraGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF3A332A),
            Color(0xFF2C2720),
            Color(0xFF1F1B16),
          ],
        ),
      ),
    );
  }
}

class _FaceOverlay extends StatelessWidget {
  const _FaceOverlay();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: [
            Positioned(
              left: w * 0.18,
              top: h * 0.18,
              right: w * 0.18,
              bottom: h * 0.20,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(220),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 1.4,
                  ),
                ),
              ),
            ),
            _Marker(left: w * 0.42, top: h * 0.30, label: 'Forehead'),
            _Marker(left: w * 0.28, top: h * 0.50, label: 'Cheek'),
            _Marker(left: w * 0.62, top: h * 0.50, label: 'Cheek'),
            _Marker(left: w * 0.46, top: h * 0.66, label: 'Chin'),
          ],
        );
      },
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.left, required this.top, required this.label});

  final double left;
  final double top;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.6),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          GlassPill(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanningHalo extends StatefulWidget {
  const _ScanningHalo();

  @override
  State<_ScanningHalo> createState() => _ScanningHaloState();
}

class _ScanningHaloState extends State<_ScanningHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1, -1 + (_ctrl.value * 2)),
                  end: Alignment(1, 1 + (_ctrl.value * 2)),
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: const [0.4, 0.5, 0.6],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _formatScanDate(String iso) {
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return 'No scan yet';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final mo = months[(dt.month - 1) % 12];
  final h12raw = dt.hour % 12;
  final h12 = h12raw == 0 ? 12 : h12raw;
  final ampm = dt.hour < 12 ? 'AM' : 'PM';
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$mo ${dt.day}, ${dt.year} · $h12:$mm $ampm';
}
