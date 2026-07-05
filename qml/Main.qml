import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 380
    height: 760
    minimumWidth: 340
    minimumHeight: 560
    visible: true
    title: qsTr("Agildo Finanças")
    color: "#F3F4F6"

    Material.theme: Material.Light
    Material.accent: "#3B82F6"

    // ==========================================================
    //  Componentes reutilizáveis
    // ==========================================================

    // Botão sólido com bom contraste (resolve o problema do texto "brando")
    component AppButton: Rectangle {
        id: btnRoot
        property string label: ""
        property color corBase: "#3B82F6"
        implicitHeight: 46
        radius: 8
        color: mouseArea.pressed ? Qt.darker(corBase, 1.15) : corBase
        Behavior on color { ColorAnimation { duration: 100 } }
        signal clicked()

        Text {
            anchors.centerIn: parent
            text: btnRoot.label
            color: "white"
            font.pixelSize: 15
            font.bold: true
        }
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            onClicked: btnRoot.clicked()
        }
    }

    // "Chip" usado para alternar Receita / Despesa / Reserva / Dívida e Depositar / Sacar
    component ToggleChip: Rectangle {
        id: chip
        property string label: ""
        property bool selecionado: false
        property color corAtiva: "#3B82F6"
        implicitHeight: 40
        radius: 8
        color: selecionado ? corAtiva : "#E5E7EB"
        Behavior on color { ColorAnimation { duration: 100 } }
        signal clicked()

        Text {
            anchors.centerIn: parent
            text: chip.label
            color: chip.selecionado ? "white" : "#374151"
            font.bold: true
            font.pixelSize: 13
        }
        MouseArea {
            anchors.fill: parent
            onClicked: chip.clicked()
        }
    }

    // Card do resumo financeiro (saldo, receitas, despesas, reserva, dívidas)
    component SummaryCard: Rectangle {
        property string titulo: ""
        property string valor: ""
        property color corValor: "#111827"
        Layout.fillWidth: true
        implicitHeight: 74
        radius: 10
        color: "white"
        border.color: "#E5E7EB"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 2
            Label {
                text: titulo
                font.pixelSize: 12
                color: "#6B7280"
            }
            Label {
                text: valor
                font.pixelSize: 20
                font.bold: true
                color: corValor
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    // ==========================================================
    //  Estado da tela
    // ==========================================================

    property string modoAtual: "despesa"     // "receita" | "despesa" | "reserva" | "divida"
    property string tipoReserva: "deposito"  // "deposito" | "saque"

    property real totalReceitas: 0
    property real totalDespesas: 0
    property real totalReserva: 0
    property real saldoTotal: 0
    property real saldoDisponivel: 0
    property real comprometidoMensal: 0
    property real dividaTotalRestante: 0

    property var categoriasDespesa: ["Alimentação", "Moradia", "Água", "Internet", "Transporte", "Cabelo", "Saúde", "Educação", "Lazer", "Dízimo", "Dízimos Colheita", "Missões", "Igreja", "Outros"]

    property string mesAtual: Qt.formatDate(new Date(), "yyyy-MM")
    property real totalFixasPrevisto: 0
    property real totalFixasPago: 0
    property real totalFixasFalta: 0
    property int idEditandoFixa: -1

    ListModel { id: listaModel }
    ListModel { id: dividasModel }
    ListModel { id: fixasModel }

    // ==========================================================
    //  Funções auxiliares
    // ==========================================================

    function formatarMoeda(valor) {
        var v = Number(valor).toFixed(2);
        var partes = v.split(".");
        var inteiro = partes[0];
        var decimal = partes[1];
        var negativo = inteiro.charAt(0) === "-";
        if (negativo) inteiro = inteiro.substring(1);
        var comPontos = inteiro.replace(/\B(?=(\d{3})+(?!\d))/g, ".");
        return (negativo ? "-" : "") + "R$ " + comPontos + "," + decimal;
    }

    function hojeISO() {
        return Qt.formatDate(new Date(), "yyyy-MM-dd");
    }

    function atualizarResumo() {
        var r = db.obterResumo();
        totalReceitas = r.totalReceitas;
        totalDespesas = r.totalDespesas;
        totalReserva = r.totalReserva;
        saldoTotal = r.saldoTotal;
        saldoDisponivel = r.saldoDisponivel;
        comprometidoMensal = r.comprometidoMensal;
        dividaTotalRestante = r.dividaTotalRestante;
    }

    function atualizarLista() {
        listaModel.clear();
        var dados = db.listarLancamentos();
        for (var i = 0; i < dados.length; i++) {
            listaModel.append(dados[i]);
        }
    }

    function atualizarDividas() {
        dividasModel.clear();
        var dividas = db.listarDividas();
        for (var i = 0; i < dividas.length; i++) {
            dividasModel.append(dividas[i]);
        }
    }

    function atualizarFixas() {
        fixasModel.clear();
        var previsto = 0, gasto = 0;
        var fixas = db.listarDespesasFixas(mesAtual);
        for (var i = 0; i < fixas.length; i++) {
            fixasModel.append(fixas[i]);
            previsto += fixas[i].valorPrevisto;
            gasto += fixas[i].valorGasto;
        }
        totalFixasPrevisto = previsto;
        totalFixasPago = gasto;
        totalFixasFalta = previsto - gasto;
    }

    function limparFormulario() {
        campoDescricao.clear();
        campoValor.clear();
        campoParcelas.clear();
        avisoValidacao.visible = false;
    }

    Component.onCompleted: {
        atualizarResumo();
        atualizarLista();
        atualizarDividas();
        atualizarFixas();
    }

    // ==========================================================
    //  Interface
    // ==========================================================

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        ColumnLayout {
            width: scrollView.availableWidth - 32
            x: 16
            y: 16
            spacing: 14

            Label {
                text: "💰 Agildo Finanças"
                font.pixelSize: 22
                font.bold: true
                color: "#111827"
            }

            AppButton {
                Layout.fillWidth: true
                label: "📋 Gerenciar despesas fixas do mês"
                corBase: "#0EA5A4"
                onClicked: {
                    atualizarFixas();
                    popupFixas.open();
                }
            }

            // ---------- Resumo ----------
            GridLayout {
                columns: 2
                columnSpacing: 10
                rowSpacing: 10
                Layout.fillWidth: true

                SummaryCard {
                    Layout.columnSpan: 2
                    implicitHeight: 84
                    titulo: "Saldo disponível"
                    valor: formatarMoeda(saldoDisponivel)
                    corValor: saldoDisponivel >= 0 ? "#16A34A" : "#DC2626"
                }
                SummaryCard {
                    titulo: "Receitas"
                    valor: formatarMoeda(totalReceitas)
                    corValor: "#16A34A"
                }
                SummaryCard {
                    titulo: "Total geral de despesas"
                    valor: formatarMoeda(totalDespesas)
                    corValor: "#DC2626"
                }
                SummaryCard {
                    titulo: "Reserva de emergência"
                    valor: formatarMoeda(totalReserva)
                    corValor: "#2563EB"
                }
                SummaryCard {
                    titulo: "Comprometido/mês"
                    valor: formatarMoeda(comprometidoMensal)
                    corValor: "#7C3AED"
                }
                SummaryCard {
                    Layout.columnSpan: 2
                    titulo: "Dívida total restante"
                    valor: formatarMoeda(dividaTotalRestante)
                    corValor: "#F59E0B"
                }
            }

            Label {
                text: "🔒 Comprometido/mês e dívida restante ainda não saíram do saldo — isso acontece conforme você for pagando as parcelas."
                font.pixelSize: 11
                color: "#9CA3AF"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            // ---------- Seletor de tipo de lançamento ----------
            GridLayout {
                columns: 2
                columnSpacing: 8
                rowSpacing: 8
                Layout.fillWidth: true

                ToggleChip {
                    Layout.fillWidth: true
                    label: "Receita"
                    corAtiva: "#16A34A"
                    selecionado: modoAtual === "receita"
                    onClicked: { modoAtual = "receita"; avisoValidacao.visible = false; }
                }
                ToggleChip {
                    Layout.fillWidth: true
                    label: "Despesa"
                    corAtiva: "#DC2626"
                    selecionado: modoAtual === "despesa"
                    onClicked: { modoAtual = "despesa"; avisoValidacao.visible = false; }
                }
                ToggleChip {
                    Layout.fillWidth: true
                    label: "Reserva"
                    corAtiva: "#2563EB"
                    selecionado: modoAtual === "reserva"
                    onClicked: { modoAtual = "reserva"; avisoValidacao.visible = false; }
                }
                ToggleChip {
                    Layout.fillWidth: true
                    label: "Dívida"
                    corAtiva: "#7C3AED"
                    selecionado: modoAtual === "divida"
                    onClicked: { modoAtual = "divida"; avisoValidacao.visible = false; }
                }
            }

            // ---------- Formulário ----------
            Rectangle {
                Layout.fillWidth: true
                radius: 12
                color: "white"
                border.color: "#E5E7EB"
                implicitHeight: formColumn.implicitHeight + 24

                ColumnLayout {
                    id: formColumn
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    TextField {
                        id: campoDescricao
                        Layout.fillWidth: true
                        placeholderText: modoAtual === "receita" ? "Ex: Salário"
                        : modoAtual === "despesa" ? "Ex: Supermercado"
                        : modoAtual === "reserva" ? "Ex: Conserto do carro"
                        : "Ex: Notebook parcelado"
                    }

                    RowLayout {
                        visible: modoAtual === "despesa"
                        Layout.fillWidth: true
                        spacing: 8
                        Label { text: "Categoria:"; color: "#374151" }
                        ComboBox {
                            id: comboCategoria
                            Layout.fillWidth: true
                            model: categoriasDespesa
                        }
                    }

                    RowLayout {
                        visible: modoAtual === "reserva"
                        Layout.fillWidth: true
                        spacing: 8
                        ToggleChip {
                            Layout.fillWidth: true
                            label: "Depositar"
                            corAtiva: "#2563EB"
                            selecionado: tipoReserva === "deposito"
                            onClicked: tipoReserva = "deposito"
                        }
                        ToggleChip {
                            Layout.fillWidth: true
                            label: "Sacar"
                            corAtiva: "#DC2626"
                            selecionado: tipoReserva === "saque"
                            onClicked: tipoReserva = "saque"
                        }
                    }

                    RowLayout {
                        visible: modoAtual === "divida"
                        Layout.fillWidth: true
                        spacing: 8
                        Label { text: "Categoria:"; color: "#374151" }
                        ComboBox {
                            id: comboCategoriaDivida
                            Layout.fillWidth: true
                            model: ["Cartão Nubank", "Cartão Inter", "Cartão Neon", "Cartão Mercado Pago", "Financiamento", "Empréstimo", "Outros"]
                        }
                    }

                    TextField {
                        id: campoValor
                        Layout.fillWidth: true
                        placeholderText: modoAtual === "divida" ? "Valor de cada parcela (R$)" : "Valor (R$)"
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                    }

                    TextField {
                        id: campoParcelas
                        visible: modoAtual === "divida"
                        Layout.fillWidth: true
                        placeholderText: "Quantidade de parcelas"
                        inputMethodHints: Qt.ImhDigitsOnly
                    }

                    Label {
                        id: avisoValidacao
                        visible: false
                        text: "Preencha a descrição e um valor válido maior que zero."
                        color: "#DC2626"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    AppButton {
                        Layout.fillWidth: true
                        label: modoAtual === "receita" ? "Adicionar receita"
                        : modoAtual === "despesa" ? "Adicionar despesa"
                        : modoAtual === "reserva" ? (tipoReserva === "deposito" ? "Depositar na reserva" : "Sacar da reserva")
                        : "Registrar dívida"
                        corBase: modoAtual === "receita" ? "#16A34A"
                        : modoAtual === "despesa" ? "#DC2626"
                        : modoAtual === "reserva" ? "#2563EB"
                        : "#7C3AED"
                        onClicked: {
                            var valor = parseFloat(campoValor.text.replace(",", "."));
                            if (isNaN(valor) || valor <= 0 || campoDescricao.text.trim() === "") {
                                avisoValidacao.text = "Preencha a descrição e um valor válido maior que zero.";
                                avisoValidacao.visible = true;
                                return;
                            }

                            var ok = false;

                            if (modoAtual === "receita") {
                                ok = db.adicionarReceita(campoDescricao.text, valor, hojeISO());
                            } else if (modoAtual === "despesa") {
                                ok = db.adicionarDespesa(campoDescricao.text, comboCategoria.currentText, valor, hojeISO());
                            } else if (modoAtual === "reserva") {
                                ok = db.adicionarMovimentoReserva(campoDescricao.text, valor, hojeISO(), tipoReserva);
                            } else if (modoAtual === "divida") {
                                var parcelas = parseInt(campoParcelas.text);
                                if (isNaN(parcelas) || parcelas <= 0) {
                                    avisoValidacao.text = "Informe a quantidade de parcelas (um número inteiro maior que zero).";
                                    avisoValidacao.visible = true;
                                    return;
                                }
                                ok = db.adicionarDivida(campoDescricao.text, comboCategoriaDivida.currentText, valor, parcelas, hojeISO());
                            }

                            if (ok) {
                                limparFormulario();
                                atualizarResumo();
                                atualizarLista();
                                atualizarDividas();
                            } else {
                                avisoValidacao.text = "Não foi possível salvar. Tente novamente.";
                                avisoValidacao.visible = true;
                            }
                        }
                    }
                }
            }

            // ---------- Dívidas e parcelamentos ----------
            Label {
                text: "Minhas dívidas e parcelamentos"
                font.pixelSize: 16
                font.bold: true
                color: "#111827"
                Layout.topMargin: 4
            }

            Label {
                visible: dividasModel.count === 0
                text: "Nenhuma dívida cadastrada. Registre cartão parcelado, financiamento etc. no formulário acima."
                color: "#9CA3AF"
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            ListView {
                id: dividasView
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                interactive: false
                spacing: 8
                model: dividasModel

                delegate: Rectangle {
                    id: divRoot
                    width: dividasView.width
                    implicitHeight: divContent.implicitHeight + 20
                    radius: 10
                    color: "white"
                    border.color: "#E5E7EB"

                    property bool quitada: model.quitada
                    property real progresso: model.totalParcelas > 0 ? model.parcelasPagas / model.totalParcelas : 0

                    ColumnLayout {
                        id: divContent
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Label {
                                    text: model.descricao
                                    font.bold: true
                                    font.pixelSize: 14
                                    color: "#111827"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: (model.categoria ? model.categoria + " · " : "") + model.parcelasPagas + "/" + model.totalParcelas + " parcelas pagas"
                                    font.pixelSize: 11
                                    color: "#6B7280"
                                }
                            }

                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: "#F3F4F6"
                                Label {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: "#9CA3AF"
                                    font.pixelSize: 11
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        db.removerDivida(model.id);
                                        atualizarDividas();
                                        atualizarResumo();
                                    }
                                }
                            }
                        }

                        // Barra de progresso
                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: "#E5E7EB"
                            Rectangle {
                                width: parent.width * divRoot.progresso
                                height: parent.height
                                radius: 3
                                color: divRoot.quitada ? "#16A34A" : "#7C3AED"
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: "Restante: " + formatarMoeda(model.valorRestante)
                                font.pixelSize: 12
                                color: "#6B7280"
                                Layout.fillWidth: true
                            }

                            AppButton {
                                visible: !divRoot.quitada
                                implicitHeight: 34
                                implicitWidth: 140
                                label: "Pagar parcela"
                                corBase: "#7C3AED"
                                onClicked: {
                                    db.pagarParcela(model.id, hojeISO());
                                    atualizarDividas();
                                    atualizarResumo();
                                    atualizarLista();
                                }
                            }

                            Label {
                                visible: divRoot.quitada
                                text: "Quitada ✓"
                                color: "#16A34A"
                                font.bold: true
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }

            // ---------- Histórico ----------
            Label {
                text: "Histórico"
                font.pixelSize: 16
                font.bold: true
                color: "#111827"
                Layout.topMargin: 4
            }

            Label {
                visible: listaModel.count === 0
                text: "Nenhum lançamento ainda. Adicione sua primeira receita ou despesa acima."
                color: "#9CA3AF"
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            ListView {
                id: listaView
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                interactive: false
                spacing: 8
                model: listaModel

                delegate: Rectangle {
                    id: delegateRoot
                    width: listaView.width
                    implicitHeight: 56
                    radius: 10
                    color: "white"
                    border.color: "#E5E7EB"

                    property color corLateral: {
                        if (model.tipo === "receita") return "#16A34A";
                        if (model.tipo === "despesa") return "#DC2626";
                        if (model.tipo === "reserva_deposito") return "#2563EB";
                        return "#F59E0B"; // reserva_saque
                    }

                    Rectangle {
                        anchors.left: parent.left
                        width: 4
                        height: parent.height
                        radius: 2
                        color: delegateRoot.corLateral
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        anchors.leftMargin: 16
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label {
                                text: model.descricao
                                font.bold: true
                                font.pixelSize: 14
                                color: "#111827"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Label {
                                text: {
                                    if (model.tipo === "despesa" && model.categoria)
                                        return model.categoria + " · " + model.data;
                                    if (model.tipo === "reserva_deposito")
                                        return "Reserva (depósito) · " + model.data;
                                    if (model.tipo === "reserva_saque")
                                        return "Reserva (saque) · " + model.data;
                                    return model.data;
                                }
                                font.pixelSize: 11
                                color: "#6B7280"
                            }
                        }

                        Label {
                            text: {
                                var sinal = (model.tipo === "despesa" || model.tipo === "reserva_saque") ? "- " : "+ ";
                                return sinal + formatarMoeda(model.valor).replace("R$ ", "");
                            }
                            font.bold: true
                            font.pixelSize: 14
                            color: delegateRoot.corLateral
                        }

                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            color: "#F3F4F6"
                            Label {
                                anchors.centerIn: parent
                                text: "✏️"
                                font.pixelSize: 11
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    idEditando = model.id;
                                    campoEditDescricao.text = model.descricao;
                                    campoEditValor.text = String(model.valor).replace(".", ",");
                                    avisoEdicao.visible = false;
                                    popupEditar.open();
                                }
                            }
                        }

                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            color: "#F3F4F6"
                            Label {
                                anchors.centerIn: parent
                                text: "✕"
                                color: "#9CA3AF"
                                font.pixelSize: 12
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    db.removerLancamento(model.id);
                                    atualizarResumo();
                                    atualizarLista();
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 16 } // margem inferior
        }
    }

    // ==========================================================
    //  Popup de edição de lançamento (permite alterar o valor)
    // ==========================================================
    property int idEditando: -1

    Popup {
        id: popupEditar
        anchors.centerIn: parent
        width: Math.min(window.width - 48, 320)
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        ColumnLayout {
            width: parent.width
            spacing: 10

            Label {
                text: "Editar lançamento"
                font.pixelSize: 16
                font.bold: true
                color: "#111827"
            }

            TextField {
                id: campoEditDescricao
                Layout.fillWidth: true
                placeholderText: "Descrição"
            }

            TextField {
                id: campoEditValor
                Layout.fillWidth: true
                placeholderText: "Valor (R$)"
                inputMethodHints: Qt.ImhFormattedNumbersOnly
            }

            Label {
                id: avisoEdicao
                visible: false
                text: "Informe um valor válido maior que zero."
                color: "#DC2626"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                AppButton {
                    Layout.fillWidth: true
                    label: "Cancelar"
                    corBase: "#9CA3AF"
                    onClicked: popupEditar.close()
                }

                AppButton {
                    Layout.fillWidth: true
                    label: "Salvar"
                    corBase: "#3B82F6"
                    onClicked: {
                        var novoValor = parseFloat(campoEditValor.text.replace(",", "."));
                        if (isNaN(novoValor) || novoValor <= 0 || campoEditDescricao.text.trim() === "") {
                            avisoEdicao.visible = true;
                            return;
                        }
                        var ok = db.editarLancamento(idEditando, campoEditDescricao.text, novoValor);
                        if (ok) {
                            popupEditar.close();
                            atualizarResumo();
                            atualizarLista();
                        } else {
                            avisoEdicao.text = "Não foi possível salvar. Tente novamente.";
                            avisoEdicao.visible = true;
                        }
                    }
                }
            }
        }
    }

    // ==========================================================
    //  Popup: menu de despesas fixas do mês (estilo caderno)
    //  Ex: Dízimo, Missões, Igreja, Internet, Água... com "OK"
    // ==========================================================
    Popup {
        id: popupFixas
        anchors.centerIn: parent
        width: window.width - 32
        height: Math.min(window.height - 64, 680)
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: "Despesas fixas · " + mesAtual
                    font.pixelSize: 16
                    font.bold: true
                    color: "#111827"
                    Layout.fillWidth: true
                }
                Rectangle {
                    width: 26; height: 26; radius: 13; color: "#F3F4F6"
                    Label { anchors.centerIn: parent; text: "✕"; color: "#9CA3AF"; font.pixelSize: 12 }
                    MouseArea { anchors.fill: parent; onClicked: popupFixas.close() }
                }
            }

            Label {
                visible: fixasModel.count === 0
                text: "Nenhuma despesa fixa cadastrada ainda. Adicione abaixo (ex: Dízimo, Internet, Água...)."
                color: "#9CA3AF"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Label {
                visible: fixasModel.count > 0
                text: "Dica: toda despesa lançada na tela inicial soma automaticamente aqui pela categoria (ex: várias despesas em \"Alimentação\" somam até completar o previsto de Comida)."
                color: "#9CA3AF"
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: popupFixas.width - 32
                    spacing: 8

                    Repeater {
                        model: fixasModel

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 56
                            radius: 10
                            color: "white"
                            border.color: model.pago ? "#16A34A" : "#E5E7EB"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: model.pago ? "#16A34A" : "#E5E7EB"
                                    Label {
                                        anchors.centerIn: parent
                                        text: model.pago ? "✓" : ""
                                        color: "white"
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (model.pago) {
                                                db.desmarcarDespesaFixaPaga(model.id, mesAtual);
                                            } else {
                                                var falta = model.valorPrevisto - model.valorGasto;
                                                if (falta <= 0) falta = model.valorPrevisto;
                                                db.marcarDespesaFixaPaga(model.id, mesAtual, falta, hojeISO());
                                            }
                                            atualizarFixas();
                                            atualizarLista();
                                            atualizarResumo();
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Label {
                                        text: model.descricao
                                        font.bold: true
                                        font.pixelSize: 13
                                        color: "#111827"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Label {
                                        text: model.categoria + " · " + formatarMoeda(model.valorGasto) + " de " + formatarMoeda(model.valorPrevisto)
                                        font.pixelSize: 11
                                        color: "#6B7280"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Label {
                                    text: formatarMoeda(model.valorPrevisto)
                                    font.bold: true
                                    font.pixelSize: 13
                                    color: model.pago ? "#16A34A" : "#111827"
                                }

                                Rectangle {
                                    width: 24; height: 24; radius: 12; color: "#F3F4F6"
                                    Label { anchors.centerIn: parent; text: "✏️"; font.pixelSize: 10 }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            idEditandoFixa = model.id;
                                            campoFixaDescricao.text = model.descricao;
                                            var idx = categoriasDespesa.indexOf(model.categoria);
                                            comboFixaCategoria.currentIndex = idx >= 0 ? idx : 0;
                                            campoFixaValor.text = String(model.valorPrevisto).replace(".", ",");
                                            popupEditarFixa.open();
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 24; height: 24; radius: 12; color: "#F3F4F6"
                                    Label { anchors.centerIn: parent; text: "✕"; color: "#9CA3AF"; font.pixelSize: 11 }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            db.removerDespesaFixa(model.id);
                                            atualizarFixas();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ---------- Resumo do mês ----------
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                        implicitHeight: 70
                        radius: 10
                        color: "#F3F4F6"
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 2
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: "Previsto: " + formatarMoeda(totalFixasPrevisto); font.pixelSize: 12; color: "#374151"; Layout.fillWidth: true }
                                Label { text: "Pago: " + formatarMoeda(totalFixasPago); font.pixelSize: 12; color: "#16A34A" }
                            }
                            Label {
                                text: "Falta pagar: " + formatarMoeda(totalFixasFalta)
                                font.pixelSize: 13
                                font.bold: true
                                color: "#DC2626"
                            }
                        }
                    }

                    // ---------- Nova despesa fixa ----------
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                        implicitHeight: novaFixaColumn.implicitHeight + 20
                        radius: 10
                        color: "white"
                        border.color: "#E5E7EB"

                        ColumnLayout {
                            id: novaFixaColumn
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Label {
                                text: "Adicionar despesa fixa"
                                font.bold: true
                                font.pixelSize: 13
                                color: "#111827"
                            }

                            TextField {
                                id: campoNovaFixaDescricao
                                Layout.fillWidth: true
                                placeholderText: "Ex: Dízimo, Internet, Água..."
                            }

                            ComboBox {
                                id: comboNovaFixaCategoria
                                Layout.fillWidth: true
                                model: categoriasDespesa
                            }

                            TextField {
                                id: campoNovaFixaValor
                                Layout.fillWidth: true
                                placeholderText: "Valor previsto (R$)"
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                            }

                            AppButton {
                                Layout.fillWidth: true
                                label: "Adicionar"
                                corBase: "#0EA5A4"
                                onClicked: {
                                    var valor = parseFloat(campoNovaFixaValor.text.replace(",", "."));
                                    if (isNaN(valor) || valor <= 0 || campoNovaFixaDescricao.text.trim() === "") {
                                        return;
                                    }
                                    var ok = db.adicionarDespesaFixa(campoNovaFixaDescricao.text, comboNovaFixaCategoria.currentText, valor);
                                    if (ok) {
                                        campoNovaFixaDescricao.clear();
                                        campoNovaFixaValor.clear();
                                        atualizarFixas();
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.preferredHeight: 8 }
                }
            }
        }
    }

    // ==========================================================
    //  Popup: editar uma despesa fixa (descrição, categoria, valor previsto)
    // ==========================================================
    Popup {
        id: popupEditarFixa
        anchors.centerIn: parent
        width: Math.min(window.width - 48, 320)
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        ColumnLayout {
            width: parent.width
            spacing: 10

            Label {
                text: "Editar despesa fixa"
                font.pixelSize: 16
                font.bold: true
                color: "#111827"
            }

            TextField {
                id: campoFixaDescricao
                Layout.fillWidth: true
                placeholderText: "Descrição"
            }

            ComboBox {
                id: comboFixaCategoria
                Layout.fillWidth: true
                model: categoriasDespesa
            }

            TextField {
                id: campoFixaValor
                Layout.fillWidth: true
                placeholderText: "Valor previsto (R$)"
                inputMethodHints: Qt.ImhFormattedNumbersOnly
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                AppButton {
                    Layout.fillWidth: true
                    label: "Cancelar"
                    corBase: "#9CA3AF"
                    onClicked: popupEditarFixa.close()
                }

                AppButton {
                    Layout.fillWidth: true
                    label: "Salvar"
                    corBase: "#0EA5A4"
                    onClicked: {
                        var valor = parseFloat(campoFixaValor.text.replace(",", "."));
                        if (isNaN(valor) || valor <= 0 || campoFixaDescricao.text.trim() === "") {
                            return;
                        }
                        var ok = db.editarDespesaFixa(idEditandoFixa, campoFixaDescricao.text, comboFixaCategoria.currentText, valor);
                        if (ok) {
                            popupEditarFixa.close();
                            atualizarFixas();
                        }
                    }
                }
            }
        }
    }
}
