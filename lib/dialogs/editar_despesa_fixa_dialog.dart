import 'package:flutter/material.dart';

import '../database_helper.dart';
import '../models.dart';
import '../utils/formatters.dart';
import '../widgets/app_button.dart';

/// Equivalente ao `popupEditarFixa` do Main.qml.
Future<void> mostrarDialogoEditarDespesaFixa(
  BuildContext context, {
  required DespesaFixa fixa,
  required VoidCallback aoSalvar,
}) {
  final campoDescricao = TextEditingController(text: fixa.descricao);
  final campoValor = TextEditingController(
      text: fixa.valorPrevisto.toString().replaceAll('.', ','));
  final categoriaInicial =
      categoriasDespesa.contains(fixa.categoria) ? fixa.categoria : categoriasDespesa.first;
  final ValueNotifier<String> categoriaSelecionada =
      ValueNotifier<String>(categoriaInicial);
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
                    'Editar despesa fixa',
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
                  ValueListenableBuilder<String>(
                    valueListenable: categoriaSelecionada,
                    builder: (context, valor, _) {
                      return DropdownButtonFormField<String>(
                        value: valor,
                        isExpanded: true,
                        items: categoriasDespesa
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (novo) {
                          if (novo != null) categoriaSelecionada.value = novo;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: campoValor,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Valor previsto (R\$)'),
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
                          corBase: const Color(0xFF0EA5A4),
                          onPressed: () async {
                            final valor = parseValorCampo(campoValor.text);
                            if (valor == null ||
                                valor <= 0 ||
                                campoDescricao.text.trim().isEmpty) {
                              erro.value =
                                  'Preencha a descrição e um valor válido.';
                              return;
                            }
                            final ok = await DatabaseHelper.instance
                                .editarDespesaFixa(
                              fixa.id,
                              campoDescricao.text,
                              categoriaSelecionada.value,
                              valor,
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
