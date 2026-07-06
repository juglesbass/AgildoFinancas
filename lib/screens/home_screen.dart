import 'package:flutter/material.dart';
import 'dart:ui'; // Necessário para o efeito de Blur (Glassmorphism)

import '../database_helper.dart';
import '../dialogs/despesas_fixas_dialog.dart';
import '../dialogs/editar_lancamento_dialog.dart';
import '../models.dart';
import '../utils/formatters.dart';
import '../widgets/app_button.dart';
import '../widgets/summary_card.dart';
import '../widgets/toggle_chip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper.instance;

  String _modoAtual = 'despesa';
  String _tipoReserva = 'deposito';
  Resumo _resumo = const Resumo();
  List<Lancamento> _lista = [];
  List<Divida> _dividas = [];
  String _categoriaDespesa = categoriasDespesa.first;
  String _categoriaDivida = categoriasDivida.first;

  final _campoDescricao = TextEditingController();
  final _campoValor = TextEditingController();
  final _campoParcelas = TextEditingController();

  String? _avisoValidacao;
  bool _carregando = true;
  final String _mesAtual = mesAtualISO();

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  @override
  void dispose() {
    _campoDescricao.dispose();
    _campoValor.dispose();
    _campoParcelas.dispose();
    super.dispose();
  }

  Future<void> _carregarTudo() async {
    final resumo = await _db.obterResumo();
    final lista = await _db.listarLancamentos();
    final dividas = await _db.listarDividas();
    if (!mounted) return;
    setState(() {
      _resumo = resumo;
      _lista = lista;
      _dividas = dividas;
      _carregando = false;
    });
  }

  Future<void> _atualizarResumo() async {
    final resumo = await _db.obterResumo();
    if (!mounted) return;
    setState(() => _resumo = resumo);
  }

  Future<void> _atualizarLista() async {
    final lista = await _db.listarLancamentos();
    if (!mounted) return;
    setState(() => _lista = lista);
  }

  Future<void> _atualizarDividas() async {
    final dividas = await _db.listarDividas();
    if (!mounted) return;
    setState(() => _dividas = dividas);
  }

  void _limparFormulario() {
    _campoDescricao.clear();
    _campoValor.clear();
    _campoParcelas.clear();
    setState(() => _avisoValidacao = null);
  }

  void _selecionarModo(String modo) {
    setState(() {
      _modoAtual = modo;
      _avisoValidacao = null;
    });
  }

  Future<void> _salvar() async {
    final valor = parseValorCampo(_campoValor.text);
    if (valor == null || valor <= 0 || _campoDescricao.text.trim().isEmpty) {
      setState(() => _avisoValidacao = 'Preencha a descrição e um valor válido.');
      return;
    }

    bool ok = false;
    switch (_modoAtual) {
      case 'receita':
        ok = await _db.adicionarReceita(_campoDescricao.text, valor, hojeISO());
        break;
      case 'despesa':
        ok = await _db.adicionarDespesa(_campoDescricao.text, _categoriaDespesa, valor, hojeISO());
        break;
      case 'reserva':
        ok = await _db.adicionarMovimentoReserva(_campoDescricao.text, valor, hojeISO(), _tipoReserva);
        break;
      case 'divida':
        final parcelas = int.tryParse(_campoParcelas.text.trim());
        if (parcelas == null || parcelas <= 0) {
          setState(() => _avisoValidacao = 'Informe a quantidade de parcelas.');
          return;
        }
        ok = await _db.adicionarDivida(_campoDescricao.text, _categoriaDivida, valor, parcelas, hojeISO());
        break;
    }

    if (ok) {
      _limparFormulario();
      await _atualizarResumo();
      await _atualizarLista();
      await _atualizarDividas();
    } else {
      setState(() => _avisoValidacao = 'Não foi possível salvar.');
    }
  }

  void _abrirDespesasFixas() {
    showDialog(
      context: context,
      builder: (_) => DespesasFixasDialog(
        mesAtual: _mesAtual,
        aoAtualizarPrincipal: () {
          _atualizarResumo();
          _atualizarLista();
        },
      ),
    );
  }

  void _abrirResumoCartoes() {
    Map<String, double> totaisPorCartao = {};
    for (var d in _dividas) {
      if (!d.quitada) {
        String cartao = (d.categoria != null && d.categoria!.isNotEmpty) ? d.categoria! : 'Outros';
        totaisPorCartao[cartao] = (totaisPorCartao[cartao] ?? 0) + d.valorRestante;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111827).withOpacity(0.7),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2))),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.credit_card, color: Colors.white, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Resumo das Faturas',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (totaisPorCartao.isEmpty)
                        const Text('Nenhuma dívida de cartão ativa.', style: TextStyle(color: Color(0xFF9CA3AF)))
                      else
                        ...totaisPorCartao.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key, style: const TextStyle(fontSize: 16, color: Color(0xFFE5E7EB))),
                              Text(
                                formatarMoeda(e.value),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                              ),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  // --- WIDGET DE GLASSMORPHISM (BLUR VIVO E BONITO) ---
  Widget _glassContainer({required Widget child, EdgeInsetsGeometry? padding, EdgeInsetsGeometry? margin, double? height}) {
    return Container(
      margin: margin,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06), // Fundo quase transparente
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.12)), // Borda de vidro
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Deixa o fundo do MaterialApp aparecer
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Gradiente de fundo super elegante para destacar o Blur
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)], 
          ),
        ),
        child: SafeArea(
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _carregarTudo,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '💰 Agildo Finanças',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        AppButton(
                          label: '📋 Gerenciar despesas fixas do mês',
                          corBase: const Color(0xFF0EA5A4),
                          onPressed: _abrirDespesasFixas,
                        ),
                        const SizedBox(height: 14),
                        _resumoGrid(),
                        const SizedBox(height: 10),
                        const Text(
                          '🔒 Comprometido/mês e dívida restante ainda não saíram do saldo.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(height: 14),
                        _seletorModo(),
                        const SizedBox(height: 14),
                        _formulario(),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Minhas dívidas',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            GestureDetector(
                              onTap: _abrirResumoCartoes,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.credit_card, size: 14, color: Color(0xFFD1D5DB)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Ver cartões',
                                      style: TextStyle(fontSize: 13, color: Color(0xFFD1D5DB), fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _secaoDividas(),
                        const SizedBox(height: 24),
                        const Text(
                          'Histórico',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        _secaoHistorico(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _resumoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: SummaryCard(titulo: 'Saldo disponível', valor: formatarMoeda(_resumo.saldoDisponivel), corValor: _resumo.saldoDisponivel >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
            const SizedBox(width: 10),
            Expanded(child: SummaryCard(titulo: 'Dívida restante', valor: formatarMoeda(_resumo.dividaTotalRestante), corValor: const Color(0xFFF59E0B))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: SummaryCard(titulo: 'Receitas', valor: formatarMoeda(_resumo.totalReceitas), corValor: const Color(0xFF16A34A))),
            const SizedBox(width: 10),
            Expanded(child: SummaryCard(titulo: 'Total despesas', valor: formatarMoeda(_resumo.totalDespesas), corValor: const Color(0xFFDC2626))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: SummaryCard(titulo: 'Reserva', valor: formatarMoeda(_resumo.totalReserva), corValor: const Color(0xFF3B82F6))),
            const SizedBox(width: 10),
            Expanded(child: SummaryCard(titulo: 'Comprometido', valor: formatarMoeda(_resumo.comprometidoMensal), corValor: const Color(0xFF8B5CF6))),
          ],
        ),
      ],
    );
  }

  Widget _seletorModo() {
    Widget linha(String labelA, String modoA, Color corA, String labelB, String modoB, Color corB) {
      return Row(
        children: [
          Expanded(child: ToggleChip(label: labelA, corAtiva: corA, selecionado: _modoAtual == modoA, onTap: () => _selecionarModo(modoA))),
          const SizedBox(width: 10),
          Expanded(child: ToggleChip(label: labelB, corAtiva: corB, selecionado: _modoAtual == modoB, onTap: () => _selecionarModo(modoB))),
        ],
      );
    }
    return Column(
      children: [
        linha('Receita', 'receita', const Color(0xFF16A34A), 'Despesa', 'despesa', const Color(0xFFDC2626)),
        const SizedBox(height: 10),
        linha('Reserva', 'reserva', const Color(0xFF3B82F6), 'Dívida', 'divida', const Color(0xFF8B5CF6)),
      ],
    );
  }

  String get _placeholderDescricao {
    switch (_modoAtual) {
      case 'receita': return 'Ex: Salário';
      case 'despesa': return 'Ex: Supermercado';
      case 'reserva': return 'Ex: Conserto do carro';
      default: return 'Ex: Notebook parcelado';
    }
  }

  String get _labelBotaoSalvar {
    switch (_modoAtual) {
      case 'receita': return 'Adicionar receita';
      case 'despesa': return 'Adicionar despesa';
      case 'reserva': return _tipoReserva == 'deposito' ? 'Depositar na reserva' : 'Sacar da reserva';
      default: return 'Registrar dívida';
    }
  }

  Color get _corBotaoSalvar {
    switch (_modoAtual) {
      case 'receita': return const Color(0xFF16A34A);
      case 'despesa': return const Color(0xFFDC2626);
      case 'reserva': return const Color(0xFF3B82F6);
      default: return const Color(0xFF8B5CF6);
    }
  }

  Widget _formulario() {
    return _glassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: _campoDescricao, decoration: InputDecoration(hintText: _placeholderDescricao)),
          const SizedBox(height: 12),
          if (_modoAtual == 'despesa') ...[
            Row(
              children: [
                const Text('Categoria:', style: TextStyle(color: Color(0xFFD1D5DB))),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _categoriaDespesa,
                    isExpanded: true,
                    items: categoriasDespesa.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _categoriaDespesa = v ?? _categoriaDespesa),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_modoAtual == 'reserva') ...[
            Row(
              children: [
                Expanded(child: ToggleChip(label: 'Depositar', corAtiva: const Color(0xFF3B82F6), selecionado: _tipoReserva == 'deposito', onTap: () => setState(() => _tipoReserva = 'deposito'))),
                const SizedBox(width: 10),
                Expanded(child: ToggleChip(label: 'Sacar', corAtiva: const Color(0xFFDC2626), selecionado: _tipoReserva == 'saque', onTap: () => setState(() => _tipoReserva = 'saque'))),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_modoAtual == 'divida') ...[
            Row(
              children: [
                const Text('Cartão:', style: TextStyle(color: Color(0xFFD1D5DB))),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _categoriaDivida,
                    isExpanded: true,
                    items: categoriasDivida.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _categoriaDivida = v ?? _categoriaDivida),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _campoValor,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(hintText: _modoAtual == 'divida' ? 'Valor de cada parcela (R\$)' : 'Valor (R\$)' ),
          ),
          if (_modoAtual == 'divida') ...[
            const SizedBox(height: 12),
            TextField(controller: _campoParcelas, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Quantidade de parcelas')),
          ],
          if (_avisoValidacao != null) ...[
            const SizedBox(height: 10),
            Text(_avisoValidacao!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 16),
          AppButton(label: _labelBotaoSalvar, corBase: _corBotaoSalvar, onPressed: _salvar),
        ],
      ),
    );
  }

  Widget _secaoDividas() {
    if (_dividas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Nenhuma dívida ativa no momento.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
      );
    }
    return Column(children: _dividas.map(_tileDivida).toList());
  }

  Widget _tileDivida(Divida d) {
    return _glassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.descricao,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // TEXTO AUMENTADO E CLARO PARA EVITAR SERRILHADO
                    Text(
                      '${d.categoria != null ? '${d.categoria} · ' : ''}${d.parcelasPagas}/${d.totalParcelas} parcelas pagas',
                      style: const TextStyle(fontSize: 13, color: Color(0xFFE5E7EB), letterSpacing: 0.3),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await _db.removerDivida(d.id);
                  await _atualizarDividas();
                  await _atualizarResumo();
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: d.progresso.clamp(0.0, 1.0).toDouble(),
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(d.quitada ? const Color(0xFF16A34A) : const Color(0xFF8B5CF6)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Restante: ${formatarMoeda(d.valorRestante)}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFFD1D5DB)),
                ),
              ),
              if (!d.quitada)
                SizedBox(
                  height: 44, // ALTURA MAIOR PARA NÃO CORTAR O BOTÃO
                  width: 150,
                  child: AppButton(
                    label: 'Pagar parcela',
                    corBase: const Color(0xFF8B5CF6),
                    height: 44,
                    onPressed: () async {
                      await _db.pagarParcela(d.id, hojeISO());
                      await _atualizarDividas();
                      await _atualizarResumo();
                      await _atualizarLista();
                    },
                  ),
                )
              else
                const Text('Quitada ✓', style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _secaoHistorico() {
    if (_lista.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Nenhum lançamento no histórico.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
      );
    }
    return Column(children: _lista.map(_tileLancamento).toList());
  }

  Color _corLateral(String tipo) {
    switch (tipo) {
      case 'receita': return const Color(0xFF4ADE80);
      case 'despesa': return const Color(0xFFF87171);
      case 'reserva_deposito': return const Color(0xFF60A5FA);
      default: return const Color(0xFFFBBF24);
    }
  }

  Widget _tileLancamento(Lancamento l) {
    final cor = _corLateral(l.tipo);
    final sinal = (l.tipo == 'despesa' || l.tipo == 'reserva_saque') ? '- ' : '+ ';
    final valorTexto = sinal + formatarMoeda(l.valor).replaceAll('R\$ ', '');

    return _glassContainer(
      margin: const EdgeInsets.only(bottom: 10),
      height: 64,
      child: Row(
        children: [
          Container(width: 5, decoration: BoxDecoration(color: cor)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l.descricao, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(l.data, style: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB))),
                      ],
                    ),
                  ),
                  Text(valorTexto, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: cor)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async { await _db.removerLancamento(l.id); await _atualizarResumo(); await _atualizarLista(); },
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}