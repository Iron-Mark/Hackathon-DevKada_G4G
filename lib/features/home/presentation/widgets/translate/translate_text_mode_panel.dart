import 'package:flutter/material.dart';

import 'package:kudlit_ph/features/home/presentation/providers/translate_page_controller.dart';
import 'package:kudlit_ph/features/home/presentation/providers/translate_text_controller.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/translate/direction_toggle.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/translate/empty_output.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/translate/filled_output.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/translate/translate_feedback_card.dart';

class TranslateTextModePanel extends StatelessWidget {
  const TranslateTextModePanel({
    super.key,
    required this.state,
    required this.inputEnabled,
    required this.disabledReason,
    required this.onDirectionChanged,
    required this.onInputChanged,
    required this.onExternalInput,
    required this.onClear,
    required this.onExplain,
    required this.onCheckInput,
    required this.onCopy,
    required this.onShare,
    this.onInputFocusChanged,
    this.inputFieldKey,
    this.compactLayout = false,
  });

  final TranslateTextState state;
  final bool inputEnabled;
  final String? disabledReason;
  final ValueChanged<bool> onDirectionChanged;
  final ValueChanged<String> onInputChanged;

  /// Non-typing input (example chips). Routes through the controller's
  /// `applyExternalInput`, which bumps the field revision so the text
  /// field picks the value up; plain typing uses [onInputChanged].
  final ValueChanged<String> onExternalInput;
  final VoidCallback onClear;
  final VoidCallback onExplain;
  final VoidCallback onCheckInput;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final ValueChanged<bool>? onInputFocusChanged;

  /// Stable identity for the inner text field so it survives the screen's
  /// keyboard-driven layout switches without re-mounting (see
  /// `_TranslateScreenState._textInputFieldKey`).
  final Key? inputFieldKey;
  final bool compactLayout;

  @override
  Widget build(BuildContext context) {
    if (compactLayout) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 4),
        child: _BottomInputArea(
          state: state,
          inputEnabled: inputEnabled,
          disabledReason: disabledReason,
          compact: true,
          onDirectionChanged: onDirectionChanged,
          onInputChanged: onInputChanged,
          onExternalInput: onExternalInput,
          onClear: onClear,
          onExplain: onExplain,
          onCheckInput: onCheckInput,
          onInputFocusChanged: onInputFocusChanged,
          inputFieldKey: inputFieldKey,
        ),
      );
    }

    if (!state.hasInput && state.aiResponse.trim().isEmpty) {
      final bool keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
      final double previewHeight = keyboardOpen
          ? 92
          : MediaQuery.sizeOf(context).height < 700
          ? 112
          : 144;
      final Widget emptyOutput = state.latinToBaybayin
          ? const EmptyOutput()
          : const EmptyOutput(
              message: 'Enter encoded Baybayin below',
              icon: Icons.translate_rounded,
            );
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
              child: SizedBox(
                height: previewHeight,
                child: Center(child: emptyOutput),
              ),
            ),
            _BottomInputArea(
              state: state,
              inputEnabled: inputEnabled,
              disabledReason: disabledReason,
              compact: false,
              onDirectionChanged: onDirectionChanged,
              onInputChanged: onInputChanged,
              onExternalInput: onExternalInput,
              onClear: onClear,
              onExplain: onExplain,
              onCheckInput: onCheckInput,
              onInputFocusChanged: onInputFocusChanged,
              inputFieldKey: inputFieldKey,
            ),
          ],
        ),
      );
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Center(
              child: state.hasInput
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        FilledOutput(
                          baybayin: state.baybayinText,
                          latin: state.latinText,
                          copyLabel: 'Copy',
                          shareLabel: 'Share',
                          onCopy: onCopy,
                          onShare: onShare,
                        ),
                        if (state.aiResponse.trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: 16),
                          TranslateFeedbackCard(
                            title: 'AI feedback',
                            body: state.aiResponse,
                            sourceLabel: state.aiSource?.label,
                          ),
                        ],
                      ],
                    )
                  : state.latinToBaybayin
                  ? const EmptyOutput()
                  : const EmptyOutput(
                      message: 'Enter encoded Baybayin below',
                      icon: Icons.translate_rounded,
                    ),
            ),
          ),
        ),
        _BottomInputArea(
          state: state,
          inputEnabled: inputEnabled,
          disabledReason: disabledReason,
          compact: false,
          onDirectionChanged: onDirectionChanged,
          onInputChanged: onInputChanged,
          onExternalInput: onExternalInput,
          onClear: onClear,
          onExplain: onExplain,
          onCheckInput: onCheckInput,
          onInputFocusChanged: onInputFocusChanged,
          inputFieldKey: inputFieldKey,
        ),
      ],
    );
  }
}

