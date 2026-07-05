#include "DatabaseManager.h"
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QDir>
#include <QVariantMap>
#include <QDebug>

DatabaseManager::DatabaseManager(QObject *parent) : QObject(parent)
{
    inicializarBanco();
}

void DatabaseManager::inicializarBanco()
{
    QString path = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(path);
    if (!dir.exists()) {
        dir.mkpath(".");
    }

    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE");
    db.setDatabaseName(path + "/financas.db");
    if (!db.open()) {
        qWarning() << "Erro ao abrir banco de dados:" << db.lastError().text();
        return;
    }

    // Tabela única: guarda receitas, despesas e movimentações da reserva de emergência.
    // tipo: 'receita' | 'despesa' | 'reserva_deposito' | 'reserva_saque'
    QSqlQuery query;
    if (!query.exec("CREATE TABLE IF NOT EXISTS lancamentos ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "tipo TEXT NOT NULL, "
        "categoria TEXT, "
        "descricao TEXT, "
        "valor REAL NOT NULL, "
        "data TEXT)")) {
        qWarning() << "Erro ao criar tabela lancamentos:" << query.lastError().text();
        }

        // Tabela de dívidas / parcelamentos (cartão, financiamento, empréstimo etc.)
        QSqlQuery queryDividas;
        if (!queryDividas.exec("CREATE TABLE IF NOT EXISTS dividas ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "descricao TEXT, "
            "categoria TEXT, "
            "valorParcela REAL NOT NULL, "
            "totalParcelas INTEGER NOT NULL, "
            "parcelasPagas INTEGER NOT NULL DEFAULT 0, "
            "data TEXT)")) {
            qWarning() << "Erro ao criar tabela dividas:" << queryDividas.lastError().text();
            }

            // Modelo de despesas fixas mensais (ex: Dízimo, Internet, Água...)
            QSqlQuery queryFixas;
            if (!queryFixas.exec("CREATE TABLE IF NOT EXISTS despesas_fixas ("
                "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                "descricao TEXT, "
                "categoria TEXT, "
                "valorPrevisto REAL NOT NULL)")) {
                qWarning() << "Erro ao criar tabela despesas_fixas:" << queryFixas.lastError().text();
                }

                migrarDadosAntigos();
}

void DatabaseManager::migrarDadosAntigos()
{
    // Só migra se a tabela antiga "despesas" existir e a nova ainda estiver vazia,
    // pra nunca duplicar dados em execuções seguintes.
    QSqlQuery checaAntiga("SELECT name FROM sqlite_master WHERE type='table' AND name='despesas'");
    if (!checaAntiga.next()) {
        return;
    }

    QSqlQuery checaNova("SELECT COUNT(*) FROM lancamentos");
    checaNova.next();
    if (checaNova.value(0).toInt() > 0) {
        return;
    }

    QSqlQuery antigos("SELECT descricao, valor, data FROM despesas");
    int migrados = 0;
    while (antigos.next()) {
        QSqlQuery insert;
        insert.prepare("INSERT INTO lancamentos (tipo, categoria, descricao, valor, data) "
        "VALUES ('despesa', 'Outros', :descricao, :valor, :data)");
        insert.bindValue(":descricao", antigos.value(0).toString());
        insert.bindValue(":valor", antigos.value(1).toDouble());
        insert.bindValue(":data", antigos.value(2).toString());
        if (insert.exec()) {
            migrados++;
        }
    }
    if (migrados > 0) {
        qDebug() << "Migração concluída:" << migrados << "despesa(s) movida(s) para lancamentos.";
    }
}

bool DatabaseManager::adicionarReceita(const QString &descricao, double valor, const QString &data)
{
    QSqlQuery query;
    query.prepare("INSERT INTO lancamentos (tipo, categoria, descricao, valor, data) "
    "VALUES ('receita', NULL, :descricao, :valor, :data)");
    query.bindValue(":descricao", descricao);
    query.bindValue(":valor", valor);
    query.bindValue(":data", data);
    if (!query.exec()) {
        qWarning() << "Erro ao adicionar receita:" << query.lastError().text();
        return false;
    }
    return true;
}

bool DatabaseManager::adicionarDespesa(const QString &descricao, const QString &categoria, double valor, const QString &data)
{
    QSqlQuery query;
    query.prepare("INSERT INTO lancamentos (tipo, categoria, descricao, valor, data) "
    "VALUES ('despesa', :categoria, :descricao, :valor, :data)");
    query.bindValue(":categoria", categoria);
    query.bindValue(":descricao", descricao);
    query.bindValue(":valor", valor);
    query.bindValue(":data", data);
    if (!query.exec()) {
        qWarning() << "Erro ao adicionar despesa:" << query.lastError().text();
        return false;
    }
    return true;
}

