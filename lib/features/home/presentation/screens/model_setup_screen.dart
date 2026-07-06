import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/core/design_system/kudlit_colors.dart';
import 'package:kudlit_ph/core/design_system/widgets/kudlit_loading_indicator.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/baybayin_backdrop.dart';
import 'package:kudlit_ph/features/home/presentation/providers/model_setup_controller.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/llm_download_tile.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/settings_card.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/settings_divider.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/vision_download_tile.dart';

/// Shown once on first launch before the required model surfaces are ready.
///
/// Transparently explains that Kudlit uses AI models for on-device
/// Baybayin recognition and translation, and asks whether the user
/// wants to download the model now or skip to cloud mode.
class ModelSetupScreen extends ConsumerStatefulWidget {
  const ModelSetupScreen({super.key});

  @override
  ConsumerState<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends ConsumerState<ModelSetupScreen> {
  @override
  Widget build(BuildContext context) {
    final ModelSetupState setupState = ref.watch(modelSetupControllerProvider);

    return Scaffold(
      backgroundColor: KudlitColors.neutralBlack,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _SetupBackground(),
          _ModelSetupBody(
            busy: setupState.busy,
            errorMessage: setupState.errorMessage == null
                ? null
                : _friendlyModelSetupError(setupState.errorMessage!),
            onContinue: () =>
                ref.read(modelSetupControllerProvider.notifier).completeSetup(),
            onSkip: () =>
                ref.read(modelSetupControllerProvider.notifier).skip(),
          ),
        ],
      ),
    );
  }

  String _friendlyModelSetupError(String rawMessage) {
    final String message = rawMessage.trim();
    if (message.isEmpty) {
      return 'Offline setup is paused. You can stay on internet mode and try again later.';
    }

    final String lower = message.toLowerCase();
    final bool looksLikeNetworkIssue =
        lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('timeout') ||
        lower.contains('supabase.co');
    if (looksLikeNetworkIssue) {
      return 'Check your connection, then retry the model download.';
    }

    if (lower.contains('cancel')) {
      return 'Download canceled. You can retry when you are ready.';
    }

    if (lower.contains('no ai models configured')) {
      return 'Offline downloads are not available right now. You can stay on internet mode for now.';
    }

    final bool looksTechnical =
        lower.contains('exception') ||
        lower.contains('stacktrace') ||
        lower.contains('statuscode') ||
        lower.contains('errno') ||
        lower.contains('uri=') ||
        lower.contains('https://');
    if (looksTechnical) {
      return 'Offline setup is paused. You can stay on internet mode and try again later.';
    }

    return message;
  }
}

class _SetupBackground extends StatelessWidget {
  const _SetupBackground();

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 900;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Deep blue-to-black gradient
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[KudlitColors.blue200, KudlitColors.neutralBlack],
              stops: <double>[0.0, 0.75],
            ),
          ),
        ),
        // Faded Baybayin glyphs
        const BaybayinBackdrop(),
        // Soft radial aura — larger on desktop for a more dramatic backdrop
        _AuraGlow(size: isDesktop ? 520 : 280, top: isDesktop ? -100 : -40),
      ],
    );
  }
}

class _AuraGlow extends StatelessWidget {
  const _AuraGlow({required this.size, required this.top});

  final double size;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                KudlitColors.blue400.withAlpha(90),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModelSetupBody extends StatelessWidget {
  const _ModelSetupBody({
    required this.busy,
    required this.onContinue,
    required this.onSkip,
    this.errorMessage,
  });

  final bool busy;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isDesktop = constraints.maxWidth >= 900;
          final bool landscape = constraints.maxWidth > constraints.maxHeight;
          final bool shortPortrait = !landscape && constraints.maxHeight < 680;
          final Widget content = isDesktop
              ? _DesktopSetupLayout(
                  busy: busy,
                  onContinue: onContinue,
                  onSkip: onSkip,
                  errorMessage: errorMessage,
                )
              : landscape
              ? _LandscapeSetupLayout(
                  busy: busy,
                  onContinue: onContinue,
                  onSkip: onSkip,
                  errorMessage: errorMessage,
                  webCentered: kIsWeb,
                )
              : shortPortrait
              ? _ShortPortraitSetupLayout(
                  busy: busy,
                  onContinue: onContinue,
                  onSkip: onSkip,
                  errorMessage: errorMessage,
                  webCentered: kIsWeb,
                )
              : _PortraitSetupLayout(
                  busy: busy,
                  onContinue: onContinue,
                  onSkip: onSkip,
                  errorMessage: errorMessage,
                  webCentered: kIsWeb,
                );

          if (kIsWeb) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(child: content),
              ),
            );
          }

          return content;
        },
      ),
    );
  }
}

