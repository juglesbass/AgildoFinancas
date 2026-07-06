import 'package:flutter/material.dart';
import 'dart:ui'; // Para o Blur

class SummaryCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color corValor;
  final double height;

  const SummaryCard({
    super.key,
    required this.titulo,
    required this.valor,
    this.corValor = Colors.white,
    this.height = 76,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06), // Fundo translúcido
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                titulo,
                style: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB), letterSpacing: 0.3),
              ),
              const SizedBox(height: 4),
              Text(
                valor,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: corValor),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}