class _BottomInputArea extends StatelessWidget {
  const _BottomInputArea({
    required this.state,
    required this.inputEnabled,
    required this.disabledReason,
    required this.compact,
    required this.onDirectionChanged,
    required this.onInputChanged,
    required this.onExternalInput,
    required this.onClear,
    required this.onExplain,
    required this.onCheckInput,
    this.onInputFocusChanged,
    this.inputFieldKey,
  });

  final TranslateTextState state;
  final bool inputEnabled;
  final String? disabledReason;
  final bool compact;
  final Key? inputFieldKey;
  final ValueChanged<bool> onDirectionChanged;
  final ValueChanged<String> onInputChanged;
  final ValueChanged<String> onExternalInput;
  final VoidCallback onClear;
  final VoidCallback onExplain;
  final VoidCallback onCheckInput;
  final ValueChanged<bool>? onInputFocusChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bool reverseInputCompact = !state.latinToBaybayin && state.hasInput;
    final bool keyboardCompact = compact || keyboardOpen || reverseInputCompact;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outline.withAlpha(80))),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        keyboardCompact ? 4 : 10,
        16,
        keyboardCompact ? 6 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DirectionToggle(
            latinToBaybayin: state.latinToBaybayin,
            compact: keyboardCompact,
            onToggle: onDirectionChanged,
          ),
          SizedBox(height: keyboardCompact ? 4 : 8),
          _InputField(
            key: inputFieldKey,
            text: state.inputText,
            revision: state.inputRevision,
            // Stay enabled while the AI is working. Disabling the field on
            // `aiBusy` drops focus and force-closes the keyboard, then
            // re-enabling on completion reopens it — the IME show/hide burst
            // seen right after each inference. The action buttons
            // (`_TextActionsRow`) and the controller already block re-entry
            // while busy, so keeping the field editable is safe.
            enabled: inputEnabled,
            expanded: !compact,
            dense: keyboardCompact,
            hintText: state.latinToBaybayin
                ? 'Type in Filipino...'
                : 'Type encoded Baybayin like ka, ki, or k+...',
            onChanged: onInputChanged,
            onClear: onClear,
            onFocusChanged: onInputFocusChanged,
          ),
          if (!state.latinToBaybayin) ...<Widget>[
            const SizedBox(height: 7),
            _ReverseExamplesHint(
              compact: keyboardCompact,
              enabled: inputEnabled && !state.aiBusy,
              onSelect: onExternalInput,
            ),
          ],
          if (state.feedbackMessages.isNotEmpty ||
              state.cleanupPreview != null) ...<Widget>[
            const SizedBox(height: 7),
            _InputFeedbackList(
              messages: state.feedbackMessages,
              cleanupPreview: state.cleanupPreview,
              compact: keyboardCompact,
            ),
          ],
          if (state.hasInput) ...<Widget>[
            const SizedBox(height: 8),
            _TextActionsRow(
              busy: state.aiBusy,
              enabled: inputEnabled && state.hasInput,
              compact: keyboardCompact,
              onExplain: onExplain,
              onCheckInput: onCheckInput,
            ),
          ],
          if (disabledReason != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              disabledReason!,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withAlpha(160),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InputField extends StatefulWidget {
  const _InputField({
    super.key,
    required this.text,
    required this.revision,
    required this.enabled,
    required this.expanded,
    required this.dense,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    this.onFocusChanged,
  });

  final String text;

  /// Bumped by the controller only on external (non-typing) mutations.
  /// The field resyncs its controller exclusively when this changes, so
  /// plain typing never resets the cursor or breaks IME composition.
  final int revision;
  final bool enabled;
  final bool expanded;
  final bool dense;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<bool>? onFocusChanged;

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.text;
    _hasText = widget.text.isNotEmpty;
    _controller.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  /// Rebuild only when the text crosses the empty/non-empty boundary —
  /// that is the only thing the field's own build depends on (the clear
  /// icon). Rebuilding on every keystroke is what made typing janky.
  void _handleTextChanged() {
    final bool hasText = _controller.text.isNotEmpty;
    if (hasText == _hasText) return;
    setState(() => _hasText = hasText);
  }

  void _handleFocusChanged() {
    widget.onFocusChanged?.call(_focusNode.hasFocus);
  }

  @override
  void didUpdateWidget(covariant _InputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only an external mutation (clear, example chip, direction-driven
    // reset) bumps the revision. Typing-driven rebuilds leave the field —
    // and the user's cursor / IME composing region — completely alone.
    if (widget.revision == oldWidget.revision) return;
    if (_controller.text == widget.text) return;
    _controller.value = TextEditingValue(
      text: widget.text,
      selection: TextSelection.collapsed(offset: widget.text.length),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return TextField(
      key: ValueKey<String>(
        widget.hintText.contains('encoded Baybayin')
            ? 'translate-encoded-baybayin-input'
            : 'translate-filipino-input',
      ),
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      keyboardType: widget.expanded
          ? TextInputType.multiline
          : TextInputType.text,
      textInputAction: widget.expanded
          ? TextInputAction.newline
          : TextInputAction.done,
      minLines: widget.expanded ? (widget.dense ? 2 : 4) : 1,
      maxLines: widget.expanded ? 7 : 1,
      textAlignVertical: widget.expanded
          ? TextAlignVertical.top
          : TextAlignVertical.center,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        filled: true,
        fillColor: cs.surfaceContainerLow,
        isDense: widget.dense || !widget.expanded,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: widget.expanded ? (widget.dense ? 8 : 14) : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline.withAlpha(100)),
        ),
        hintStyle: TextStyle(color: cs.onSurface.withAlpha(120), fontSize: 14),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: cs.onSurface.withAlpha(130),
                ),
                onPressed: () {
                  _controller.clear();
                  widget.onClear();
                },
              )
            : null,
      ),
    );
  }
}

