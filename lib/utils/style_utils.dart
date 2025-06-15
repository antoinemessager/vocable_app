import 'package:flutter/material.dart';

class StyleUtils {
  // Taille de référence (écran de test)
  static const double _referenceWidth = 360;
  static const double _referenceHeight = 800;

  static double getAdaptiveFontSize(BuildContext context, double baseSize) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // Calculer le facteur d'échelle en fonction de la plus petite dimension
    final widthScale = width / _referenceWidth;
    final heightScale = height / _referenceHeight;
    final scaleFactor = widthScale < heightScale ? widthScale : heightScale;

    // Limiter le facteur d'échelle pour éviter des tailles trop grandes ou trop petites
    final limitedScaleFactor = scaleFactor.clamp(0.8, 1.2);

    // Appliquer le facteur d'échelle à la taille de base
    return baseSize * limitedScaleFactor;
  }

  static double getAdaptiveLineHeight(BuildContext context, double baseHeight) {
    final size = MediaQuery.of(context).size;
    final height = size.height;

    // Calculer le facteur d'échelle en fonction de la hauteur
    final heightScale = height / _referenceHeight;

    // Limiter le facteur d'échelle
    final limitedScaleFactor = heightScale.clamp(0.8, 1.2);

    return baseHeight * limitedScaleFactor;
  }

  static TextStyle getAdaptiveTextStyle(
    BuildContext context, {
    required double baseSize,
    double? baseLineHeight,
    Color? color,
    FontWeight? fontWeight,
    String? fontFamily,
    FontStyle? fontStyle,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontSize: getAdaptiveFontSize(context, baseSize),
      height: baseLineHeight != null
          ? getAdaptiveLineHeight(context, baseLineHeight)
          : null,
      color: color,
      fontWeight: fontWeight,
      fontFamily: fontFamily,
      fontStyle: fontStyle,
      decoration: decoration,
    );
  }

  // Constantes pour les tailles de texte courantes
  static const double headlineLarge = 32;
  static const double headlineMedium = 24;
  static const double headlineSmall = 20;
  static const double titleLarge = 18;
  static const double titleMedium = 16;
  static const double titleSmall = 14;
  static const double bodyLarge = 16;
  static const double bodyMedium = 14;
  static const double bodySmall = 12;
  static const double labelLarge = 14;
  static const double labelMedium = 12;
  static const double labelSmall = 10;

  // Constantes pour les interlignes courants
  static const double lineHeightTight = 1.0;
  static const double lineHeightNormal = 1.2;
  static const double lineHeightLoose = 1.5;
}