class _DesktopSetupLayout extends StatelessWidget {
  const _DesktopSetupLayout({
    required this.busy,
    required this.onContinue,
    required this.onSkip,
    this.errorMessage,
  });

  final bool busy;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Container(
            padding: const EdgeInsets.fromLTRB(44, 48, 44, 48),
            decoration: BoxDecoration(
              color: KudlitColors.blue100,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: KudlitColors.blue300.withAlpha(90),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Expanded(flex: 5, child: _DesktopBranding()),
                const _DesktopDivider(),
                Expanded(
                  flex: 4,
                  child: _DesktopFormPanel(
                    busy: busy,
                    onContinue: onContinue,
                    onSkip: onSkip,
                    errorMessage: errorMessage,
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

class _DesktopBranding extends StatelessWidget {
  const _DesktopBranding();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          _SetupHero(height: 150),
          SizedBox(height: 28),
          _SetupHeadline(large: true),
        ],
      ),
    );
  }
}

class _DesktopFormPanel extends StatelessWidget {
  const _DesktopFormPanel({
    required this.busy,
    required this.onContinue,
    required this.onSkip,
    this.errorMessage,
  });

  final bool busy;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _ModelDownloadsPanel(),
        const SizedBox(height: 14),
        const _DownloadNotice(),
        if (errorMessage != null) ...<Widget>[
          const SizedBox(height: 10),
          _SetupErrorBanner(message: errorMessage!),
        ],
        const SizedBox(height: 28),
        _SetupActions(busy: busy, onContinue: onContinue, onSkip: onSkip),
      ],
    );
  }
}

class _DesktopDivider extends StatelessWidget {
  const _DesktopDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 280,
      margin: const EdgeInsets.only(right: 36),
      color: KudlitColors.blue300.withAlpha(70),
    );
  }
}

class _PortraitSetupLayout extends StatelessWidget {
  const _PortraitSetupLayout({
    required this.busy,
    required this.onContinue,
    required this.onSkip,
    this.errorMessage,
    this.webCentered = false,
  });

  final bool busy;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final String? errorMessage;
  final bool webCentered;

  @override
  Widget build(BuildContext context) {
    if (webCentered) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SetupHero(),
                const SizedBox(height: 20),
                const _SetupHeadline(),
                const SizedBox(height: 18),
                const _ModelDownloadsPanel(),
                const SizedBox(height: 10),
                const _DownloadNotice(),
                if (errorMessage != null) ...<Widget>[
                  const SizedBox(height: 10),
                  _SetupErrorBanner(message: errorMessage!),
                ],
                _SetupActions(
                  busy: busy,
                  onContinue: onContinue,
                  onSkip: onSkip,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Spacer(flex: 2),
              const _SetupHero(),
              const SizedBox(height: 20),
              const _SetupHeadline(),
              const SizedBox(height: 18),
              const _ModelDownloadsPanel(),
              const SizedBox(height: 10),
              const _DownloadNotice(),
              if (errorMessage != null) ...<Widget>[
                const SizedBox(height: 10),
                _SetupErrorBanner(message: errorMessage!),
              ],
              const Spacer(flex: 3),
              _SetupActions(busy: busy, onContinue: onContinue, onSkip: onSkip),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortPortraitSetupLayout extends StatelessWidget {
  const _ShortPortraitSetupLayout({
    required this.busy,
    required this.onContinue,
    required this.onSkip,
    this.errorMessage,
    this.webCentered = false,
  });

  final bool busy;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final String? errorMessage;
  final bool webCentered;

  @override
  Widget build(BuildContext context) {
    if (webCentered) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _SetupHero(height: 86),
                const SizedBox(height: 14),
                const _SetupHeadline(compact: true),
                const SizedBox(height: 16),
                const _ModelDownloadsPanel(),
                const SizedBox(height: 10),
                const _DownloadNotice(compact: true),
                if (errorMessage != null) ...<Widget>[
                  const SizedBox(height: 10),
                  _SetupErrorBanner(message: errorMessage!),
                ],
                const SizedBox(height: 18),
                _SetupActions(
                  busy: busy,
                  onContinue: onContinue,
                  onSkip: onSkip,
                  compact: true,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SetupHero(height: 86),
          const SizedBox(height: 14),
          const _SetupHeadline(compact: true),
          const SizedBox(height: 16),
          const _ModelDownloadsPanel(),
          const SizedBox(height: 10),
          const _DownloadNotice(compact: true),
          if (errorMessage != null) ...<Widget>[
            const SizedBox(height: 10),
            _SetupErrorBanner(message: errorMessage!),
          ],
          const SizedBox(height: 18),
          _SetupActions(
            busy: busy,
            onContinue: onContinue,
            onSkip: onSkip,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _LandscapeSetupLayout extends StatelessWidget {
  const _LandscapeSetupLayout({
    required this.busy,
    required this.onContinue,
    required this.onSkip,
    this.errorMessage,
    this.webCentered = false,
  });

  final bool busy;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final String? errorMessage;
  final bool webCentered;

  @override
  Widget build(BuildContext context) {
    final Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Expanded(
          flex: 5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SetupHero(height: 86),
              SizedBox(height: 14),
              _SetupHeadline(compact: true),
            ],
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _ModelDownloadsPanel(),
              const SizedBox(height: 8),
              const _DownloadNotice(compact: true),
              if (errorMessage != null) ...<Widget>[
                const SizedBox(height: 8),
                _SetupErrorBanner(message: errorMessage!),
              ],
              const SizedBox(height: 10),
              _SetupActions(
                busy: busy,
                onContinue: onContinue,
                onSkip: onSkip,
                compact: true,
              ),
            ],
          ),
        ),
      ],
    );

    if (webCentered) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: content,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: content,
        ),
      ),
    );
  }
}

