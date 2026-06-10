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
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingM),
            child: Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
    );

    if (fullScreen) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: content,
      );
    }

    return content;
  }
}
