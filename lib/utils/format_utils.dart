import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';

/// Utility class for formatting values across the app
class FormatUtils {
  /// Format currency amount with K/L notation for large numbers
  static String formatCurrency(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  /// Format date to 'dd MMM yyyy' format
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format date to 'dd/MM/yyyy' format
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Get bill icon based on utility type
  static IconData getBillIcon(String utilityType) {
    final lowerType = utilityType.toLowerCase();
    if (lowerType.contains('electricity') || lowerType.contains('power') || lowerType.contains('light')) {
      return Icons.electrical_services;
    } else if (lowerType.contains('water')) {
      return Icons.water_drop;
    } else if (lowerType.contains('elevator') || lowerType.contains('lift')) {
      return Icons.elevator;
    } else if (lowerType.contains('parking') || lowerType.contains('car')) {
      return Icons.local_parking;
    } else if (lowerType.contains('maintenance')) {
      return Icons.build;
    } else {
      return Icons.receipt;
    }
  }

  /// Get bill color based on utility type
  static Color getBillColor(String utilityType) {
    final lowerType = utilityType.toLowerCase();
    if (lowerType.contains('electricity') || lowerType.contains('power') || lowerType.contains('light')) {
      return AppColors.electricity;
    } else if (lowerType.contains('water')) {
      return AppColors.water;
    } else if (lowerType.contains('elevator') || lowerType.contains('lift')) {
      return AppColors.maintenance;
    } else if (lowerType.contains('parking') || lowerType.contains('car')) {
      return AppColors.info;
    } else if (lowerType.contains('maintenance')) {
      return AppColors.maintenance;
    } else {
      return AppColors.primary;
    }
  }

  /// Get month name from month number (1-12)
  static String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  /// Get month index from month name
  static int getMonthIndex(String monthName) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months.indexOf(monthName);
  }

  /// Format time to 'hh:mm a' format
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  /// Format date and time
  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }
}

