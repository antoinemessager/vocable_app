import 'package:flutter/material.dart';

class StyleUtils {
  static double getAdaptiveFontSize(BuildContext context, double baseSize) {
    // Taille de référence (écran de test)
    const double referenceWidth = 360; // Largeur de l'écran de test

    // Obtenir les dimensions de l'écran actuel
    final size = MediaQuery.of(context).size;

    final width = size.width;

    // Calculer le facteur d'échelle en fonction de la plus petite dimension
    final scaleFactor = width < referenceWidth ? width / referenceWidth : 1.0;

    // Appliquer le facteur d'échelle à la taille de base
    return baseSize * scaleFactor;
  }

  static TextStyle getAdaptiveTextStyle(
    BuildContext context, {
    required double baseSize,
    Color? color,
    FontWeight? fontWeight,
    String? fontFamily,
  }) {
    return TextStyle(
      fontSize: getAdaptiveFontSize(context, baseSize),
      color: color,
      fontWeight: fontWeight,
      fontFamily: fontFamily,
    );
  }
}
