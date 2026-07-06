import 'package:flutter/material.dart';

import 'row_icon.dart';

class ProfileNavRow extends StatelessWidget {
  const ProfileNavRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingLabel,
    this.isSoon = false,
    this.isDestructive = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final bool isSoon;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color fg = isDestructive
        ? cs.error
        : isSoon
        ? cs.onSurface.withAlpha(110)
        : cs.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: <Widget>[
            Opacity(
              opacity: isSoon ? 0.45 : 1.0,
              child: RowIcon(
                icon: icon,
                iconColor: isDestructive ? cs.onError : null,
                bgColor: isDestructive ? cs.error : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NavRowText(
                title: title,
                subtitle: subtitle,
                titleColor: fg,
              ),
            ),
            const SizedBox(width: 8),
            if (!isSoon && trailingLabel != null)
              Text(
                trailingLabel!,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withAlpha(128),
                ),
              ),
            const SizedBox(width: 4),
            if (isSoon) _SoonChip(cs: cs) else _NavChevron(cs: cs),
          ],
        ),
      ),
    );
  }
}

class _NavRowText extends StatelessWidget {
  const _NavRowText({
    required this.title,
    required this.titleColor,
    this.subtitle,
  });

  final String title;
  final Color titleColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11.5,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(110),
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }
}

class _SoonChip extends StatelessWidget {
  const _SoonChip({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        'Soon',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: cs.onSurface.withAlpha(110),
        ),
      ),
    );
  }
}

class _NavChevron extends StatelessWidget {
  const _NavChevron({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      size: 20,
      color: cs.onSurface.withAlpha(64),
    );
  }
}
