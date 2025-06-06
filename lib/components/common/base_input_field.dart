import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../themes/design_tokens.dart';

class BaseInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? error;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? prefix;
  final Widget? suffix;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const BaseInputField({
    Key? key,
    required this.label,
    this.hint,
    this.error,
    this.obscureText = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: DesignTokens.textPrimaryColor,
            fontSize: DesignTokens.fontSizeSm,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: DesignTokens.spacingXs),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
          autofocus: autofocus,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: TextStyle(
            color: DesignTokens.textPrimaryColor,
            fontSize: DesignTokens.fontSizeMd,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: DesignTokens.textSecondaryColor,
              fontSize: DesignTokens.fontSizeMd,
            ),
            errorText: error,
            errorStyle: TextStyle(
              color: DesignTokens.primaryColor,
              fontSize: DesignTokens.fontSizeSm,
            ),
            prefixIcon: prefix,
            suffixIcon: suffix,
            filled: true,
            fillColor: enabled ? DesignTokens.surfaceColor : DesignTokens.surfaceColor.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
              borderSide: BorderSide(color: DesignTokens.primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
              borderSide: BorderSide(color: DesignTokens.primaryColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
              borderSide: BorderSide(color: DesignTokens.primaryColor),
            ),
            contentPadding: EdgeInsets.all(DesignTokens.spacingMd),
          ),
        ),
      ],
    );
  }
} 