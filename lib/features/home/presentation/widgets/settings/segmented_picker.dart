import 'package:flutter/material.dart';

class SegmentedPicker<T> extends StatelessWidget {
  const SegmentedPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map(((T, String) opt) {
          final bool active = opt.$1 == selected;
          final BorderRadius radius = BorderRadius.circular(7);
          return Padding(
            padding: EdgeInsetsDirectional.only(
              end: identical(opt, options.last) ? 0 : 2,
            ),
            child: Semantics(
              button: true,
              selected: active,
              label: '${opt.$2} option',
              excludeSemantics: true,
              child: Tooltip(
                message: opt.$2,
                excludeFromSemantics: true,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: radius,
                  child: InkWell(
                    onTap: () => onSelect(opt.$1),
                    borderRadius: radius,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? cs.primary : Colors.transparent,
                        borderRadius: radius,
                      ),
                      child: Text(
                        opt.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: active
                              ? cs.onPrimary
                              : cs.onSurface.withAlpha(185),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
