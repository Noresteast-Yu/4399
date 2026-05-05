import 'package:flutter/material.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class ErrorRetryPage extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  
  const ErrorRetryPage({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
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
              Icons.error_outline,
              size: 80,
              color: AppTheme.errorColor,
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
            Padding(
              padding: EdgeInsets.only(top: AppTheme.spacingL),
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                    vertical: AppTheme.spacingM,
                  ),
                ),
                child: const Text('重试'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
