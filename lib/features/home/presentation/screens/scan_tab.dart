import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:kudlit_ph/core/utils/baybayify.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/butty_chat/butty_bubble.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/butty_chat/typing_bubble.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/baybayin_detection.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/scan_result.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/scan_history_provider.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/scan_tab_controller.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/scanner_evaluation_provider.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/scanner_provider.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/yolo_model_selection_provider.dart';
import 'package:kudlit_ph/features/scanner/presentation/widgets/aggregated_bounding_box.dart';
import 'package:kudlit_ph/features/scanner/presentation/widgets/scanner_camera.dart';
import 'package:kudlit_ph/features/scanner/presentation/widgets/yolo_model_dropdown.dart';

/// Baybayin scanner screen.
///
/// Embeds [ScannerCamera] (which owns the YOLO inference), reads the latest
/// detections from [ScannerNotifier], and renders the controls + result panel.
class ScanTab extends ConsumerStatefulWidget {
  const ScanTab({super.key});

  @override
  ConsumerState<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends ConsumerState<ScanTab> {
  /// GlobalKey on the RepaintBoundary that wraps ScannerCamera.
  /// Used to capture the live camera frame as PNG bytes when the shutter fires.
  final GlobalKey _cameraRepaintKey = GlobalKey();

  /// Whether the white "camera flash" overlay is visible.
  bool _showShutterFlash = false;
  Timer? _shutterFlashTimer;

  WebScannerCapture? _webCapture;
  WebScannerSwitchCamera? _webSwitchCamera;
  WebScannerStatus _webStatus = WebScannerStatus.initializing;
  bool _showStatusChip = true;
  Timer? _statusFadeTimer;
  String? _statusKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _revealStatusChip();
    });
  }

  @override
  void dispose() {
    _statusFadeTimer?.cancel();
    _shutterFlashTimer?.cancel();
    super.dispose();
  }

  void _setWebCapture(WebScannerCapture? capture) {
    if (_webCapture == capture) return;
    setState(() => _webCapture = capture);
  }

  void _setWebSwitchCamera(WebScannerSwitchCamera? switchCamera) {
    if (_webSwitchCamera == switchCamera) return;
    setState(() => _webSwitchCamera = switchCamera);
  }

  void _setWebStatus(WebScannerStatus status) {
    if (_webStatus == status) return;
    setState(() => _webStatus = status);
    _revealStatusChip();
  }

  bool _shouldCenterWebStatusChip() {
    return kIsWeb &&
        (_webStatus == WebScannerStatus.initializing ||
            _webStatus == WebScannerStatus.permissionNeeded ||
            _webStatus == WebScannerStatus.error);
  }

  void _revealStatusChip() {
    _statusFadeTimer?.cancel();
    if (mounted) {
      setState(() => _showStatusChip = true);
    }
    _statusFadeTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      setState(() => _showStatusChip = false);
    });
  }

  void _syncStatusCue(String key) {
    if (_statusKey == key) return;
    _statusKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _revealStatusChip();
    });
  }

  void _showRetryReadyCue() {
    HapticFeedback.selectionClick();
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 10,
          backgroundColor: cs.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: cs.primary.withAlpha(90)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          duration: const Duration(milliseconds: 2600),
          margin: EdgeInsets.fromLTRB(
            28,
            0,
            28,
            MediaQuery.paddingOf(context).bottom + 96,
          ),
          content: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withAlpha(170),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: cs.primary,
                    backgroundColor: cs.primary.withAlpha(40),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Trying again',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Frame the glyph, then tap capture.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withAlpha(180),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _retryNativeScanNotice(ScanTabController controller) {
    controller.clearNotice();
    _showRetryReadyCue();
  }

  Future<void> _switchCamera(ScanTabController controller) async {
    HapticFeedback.selectionClick();
    if (kIsWeb) {
      final WebScannerSwitchCamera? switchCamera = _webSwitchCamera;
      if (switchCamera == null) return;
      await switchCamera();
      return;
    }
    await controller.switchCamera();
  }

  VoidCallback? _noticeTryAgainAction(
    ScanTabController controller,
    ScanTabState scanState,
  ) {
    if (scanState.isLoadingImage) return null;
    if (!kIsWeb) return () => _retryNativeScanNotice(controller);

    final WebScannerCapture? capture = _webCapture;
    if (capture == null) return null;
    return () => controller.captureWebFrame(capture);
  }

  /// Captures the current live camera frame, triggers a brief white-flash
  /// animation, then runs still-image inference on that exact frame.
  ///
  /// Falls back gracefully with a scanner notice if the native frame is not
  /// ready, instead of reusing the previous live detection snapshot.
  Future<void> _captureAndShutter() async {
    final ScanTabController controller = ref.read(
      scanTabControllerProvider.notifier,
    );

    // Trigger the flash animation immediately for tactile feedback.
    _shutterFlashTimer?.cancel();
    setState(() => _showShutterFlash = true);
    _shutterFlashTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _showShutterFlash = false);
    });
    HapticFeedback.mediumImpact();

    // Try to capture the current camera frame as PNG bytes.
    Uint8List? capturedBytes;
    try {
      final RenderObject? render = _cameraRepaintKey.currentContext
          ?.findRenderObject();
      if (render is RenderRepaintBoundary) {
        final ui.Image image = await render.toImage(pixelRatio: 1.5);
        final ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        image.dispose();
        capturedBytes = byteData?.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('[ScanTab] frame capture failed: $e');
    }

    await controller.captureNativeFrame(fallbackBytes: capturedBytes);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final ScanTabController controller = ref.read(
          scanTabControllerProvider.notifier,
        );
        final ScanTabState scanState = ref.watch(scanTabControllerProvider);
        final Size viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final double safeBottom = MediaQuery.paddingOf(context).bottom;
        final bool compactLandscape =
            viewport.width > viewport.height && viewport.height < 430;
        final bool tinyViewport = viewport.width < 340;
        final bool tinyLandscapeNotice =
            compactLandscape && viewport.width <= 340;
        final double sideGutter = viewport.width < 380 ? 10 : 12;
        final double topGutter = compactLandscape ? 6 : 10;
        final double controlsBottom = safeBottom + (compactLandscape ? 8 : 40);
        final double controlsHeight = compactLandscape ? 82 : 96;
        final double panelBottom = controlsBottom + controlsHeight;
        final List<BaybayinDetection> detections = ref.watch(
          scannerNotifierProvider,
        );
        final bool isFrozen =
            scanState.isShutterFrozen || scanState.selectedImageBytes != null;
        final String statusLabel = scanState.selectedImageBytes != null
            ? 'Image preview'
            : scanState.isShutterFrozen
            ? 'Photo captured'
            : kIsWeb
            ? _webStatus.label
            : 'Camera ready';
        final IconData statusIcon = scanState.selectedImageBytes != null
            ? Icons.image_outlined
            : scanState.isShutterFrozen
            ? Icons.camera_alt_rounded
            : kIsWeb
            ? _webStatus.icon
            : Icons.camera_alt_outlined;
        _syncStatusCue('$statusLabel:$_webStatus:$isFrozen');

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _ScanCameraStack(
              detections: detections,
              flashOn: scanState.flashOn,
              scannerPaused: scanState.resultVisible && !kIsWeb,
              onDetections: controller.applyLiveDetections,
              onFlashToggle: kIsWeb ? null : () => controller.toggleFlash(),
              selectedImageBytes: scanState.selectedImageBytes,
              capturedFrameBytes: scanState.capturedFrameBytes,
              cameraRepaintKey: _cameraRepaintKey,
              onWebCaptureChanged: _setWebCapture,
              onWebSwitchCameraChanged: _setWebSwitchCamera,
              onWebStatusChanged: _setWebStatus,
              onPermutationsTap: (List<String> permutations) async {
                controller.setDetectionsFrozen(true);
                await showDialog<void>(
                  context: context,
                  builder: (BuildContext _) {
                    return _PermutationsDialog(permutations: permutations);
                  },
                );
                controller.setDetectionsFrozen(false);
              },
            ),
            // Camera-shutter white flash overlay — fades out after 200 ms.
            if (_showShutterFlash)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _showShutterFlash ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: const ColoredBox(color: Colors.white),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              left: sideGutter,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.only(top: topGutter),
                  child: _ScanUtilityBar(
                    key: const ValueKey('scan-utility-bar'),
                    flashOn: scanState.flashOn,
                    // Hide gallery/flash controls when frozen — retake handles return.
                    onGalleryTap: isFrozen
                        ? null
                        : () => controller.pickImageFromGallery(),
                    onFlashToggle: kIsWeb || isFrozen
                        ? null
                        : () => controller.toggleFlash(),
                    compact: compactLandscape,
                    tiny: tinyViewport,
                  ),
                ),
              ),
            ),
            if (scanState.isLoadingImage)
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator()),
              ),
            Positioned(
              top: 0,
              left: _shouldCenterWebStatusChip() ? sideGutter : null,
              right: sideGutter,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.only(top: topGutter),
                  child: IgnorePointer(
                    ignoring: !_showStatusChip,
                    child: AnimatedOpacity(
                      opacity: _showStatusChip ? 1 : 0,
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutCubic,
                      child: _shouldCenterWebStatusChip()
                          ? Center(
                              child: _ScanStatusChip(
                                key: const ValueKey('scan-status-chip'),
                                label: statusLabel,
                                icon: statusIcon,
                              ),
                            )
                          : _ScanStatusChip(
                              key: const ValueKey('scan-status-chip'),
                              label: statusLabel,
                              icon: statusIcon,
                            ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: compactLandscape
                  ? (tinyViewport ? 28 : 36)
                  : (tinyViewport ? 38 : 44),
              right: sideGutter,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.only(top: topGutter),
                  child: const YoloModelDropdown(scope: YoloModelScope.camera),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: controlsBottom,
              child: _ScanControls(
                key: const ValueKey('scan-controls'),
                frozen: isFrozen,
                onShutter: isFrozen
                    // Retake: dismiss frozen frame and go back to live camera.
                    ? controller.dismissResult
                    : kIsWeb
                    ? (_webCapture == null || scanState.isLoadingImage
                          ? null
                          : () => controller.captureWebFrame(_webCapture!))
                    : (scanState.isLoadingImage ? null : _captureAndShutter),
                shutterLabel: isFrozen
                    ? 'Retake'
                    : kIsWeb
                    ? 'Capture Webcam Frame'
                    : 'Capture Scan',
                onRotateCamera: isFrozen || scanState.isLoadingImage
                    ? null
                    : () => _switchCamera(controller),
                rotateLabel: kIsWeb && _webSwitchCamera == null
                    ? 'Only one camera available'
                    : 'Switch camera',
                compact: compactLandscape,
                tiny: tinyViewport,
              ),
            ),
            if (scanState.scanNotice != null)
              Positioned(
                left: 14,
                right: 14,
                bottom: panelBottom,
                child: _ScanNoticePanel(
                  key: const ValueKey('scan-notice-panel'),
                  notice: scanState.scanNotice!,
                  onTryAgain: _noticeTryAgainAction(controller, scanState),
                  onGalleryTap: () => controller.pickImageFromGallery(),
                  onDismiss: controller.clearNotice,
                  compact: tinyLandscapeNotice,
                ),
              ),
            if (scanState.resultVisible)
              Positioned(
                left: 14,
                right: 14,
                bottom: panelBottom,
                child: ScannerResultPanel(
                  detections: scanState.snapshot,
                  onDismiss: controller.dismissResult,
                ),
              )
            else if (scanState.aggregatedWinner != null)
              Positioned(
                left: 14,
                right: 14,
                bottom: panelBottom,
                child: _AggregatedWinnerBanner(
                  winner: scanState.aggregatedWinner!,
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Aggregated winner banner ─────────────────────────────────────────────────

class _AggregatedWinnerBanner extends StatelessWidget {
  const _AggregatedWinnerBanner({required this.winner});

  final String winner;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.auto_awesome_rounded, size: 16, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Settled reading',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withAlpha(140),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  winner,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Camera + overlays ────────────────────────────────────────────────────────

class _ScanCameraStack extends StatelessWidget {
  const _ScanCameraStack({
    required this.detections,
    required this.flashOn,
    required this.scannerPaused,
    required this.onDetections,
    required this.onFlashToggle,
    required this.onPermutationsTap,
    required this.cameraRepaintKey,
    this.onWebCaptureChanged,
    this.onWebSwitchCameraChanged,
    this.onWebStatusChanged,
    this.selectedImageBytes,
    this.capturedFrameBytes,
  });

  final List<BaybayinDetection> detections;
  final bool flashOn;
  final bool scannerPaused;
  final void Function(List<BaybayinDetection>) onDetections;
  final VoidCallback? onFlashToggle;
  final ValueChanged<WebScannerCapture?>? onWebCaptureChanged;
  final ValueChanged<WebScannerSwitchCamera?>? onWebSwitchCameraChanged;
  final ValueChanged<WebScannerStatus>? onWebStatusChanged;
  final Uint8List? selectedImageBytes;
  final void Function(List<String> permutations) onPermutationsTap;

  /// Frozen camera frame from a shutter press. Takes priority over live camera.
  final Uint8List? capturedFrameBytes;

  /// Key on the [RepaintBoundary] that wraps the live [ScannerCamera].
  /// Used by the parent to capture the frame just before freezing.
  final GlobalKey cameraRepaintKey;

  @override
  Widget build(BuildContext context) {
    final Uint8List? frozenImage = capturedFrameBytes ?? selectedImageBytes;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (frozenImage != null)
          Image.memory(frozenImage, fit: BoxFit.cover)
        else
          RepaintBoundary(
            key: cameraRepaintKey,
            child: ScannerCamera(
              flashOn: flashOn,
              paused: scannerPaused,
              onDetections: onDetections,
              onFlashToggle: onFlashToggle,
              onWebCaptureChanged: onWebCaptureChanged,
              onWebSwitchCameraChanged: onWebSwitchCameraChanged,
              onWebStatusChanged: onWebStatusChanged,
            ),
          ),
        AggregatedBoundingBox(
          detections: detections,
          onPermutationsTap: onPermutationsTap,
        ),
      ],
    );
  }
}

// ── Controls ──────────────────────────────────────────────────────────────────

class _ScanControls extends StatelessWidget {
  const _ScanControls({
    super.key,
    required this.onShutter,
    required this.shutterLabel,
    required this.rotateLabel,
    this.onRotateCamera,
    this.frozen = false,
    this.compact = false,
    this.tiny = false,
  });

  final VoidCallback? onShutter;
  final String shutterLabel;
  final VoidCallback? onRotateCamera;
  final String rotateLabel;

  /// When true the user has a frozen frame — left button becomes "Retake"
  /// and the shutter transforms into a close/retake indicator.
  final bool frozen;
  final bool compact;
  final bool tiny;

  @override
  Widget build(BuildContext context) {
    final double rotateOffset = tiny
        ? (compact ? 12 : 14)
        : (compact ? 18 : 28);
    return SizedBox(
      height: compact ? 82 : 96,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: rotateOffset),
              child: frozen
                  ? _ControlIcon(
                      icon: Icons.replay_rounded,
                      label: 'Close preview',
                      onTap: onShutter,
                      size: compact ? 48 : 54,
                      small: tiny,
                      prominent: true,
                    )
                  : _ControlIcon(
                      icon: Icons.cameraswitch_rounded,
                      label: rotateLabel,
                      onTap: onRotateCamera,
                      size: compact ? 48 : 54,
                      small: tiny,
                      prominent: true,
                    ),
            ),
          ),
          _ShutterButton(
            onTap: onShutter,
            label: shutterLabel,
            compact: compact,
            frozen: frozen,
            tiny: tiny,
          ),
        ],
      ),
    );
  }
}

