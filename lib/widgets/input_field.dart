import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';

class CustomInputField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final void Function(String)? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderRadius;
  final bool isRequired;

  const CustomInputField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.focusNode,
    this.contentPadding,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(
                label!,
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppStyles.spacing8),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          onChanged: onChanged,
          onTap: onTap,
          onFieldSubmitted: onSubmitted,
          inputFormatters: inputFormatters,
          focusNode: focusNode,
          style: AppStyles.bodyMedium.copyWith(
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding: contentPadding ?? const EdgeInsets.symmetric(
              horizontal: AppStyles.spacing16,
              vertical: AppStyles.spacing12,
            ),
            filled: true,
            fillColor: fillColor ?? AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? AppStyles.radius8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? AppStyles.radius8),
              borderSide: BorderSide(
                color: borderColor ?? AppColors.grey300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? AppStyles.radius8),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? AppStyles.radius8),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? AppStyles.radius8),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? AppStyles.radius8),
              borderSide: BorderSide(
                color: AppColors.grey300,
                width: 1,
              ),
            ),
            hintStyle: AppStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            errorStyle: AppStyles.bodySmall.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}

class CustomDropdownField<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final bool isRequired;
  final Widget? prefixIcon;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderRadius;

  const CustomDropdownField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.isRequired = false,
    this.prefixIcon,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(
                label!,
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppStyles.spacing8),
        ],
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          style: AppStyles.bodyMedium.copyWith(
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppStyles.spacing16,
              vertical: AppStyles.spacing12,
            ),
            filled: true,
            fillColor: fillColor ?? AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? AppStyles.radius8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? AppStyles.radius8),
              borderSide: BorderSide(
                color: borderColor ?? AppColors.grey300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? AppStyles.radius8),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? AppStyles.radius8),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? AppStyles.radius8),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? AppStyles.radius8),
              borderSide: BorderSide(
                color: AppColors.grey300,
                width: 1,
              ),
            ),
            hintStyle: AppStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            errorStyle: AppStyles.bodySmall.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}

class CustomDateField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final DateTime? value;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final void Function(DateTime?)? onChanged;
  final String? Function(DateTime?)? validator;
  final bool enabled;
  final bool isRequired;
  final Widget? prefixIcon;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderRadius;

  const CustomDateField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.value,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.isRequired = false,
    this.prefixIcon,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(
                label!,
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppStyles.spacing8),
        ],
        GestureDetector(
          onTap: enabled ? () => _selectDate(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyles.spacing16,
              vertical: AppStyles.spacing12,
            ),
            decoration: BoxDecoration(
              color: fillColor ?? AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(borderRadius ?? AppStyles.radius8),
              border: Border.all(
                color: borderColor ?? AppColors.grey300,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  prefixIcon!,
                  const SizedBox(width: AppStyles.spacing12),
                ],
                Expanded(
                  child: Text(
                    value != null
                        ? '${value!.day}/${value!.month}/${value!.year}'
                        : hint ?? 'Select Date',
                    style: AppStyles.bodyMedium.copyWith(
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppStyles.spacing4),
          Text(
            errorText!,
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
    );
    if (picked != null && picked != value) {
      onChanged?.call(picked);
    }
  }
}

class CustomSearchField extends StatelessWidget {
  final String? hint;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderRadius;

  const CustomSearchField({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      style: AppStyles.bodyMedium.copyWith(
        color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
      ),
      decoration: InputDecoration(
        hintText: hint ?? 'Search...',
        prefixIcon: prefixIcon ?? const Icon(Icons.search),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacing16,
          vertical: AppStyles.spacing12,
        ),
        filled: true,
        fillColor: fillColor ?? AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? AppStyles.radius8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? AppStyles.radius8),
          borderSide: BorderSide(
            color: borderColor ?? AppColors.grey300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? AppStyles.radius8),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        hintStyle: AppStyles.bodyMedium.copyWith(
          color: AppColors.textHint,
        ),
      ),
    );
  }
}
