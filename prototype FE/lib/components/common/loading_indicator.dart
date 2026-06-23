import 'package:flutter/material.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool fullScreen;
  
  const LoadingIndicator({
    super.key,
    this.message,
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
        if (message != null)
          Padding(
            padding: EdgeInsets.only(top: AppTheme.spacingM),
            child: Text(
              message!,
              style: AppTheme.bodyText2,
            ),
          ),
      ],
    );
    
    if (fullScreen) {
      return Container(
        color: AppTheme.background,
        child: content,
      );
    }
    
    return content;
  }
}
