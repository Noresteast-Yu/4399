import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_app/providers/user_preferences_provider.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';

class AbilitySettingsPage extends StatelessWidget {
  const AbilitySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(
        title: '行动能力设置',
        showBack: true,
      ),
      body: Consumer<UserPreferencesProvider>(
        builder: (context, preferences, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  context,
                  '行动能力等级',
                  [
                    _buildRadioOption(
                      context,
                      '正常',
                      '行动自如，无特殊需求',
                      preferences.mobilityLevel == 'normal',
                      () => preferences.setMobilityLevel('normal'),
                    ),
                    _buildRadioOption(
                      context,
                      '行动不便',
                      '行走较慢，需要无障碍设施',
                      preferences.mobilityLevel == 'limited',
                      () => preferences.setMobilityLevel('limited'),
                    ),
                    _buildRadioOption(
                      context,
                      '轮椅使用者',
                      '需要使用轮椅，必须有无障碍设施',
                      preferences.mobilityLevel == 'wheelchair',
                      () => preferences.setMobilityLevel('wheelchair'),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingL),
                _buildSection(
                  context,
                  '设施需求',
                  [
                    _buildSwitchOption(
                      context,
                      '需要电梯',
                      '优先规划有电梯的路线',
                      preferences.needElevator,
                      (value) => preferences.setNeedElevator(value),
                    ),
                    _buildSwitchOption(
                      context,
                      '需要扶梯',
                      '优先规划有扶梯的路线',
                      preferences.needEscalator,
                      (value) => preferences.setNeedEscalator(value),
                    ),
                    _buildSwitchOption(
                      context,
                      '避免楼梯',
                      '避开需要走楼梯的路线',
                      preferences.avoidStairs,
                      (value) => preferences.setAvoidStairs(value),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingL),
                _buildSection(
                  context,
                  '步行距离限制',
                  [
                    _buildSliderOption(
                      context,
                      '最大步行距离',
                      '单次步行不超过此距离',
                      preferences.maxWalkingDistance,
                      100,
                      1000,
                      (value) => preferences.setMaxWalkingDistance(value),
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
        const SizedBox(height: AppTheme.spacingM),
        Card(
          shape: const RoundedRectangleBorder(
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

  Widget _buildSliderOption(
    BuildContext context,
    String title,
    String description,
    int value,
    int min,
    int max,
    Function(int) onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$value米',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: (max - min) ~/ 50,
            label: '$value米',
            onChanged: (newValue) => onChanged(newValue.round()),
          ),
        ],
      ),
    );
  }
}
