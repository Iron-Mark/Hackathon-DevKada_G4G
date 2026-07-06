import 'package:flutter/material.dart';

class SuggestedQuestionsRow extends StatelessWidget {
  const SuggestedQuestionsRow({super.key, required this.onTap});

  final void Function(String question) onTap;

  static const double _compactFloatingNavClearance = 124;
  static const double _regularFloatingNavClearance = 84;

  static const List<String> _questions = <String>[
    'Write my name in Baybayin',
    'What is a kudlit?',
    'Baybayin history?',
    'Translate "mahal kita"',
    'How many letters are there?',
    'Why did Baybayin disappear?',
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double floatingNavClearance = constraints.maxWidth < 420
            ? _compactFloatingNavClearance
            : _regularFloatingNavClearance;

        return SizedBox(
          height: 48,
          child: Padding(
            padding: EdgeInsetsDirectional.only(end: floatingNavClearance),
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (Rect bounds) => const LinearGradient(
                colors: <Color>[Colors.black, Colors.black, Colors.transparent],
                stops: <double>[0, 0.88, 1],
              ).createShader(bounds),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsetsDirectional.only(start: 16, end: 10),
                itemCount: _questions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, int i) => Semantics(
                  button: true,
                  label: _questions[i],
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => onTap(_questions[i]),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: cs.primary.withAlpha(105)),
                          borderRadius: BorderRadius.circular(17),
                          color: cs.surfaceContainerLowest,
                        ),
                        child: Text(
                          _questions[i],
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
