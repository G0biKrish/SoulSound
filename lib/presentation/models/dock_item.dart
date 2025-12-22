import 'package:flutter/material.dart';

class DockItem {
  final int originalIndex;
  final IconData icon;
  final String label;

  const DockItem({
    required this.originalIndex,
    required this.icon,
    required this.label,
  });
}