bool DatabaseManager::adicionarMovimentoReserva(const QString &descricao, double valor, const QString &data, const QString &tipoMovimento)
{
    const QString tipoInterno = (tipoMovimento == "saque") ? "reserva_saque" : "reserva_deposito";

    QSqlQuery query;
    query.prepare("INSERT INTO lancamentos (tipo, categoria, descricao, valor, data) "
    "VALUES (:tipo, NULL, :descricao, :valor, :data)");
    query.bindValue(":tipo", tipoInterno);
    query.bindValue(":descricao", descricao);
    query.bindValue(":valor", valor);
    query.bindValue(":data", data);
    if (!query.exec()) {
        qWarning() << "Erro ao movimentar reserva:" << query.lastError().text();
        return false;
    }
    return true;
}

bool DatabaseManager::removerLancamento(int id)
{
    QSqlQuery query;
    query.prepare("DELETE FROM lancamentos WHERE id = :id");
    query.bindValue(":id", id);
    if (!query.exec()) {
        qWarning() << "Erro ao remover lançamento:" << query.lastError().text();
        return false;
    }
    return true;
}

bool DatabaseManager::editarLancamento(int id, const QString &descricao, double valor)
{
    QSqlQuery query;
    query.prepare("UPDATE lancamentos SET descricao = :descricao, valor = :valor WHERE id = :id");
    query.bindValue(":descricao", descricao);
    query.bindValue(":valor", valor);
    query.bindValue(":id", id);
    if (!query.exec()) {
        qWarning() << "Erro ao editar lançamento:" << query.lastError().text();
        return false;
    }
    return true;
}

QVariantList DatabaseManager::listarLancamentos(int limite)
{
    QVariantList lista;
    QString sql = "SELECT id, tipo, categoria, descricao, valor, data FROM lancamentos ORDER BY id DESC";
    if (limite > 0) {
        sql += QString(" LIMIT %1").arg(limite);
    }

    QSqlQuery query(sql);
    while (query.next()) {
        QVariantMap item;
        item["id"] = query.value(0).toInt();
        item["tipo"] = query.value(1).toString();
        item["categoria"] = query.value(2).toString();
        item["descricao"] = query.value(3).toString();
        item["valor"] = query.value(4).toDouble();
        item["data"] = query.value(5).toString();
        lista.append(item);
    }
    return lista;
}

QVariantMap DatabaseManager::obterResumo()
{
    double totalReceitas = 0.0;
    double totalDespesas = 0.0;
    double totalReserva = 0.0;

    QSqlQuery query("SELECT tipo, SUM(valor) FROM lancamentos GROUP BY tipo");
    while (query.next()) {
        const QString tipo = query.value(0).toString();
        const double soma = query.value(1).toDouble();
        if (tipo == "receita") totalReceitas = soma;
        else if (tipo == "despesa") totalDespesas = soma;
        else if (tipo == "reserva_deposito") totalReserva += soma;
        else if (tipo == "reserva_saque") totalReserva -= soma;
    }

    const double saldoTotal = totalReceitas - totalDespesas;       // patrimônio total (inclui reserva)
    const double saldoDisponivel = saldoTotal - totalReserva;      // livre pra gastar sem mexer na reserva

    double comprometidoMensal = 0.0;
    double dividaTotalRestante = 0.0;
    QSqlQuery queryDividas("SELECT valorParcela, totalParcelas, parcelasPagas FROM dividas");
    while (queryDividas.next()) {
        const double valorParcela = queryDividas.value(0).toDouble();
        const int totalParcelas = queryDividas.value(1).toInt();
        const int parcelasPagas = queryDividas.value(2).toInt();
        const int parcelasRestantes = totalParcelas - parcelasPagas;
        if (parcelasRestantes > 0) {
            comprometidoMensal += valorParcela;
            dividaTotalRestante += valorParcela * parcelasRestantes;
        }
    }

    QVariantMap resumo;
    resumo["totalReceitas"] = totalReceitas;
    resumo["totalDespesas"] = totalDespesas;
    resumo["totalReserva"] = totalReserva;
    resumo["saldoTotal"] = saldoTotal;
    resumo["saldoDisponivel"] = saldoDisponivel;
    resumo["comprometidoMensal"] = comprometidoMensal;
    resumo["dividaTotalRestante"] = dividaTotalRestante;
    return resumo;
}