class _ScanUtilityBar extends StatelessWidget {
  const _ScanUtilityBar({
    super.key,
    required this.flashOn,
    required this.onGalleryTap,
    this.onFlashToggle,
    this.compact = false,
    this.tiny = false,
  });

  final bool flashOn;
  final VoidCallback? onGalleryTap;
  final VoidCallback? onFlashToggle;
  final bool compact;
  final bool tiny;

  double get _iconSize => tiny ? (compact ? 48 : 52) : 48;
  double get _interIconGap => tiny ? 2 : 4;
  double get _barPadding => tiny ? 3 : 4;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(185),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withAlpha(120)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x33000000), blurRadius: 14),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(_barPadding),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _ControlIcon(
              icon: Icons.photo_library_outlined,
              label: 'Open Gallery',
              onTap: onGalleryTap,
              size: _iconSize,
              small: tiny,
            ),
            if (onFlashToggle != null) ...<Widget>[
              SizedBox(width: _interIconGap),
              _ControlIcon(
                icon: flashOn
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                label: flashOn ? 'Turn Flash Off' : 'Turn Flash On',
                onTap: onFlashToggle,
                selected: flashOn,
                size: _iconSize,
                small: tiny,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ControlIcon extends StatelessWidget {
  const _ControlIcon({
    required this.icon,
    required this.label,
    this.onTap,
    this.selected = false,
    this.size = 44,
    this.prominent = false,
    this.small = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final double size;
  final bool prominent;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool enabled = onTap != null;
    final Color background = selected
        ? cs.primary
        : prominent
        ? cs.surfaceContainerHigh.withAlpha(220)
        : Colors.transparent;
    final Color foreground = selected ? cs.onPrimary : cs.onSurface;
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        enabled: enabled,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Material(
            color: background,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: size,
                height: size,
                child: Icon(
                  icon,
                  size: small ? (prominent ? 20 : 16) : (prominent ? 26 : 21),
                  color: foreground.withAlpha(enabled ? 230 : 170),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.onTap,
    required this.label,
    required this.compact,
    this.frozen = false,
    this.tiny = false,
  });

  final VoidCallback? onTap;
  final String label;
  final bool compact;
  final bool tiny;

  /// When [frozen] the button renders as a close/retake circle with an ×.
  final bool frozen;

  @override
  Widget build(BuildContext context) {
    final double outerSize = compact ? (tiny ? 58 : 64) : (tiny ? 66 : 72);
    final double innerSize = compact ? (tiny ? 44 : 50) : (tiny ? 50 : 56);
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        enabled: onTap != null,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: outerSize,
            height: outerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: frozen
                  ? Colors.black.withAlpha(140)
                  : const Color(0xFF0E1425).withAlpha(100),
              border: Border.all(
                color: Colors.white.withAlpha(onTap == null ? 80 : 180),
                width: 2.5,
              ),
            ),
            child: Center(
              child: frozen
                  ? Icon(
                      Icons.close_rounded,
                      color: Colors.white.withAlpha(onTap == null ? 130 : 230),
                      size: compact ? 26 : 30,
                    )
                  : Container(
                      width: innerSize,
                      height: innerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(
                          onTap == null ? 130 : 255,
                        ),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(color: Color(0x4D7AAAFF), blurRadius: 18),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanStatusChip extends StatelessWidget {
  const _ScanStatusChip({super.key, required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Scanner state: $label',
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, maxWidth: 224),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withAlpha(220),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withAlpha(130)),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x33000000), blurRadius: 14),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 15, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: cs.onSurface.withAlpha(230),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Result panel ──────────────────────────────────────────────────────────────

class _ScanNoticePanel extends StatelessWidget {
  const _ScanNoticePanel({
    super.key,
    required this.notice,
    required this.onGalleryTap,
    required this.onDismiss,
    this.onTryAgain,
    this.compact = false,
  });

  final ScanNotice notice;
  final VoidCallback? onTryAgain;
  final VoidCallback onGalleryTap;
  final VoidCallback onDismiss;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color accent = switch (notice.kind) {
      ScanNoticeKind.info => cs.primary,
      ScanNoticeKind.warning => cs.tertiary,
      ScanNoticeKind.error => cs.error,
    };
    final double iconBadgeSize = compact ? 24 : 34;
    final double iconSize = compact ? 16 : 18;
    final double iconRadius = compact ? 8 : 10;
    final EdgeInsets panelPadding = compact
        ? const EdgeInsets.fromLTRB(10, 8, 10, 8)
        : const EdgeInsets.fromLTRB(14, 12, 12, 12);
    final double titleFontSize = compact ? 12.8 : 14;
    final double messageFontSize = compact ? 10.8 : 12;
    final double panelRadius = compact ? 12 : 16;
    final int messageMaxLines = compact ? 2 : 3;
    final double spacing = compact ? 8 : 10;
    final double messageLineHeight = compact ? 1.15 : 1.2;

    return Semantics(
      liveRegion: true,
      label: '${notice.title}. ${notice.message}',
      child: Container(
        padding: panelPadding,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(panelRadius),
          border: Border.all(color: accent.withAlpha(120)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x59000000),
              blurRadius: 24,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: iconBadgeSize,
                  height: iconBadgeSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(26),
                    borderRadius: BorderRadius.circular(iconRadius),
                  ),
                  child: Icon(
                    notice.kind == ScanNoticeKind.error
                        ? Icons.error_outline_rounded
                        : Icons.info_outline_rounded,
                    size: iconSize,
                    color: accent,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        notice.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      SizedBox(height: compact ? 1 : 2),
                      Text(
                        notice.message,
                        maxLines: messageMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: messageFontSize,
                          height: messageLineHeight,
                          color: cs.onSurface.withAlpha(170),
                        ),
                      ),
                    ],
                  ),
                ),
                _ActionChip(
                  icon: Icons.close_rounded,
                  label: 'Dismiss scanner message',
                  onTap: onDismiss,
                ),
              ],
            ),
            if (!compact) ...<Widget>[
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _NoticeButton(
                      icon: Icons.image_outlined,
                      label: 'Use Gallery',
                      onTap: onGalleryTap,
                      filled: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NoticeButton(
                      icon: Icons.center_focus_strong_rounded,
                      label: 'Try Again',
                      onTap: onTryAgain,
                      filled: false,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoticeButton extends StatelessWidget {
  const _NoticeButton({
    required this.icon,
    required this.label,
    required this.filled,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color background = filled ? cs.primary : cs.surfaceContainer;
    final Color foreground = filled ? cs.onPrimary : cs.onSurface;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: onTap == null ? cs.surfaceContainer : background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: onTap == null
                    ? cs.outline.withAlpha(90)
                    : filled
                    ? cs.primary
                    : cs.outline,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  icon,
                  size: 16,
                  color: onTap == null
                      ? cs.onSurface.withAlpha(100)
                      : foreground,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: onTap == null
                          ? cs.onSurface.withAlpha(100)
                          : foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScannerResultPanel extends ConsumerStatefulWidget {
  const ScannerResultPanel({
    super.key,
    required this.detections,
    required this.onDismiss,
  });

  final List<BaybayinDetection> detections;
  final VoidCallback onDismiss;

  @override
  ConsumerState<ScannerResultPanel> createState() => _ScanResultPanelState();
}

class _ScanResultPanelState extends ConsumerState<ScannerResultPanel> {
  int _index = 0;

  static List<String> _tokensFor(List<BaybayinDetection> dets) {
    final List<BaybayinDetection> ordered = List<BaybayinDetection>.of(dets)
      ..sort(
        (BaybayinDetection a, BaybayinDetection b) => a.left.compareTo(b.left),
      );
    return ordered
        .map((BaybayinDetection d) => d.label.trim().toLowerCase())
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<String> get _tokens => _tokensFor(widget.detections);
  List<String> get _permutations => permuteBaybayin(_tokens);

  @override
  void didUpdateWidget(covariant ScannerResultPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(_tokensFor(oldWidget.detections), _tokens)) {
      _index = 0;
    }
  }

  void _prev() {
    final List<String> p = _permutations;
    if (p.length <= 1) return;
    setState(() => _index = (_index - 1 + p.length) % p.length);
  }

  void _next() {
    final List<String> p = _permutations;
    if (p.length <= 1) return;
    setState(() => _index = (_index + 1) % p.length);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<String> tokens = _tokens;
    final List<String> perms = _permutations;
    final String current = perms.isEmpty
        ? ''
        : perms[_index.clamp(0, perms.length - 1)];
    final String tokenPreview = tokens.isEmpty ? '' : tokens.join(' · ');

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow = constraints.maxWidth < 360;
        final Widget actions = _ResultActions(
          onCopy: perms.isEmpty
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: current));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
          onShare: perms.isEmpty
              ? null
              : () async {
                  final ScanEvalState evalState = ref.read(
                    scannerEvaluationProvider,
                  );
                  final String translation = evalState.translation.value ?? '';
                  final StringBuffer sb = StringBuffer(
                    'Scanned Baybayin word: $current',
                  );
                  if (translation.isNotEmpty) {
                    sb
                      ..write('\n')
                      ..write(translation);
                  }
                  await SharePlus.instance.share(
                    ShareParams(text: sb.toString()),
                  );
                },
          onSave: perms.isEmpty
              ? null
              : () {
                  final ScanEvalState evalState = ref.read(
                    scannerEvaluationProvider,
                  );
                  final String translation = evalState.translation.value ?? '';
                  ref
                      .read(scanHistoryNotifierProvider.notifier)
                      .addResult(
                        ScanResult(
                          tokens: _tokens,
                          translation: translation,
                          timestamp: DateTime.now(),
                        ),
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Saved to history.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
          onDismiss: widget.onDismiss,
        );

        return Container(
          padding: EdgeInsets.fromLTRB(14, 10, 14, narrow ? 12 : 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x59000000),
                blurRadius: 24,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _ResultHandle(),
              SizedBox(height: narrow ? 7 : 8),
              if (narrow) ...<Widget>[
                _ResultText(current: current, tokenPreview: tokenPreview),
                const SizedBox(height: 10),
                actions,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _ResultText(
                        current: current,
                        tokenPreview: tokenPreview,
                      ),
                    ),
                    const SizedBox(width: 12),
                    actions,
                  ],
                ),
              if (perms.length > 1) ...<Widget>[
                const SizedBox(height: 10),
                _PermutationCycler(
                  index: _index,
                  total: perms.length,
                  onPrev: _prev,
                  onNext: _next,
                ),
              ],
              const _ButtyTranslationArea(),
            ],
          ),
        );
      },
    );
  }
}

class _ResultHandle extends StatelessWidget {
  const _ResultHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 28,
        height: 3,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(60),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _ResultText extends StatelessWidget {
  const _ResultText({required this.current, required this.tokenPreview});

  final String current;
  final String tokenPreview;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool compact = MediaQuery.sizeOf(context).width < 380;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          baybayifyWord(current),
          style: TextStyle(
            fontFamily: 'Baybayin Simple TAWBID',
            fontSize: compact ? 24 : 28,
            color: cs.onSurface,
            letterSpacing: compact ? 3 : 5,
            height: 1.1,
          ),
          softWrap: true,
        ),
        const SizedBox(height: 2),
        Text(
          current.isEmpty ? '—' : current,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: 0,
          ),
          softWrap: true,
        ),
        if (tokenPreview.isNotEmpty) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            tokenPreview,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withAlpha(175),
              letterSpacing: 0.2,
            ),
            softWrap: true,
          ),
        ],
      ],
    );
  }
}

