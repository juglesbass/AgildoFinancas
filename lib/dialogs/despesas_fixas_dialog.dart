import 'package:flutter/material.dart';

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: SizedBox(
        width: tamanhoTela.width - 32,
        height: (tamanhoTela.height - 64).clamp(0, 680).toDouble(),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
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
                    style: TextStyle(color: Color(0xFF9CA3AF)),
                  ),
                ),
              if (!_carregando && _fixas.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Dica: toda despesa lançada na tela inicial soma '
                    'automaticamente aqui pela categoria (ex: várias despesas '
                    'em "Alimentação" somam até completar o previsto de Comida).',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                  ),
                ),
              Expanded(
                child: _carregando
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          for (final fixa in _fixas) _tileFixa(fixa),
                          const SizedBox(height: 8),
                          _cardTotais(),
                          const SizedBox(height: 8),
                          _formNovaFixa(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tileFixa(DespesaFixa fixa) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: fixa.pago ? const Color(0xFF16A34A) : const Color(0xFFE5E7EB),
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
                    : const Color(0xFFE5E7EB),
              ),
              child: fixa.pago
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fixa.descricao,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${fixa.categoria} · ${formatarMoeda(fixa.valorGasto)} de '
                  '${formatarMoeda(fixa.valorPrevisto)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            formatarMoeda(fixa.valorPrevisto),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: fixa.pago ? const Color(0xFF16A34A) : const Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 6),
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
          const SizedBox(width: 4),
          _BotaoCircular(
            icone: Icons.close,
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
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
                  style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                ),
              ),
              Text(
                'Pago: ${formatarMoeda(_totalPago)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Falta pagar: ${formatarMoeda(_totalFalta)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formNovaFixa() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Adicionar despesa fixa',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _campoDescricao,
            decoration: const InputDecoration(
              hintText: 'Ex: Dízimo, Internet, Água...',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          TextField(
            controller: _campoValor,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Valor previsto (R\$)',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
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
    this.tamanhoIcone = 14,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFF3F4F6),
        ),
        child: Icon(icone, size: tamanhoIcone, color: const Color(0xFF9CA3AF)),
      ),
    );
  }
}
