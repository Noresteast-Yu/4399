import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_app/providers/user_preferences_provider.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';

class LuggageSettingsPage extends StatelessWidget {
  const LuggageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(
        title: '行李设置',
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
                  '行李信息',
                  [
                    _buildSwitchOption(
                      context,
                      '携带行李',
                      '开启后将优先规划适合携带行李的路线',
                      preferences.hasLuggage,
                      (value) => preferences.setHasLuggage(value),
                    ),
                  ],
                ),
                if (preferences.hasLuggage) ...[
                  SizedBox(height: AppTheme.spacingL),
                  _buildSection(
                    context,
                    '行李规格',
                    [
                      _buildRadioOption(
                        context,
                        '小型行李',
                        '背包、手提包等，可随身携带',
                        preferences.luggageSize == 'small',
                        () => preferences.setLuggageSize('small'),
                      ),
                      _buildRadioOption(
                        context,
                        '中型行李',
                        '登机箱、中型行李箱',
                        preferences.luggageSize == 'medium',
                        () => preferences.setLuggageSize('medium'),
                      ),
                      _buildRadioOption(
                        context,
                        '大型行李',
                        '托运箱、大型行李箱',
                        preferences.luggageSize == 'large',
                        () => preferences.setLuggageSize('large'),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingL),
                  _buildSection(
                    context,
                    '行李数量',
                    [
                      _buildCounterOption(
                        context,
                        '行李件数',
                        '请选择携带的行李件数',
                        preferences.luggageCount,
                        0,
                        5,
                        (value) => preferences.setLuggageCount(value),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingL),
                  _buildSection(
                    context,
                    '特殊需求',
                    [
                      _buildSwitchOption(
                        context,
                        '需要宽闸机',
                        '携带大件行李时需要使用宽闸机',
                        preferences.needWideGate,
                        (value) => preferences.setNeedWideGate(value),
                      ),
                    ],
                  ),
                ],
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

  Widget _buildCounterOption(
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
      padding: EdgeInsets.all(AppTheme.spacingM),
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
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline),
                    color: value <= min
                        ? colorScheme.onSurfaceVariant.withOpacity(0.3)
                        : colorScheme.primary,
                    onPressed: value > min
                        ? () => onChanged(value - 1)
                        : null,
                  ),
                  Container(
                    width: 50,
                    alignment: Alignment.center,
                    child: Text(
                      '$value',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    color: value >= max
                        ? colorScheme.onSurfaceVariant.withOpacity(0.3)
                        : colorScheme.primary,
                    onPressed: value < max
                        ? () => onChanged(value + 1)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
