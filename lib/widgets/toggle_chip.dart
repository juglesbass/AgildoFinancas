import 'package:flutter/material.dart';

/// Equivalente ao componente `ToggleChip` do Main.qml.
class ToggleChip extends StatelessWidget {
  final String label;
  final bool selecionado;
  final Color corAtiva;
  final VoidCallback onTap;

  const ToggleChip({
    super.key,
    required this.label,
    required this.selecionado,
    required this.onTap,
    this.corAtiva = const Color(0xFF3B82F6),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selecionado ? corAtiva : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selecionado ? Colors.white : const Color(0xFF374151),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
