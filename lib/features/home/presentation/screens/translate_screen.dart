import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';
import 'package:kudlit_ph/features/home/presentation/providers/translate_page_controller.dart';
import 'package:kudlit_ph/features/home/presentation/providers/translate_sketchpad_controller.dart';
import 'package:kudlit_ph/features/home/presentation/providers/translate_text_controller.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/translate/export_sheet.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/translate/translate_header.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/translate/translate_model_status_banner.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/translate/translate_sketchpad_mode_panel.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/translate/translate_text_mode_panel.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/floating_tab_nav.dart';

class TranslateScreen extends ConsumerStatefulWidget {
  const TranslateScreen({super.key});

  @override
  ConsumerState<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends ConsumerState<TranslateScreen> {
  bool _textInputFocused = false;

  /// Stable identity for the text input across every layout branch. The
  /// keyboard inset animates frame-by-frame, and several layout switches key
  /// off it (constrained vs full layout, header/banner add/remove). Without a
  /// GlobalKey those switches re-parent and re-mount the field, disposing its
  /// FocusNode mid-edit — which hides the keyboard, refocuses, and loops
  /// (the IME show/hide thrash + viewport-metric spam). A GlobalKey makes
  /// Flutter migrate the same Element/State instead of re-mounting it.
  final GlobalKey _textInputFieldKey = GlobalKey();

  void _setTextInputFocused(bool focused) {
    if (_textInputFocused == focused) return;
    setState(() => _textInputFocused = focused);
  }

  @override
  Widget build(BuildContext context) {
    final TranslatePageState pageState = ref.watch(
      translatePageControllerProvider,
    );
    final TranslateTextState textState = ref.watch(
      translateTextControllerProvider,
    );
    final TranslateSketchpadState sketchState = ref.watch(
      translateSketchpadControllerProvider,
    );
    final AsyncValue<AppPreferences> prefsAsync = ref.watch(
      appPreferencesNotifierProvider,
    );
    final AiPreference mode =
        prefsAsync.value?.aiPreference ?? AiPreference.cloud;
    // The shared inference repository now owns model resolution and cloud
    // fallback, so AI actions stay enabled; the status banner communicates
    // offline readiness and the setup affordance (parity with Butty).
    const bool aiActionsEnabled = true;
    const String? disabledReason = null;
    final bool showModelBanner = mode == AiPreference.local;
    final Size screenSize = MediaQuery.sizeOf(context);
    final view = View.of(context);
    final double rawKeyboardInset =
        view.viewInsets.bottom / view.devicePixelRatio;
    final bool keyboardOpen =
        MediaQuery.viewInsetsOf(context).bottom > 0 || rawKeyboardInset > 0;
    final bool compactLandscape =
        screenSize.height < 500 && screenSize.width > screenSize.height;
    final double navClearance = keyboardOpen
        ? 0
        : compactLandscape
        ? 10
        : kFloatingNavClearance - 32;
    Widget textModePanel({required bool compactLayout}) {
      return TranslateTextModePanel(
        state: textState,
        inputEnabled: aiActionsEnabled,
        disabledReason: disabledReason,
        compactLayout: compactLayout,
        inputFieldKey: _textInputFieldKey,
        onDirectionChanged: ref
            .read(translateTextControllerProvider.notifier)
            .setDirection,
        onInputChanged: ref
            .read(translateTextControllerProvider.notifier)
            .setInput,
        onExternalInput: ref
            .read(translateTextControllerProvider.notifier)
            .applyExternalInput,
        onClear: ref.read(translateTextControllerProvider.notifier).clearInput,
        onExplain: () => unawaited(
          ref.read(translateTextControllerProvider.notifier).explain(),
        ),
        onCheckInput: () => unawaited(
          ref.read(translateTextControllerProvider.notifier).checkInput(),
        ),
        onCopy: () => _copyOutput(context, textState),
        onShare: () => _shareOutput(context, textState),
        onInputFocusChanged: _setTextInputFocused,
      );
    }

    Widget sketchpadPanel() {
      return TranslateSketchpadModePanel(
        state: sketchState,
        aiActionsEnabled: aiActionsEnabled,
        disabledReason: disabledReason,
        onTargetChanged: ref
            .read(translateSketchpadControllerProvider.notifier)
            .setTarget,
        onGetFeedback: ref
            .read(translateSketchpadControllerProvider.notifier)
            .requestFeedback,
      );
    }

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool portraitKeyboardOpen =
                keyboardOpen && screenSize.height >= screenSize.width;
            final bool textMode =
                pageState.mode == TranslateWorkspaceMode.text;
            // Eager (non-async) preserve: in portrait text mode the keyboard
            // can only be open because the text field is focused, so lock the
            // layout immediately instead of waiting for the focus-listener
            // setState to land a frame later (which is what let the constrained
            // branch fire on the first animation frame and start the loop).
            final bool preserveFocusedPortraitInput =
                (textMode && portraitKeyboardOpen) ||
                (_textInputFocused &&
                    (portraitKeyboardOpen ||
                        (screenSize.width <= 500 &&
                            constraints.maxHeight < 560)));
            final bool shortLandscape =
                constraints.maxWidth > constraints.maxHeight &&
                constraints.maxHeight < 500;
            final bool constrainedKeyboardLayout =
                shortLandscape ||
                ((keyboardOpen || constraints.maxHeight < 560) &&
                    !preserveFocusedPortraitInput);
            if (constrainedKeyboardLayout) {
              return switch (pageState.mode) {
                TranslateWorkspaceMode.text => textModePanel(
                  compactLayout: true,
                ),
                TranslateWorkspaceMode.sketchpad => sketchpadPanel(),
              };
            }

            return Column(
              children: <Widget>[
                if (!keyboardOpen)
                  TranslateHeader(
                    workspaceMode: pageState.mode,
                    onWorkspaceModeChanged: ref
                        .read(translatePageControllerProvider.notifier)
                        .setMode,
                  ),
                if (showModelBanner &&
                    !keyboardOpen &&
                    pageState.mode == TranslateWorkspaceMode.text)
                  const TranslateModelStatusBanner(),
                Expanded(
                  child: switch (pageState.mode) {
                    TranslateWorkspaceMode.text => textModePanel(
                      compactLayout: false,
                    ),
                    TranslateWorkspaceMode.sketchpad => sketchpadPanel(),
                  },
                ),
                SizedBox(
                  height: MediaQuery.paddingOf(context).bottom + navClearance,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _copyOutput(
    BuildContext context,
    TranslateTextState state,
  ) async {
    final String output = _textOutput(state);
    if (output.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nothing to copy yet.')));
      }
      return;
    }
    await Clipboard.setData(ClipboardData(text: output));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copied output.')));
    }
  }

  Future<void> _shareOutput(
    BuildContext context,
    TranslateTextState state,
  ) async {
    if (!state.hasInput) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nothing to share yet.')));
      }
      return;
    }
    if (context.mounted) {
      await BaybayinExportSheet.show(
        context,
        baybayin: state.baybayinText,
        latin: state.latinText,
      );
    }
  }

  String _textOutput(TranslateTextState state) {
    return state.latinToBaybayin ? state.baybayinText : state.latinText;
  }
}
