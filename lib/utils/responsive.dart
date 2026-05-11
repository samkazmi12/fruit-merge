import 'package:flutter/material.dart';

/// Responsive sizing extension on BuildContext.
///
/// Design baseline: 390px wide (iPhone 14 / Pixel 8).
/// Scale factor is clamped so small phones (≥ 320px) and tablets (≤ 507px)
/// stay within a readable range without distorting the layout.
///
/// Usage:
///   context.s(44)   → scaled widget size / padding / radius / gap
///   context.sp(16)  → scaled font size
extension Responsive on BuildContext {
  double get _sf =>
      (MediaQuery.sizeOf(this).width / 390).clamp(0.75, 1.35);

  double s(double v) => v * _sf;
  double sp(double v) => v * _sf;
}
