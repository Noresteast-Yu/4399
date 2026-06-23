import 'package:flutter/material.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class CommonInput extends StatelessWidget {
  final String hintText;
  final String? labelText;
  final String? errorText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final VoidCallback? onTap;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  
  const CommonInput({
    super.key,
    required this.hintText,
    this.labelText,
    this.errorText,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusM,
          borderSide: BorderSide(color: AppTheme.textTertiary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusM,
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusM,
          borderSide: BorderSide(color: AppTheme.errorColor),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingM,
        ),
      ),
    );
  }
}
