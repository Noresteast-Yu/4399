import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_app/providers/user_preferences_provider.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const TopNavBar(
        title: '出行偏好',
        showBack: true,
      ),
      body: Consumer<UserPreferencesProvider>(
        builder: (context, preferences, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  context,
                  '路线偏好',
                  [
                    _buildSwitchOption(
                      context,
                      '优先最少换乘',
                      '减少换乘次数，即使路线稍长',
                      preferences.preferLessTransfers,
                      (value) => preferences.setPreferLessTransfers(value),
                    ),
                    _buildSwitchOption(
                      context,
                      '优先最快路线',
                      '选择用时最短的路线',
                      preferences.preferFastestRoute,
                      (value) => preferences.setPreferFastestRoute(value),
                    ),
                    _buildSwitchOption(
                      context,
                      '优先最少步行',
                      '减少步行距离，适合携带行李',
                      preferences.preferLessWalking,
                      (value) => preferences.setPreferLessWalking(value),
                    ),
                    _buildSwitchOption(
                      context,
                      '避开拥挤线路',
                      '避开高峰时段拥挤的线路',
                      preferences.avoidCrowdedLines,
                      (value) => preferences.setAvoidCrowdedLines(value),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingL),
                _buildSection(
                  context,
                  '路线类型偏好',
                  [
                    _buildRadioOption(
                      context,
                      '最快路线',
                      '优先选择用时最短的路线',
                      preferences.preferredRouteType == 'fastest',
                      () => preferences.setPreferredRouteType('fastest'),
                    ),
                    _buildRadioOption(
                      context,
                      '最少换乘',
                      '优先选择换乘次数最少的路线',
                      preferences.preferredRouteType == 'least_transfer',
                      () => preferences.setPreferredRouteType('least_transfer'),
                    ),
                    _buildRadioOption(
                      context,
                      '最少步行',
                      '优先选择步行距离最短的路线',
                      preferences.preferredRouteType == 'least_walking',
                      () => preferences.setPreferredRouteType('least_walking'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppTheme.spacingM),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusL,
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchOption(
    BuildContext context,
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      title: Text(
        title,
        style: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        description,
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildRadioOption(
    BuildContext context,
    String title,
    String description,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      leading: Radio<bool>(
        value: true,
        groupValue: isSelected,
        onChanged: (value) => onTap(),
      ),
      title: Text(
        title,
        style: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        description,
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
    );
  }
}
