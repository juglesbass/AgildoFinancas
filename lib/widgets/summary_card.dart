import 'package:flutter/material.dart';

/// Equivalente ao componente `SummaryCard` do Main.qml.
class SummaryCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color corValor;
  final double height;

  const SummaryCard({
    super.key,
    required this.titulo,
    required this.valor,
    this.corValor = const Color(0xFF111827),
    this.height = 74,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: corValor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
