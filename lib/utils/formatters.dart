/// Formata um valor numérico como moeda brasileira: "R$ 1.234,56".
/// Lógica equivalente à função `formatarMoeda` do Main.qml original.
String formatarMoeda(double valor) {
  final v = valor.toStringAsFixed(2);
  final partes = v.split('.');
  var inteiro = partes[0];
  final decimal = partes[1];
  final negativo = inteiro.startsWith('-');
  if (negativo) inteiro = inteiro.substring(1);

  final comPontos = inteiro.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => '.',
  );
  return (negativo ? '-' : '') + 'R\$ ' + comPontos + ',' + decimal;
}

/// Data de hoje no formato ISO "yyyy-MM-dd", igual a `hojeISO()` no QML.
String hojeISO() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

/// Mês/ano atual no formato "yyyy-MM", igual a `mesAtual` no QML.
String mesAtualISO() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}';
}

/// Converte um texto de campo de valor (aceita vírgula ou ponto) em double.
/// Retorna null se inválido, igual à validação usada nos formulários do QML.
double? parseValorCampo(String texto) {
  final normalizado = texto.trim().replaceAll(',', '.');
  if (normalizado.isEmpty) return null;
  return double.tryParse(normalizado);
}
