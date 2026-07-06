import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/features/home/presentation/screens/butty_chat_screen.dart';
import 'package:kudlit_ph/features/home/presentation/screens/learn_tab.dart';
import 'package:kudlit_ph/features/home/presentation/screens/scan_tab.dart';
import 'package:kudlit_ph/features/home/presentation/screens/translate_screen.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/app_header/app_header.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/floating_tab_nav.dart';
import 'package:kudlit_ph/features/scanner/domain/repositories/baybayin_detector.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/scanner_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  AppTab _activeTab = AppTab.scan;
  late PageController _pageController;
  String? _appliedRouteTab;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _activeTab.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String? routeTab = GoRouterState.of(
      context,
    ).uri.queryParameters['tab'];
    if (routeTab == _appliedRouteTab) return;
    _appliedRouteTab = routeTab;

    final AppTab? targetTab = _tabFromRoute(routeTab);
    if (targetTab == null || targetTab == _activeTab) return;
    final AppTab previousTab = _activeTab;
    _activeTab = targetTab;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(targetTab.index);
    } else {
      _pageController.dispose();
      _pageController = PageController(initialPage: targetTab.index);
    }
    _syncScannerInference(previous: previousTab, next: targetTab);
  }

  void _onTabSelected(AppTab tab) {
    if (tab == _activeTab) return;
    final AppTab previousTab = _activeTab;
    setState(() => _activeTab = tab);
    _pageController.animateToPage(
      tab.index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
    _syncScannerInference(previous: previousTab, next: tab);
  }

  /// Pauses the native YOLO pipeline when leaving the Scan tab and resumes it
  /// when returning, so inference does not run while the user is in another
  /// tab (the PageView keeps `ScanTab` mounted for the app's lifetime).
  ///
  /// No-op on web — the web detector stubs already make these calls inert,
  /// but the `kIsWeb` guard keeps us from instantiating the detector via the
  /// `keepAlive` provider during a web build that may not need it yet.
  void _syncScannerInference({required AppTab previous, required AppTab next}) {
    if (kIsWeb) return;
    if (previous == next) return;
    final bool leavingScan = previous == AppTab.scan && next != AppTab.scan;
    final bool enteringScan = previous != AppTab.scan && next == AppTab.scan;
    if (!leavingScan && !enteringScan) return;
    final BaybayinDetector detector = ref.read(baybayinDetectorProvider);
    final Future<Either<Failure, Unit>> action = leavingScan
        ? detector.pauseInference()
        : detector.resumeInference();
    // Pause / resume failures on tab change are not user-facing — the user
    // didn't ask the camera to do anything; we're just being a good citizen
    // about resource usage. Log and move on.
    unawaited(
      action.then((Either<Failure, Unit> result) {
        result.fold(
          (Failure failure) => debugPrint(
            '[HomeScreen] scanner ${leavingScan ? 'pauseInference' : 'resumeInference'} '
            'failed: ${_failureMessage(failure)}',
          ),
          (_) {},
        );
      }),
    );
  }

  String _failureMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure(:final String message) => message,
      UnknownFailure(:final String message) => message,
      _ => failure.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safePadding = MediaQuery.paddingOf(context);
    final double navBottom = safePadding.bottom + 56;
    final double navRight = safePadding.right + 18;

    return Scaffold(
      body: Column(
        children: <Widget>[
          AppHeader(showTranslateControls: _activeTab == AppTab.translate),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: _HomeBody(
                pageController: _pageController,
                activeTab: _activeTab,
                onTabSelected: _onTabSelected,
                navBottom: navBottom,
                navRight: navRight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppTab? _tabFromRoute(String? value) {
    return switch (value) {
      'scan' => AppTab.scan,
      'translate' => AppTab.translate,
      'learn' => AppTab.learn,
      'butty' => AppTab.butty,
      _ => null,
    };
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.pageController,
    required this.activeTab,
    required this.onTabSelected,
    required this.navBottom,
    required this.navRight,
  });

  final PageController pageController;
  final AppTab activeTab;
  final ValueChanged<AppTab> onTabSelected;
  final double navBottom;
  final double navRight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        PageView(
          controller: pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            const ScanTab(),
            const TranslateScreen(),
            LearnTab(onSwitchToButty: () => onTabSelected(AppTab.butty)),
            const ButtyChatScreen(),
          ],
        ),
        Positioned(
          right: navRight,
          bottom: navBottom,
          child: FloatingTabNav(
            activeTab: activeTab,
            onTabSelected: onTabSelected,
          ),
        ),
      ],
    );
  }
}