bool DatabaseManager::adicionarDivida(const QString &descricao, const QString &categoria, double valorParcela, int totalParcelas, const QString &data)
{
    QSqlQuery query;
    query.prepare("INSERT INTO dividas (descricao, categoria, valorParcela, totalParcelas, parcelasPagas, data) "
    "VALUES (:descricao, :categoria, :valorParcela, :totalParcelas, 0, :data)");
    query.bindValue(":descricao", descricao);
    query.bindValue(":categoria", categoria);
    query.bindValue(":valorParcela", valorParcela);
    query.bindValue(":totalParcelas", totalParcelas);
    query.bindValue(":data", data);
    if (!query.exec()) {
        qWarning() << "Erro ao adicionar dívida:" << query.lastError().text();
        return false;
    }
    return true;
}

bool DatabaseManager::removerDivida(int id)
{
    QSqlQuery query;
    query.prepare("DELETE FROM dividas WHERE id = :id");
    query.bindValue(":id", id);
    if (!query.exec()) {
        qWarning() << "Erro ao remover dívida:" << query.lastError().text();
        return false;
    }
    return true;
}

bool DatabaseManager::pagarParcela(int id, const QString &data)
{
    QSqlQuery busca;
    busca.prepare("SELECT descricao, categoria, valorParcela, totalParcelas, parcelasPagas FROM dividas WHERE id = :id");
    busca.bindValue(":id", id);
    if (!busca.exec() || !busca.next()) {
        qWarning() << "Erro ao buscar dívida para pagar parcela:" << busca.lastError().text();
        return false;
    }

    const QString descricao = busca.value(0).toString();
    const QString categoria = busca.value(1).toString();
    const double valorParcela = busca.value(2).toDouble();
    const int totalParcelas = busca.value(3).toInt();
    const int parcelasPagas = busca.value(4).toInt();

    if (parcelasPagas >= totalParcelas) {
        return false; // já quitada
    }

    QSqlQuery atualiza;
    atualiza.prepare("UPDATE dividas SET parcelasPagas = parcelasPagas + 1 WHERE id = :id");
    atualiza.bindValue(":id", id);
    if (!atualiza.exec()) {
        qWarning() << "Erro ao atualizar parcelas pagas:" << atualiza.lastError().text();
        return false;
    }

    // Registra a parcela paga como uma despesa no histórico
    return adicionarDespesa(QString("Parcela: %1").arg(descricao), categoria, valorParcela, data);
}

QVariantList DatabaseManager::listarDividas()
{
    QVariantList lista;
    QSqlQuery query("SELECT id, descricao, categoria, valorParcela, totalParcelas, parcelasPagas, data FROM dividas ORDER BY id DESC");
    while (query.next()) {
        QVariantMap item;
        const int totalParcelas = query.value(4).toInt();
        const int parcelasPagas = query.value(5).toInt();
        const double valorParcela = query.value(3).toDouble();

        item["id"] = query.value(0).toInt();
        item["descricao"] = query.value(1).toString();
        item["categoria"] = query.value(2).toString();
        item["valorParcela"] = valorParcela;
        item["totalParcelas"] = totalParcelas;
        item["parcelasPagas"] = parcelasPagas;
        item["data"] = query.value(6).toString();
        item["valorRestante"] = valorParcela * (totalParcelas - parcelasPagas);
        item["quitada"] = parcelasPagas >= totalParcelas;
        lista.append(item);
    }
    return lista;
}

bool DatabaseManager::adicionarDespesaFixa(const QString &descricao, const QString &categoria, double valorPrevisto)
{
    QSqlQuery query;
    query.prepare("INSERT INTO despesas_fixas (descricao, categoria, valorPrevisto) "
    "VALUES (:descricao, :categoria, :valorPrevisto)");
    query.bindValue(":descricao", descricao);
    query.bindValue(":categoria", categoria);
    query.bindValue(":valorPrevisto", valorPrevisto);
    if (!query.exec()) {
        qWarning() << "Erro ao adicionar despesa fixa:" << query.lastError().text();
        return false;
    }
    return true;
}

bool DatabaseManager::editarDespesaFixa(int id, const QString &descricao, const QString &categoria, double valorPrevisto)
{
    QSqlQuery query;
    query.prepare("UPDATE despesas_fixas SET descricao = :descricao, categoria = :categoria, "
    "valorPrevisto = :valorPrevisto WHERE id = :id");
    query.bindValue(":descricao", descricao);
    query.bindValue(":categoria", categoria);
    query.bindValue(":valorPrevisto", valorPrevisto);
    query.bindValue(":id", id);
    if (!query.exec()) {
        qWarning() << "Erro ao editar despesa fixa:" << query.lastError().text();
        return false;
    }
    return true;
}

