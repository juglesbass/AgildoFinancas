import 'package:flutter/material.dart';

/// Equivalente ao componente `AppButton` do Main.qml.
class AppButton extends StatelessWidget {
  final String label;
  final Color corBase;
  final VoidCallback? onPressed;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.corBase = const Color(0xFF3B82F6),
    this.height = 46,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: corBase,
          foregroundColor: Colors.white, // Letra sempre branca
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}