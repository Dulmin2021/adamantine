import 'package:flutter/material.dart';

enum PhotoFilterPreset {
  none('Original'),
  emerald('Obsidian Emerald'),
  vivid('Vivid'),
  cyberpunk('Adamantine Violet'),
  monochrome('B&W'),
  warmSunset('Warm Sunset'),
  coolMist('Cool Mist');

  final String label;
  const PhotoFilterPreset(this.label);
}

class EditService {
  /// Generate a 4x5 ColorMatrix for the given brightness, contrast, and preset filter
  static ColorFilter getColorFilter({
    double brightness = 0.0, // -1.0 to 1.0
    double contrast = 1.0,   // 0.0 to 2.0
    PhotoFilterPreset preset = PhotoFilterPreset.none,
  }) {
    // Base contrast matrix
    final double t = (1.0 - contrast) / 2.0 * 255.0;
    final double b = brightness * 255.0;

    List<double> matrix = [
      contrast, 0, 0, 0, t + b,
      0, contrast, 0, 0, t + b,
      0, 0, contrast, 0, t + b,
      0, 0, 0, 1, 0,
    ];

    switch (preset) {
      case PhotoFilterPreset.emerald:
        // Radiant Obsidian Emerald tone: enrich deep greens & luminous mint highlights
        matrix = _multiplyMatrices(matrix, [
          0.9, 0.1, 0.0, 0, -5,
          0.1, 1.35, 0.1, 0, 20,
          0.0, 0.1, 0.95, 0, 5,
          0, 0, 0, 1, 0,
        ]);
        break;

      case PhotoFilterPreset.vivid:
        matrix = _multiplyMatrices(matrix, [
          1.3, -0.1, -0.1, 0, 0,
          -0.1, 1.3, -0.1, 0, 0,
          -0.1, -0.1, 1.3, 0, 0,
          0, 0, 0, 1, 0,
        ]);
        break;

      case PhotoFilterPreset.cyberpunk:
        // Electric violet shift: enhance blues/magenta, add purple glow in shadows
        matrix = _multiplyMatrices(matrix, [
          1.1, 0.0, 0.2, 0, 20,
          0.0, 0.9, 0.1, 0, -10,
          0.3, 0.1, 1.4, 0, 35,
          0, 0, 0, 1, 0,
        ]);
        break;

      case PhotoFilterPreset.monochrome:
        // Standard Rec. 709 grayscale luminance
        matrix = _multiplyMatrices(matrix, [
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
        break;

      case PhotoFilterPreset.warmSunset:
        matrix = _multiplyMatrices(matrix, [
          1.2, 0.1, 0.0, 0, 15,
          0.0, 1.0, 0.0, 0, 5,
          0.0, 0.0, 0.8, 0, -15,
          0, 0, 0, 1, 0,
        ]);
        break;

      case PhotoFilterPreset.coolMist:
        matrix = _multiplyMatrices(matrix, [
          0.85, 0.0, 0.1, 0, -10,
          0.0, 1.0, 0.1, 0, 5,
          0.1, 0.1, 1.3, 0, 20,
          0, 0, 0, 1, 0,
        ]);
        break;

      case PhotoFilterPreset.none:
        break;
    }

    return ColorFilter.matrix(matrix);
  }

  static List<double> _multiplyMatrices(List<double> a, List<double> b) {
    final List<double> result = List.filled(20, 0.0);
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 5; col++) {
        double sum = 0.0;
        for (int k = 0; k < 4; k++) {
          sum += a[row * 5 + k] * b[k * 5 + col];
        }
        if (col == 4) {
          sum += a[row * 5 + 4]; // add translation term
        }
        result[row * 5 + col] = sum;
      }
    }
    return result;
  }
}