bool DatabaseManager::removerDespesaFixa(int id)
{
    QSqlQuery query;
    query.prepare("DELETE FROM despesas_fixas WHERE id = :id");
    query.bindValue(":id", id);
    if (!query.exec()) {
        qWarning() << "Erro ao remover despesa fixa:" << query.lastError().text();
        return false;
    }
    return true;
}

QVariantList DatabaseManager::listarDespesasFixas(const QString &mesAno)
{
    QVariantList lista;
    QSqlQuery query("SELECT id, descricao, categoria, valorPrevisto FROM despesas_fixas ORDER BY id ASC");
    if (!query.exec()) {
        qWarning() << "Erro ao listar despesas fixas:" << query.lastError().text();
        return lista;
    }

    const QString mesPrefix = mesAno + "%";

    while (query.next()) {
        const int id = query.value(0).toInt();
        const QString descricao = query.value(1).toString();
        const QString categoria = query.value(2).toString();
        const double valorPrevisto = query.value(3).toDouble();

        // Soma tudo que já foi lançado nessa categoria neste mês (na tela inicial
        // ou aqui mesmo) — assim várias despesas pequenas da mesma categoria
        // (ex: Comida) se somam automaticamente até bater o valor previsto.
        QSqlQuery somaGasto;
        somaGasto.prepare("SELECT COALESCE(SUM(valor), 0) FROM lancamentos "
        "WHERE tipo = 'despesa' AND categoria = :categoria AND data LIKE :mesPrefix");
        somaGasto.bindValue(":categoria", categoria);
        somaGasto.bindValue(":mesPrefix", mesPrefix);
        double valorGasto = 0.0;
        if (somaGasto.exec() && somaGasto.next()) {
            valorGasto = somaGasto.value(0).toDouble();
        }

        QVariantMap item;
        item["id"] = id;
        item["descricao"] = descricao;
        item["categoria"] = categoria;
        item["valorPrevisto"] = valorPrevisto;
        item["valorGasto"] = valorGasto;
        item["pago"] = valorGasto >= valorPrevisto;
        lista.append(item);
    }
    return lista;
}

bool DatabaseManager::marcarDespesaFixaPaga(int id, const QString &mesAno, double valorPago, const QString &data)
{
    Q_UNUSED(mesAno);

    QSqlQuery buscaFixa;
    buscaFixa.prepare("SELECT descricao, categoria FROM despesas_fixas WHERE id = :id");
    buscaFixa.bindValue(":id", id);
    if (!buscaFixa.exec() || !buscaFixa.next()) {
        qWarning() << "Erro ao buscar despesa fixa:" << buscaFixa.lastError().text();
        return false;
    }
    const QString descricao = buscaFixa.value(0).toString();
    const QString categoria = buscaFixa.value(1).toString();

    if (valorPago <= 0) {
        return true; // categoria já estava com o valor previsto coberto
    }

    // Lança o valor que falta para completar o previsto — o mesmo lançamento
    // que apareceria se você tivesse adicionado direto na tela inicial.
    return adicionarDespesa(descricao, categoria, valorPago, data);
}

bool DatabaseManager::desmarcarDespesaFixaPaga(int id, const QString &mesAno)
{
    QSqlQuery buscaFixa;
    buscaFixa.prepare("SELECT categoria FROM despesas_fixas WHERE id = :id");
    buscaFixa.bindValue(":id", id);
    if (!buscaFixa.exec() || !buscaFixa.next()) {
        return false;
    }
    const QString categoria = buscaFixa.value(0).toString();

    // Remove o lançamento mais recente dessa categoria neste mês
    // (o "desfazer" do último toque em OK).
    QSqlQuery buscaUltimo;
    buscaUltimo.prepare("SELECT id FROM lancamentos "
    "WHERE tipo = 'despesa' AND categoria = :categoria AND data LIKE :mesPrefix "
    "ORDER BY id DESC LIMIT 1");
    buscaUltimo.bindValue(":categoria", categoria);
    buscaUltimo.bindValue(":mesPrefix", mesAno + "%");
    if (!buscaUltimo.exec() || !buscaUltimo.next()) {
        return false; // nada lançado nessa categoria neste mês
    }
    const int lancamentoId = buscaUltimo.value(0).toInt();

    QSqlQuery remove;
    remove.prepare("DELETE FROM lancamentos WHERE id = :id");
    remove.bindValue(":id", lancamentoId);
    if (!remove.exec()) {
        qWarning() << "Erro ao desmarcar despesa fixa:" << remove.lastError().text();
        return false;
    }
    return true;
}
