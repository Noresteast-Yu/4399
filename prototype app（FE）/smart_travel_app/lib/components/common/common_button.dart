import 'package:flutter/material.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final double? height;
  
  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading || isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? AppTheme.primaryColor
              : AppTheme.surface,
          foregroundColor: isPrimary
              ? AppTheme.surface
              : AppTheme.primaryColor,
          side: isPrimary
              ? null
              : BorderSide(color: AppTheme.primaryColor),
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingL,
            vertical: AppTheme.spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusM,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPrimary ? AppTheme.surface : AppTheme.primaryColor,
                  ),
                ),
              )
            : Text(text),
      ),
    );
  }
}
