import 'package:flutter/material.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class EmptyDataPage extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  
  const EmptyDataPage({
    super.key,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: AppTheme.textTertiary,
            ),
            SizedBox(height: AppTheme.spacingM),
            Text(
              title,
              style: AppTheme.headline3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacingS),
            Text(
              message,
              style: AppTheme.bodyText2,
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null)
              Padding(
                padding: EdgeInsets.only(top: AppTheme.spacingL),
                child: ElevatedButton(
                  onPressed: onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingL,
                      vertical: AppTheme.spacingM,
                    ),
                  ),
                  child: Text(buttonText!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
