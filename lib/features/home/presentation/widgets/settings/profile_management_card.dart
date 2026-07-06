import 'package:flutter/material.dart';

import 'profile_management_item.dart';
import 'profile_management_tile.dart';
import 'settings_card.dart';
import 'settings_divider.dart';

class ProfileManagementCard extends StatelessWidget {
  const ProfileManagementCard({
    super.key,
    required this.items,
    required this.loadingActions,
    required this.onAction,
  });

  final List<ProfileManagementItem> items;
  final Set<String> loadingActions;
  final void Function(String actionId, String message) onAction;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          ProfileManagementTile(
            item: items[i],
            isPrimaryLoading: loadingActions.contains(items[i].primaryActionId),
            isSecondaryLoading:
                items[i].secondaryActionId != null &&
                loadingActions.contains(items[i].secondaryActionId!),
            onPrimaryTap: () => onAction(
              items[i].primaryActionId,
              items[i].primaryActionMessage,
            ),
            onSecondaryTap: items[i].secondaryActionMessage == null
                ? null
                : () => onAction(
                    items[i].secondaryActionId!,
                    items[i].secondaryActionMessage!,
                  ),
          ),
          if (i < items.length - 1) const SettingsDivider(),
        ],
      ],
    );
  }
}