class _PermutationCycler extends StatelessWidget {
  const _PermutationCycler({
    required this.index,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  final int index;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _CyclerButton(
            icon: Icons.chevron_left_rounded,
            onTap: onPrev,
            tooltip: 'Previous reading',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Reading ${index + 1} of $total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withAlpha(200),
                letterSpacing: 0.2,
              ),
            ),
          ),
          _CyclerButton(
            icon: Icons.chevron_right_rounded,
            onTap: onNext,
            tooltip: 'Next reading',
          ),
        ],
      ),
    );
  }
}

class _CyclerButton extends StatelessWidget {
  const _CyclerButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: cs.onSurface),
        ),
      ),
    );
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({
    required this.onDismiss,
    this.onCopy,
    this.onShare,
    this.onSave,
  });

  final VoidCallback onDismiss;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        _ActionChip(
          icon: Icons.copy_rounded,
          label: 'Copy reading',
          onTap: onCopy,
        ),
        _ActionChip(
          icon: Icons.share_rounded,
          label: 'Share reading',
          onTap: onShare,
        ),
        _ActionChip(
          icon: Icons.bookmark_add_outlined,
          label: 'Save reading',
          onTap: onSave,
        ),
        _ActionChip(
          icon: Icons.close_rounded,
          label: 'Close result',
          onTap: onDismiss,
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool enabled = onTap != null;
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        enabled: enabled,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.55,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outline),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: cs.onSurface.withAlpha(enabled ? 210 : 150),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Butty translation area ────────────────────────────────────────────────────

