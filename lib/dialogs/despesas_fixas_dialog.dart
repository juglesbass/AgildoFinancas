import 'package:flutter/material.dart';
import 'dart:ui'; // Para o efeito de Blur (Glassmorphism)

import '../database_helper.dart';
import '../models.dart';
import '../utils/formatters.dart';
import '../widgets/app_button.dart';
import 'editar_despesa_fixa_dialog.dart';

/// Equivalente ao `popupFixas` do Main.qml: gerenciamento de despesas fixas
/// do mês, com marcação de pago/não pago e cadastro de novas despesas fixas.
class DespesasFixasDialog extends StatefulWidget {
  final String mesAtual;

  /// Chamado sempre que algo muda aqui dentro e a tela principal (resumo e
  /// histórico) precisa ser recarregada.
  final VoidCallback aoAtualizarPrincipal;

  const DespesasFixasDialog({
    super.key,
    required this.mesAtual,
    required this.aoAtualizarPrincipal,
  });

  @override
  State<DespesasFixasDialog> createState() => _DespesasFixasDialogState();
}

class _DespesasFixasDialogState extends State<DespesasFixasDialog> {
  final _db = DatabaseHelper.instance;
  List<DespesaFixa> _fixas = [];
  bool _carregando = true;

  final _campoDescricao = TextEditingController();
  String _categoriaNova = categoriasDespesa.first;
  final _campoValor = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _campoDescricao.dispose();
    _campoValor.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final fixas = await _db.listarDespesasFixas(widget.mesAtual);
    if (!mounted) return;
    setState(() {
      _fixas = fixas;
      _carregando = false;
    });
  }

  double get _totalPrevisto =>
      _fixas.fold(0.0, (soma, f) => soma + f.valorPrevisto);
  double get _totalPago => _fixas.fold(0.0, (soma, f) => soma + f.valorGasto);
  double get _totalFalta => _totalPrevisto - _totalPago;

  Future<void> _alternarPago(DespesaFixa fixa) async {
    if (fixa.pago) {
      await _db.desmarcarDespesaFixaPaga(fixa.id, widget.mesAtual);
    } else {
      var falta = fixa.valorPrevisto - fixa.valorGasto;
      if (falta <= 0) falta = fixa.valorPrevisto;
      await _db.marcarDespesaFixaPaga(fixa.id, widget.mesAtual, falta, hojeISO());
    }
    await _carregar();
    widget.aoAtualizarPrincipal();
  }

  Future<void> _adicionar() async {
    final valor = parseValorCampo(_campoValor.text);
    if (valor == null || valor <= 0 || _campoDescricao.text.trim().isEmpty) {
      return;
    }
    final ok = await _db.adicionarDespesaFixa(
        _campoDescricao.text, _categoriaNova, valor);
    if (ok) {
      _campoDescricao.clear();
      _campoValor.clear();
      await _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tamanhoTela = MediaQuery.of(context).size;
    
    return Dialog(
      backgroundColor: Colors.transparent, // Remove o fundo cinza padrão do Flutter
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Efeito de vidro
          child: Container(
            width: tamanhoTela.width - 32,
            height: (tamanhoTela.height - 64).clamp(0, 680).toDouble(),
            decoration: BoxDecoration(
              color: const Color(0xFF111827).withOpacity(0.7), // Fundo translúcido escuro
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)), // Borda brilhante
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Despesas fixas · ${widget.mesAtual}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Letra clara
                          ),
                        ),
                      ),
                      _BotaoCircular(
                        icone: Icons.close,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (!_carregando && _fixas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhuma despesa fixa cadastrada ainda. Adicione abaixo '
                        '(ex: Dízimo, Internet, Água...).',
                        style: TextStyle(color: Color(0xFF9CA3AF)), // Cinza elegante
                      ),
                    ),
                  if (!_carregando && _fixas.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Dica: toda despesa lançada na tela inicial soma '
                        'automaticamente aqui pela categoria.',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                      ),
                    ),
                  Expanded(
                    child: _carregando
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
                            children: [
                              for (final fixa in _fixas) _tileFixa(fixa),
                              const SizedBox(height: 12),
                              _cardTotais(),
                              const SizedBox(height: 12),
                              _formNovaFixa(),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tileFixa(DespesaFixa fixa) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06), // Fundo de vidro
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: fixa.pago ? const Color(0xFF16A34A) : Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _alternarPago(fixa),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fixa.pago
                    ? const Color(0xFF16A34A)
                    : Colors.white.withOpacity(0.1),
              ),
              child: fixa.pago
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fixa.descricao,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${fixa.categoria} · ${formatarMoeda(fixa.valorGasto)} de '
                  '${formatarMoeda(fixa.valorPrevisto)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFD1D5DB)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            formatarMoeda(fixa.valorPrevisto),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: fixa.pago ? const Color(0xFF4ADE80) : Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          _BotaoCircular(
            icone: Icons.edit,
            tamanhoIcone: 12,
            onTap: () {
              mostrarDialogoEditarDespesaFixa(
                context,
                fixa: fixa,
                aoSalvar: () {
                  _carregar();
                  widget.aoAtualizarPrincipal();
                },
              );
            },
          ),
          const SizedBox(width: 6),
          _BotaoCircular(
            icone: Icons.close,
            tamanhoIcone: 12,
            onTap: () async {
              await _db.removerDespesaFixa(fixa.id);
              await _carregar();
            },
          ),
        ],
      ),
    );
  }

  Widget _cardTotais() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06), // Fundo de vidro
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Previsto: ${formatarMoeda(_totalPrevisto)}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
                ),
              ),
              Text(
                'Pago: ${formatarMoeda(_totalPago)}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF4ADE80)), // Verde vivo
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Falta pagar: ${formatarMoeda(_totalFalta)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF87171), // Vermelho vivo
            ),
          ),
        ],
      ),
    );
  }

  Widget _formNovaFixa() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06), // Fundo de vidro
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Adicionar despesa fixa',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _campoDescricao,
            decoration: const InputDecoration(
              hintText: 'Ex: Dízimo, Internet, Água...',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _categoriaNova,
            isExpanded: true,
            items: categoriasDespesa
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (novo) {
              if (novo != null) setState(() => _categoriaNova = novo);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _campoValor,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Valor previsto (R\$)',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Adicionar',
            corBase: const Color(0xFF0EA5A4),
            onPressed: _adicionar,
          ),
        ],
      ),
    );
  }
}

class _BotaoCircular extends StatelessWidget {
  final IconData icone;
  final VoidCallback onTap;
  final double tamanhoIcone;

  const _BotaoCircular({
    required this.icone,
    required this.onTap,
    this.tamanhoIcone = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15), // Botão de vidro
        ),
        child: Icon(icone, size: tamanhoIcone, color: Colors.white), // Ícone branco
      ),
    );
  }
}