class _SetupHero extends StatelessWidget {
  const _SetupHero({this.height = 110});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Image.asset(
          'assets/brand/ButtyRead.webp',
          height: height,
          errorBuilder: (context, error, stackTrace) =>
              SizedBox(height: height),
        ),
      ),
    );
  }
}

class _SetupHeadline extends StatelessWidget {
  const _SetupHeadline({this.compact = false, this.large = false});

  final bool compact;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Get ready to use Kudlit',
          style: TextStyle(
            color: KudlitColors.blue900,
            fontSize: large
                ? 32
                : compact
                ? 24
                : 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(
          height: large
              ? 14
              : compact
              ? 8
              : 10,
        ),
        Text(
          kIsWeb
              ? 'Set up the downloads Kudlit needs before you start.'
              : 'Download these once so key features can keep working even without internet.',
          style: TextStyle(
            color: KudlitColors.grey300,
            fontSize: large
                ? 16
                : compact
                ? 13
                : 15,
            height: large
                ? 1.6
                : compact
                ? 1.35
                : 1.55,
          ),
        ),
      ],
    );
  }
}

class _DownloadNotice extends StatelessWidget {
  const _DownloadNotice({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 10,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: KudlitColors.blue100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KudlitColors.blue300.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: compact ? 12 : 13,
            color: KudlitColors.blue800,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              kIsWeb
                  ? 'The first setup happens in this browser and may take a while.'
                  : 'These downloads can be large. Wi-Fi is recommended.',
              style: TextStyle(
                color: KudlitColors.blue800,
                fontSize: compact ? 10 : 11,
                height: compact ? 1.35 : 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupActions extends StatelessWidget {
  const _SetupActions({
    required this.busy,
    required this.onContinue,
    required this.onSkip,
    this.compact = false,
  });

  final bool busy;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final String label = busy ? 'Checking setup' : 'Continue';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          button: true,
          enabled: !busy,
          label: label,
          hint: 'Checks whether everything is ready, then continues.',
          child: FilledButton.icon(
            onPressed: busy ? null : onContinue,
            icon: busy
                ? const KudlitLoadingIndicator(
                    size: 16,
                    strokeWidth: 2,
                    color: KudlitColors.blue900,
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(label),
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(compact ? 46 : 52),
              backgroundColor: KudlitColors.blue400,
              disabledBackgroundColor: KudlitColors.grey300.withAlpha(60),
              foregroundColor: KudlitColors.blue900,
              disabledForegroundColor: KudlitColors.grey300,
              padding: EdgeInsets.symmetric(vertical: compact ? 12 : 16),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        TextButton(
          onPressed: busy ? null : onSkip,
          style: TextButton.styleFrom(
            minimumSize: Size.fromHeight(compact ? 44 : 48),
            padding: EdgeInsets.symmetric(vertical: compact ? 8 : 10),
            foregroundColor: KudlitColors.grey300,
            disabledForegroundColor: KudlitColors.grey500,
          ),
          child: const Text(
            'Not now - stay on internet mode',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ModelDownloadsPanel extends StatelessWidget {
  const _ModelDownloadsPanel();

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      children: <Widget>[
        const LlmDownloadTile(),
        const SettingsDivider(),
        const VisionDownloadTile(),
      ],
    );
  }
}

class _SetupErrorBanner extends StatelessWidget {
  const _SetupErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: KudlitColors.danger400.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KudlitColors.danger400.withAlpha(90)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: KudlitColors.grey500,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}
