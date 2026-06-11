import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_app/providers/theme_provider.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  static const List<Map<String, dynamic>> themeColors = [
    {
      'name': '跟随系统',
      'icon': Icons.auto_awesome,
      'option': ThemeColorOption.system,
      'color': null,
    },
    {
      'name': '蓝色',
      'icon': Icons.color_lens,
      'option': ThemeColorOption.blue,
      'color': AppTheme.blueSeed,
    },
    {
      'name': '橙色',
      'icon': Icons.color_lens,
      'option': ThemeColorOption.orange,
      'color': AppTheme.orangeSeed,
    },
    {
      'name': '绿色',
      'icon': Icons.color_lens,
      'option': ThemeColorOption.green,
      'color': AppTheme.greenSeed,
    },
    {
      'name': '红色',
      'icon': Icons.color_lens,
      'option': ThemeColorOption.red,
      'color': AppTheme.redSeed,
    },
    {
      'name': '紫色',
      'icon': Icons.color_lens,
      'option': ThemeColorOption.purple,
      'color': AppTheme.purpleSeed,
    },
  ];

  static const List<Map<String, dynamic>> themeModes = [
    {
      'name': '浅色',
      'icon': Icons.light_mode,
      'option': ThemeModeOption.light,
    },
    {
      'name': '深色',
      'icon': Icons.dark_mode,
      'option': ThemeModeOption.dark,
    },
    {
      'name': '跟随系统',
      'icon': Icons.brightness_auto,
      'option': ThemeModeOption.system,
    },
  ];

  static const List<Map<String, dynamic>> fontSizes = [
    {
      'name': '最小',
      'icon': Icons.text_decrease,
      'option': FontSizeOption.smallest,
    },
    {
      'name': '较小',
      'icon': Icons.text_decrease,
      'option': FontSizeOption.smaller,
    },
    {
      'name': '标准',
      'icon': Icons.text_fields,
      'option': FontSizeOption.medium,
    },
    {
      'name': '较大',
      'icon': Icons.text_increase,
      'option': FontSizeOption.larger,
    },
    {
      'name': '最大',
      'icon': Icons.text_increase,
      'option': FontSizeOption.largest,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: const TopNavBar(
        title: '外观设置',
        showBack: true,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '外观',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),

                // 主题色选择
                _buildSectionCard(
                  context,
                  icon: Icons.palette,
                  title: '主题色',
                  subtitle: _getThemeColorName(themeProvider.themeColor),
                  onTap: () => _showThemeColorDialog(context, themeProvider),
                ),

                const SizedBox(height: AppTheme.spacingM),

                // 主题模式选择
                _buildSectionCard(
                  context,
                  icon: Icons.brightness_6,
                  title: '主题',
                  subtitle: _getThemeModeName(themeProvider.themeMode),
                  onTap: () => _showThemeModeDialog(context, themeProvider),
                ),

                const SizedBox(height: AppTheme.spacingM),

                // 字体大小选择
                _buildSectionCard(
                  context,
                  icon: Icons.text_fields,
                  title: '字体大小',
                  subtitle: _getFontSizeName(themeProvider.fontSize),
                  onTap: () => _showFontSizeDialog(context, themeProvider),
                ),

                const SizedBox(height: AppTheme.spacingL),

                // 主题色预览
                Text(
                  '主题色预览',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildThemeColorPreview(context, themeProvider.themeColor),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusXL,
      ),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.onSurfaceVariant),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        trailing:
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }

  String _getThemeColorName(ThemeColorOption color) {
    switch (color) {
      case ThemeColorOption.system:
        return '跟随系统';
      case ThemeColorOption.blue:
        return '蓝色';
      case ThemeColorOption.orange:
        return '橙色';
      case ThemeColorOption.green:
        return '绿色';
      case ThemeColorOption.red:
        return '红色';
      case ThemeColorOption.purple:
        return '紫色';
    }
  }

  String _getThemeModeName(ThemeModeOption mode) {
    switch (mode) {
      case ThemeModeOption.light:
        return '浅色';
      case ThemeModeOption.dark:
        return '深色';
      case ThemeModeOption.system:
        return '跟随系统';
    }
  }

  String _getFontSizeName(FontSizeOption size) {
    switch (size) {
      case FontSizeOption.smallest:
        return '最小';
      case FontSizeOption.smaller:
        return '较小';
      case FontSizeOption.medium:
        return '标准';
      case FontSizeOption.larger:
        return '较大';
      case FontSizeOption.largest:
        return '最大';
    }
  }

  Widget _buildThemeColorPreview(BuildContext context, ThemeColorOption color) {
    final previewColors = themeColors.map((c) {
      final displayColor = c['option'] == ThemeColorOption.system
          ? Theme.of(context).colorScheme.primary
          : c['color'] as Color;
      return {
        'name': c['name'],
        'color': displayColor,
        'option': c['option'],
      };
    }).toList();

    return Card(
      elevation: 0,
      color: previewColors.firstWhere((c) => c['option'] == color,
          orElse: () => previewColors[1])['color'] as Color,
      shape: const RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusXL,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: previewColors.map((themeColor) {
            final isSelected = color == themeColor['option'];
            return _buildColorChip(
              context,
              themeColor['name'] as String,
              themeColor['color'] as Color,
              isSelected,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildColorChip(
      BuildContext context, String label, Color color, bool isSelected) {
    final brightness = ThemeData.estimateBrightnessForColor(color);
    final isDark = brightness == Brightness.dark;
    final chipColor = isSelected
        ? (isDark ? color.lighten(0.3) : color.darken(0.3))
        : color.withValues(alpha: 0.2);
    final textColor =
        isSelected ? (isDark ? Colors.white : Colors.black87) : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: AppTheme.borderRadiusM,
        border: isSelected ? Border.all(color: color, width: 2) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showThemeColorDialog(
      BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题色'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: themeColors.map((themeColor) {
              return _buildThemeOption(
                context,
                themeColor['name'] as String,
                themeColor['icon'] as IconData,
                themeColor['option'] as ThemeColorOption,
                themeProvider,
                color: themeColor['color'] as Color?,
                isColorOption: true,
                isFontSizeOption: false,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showThemeModeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themeModes.map((themeMode) {
            return _buildThemeOption(
              context,
              themeMode['name'] as String,
              themeMode['icon'] as IconData,
              themeMode['option'] as ThemeModeOption,
              themeProvider,
              isColorOption: false,
              isFontSizeOption: false,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择字体大小'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: fontSizes.map((fontSize) {
            return _buildThemeOption(
              context,
              fontSize['name'] as String,
              fontSize['icon'] as IconData,
              fontSize['option'] as FontSizeOption,
              themeProvider,
              isColorOption: false,
              isFontSizeOption: true,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    IconData icon,
    dynamic option,
    ThemeProvider themeProvider, {
    Color? color,
    required bool isColorOption,
    required bool isFontSizeOption,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isSelected;
    if (isColorOption) {
      isSelected = themeProvider.themeColor == option;
    } else if (isFontSizeOption) {
      isSelected = themeProvider.fontSize == option;
    } else {
      isSelected = themeProvider.themeMode == option;
    }

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : null,
      selected: isSelected,
      onTap: () {
        if (isColorOption) {
          themeProvider.setThemeColor(option as ThemeColorOption);
        } else if (isFontSizeOption) {
          themeProvider.setFontSize(option as FontSizeOption);
        } else {
          themeProvider.setThemeMode(option as ThemeModeOption);
        }
        Navigator.pop(context);
      },
    );
  }
}

extension ColorBrightness on Color {
  Color lighten(double amount) {
    return Color.lerp(this, Colors.white, amount)!;
  }

  Color darken(double amount) {
    return Color.lerp(this, Colors.black, amount)!;
  }
}