class _ButtyTranslationArea extends ConsumerWidget {
  const _ButtyTranslationArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScanEvalState evalState = ref.watch(scannerEvaluationProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 8),
        evalState.translation.when(
          loading: () => const TypingBubble(),
          data: (String text) =>
              text.isEmpty ? const SizedBox.shrink() : ButtyBubble(text: text),
          error: (Object e, StackTrace s) => ButtyBubble(
            text: 'Ay nako, I had trouble reading that. Try again?',
          ),
        ),
        if (evalState.canRequestFollowUp) ...<Widget>[
          const SizedBox(height: 2),
          _TellMeMoreButton(
            onTap: () =>
                ref.read(scannerEvaluationProvider.notifier).requestFollowUp(),
          ),
        ],
        if (evalState.followUp != null) ...<Widget>[
          const SizedBox(height: 4),
          evalState.followUp!.when(
            loading: () => const TypingBubble(),
            data: (String text) => text.isEmpty
                ? const SizedBox.shrink()
                : ButtyBubble(text: text),
            error: (Object e, StackTrace s) => const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

class _TellMeMoreButton extends StatelessWidget {
  const _TellMeMoreButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withAlpha(100),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: cs.primary.withAlpha(80)),
            ),
            child: Text(
              'Tell me more',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Permutations dialog ───────────────────────────────────────────────────────

class _PermutationsDialog extends StatelessWidget {
  const _PermutationsDialog({required this.permutations});

  final List<String> permutations;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: cs.surfaceContainerHigh,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480, maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _PermDialogHeader(count: permutations.length),
            const Divider(height: 1),
            Flexible(child: _PermDialogList(permutations: permutations)),
            const Divider(height: 1),
            const _PermDialogFooter(),
          ],
        ),
      ),
    );
  }
}

class _PermDialogHeader extends StatelessWidget {
  const _PermDialogHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.unfold_more_rounded,
              size: 18,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Possible readings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count interpretations of the detected glyphs',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withAlpha(160),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermDialogList extends StatelessWidget {
  const _PermDialogList({required this.permutations});

  final List<String> permutations;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      itemCount: permutations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 2),
      itemBuilder: (BuildContext context, int i) =>
          _PermRow(text: permutations[i], index: i),
    );
  }
}

class _PermRow extends StatelessWidget {
  const _PermRow({required this.text, required this.index});

  final String text;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => Clipboard.setData(ClipboardData(text: text)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 28,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withAlpha(120),
                ),
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.copy_rounded,
              size: 16,
              color: cs.onSurface.withAlpha(140),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermDialogFooter extends StatelessWidget {
  const _PermDialogFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
