#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class DatabaseManager : public QObject
{
    Q_OBJECT
public:
    explicit DatabaseManager(QObject *parent = nullptr);

    // --- Lançamentos ---
    Q_INVOKABLE bool adicionarReceita(const QString &descricao, double valor, const QString &data);
    Q_INVOKABLE bool adicionarDespesa(const QString &descricao, const QString &categoria, double valor, const QString &data);
    // tipoMovimento esperado: "deposito" ou "saque"
    Q_INVOKABLE bool adicionarMovimentoReserva(const QString &descricao, double valor, const QString &data, const QString &tipoMovimento);
    Q_INVOKABLE bool removerLancamento(int id);
    Q_INVOKABLE bool editarLancamento(int id, const QString &descricao, double valor);

    // --- Consultas ---
    Q_INVOKABLE QVariantList listarLancamentos(int limite = -1);
    Q_INVOKABLE QVariantMap obterResumo();

    // --- Dívidas / parcelamentos ---
    Q_INVOKABLE bool adicionarDivida(const QString &descricao, const QString &categoria, double valorParcela, int totalParcelas, const QString &data);
    Q_INVOKABLE bool removerDivida(int id);
    Q_INVOKABLE bool pagarParcela(int id, const QString &data);
    Q_INVOKABLE QVariantList listarDividas();

    // --- Despesas fixas (checklist mensal: Dízimo, Internet, Água, etc.) ---
    Q_INVOKABLE bool adicionarDespesaFixa(const QString &descricao, const QString &categoria, double valorPrevisto);
    Q_INVOKABLE bool editarDespesaFixa(int id, const QString &descricao, const QString &categoria, double valorPrevisto);
    Q_INVOKABLE bool removerDespesaFixa(int id);
    Q_INVOKABLE QVariantList listarDespesasFixas(const QString &mesAno);
    Q_INVOKABLE bool marcarDespesaFixaPaga(int id, const QString &mesAno, double valorPago, const QString &data);
    Q_INVOKABLE bool desmarcarDespesaFixaPaga(int id, const QString &mesAno);

private:
    void inicializarBanco();
    void migrarDadosAntigos();
};
#endif // DATABASEMANAGER_H
