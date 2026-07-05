import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// Porte direto de DatabaseManager (C++/Qt) para Dart usando sqflite.
/// Mesmo schema, mesmas tabelas, mesmos nomes de método (traduzidos para
/// convenção Dart camelCase, que já era usada no original).
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _inicializarBanco();
    return _database!;
  }

  Future<Database> _inicializarBanco() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'financas.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS lancamentos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tipo TEXT NOT NULL,
            categoria TEXT,
            descricao TEXT,
            valor REAL NOT NULL,
            data TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS dividas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            descricao TEXT,
            categoria TEXT,
            valorParcela REAL NOT NULL,
            totalParcelas INTEGER NOT NULL,
            parcelasPagas INTEGER NOT NULL DEFAULT 0,
            data TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS despesas_fixas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            descricao TEXT,
            categoria TEXT,
            valorPrevisto REAL NOT NULL
          )
        ''');
      },
    );
  }

  // ==========================================================
  //  Lançamentos (receitas, despesas, reserva)
  // ==========================================================

  Future<bool> adicionarReceita(
      String descricao, double valor, String data) async {
    final db = await database;
    final id = await db.insert('lancamentos', {
      'tipo': 'receita',
      'categoria': null,
      'descricao': descricao,
      'valor': valor,
      'data': data,
    });
    return id > 0;
  }

  Future<bool> adicionarDespesa(
      String descricao, String categoria, double valor, String data) async {
    final db = await database;
    final id = await db.insert('lancamentos', {
      'tipo': 'despesa',
      'categoria': categoria,
      'descricao': descricao,
      'valor': valor,
      'data': data,
    });
    return id > 0;
  }

  Future<bool> adicionarMovimentoReserva(String descricao, double valor,
      String data, String tipoMovimento) async {
    final tipoInterno =
        tipoMovimento == 'saque' ? 'reserva_saque' : 'reserva_deposito';
    final db = await database;
    final id = await db.insert('lancamentos', {
      'tipo': tipoInterno,
      'categoria': null,
      'descricao': descricao,
      'valor': valor,
      'data': data,
    });
    return id > 0;
  }

  Future<bool> removerLancamento(int id) async {
    final db = await database;
    final linhas =
        await db.delete('lancamentos', where: 'id = ?', whereArgs: [id]);
    return linhas > 0;
  }

  Future<bool> editarLancamento(int id, String descricao, double valor) async {
    final db = await database;
    final linhas = await db.update(
      'lancamentos',
      {'descricao': descricao, 'valor': valor},
      where: 'id = ?',
      whereArgs: [id],
    );
    return linhas > 0;
  }

  Future<List<Lancamento>> listarLancamentos({int limite = -1}) async {
    final db = await database;
    final rows = await db.query(
      'lancamentos',
      orderBy: 'id DESC',
      limit: limite > 0 ? limite : null,
    );
    return rows.map((r) => Lancamento.fromMap(r)).toList();
  }

  Future<Resumo> obterResumo() async {
    final db = await database;

    double totalReceitas = 0, totalDespesas = 0, totalReserva = 0;
    final somaPorTipo = await db
        .rawQuery('SELECT tipo, SUM(valor) as soma FROM lancamentos GROUP BY tipo');
    for (final row in somaPorTipo) {
      final tipo = row['tipo'] as String;
      final soma = (row['soma'] as num?)?.toDouble() ?? 0;
      if (tipo == 'receita') {
        totalReceitas = soma;
      } else if (tipo == 'despesa') {
        totalDespesas = soma;
      } else if (tipo == 'reserva_deposito') {
        totalReserva += soma;
      } else if (tipo == 'reserva_saque') {
        totalReserva -= soma;
      }
    }

    final saldoTotal = totalReceitas - totalDespesas;
    final saldoDisponivel = saldoTotal - totalReserva;

    double comprometidoMensal = 0, dividaTotalRestante = 0;
    final dividas = await db
        .rawQuery('SELECT valorParcela, totalParcelas, parcelasPagas FROM dividas');
    for (final row in dividas) {
      final valorParcela = (row['valorParcela'] as num).toDouble();
      final totalParcelas = row['totalParcelas'] as int;
      final parcelasPagas = row['parcelasPagas'] as int;
      final parcelasRestantes = totalParcelas - parcelasPagas;
      if (parcelasRestantes > 0) {
        comprometidoMensal += valorParcela;
        dividaTotalRestante += valorParcela * parcelasRestantes;
      }
    }

    return Resumo(
      totalReceitas: totalReceitas,
      totalDespesas: totalDespesas,
      totalReserva: totalReserva,
      saldoTotal: saldoTotal,
      saldoDisponivel: saldoDisponivel,
      comprometidoMensal: comprometidoMensal,
      dividaTotalRestante: dividaTotalRestante,
    );
  }

  // ==========================================================
  //  Dívidas / parcelamentos
  // ==========================================================

  Future<bool> adicionarDivida(String descricao, String categoria,
      double valorParcela, int totalParcelas, String data) async {
    final db = await database;
    final id = await db.insert('dividas', {
      'descricao': descricao,
      'categoria': categoria,
      'valorParcela': valorParcela,
      'totalParcelas': totalParcelas,
      'parcelasPagas': 0,
      'data': data,
    });
    return id > 0;
  }

  Future<bool> removerDivida(int id) async {
    final db = await database;
    final linhas = await db.delete('dividas', where: 'id = ?', whereArgs: [id]);
    return linhas > 0;
  }

  Future<bool> pagarParcela(int id, String data) async {
    final db = await database;
    final busca = await db.query('dividas', where: 'id = ?', whereArgs: [id]);
    if (busca.isEmpty) return false;

    final row = busca.first;
    final descricao = row['descricao'] as String;
    final categoria = row['categoria'] as String? ?? '';
    final valorParcela = (row['valorParcela'] as num).toDouble();
    final totalParcelas = row['totalParcelas'] as int;
    final parcelasPagas = row['parcelasPagas'] as int;

    if (parcelasPagas >= totalParcelas) return false;

    final atualizadas = await db.rawUpdate(
      'UPDATE dividas SET parcelasPagas = parcelasPagas + 1 WHERE id = ?',
      [id],
    );
    if (atualizadas == 0) return false;

    return adicionarDespesa('Parcela: $descricao', categoria, valorParcela, data);
  }

  Future<List<Divida>> listarDividas() async {
    final db = await database;
    final rows = await db.query('dividas', orderBy: 'id DESC');
    return rows.map((r) => Divida.fromMap(r)).toList();
  }

  // ==========================================================
  //  Despesas fixas
  // ==========================================================

  Future<bool> adicionarDespesaFixa(
      String descricao, String categoria, double valorPrevisto) async {
    final db = await database;
    final id = await db.insert('despesas_fixas', {
      'descricao': descricao,
      'categoria': categoria,
      'valorPrevisto': valorPrevisto,
    });
    return id > 0;
  }

  Future<bool> editarDespesaFixa(
      int id, String descricao, String categoria, double valorPrevisto) async {
    final db = await database;
    final linhas = await db.update(
      'despesas_fixas',
      {
        'descricao': descricao,
        'categoria': categoria,
        'valorPrevisto': valorPrevisto,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return linhas > 0;
  }

  Future<bool> removerDespesaFixa(int id) async {
    final db = await database;
    final linhas =
        await db.delete('despesas_fixas', where: 'id = ?', whereArgs: [id]);
    return linhas > 0;
  }

  Future<List<DespesaFixa>> listarDespesasFixas(String mesAno) async {
    final db = await database;
    final fixas =
        await db.query('despesas_fixas', orderBy: 'id ASC');

    final mesPrefix = '$mesAno%';
    final lista = <DespesaFixa>[];
    for (final f in fixas) {
      final categoria = f['categoria'] as String? ?? '';
      final somaGasto = await db.rawQuery(
        "SELECT COALESCE(SUM(valor), 0) as soma FROM lancamentos "
        "WHERE tipo = 'despesa' AND categoria = ? AND data LIKE ?",
        [categoria, mesPrefix],
      );
      final valorGasto = (somaGasto.first['soma'] as num?)?.toDouble() ?? 0;

      lista.add(DespesaFixa(
        id: f['id'] as int,
        descricao: f['descricao'] as String,
        categoria: categoria,
        valorPrevisto: (f['valorPrevisto'] as num).toDouble(),
        valorGasto: valorGasto,
      ));
    }
    return lista;
  }

  Future<bool> marcarDespesaFixaPaga(
      int id, String mesAno, double valorPago, String data) async {
    final db = await database;
    final busca = await db.query('despesas_fixas', where: 'id = ?', whereArgs: [id]);
    if (busca.isEmpty) return false;

    if (valorPago <= 0) return true;

    final descricao = busca.first['descricao'] as String? ?? '';
    final categoria = busca.first['categoria'] as String? ?? '';
    return adicionarDespesa(descricao, categoria, valorPago, data);
  }

  Future<bool> desmarcarDespesaFixaPaga(int id, String mesAno) async {
    final db = await database;
    final buscaFixa =
        await db.query('despesas_fixas', where: 'id = ?', whereArgs: [id]);
    if (buscaFixa.isEmpty) return false;
    final categoria = buscaFixa.first['categoria'] as String? ?? '';

    final buscaUltimo = await db.rawQuery(
      "SELECT id FROM lancamentos WHERE tipo = 'despesa' AND categoria = ? "
      "AND data LIKE ? ORDER BY id DESC LIMIT 1",
      [categoria, '$mesAno%'],
    );
    if (buscaUltimo.isEmpty) return false;

    final idLancamento = buscaUltimo.first['id'] as int;
    final linhas = await db
        .delete('lancamentos', where: 'id = ?', whereArgs: [idLancamento]);
    return linhas > 0;
  }
}
