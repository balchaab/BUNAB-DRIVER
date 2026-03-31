import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/helper/responsive_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

// A global flag to prevent race conditions during snackbar transitions
bool _isSnackbarInProgress = false;

void customPrint(String message) {
  if (kDebugMode) {
    print(message);
  }
}

Future<void> showCustomSnackBar(String message, {
  bool isError = true, 
  int seconds = 3, 
  String? subMessage,
}) async {
  // 1. Guard: If a snackbar is currently being built/shown, ignore new triggers
  // This prevents the "transitionCompleter" assertion error during rapid events.
  if (_isSnackbarInProgress) return;

  // 2. Clear existing snackbars safely
  if (Get.isSnackbarOpen) {
    _isSnackbarInProgress = true;
    await Get.closeCurrentSnackbar();
    // Give the GetX SnackbarController enough time to fully dispose (approx 250ms)
    await Future.delayed(const Duration(milliseconds: 250));
    _isSnackbarInProgress = false;
  }

  // 3. Prevent crashes if the app context is lost or backgrounded
  if (Get.context == null) return;

  _isSnackbarInProgress = true;

  final context = Get.context!;
  final isDark = Get.isDarkMode;
  
  // Pre-calculate styles
  final Color backgroundColor = isDark 
      ? Colors.white 
      : Theme.of(context).textTheme.titleMedium?.color ?? Colors.black;
      
  final Color textColor = isDark 
      ? Theme.of(context).textTheme.bodySmall?.color ?? Colors.black 
      : Colors.white;

  // 4. Trigger the snackbar
  Get.rawSnackbar(
    duration: Duration(seconds: seconds),
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: backgroundColor,
    borderRadius: Dimensions.paddingSizeSmall,
    margin: EdgeInsets.all(Dimensions.paddingSizeSmall).copyWith(
      right: ResponsiveHelper.isDesktop ? Get.width * 0.7 : Dimensions.paddingSizeSmall,
    ),
    dismissDirection: DismissDirection.horizontal,
    messageText: Row(
      children: [
        Image.asset(
          isError ? Images.errorMessageIcon : Images.successMessageIcon,
          height: 20, width: 20,
        ),
        const SizedBox(width: Dimensions.paddingSize),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message, 
                style: textMedium.copyWith(color: textColor),
              ),
              if (subMessage != null) ...[
                const SizedBox(height: 2),
                Text(
                  subMessage,
                  style: textMedium.copyWith(
                    color: textColor.withValues(alpha: 0.75),
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  // Allow new snackbars once the "showing" logic is complete
  _isSnackbarInProgress = false;
}