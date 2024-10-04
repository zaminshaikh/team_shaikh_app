import 'package:flutter/material.dart';

/// Color constants used in the app.
class AppColors {
  static const defaultWhite = Color(0xFFFFFFFF);
  static const defaultGray50 = Color(0xFFF9FAFB);
  static const defaultGray100 = Color(0xFFF3F4F6);
  static const defaultGray200 = Color(0xFFE5E7EB);
  static const defaultGray500 = Color(0xFF6B7280);
  static const defaultGray700 = Color(0xFF373F51);
  static const defaultGray800 = Color(0xFF1F2937);

  static const defaultGreen100 = Color(0xFFD1FAE5);
  static const defaultGreen200 = Color(0xFFA7F3D0);
  static const defaultGreen400 = Color(0xFF34D399);

  static const defaultRed100 = Color(0xFFFEF2F2);
  static const defaultRed200 = Color(0xFFFECACA); // Corrected hex code
  static const defaultRed400 = Color(0xFFF87171);

  static const defaultYellow400 = Color(0xFFFBBD24); // Corrected hex code

  static const defaultBlue500 = Color(0xFF0D5EAF);
  static const defaultBlue300 = Color(0xFF3199DD);
  static const defaultBlue100 = Color(0xFFD3EEFF);

  static const defaultBlueGray900 = Color(0xFF111827);
  static const defaultBlueGray800 = Color(0xFF1E293B);
  static const defaultBlueGray700 = Color(0xFF334155);
  static const defaultBlueGray600 = Color(0xFF475569);
  static const defaultBlueGray500 = Color(0xFF64748B);
  static const defaultBlueGray400 = Color(0xFF94A3B8);
  static const defaultBlueGray300 = Color(0xFFCBD5E1);
  static const defaultBlueGray200 = Color(0xFFE2E8F0);
  static const defaultBlueGray100 = Color(0xFFF1F5F9);

  static const extendedEmerald200 = Color(0xFFA7F3D0);
  static const extendedEmerald400 = Color(0xFF34D399);
  static const extendedEmerald600 = Color(0xFF059669);
  static const extendedEmerald800 = Color(0xFF065F46);

  static const extendedIndigo50 = Color(0xFFEEF2FF);
  static const extendedIndigo200 = Color(0xFFC7D2FE);
  static const extendedIndigo400 = Color(0xFF818CF8);
  static const extendedIndigo800 = Color(0xFF3730A3);

  // Additional colors from constants.dart (adjusted names to avoid conflicts)
  static const altBlue500 = Color(0xFF1E4B89);
  static const altBlue300 = Color(0xFF9DBBE6);
  static const altBlueGray800 = Color(0xFF374151);
  static const altBlueGray900 = Color(0xFF1F2937);
  static const gray = Color(0xFF7A7A7A);
  static const grayDark = Color(0xFF555657);
  static const green = Color(0xFF2F862F);
  static const yellow = Color(0xFFDBC33C);
  static const red = Color(0xFF951C1C);
}

/// Text style constants used in the app.
class AppTextStyles {
  static const _fontFamily = 'Titillium Web';

  // Original text styles
  static TextStyle xl3({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 28.0,
        color: color,
      );

  static TextStyle xl2({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 24.0,
        color: color,
      );

  static TextStyle xl({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 20.0,
        color: color,
      );

  static TextStyle lBold({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 18.0,
        color: color,
      );

  static TextStyle lRegular({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.normal,
        fontSize: 18.0,
        color: color,
      );

  static TextStyle mBold({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 16.0,
        color: color,
      );

  static TextStyle mSemiBold({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 16.0,
        color: color,
      );

  static TextStyle mRegular({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.normal,
        fontSize: 16.0,
        color: color,
      );

  static TextStyle sBold({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 15.0,
        color: color,
      );

  static TextStyle sRegular({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.normal,
        fontSize: 15.0,
        color: color,
      );

  static TextStyle xsBold({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 14.0,
        color: color,
      );

  static TextStyle sSemiBold({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 14.0,
        color: color,
      );

  static TextStyle xsRegular({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.normal,
        fontSize: 14.0,
        color: color,
      );

  static TextStyle xs2Bold({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 12.0,
        color: color,
      );

  static TextStyle xs2Regular({Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.normal,
        fontSize: 12.0,
        color: color,
      );

  // Additional styles from styles.dart
  static const headerTextStyle = TextStyle(
    fontSize: 26,
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontFamily: _fontFamily,
  );

  static const inputTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontFamily: _fontFamily,
  );

  static const orTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
    color: Colors.white,
    fontFamily: _fontFamily,
  );

  static const validationTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontFamily: _fontFamily,
  );

  static const nextButtonTextStyle = TextStyle(
    fontSize: 18,
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontFamily: _fontFamily,
  );

  static const bodyTextStyle = TextStyle(
    fontSize: 18,
    color: Colors.white,
    fontFamily: _fontFamily,
  );

  static const loginTextStyle = TextStyle(
    fontSize: 18,
    color: Colors.blue,
    fontWeight: FontWeight.bold,
    fontFamily: _fontFamily,
  );

  static const dialogTitleTextStyle = TextStyle(
    fontSize: 20,
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontFamily: _fontFamily,
  );

  static const dialogBodyTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontFamily: _fontFamily,
  );

  static const continueButtonTextStyle = TextStyle(
    fontSize: 18,
    color: Colors.blue,
    fontWeight: FontWeight.bold,
    fontFamily: _fontFamily,
  );

  static const googleButtonTextStyle = TextStyle(
    fontSize: 18,
    color: Colors.blue,
    fontWeight: FontWeight.bold,
    fontFamily: _fontFamily,
  );
}
