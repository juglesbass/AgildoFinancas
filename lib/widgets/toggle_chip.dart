import 'package:flutter/material.dart';
import 'dart:ui'; // Para o Blur

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            height: 44, // Mais alto para o texto respirar
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selecionado ? corAtiva : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selecionado ? corAtiva : Colors.white.withOpacity(0.12),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selecionado ? Colors.white : const Color(0xFFD1D5DB),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.3, // Evita serrilhados
              ),
            ),
          ),
        ),
      ),
    );
  }
}