class _InputFeedbackList extends StatelessWidget {
  const _InputFeedbackList({
    required this.messages,
    required this.cleanupPreview,
    required this.compact,
  });

  final List<String> messages;
  final String? cleanupPreview;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<Widget> children = messages
        .map(
          (String message) => Padding(
            padding: EdgeInsets.only(bottom: compact ? 3 : 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.info_outline_rounded,
                  size: compact ? 13 : 14,
                  color: cs.primary.withAlpha(190),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      height: 1.25,
                      color: cs.onSurface.withAlpha(170),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(growable: true);
    final String? cleanedInput = cleanupPreview;
    if (cleanedInput != null) {
      children.add(
        Padding(
          padding: EdgeInsets.only(top: compact ? 1 : 2),
          child: _CleanupPreviewPill(value: cleanedInput, compact: compact),
        ),
      );
    }
    return Semantics(
      label: <String>[
        ...messages,
        if (cleanedInput != null) 'Used as: $cleanedInput',
      ].join(' '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _CleanupPreviewPill extends StatelessWidget {
  const _CleanupPreviewPill({required this.value, required this.compact});

  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 6 : 7),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withAlpha(95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.tertiary.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.cleaning_services_outlined,
            size: compact ? 13 : 14,
            color: cs.onTertiaryContainer.withAlpha(190),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Used as: $value',
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                height: 1.25,
                color: cs.onTertiaryContainer.withAlpha(220),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReverseExamplesHint extends StatelessWidget {
  const _ReverseExamplesHint({
    required this.compact,
    required this.enabled,
    required this.onSelect,
  });

  final bool compact;
  final bool enabled;
  final ValueChanged<String> onSelect;

  static const List<String> _examples = <String>['ka', 'ki', 'ku', 'k+'];

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Examples: ka, ki, ku, k+',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Text(
              compact ? 'Try:' : 'Examples:',
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withAlpha(170),
              ),
            ),
          ),
          for (final String example in _examples)
            ActionChip(
              visualDensity: compact
                  ? VisualDensity.compact
                  : VisualDensity.standard,
              label: Text(example),
              tooltip: 'Use $example',
              onPressed: enabled ? () => onSelect(example) : null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelStyle: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: enabled ? cs.onSecondaryContainer : cs.onSurfaceVariant,
              ),
              backgroundColor: cs.secondaryContainer.withAlpha(190),
              disabledColor: cs.surfaceContainerHighest,
              side: BorderSide(color: cs.outline.withAlpha(90)),
              padding: const EdgeInsets.symmetric(horizontal: 2),
            ),
        ],
      ),
    );
  }
}

class _TextActionsRow extends StatelessWidget {
  const _TextActionsRow({
    required this.busy,
    required this.enabled,
    required this.compact,
    required this.onExplain,
    required this.onCheckInput,
  });

  final bool busy;
  final bool enabled;
  final bool compact;
  final VoidCallback onExplain;
  final VoidCallback onCheckInput;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        children: <Widget>[
          Expanded(
            child: _ActionButton(
              label: busy ? 'Working...' : 'Explain',
              enabled: enabled && !busy,
              compact: true,
              onTap: onExplain,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              label: 'Check Input',
              enabled: enabled && !busy,
              compact: true,
              onTap: onCheckInput,
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _ActionButton(
          label: busy ? 'Working...' : 'Explain',
          enabled: enabled && !busy,
          compact: false,
          onTap: onExplain,
        ),
        _ActionButton(
          label: 'Check Input',
          enabled: enabled && !busy,
          compact: false,
          onTap: onCheckInput,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.enabled,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 40 : 44),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 7 : 9,
          ),
          decoration: BoxDecoration(
            color: enabled ? cs.surfaceContainer : cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: enabled ? cs.outline : cs.outline.withAlpha(90),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: enabled ? cs.onSurface : cs.onSurface.withAlpha(120),
            ),
          ),
        ),
      ),
    );
  }
}
