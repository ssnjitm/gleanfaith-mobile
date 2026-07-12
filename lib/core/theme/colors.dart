import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF2563EB); // blue-600
  static const Color primaryAmber = Color(0xFFD97706); // amber-600
  static const Color primaryLight = Color(0xFF3B82F6); // blue-500
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryBlue, primaryAmber],
  );
  
  // Success
  static const Color success = Color(0xFF059669); // green-600
  static const Color successLight = Color(0xFF10B981); // green-500
  static const Color successBg = Color(0xFFD1FAE5); // green-100
  
  // Error
  static const Color error = Color(0xFFDC2626); // red-600
  static const Color errorLight = Color(0xFFEF4444); // red-500
  static const Color errorBg = Color(0xFFFEE2E2); // red-100
  static const Color errorBorder = Color(0xFFF87171); // red-400
  
  // Warning/Alert
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color warningBg = Color(0xFFFEF3C7); // yellow-100
  static const Color warningBorder = Color(0xFFFCD34D); // yellow-400
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937); // gray-800
  static const Color textSecondary = Color(0xFF374151); // gray-700
  static const Color textMuted = Color(0xFF6B7280); // gray-600
  static const Color textLight = Color(0xFF9CA3AF); // gray-500
  static const Color textWhite = Color(0xFFFFFFFF);
  
  // Backgrounds
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgGray = Color(0xFFF9FAFB); // gray-50
  static const Color bgCard = Color(0xFFFFFFFF);
  
  // Borders
  static const Color borderLight = Color(0xFFE5E7EB); // gray-200
  static const Color borderMedium = Color(0xFFD1D5DB); // gray-300
  static const Color borderFocus = Color(0xFF2563EB); // blue-600
  
  // Shadows
  static const Color shadowLight = Color(0x1A000000); // 10% opacity
  static const Color shadowMedium = Color(0x33000000); // 20% opacity
  
  // Disabled
  static const Color disabledBg = Color(0xFFF3F4F6); // gray-100
  static const Color disabledText = Color(0xFF9CA3AF); // gray-400
  
  // Input Field
  static const Color inputBg = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFD1D5DB); // gray-300
  static const Color inputFocusBorder = Color(0xFF2563EB); // blue-600
  static const Color inputFocusRing = Color(0x332563EB); // blue-600 with opacity
  static const Color inputPlaceholder = Color(0xFF9CA3AF); // gray-400
  static const Color inputIcon = Color(0xFF9CA3AF); // gray-400
  
  // Checkbox
  static const Color checkboxInactive = Color(0xFFD1D5DB); // gray-300
  static const Color checkboxActive = Color(0xFF2563EB); // blue-600
  
  // Link
  static const Color link = Color(0xFF2563EB); // blue-600
  static const Color linkHover = Color(0xFF1D4ED8); // blue-700
  
  // OTP Input
  static const Color otpBorder = Color(0xFFD1D5DB); // gray-300
  static const Color otpFocusBorder = Color(0xFF2563EB); // blue-600
  static const Color otpFocusRing = Color(0x332563EB); // blue-600 with opacity
}

// Extension for easy theme creation
extension AppThemeExtension on ThemeData {
  ThemeData get appTheme {
    return copyWith(
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.bgGray,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryAmber,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.errorBorder, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.errorBorder, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.inputPlaceholder),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        errorStyle: const TextStyle(color: AppColors.error),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.textMuted,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppColors.textLight,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.textLight,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: const BorderSide(color: AppColors.checkboxInactive, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.checkboxActive;
          }
          return AppColors.bgWhite;
        }),
      ),
    );
  }
}

// Custom Theme Data for Auth Cards
class AuthCardTheme {
  static const double cardRadius = 12;
  static const double cardPadding = 32;
  static const double maxCardWidth = 440;
  
  static const BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.bgCard,
    borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowLight,
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  );
}

// Custom Button Styles
class AppButtonStyles {
  static ButtonStyle primaryGradientButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.textWhite,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(vertical: 12),
    minimumSize: const Size(double.infinity, 48),
  ).copyWith(
    backgroundBuilder: (BuildContext context, Set<WidgetState> states, Widget? child) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      );
    },
  );

  static ButtonStyle outlinedButton = OutlinedButton.styleFrom(
    foregroundColor: AppColors.textMuted,
    side: const BorderSide(color: AppColors.borderMedium),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(vertical: 12),
    minimumSize: const Size(double.infinity, 48),
  );

  static ButtonStyle textButton = TextButton.styleFrom(
    foregroundColor: AppColors.textMuted,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
  );
}

// Custom Text Styles for Auth
class AuthTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    color: AppColors.textMuted,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.link,
  );

  static const TextStyle error = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
  );

  static const TextStyle success = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );

  static const TextStyle otpDigit = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}