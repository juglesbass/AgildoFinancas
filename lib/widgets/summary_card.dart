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
    // Se a cor do valor não for passada, usa branco por padrão no modo escuro
    this.corValor = Colors.white, 
    this.height = 74,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937), // Fundo escuro (Dark Mode)
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF374151)), // Borda escura
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)), // Texto secundário claro
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: corValor, // Mantém o verde/vermelho/amarelo
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}