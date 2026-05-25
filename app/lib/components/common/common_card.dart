import 'package:flutter/material.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class CommonCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isOutlined;
  final Color? color;

  const CommonCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.isOutlined = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).cardTheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusL,
        side: isOutlined
            ? BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              )
            : BorderSide.none,
      ),
      color: color ?? cardTheme.color,
      margin: margin ?? EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: AppTheme.borderRadiusL,
              child: _buildContent(),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (padding != null) {
      return Padding(
        padding: padding!,
        child: child,
      );
    }
    return child;
  }
}

class CommonCardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const CommonCardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
          if (onTap != null && trailing == null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}
