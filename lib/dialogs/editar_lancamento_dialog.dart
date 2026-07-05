import 'package:flutter/material.dart';

import '../database_helper.dart';
import '../models.dart';
import '../utils/formatters.dart';
import '../widgets/app_button.dart';

/// Equivalente ao `popupEditar` do Main.qml.
Future<void> mostrarDialogoEditarLancamento(
  BuildContext context, {
  required Lancamento lancamento,
  required VoidCallback aoSalvar,
}) {
  final campoDescricao = TextEditingController(text: lancamento.descricao);
  final campoValor =
      TextEditingController(text: lancamento.valor.toString().replaceAll('.', ','));
  final ValueNotifier<String?> erro = ValueNotifier<String?>(null);

  return showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ValueListenableBuilder<String?>(
            valueListenable: erro,
            builder: (context, mensagemErro, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Editar lançamento',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: campoDescricao,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: campoValor,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                  ),
                  if (mensagemErro != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      mensagemErro,
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Cancelar',
                          corBase: const Color(0xFF9CA3AF),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          label: 'Salvar',
                          corBase: const Color(0xFF3B82F6),
                          onPressed: () async {
                            final novoValor = parseValorCampo(campoValor.text);
                            if (novoValor == null ||
                                novoValor <= 0 ||
                                campoDescricao.text.trim().isEmpty) {
                              erro.value =
                                  'Informe um valor válido maior que zero.';
                              return;
                            }
                            final ok = await DatabaseHelper.instance
                                .editarLancamento(
                              lancamento.id,
                              campoDescricao.text,
                              novoValor,
                            );
                            if (ok) {
                              aoSalvar();
                              if (context.mounted) Navigator.of(context).pop();
                            } else {
                              erro.value = 'Não foi possível salvar.';
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
