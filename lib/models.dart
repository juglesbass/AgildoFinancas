/// Modelos de dados usados pelo app.
/// Equivalem diretamente aos QVariantMap retornados pelo DatabaseManager em C++.

class Lancamento {
  final int id;
  final String tipo; // receita | despesa | reserva_deposito | reserva_saque
  final String? categoria;
  final String descricao;
  final double valor;
  final String data;

  Lancamento({
    required this.id,
    required this.tipo,
    this.categoria,
    required this.descricao,
    required this.valor,
    required this.data,
  });

  factory Lancamento.fromMap(Map<String, dynamic> map) {
    return Lancamento(
      id: map['id'] as int,
      tipo: map['tipo'] as String,
      categoria: map['categoria'] as String?,
      descricao: map['descricao'] as String,
      valor: (map['valor'] as num).toDouble(),
      data: map['data'] as String? ?? '',
    );
  }
}

class Divida {
  final int id;
  final String descricao;
  final String? categoria;
  final double valorParcela;
  final int totalParcelas;
  final int parcelasPagas;
  final String data;

  Divida({
    required this.id,
    required this.descricao,
    this.categoria,
    required this.valorParcela,
    required this.totalParcelas,
    required this.parcelasPagas,
    required this.data,
  });

  double get valorRestante => valorParcela * (totalParcelas - parcelasPagas);
  bool get quitada => parcelasPagas >= totalParcelas;
  double get progresso => totalParcelas > 0 ? parcelasPagas / totalParcelas : 0;

  factory Divida.fromMap(Map<String, dynamic> map) {
    return Divida(
      id: map['id'] as int,
      descricao: map['descricao'] as String,
      categoria: map['categoria'] as String?,
      valorParcela: (map['valorParcela'] as num).toDouble(),
      totalParcelas: map['totalParcelas'] as int,
      parcelasPagas: map['parcelasPagas'] as int,
      data: map['data'] as String? ?? '',
    );
  }
}

class DespesaFixa {
  final int id;
  final String descricao;
  final String categoria;
  final double valorPrevisto;
  final double valorGasto;

  DespesaFixa({
    required this.id,
    required this.descricao,
    required this.categoria,
    required this.valorPrevisto,
    required this.valorGasto,
  });

  bool get pago => valorGasto >= valorPrevisto;

  factory DespesaFixa.fromMap(Map<String, dynamic> map) {
    return DespesaFixa(
      id: map['id'] as int,
      descricao: map['descricao'] as String,
      categoria: map['categoria'] as String,
      valorPrevisto: (map['valorPrevisto'] as num).toDouble(),
      valorGasto: (map['valorGasto'] as num).toDouble(),
    );
  }
}

class Resumo {
  final double totalReceitas;
  final double totalDespesas;
  final double totalReserva;
  final double saldoTotal;
  final double saldoDisponivel;
  final double comprometidoMensal;
  final double dividaTotalRestante;

  const Resumo({
    this.totalReceitas = 0,
    this.totalDespesas = 0,
    this.totalReserva = 0,
    this.saldoTotal = 0,
    this.saldoDisponivel = 0,
    this.comprometidoMensal = 0,
    this.dividaTotalRestante = 0,
  });
}

/// Categorias fixas usadas nos formulários (idênticas ao Main.qml original).
const List<String> categoriasDespesa = [
  'Alimentação',
  'Moradia',
  'Água',
  'Internet',
  'Transporte',
  'Cabelo',
  'Saúde',
  'Educação',
  'Lazer',
  'Dízimo',
  'Dízimos Colheita',
  'Missões',
  'Igreja',
  'Outros',
];

const List<String> categoriasDivida = [
  'Cartão Nubank',
  'Cartão Inter',
  'Cartão Neon',
  'Cartão Mercado Pago',
  'Financiamento',
  'Empréstimo',
  'Outros',
];
