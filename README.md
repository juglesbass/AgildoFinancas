# Agildo Finanças — versão Flutter

Porte completo do app original em **Qt/QML + C++** para **Flutter/Dart**, mantendo o
mesmo banco de dados SQLite, as mesmas telas e o mesmo comportamento.

## Como o código se mapeia para o original

| Original (Qt/QML + C++)      | Flutter/Dart                                  |
|-------------------------------|------------------------------------------------|
| `main.cpp`                    | `lib/main.dart`                                |
| `DatabaseManager.h/.cpp`       | `lib/database_helper.dart` (usa `sqflite`)      |
| `Main.qml` (janela inteira)    | `lib/screens/home_screen.dart`                  |
| `component AppButton`          | `lib/widgets/app_button.dart`                   |
| `component ToggleChip`         | `lib/widgets/toggle_chip.dart`                  |
| `component SummaryCard`        | `lib/widgets/summary_card.dart`                 |
| `popupEditar`                  | `lib/dialogs/editar_lancamento_dialog.dart`     |
| `popupFixas`                   | `lib/dialogs/despesas_fixas_dialog.dart`        |
| `popupEditarFixa`              | `lib/dialogs/editar_despesa_fixa_dialog.dart`   |
| `formatarMoeda()` / `hojeISO()`| `lib/utils/formatters.dart`                     |

O schema do banco (`lancamentos`, `dividas`, `despesas_fixas`) é **idêntico** ao
original, e todos os métodos do `DatabaseManager` (adicionarReceita,
adicionarDespesa, pagarParcela, marcarDespesaFixaPaga etc.) foram portados com a
mesma lógica e as mesmas assinaturas (adaptadas para `Future` assíncrono, já que
`sqflite` é assíncrono, diferente do driver Qt SQL que era síncrono).

> **Observação:** a migração automática de uma tabela antiga `despesas` (função
> `migrarDadosAntigos()` no C++) não foi portada, pois é específica de uma versão
> anterior do app Qt. Se você tiver um `financas.db` antigo que precise migrar,
> me avise que eu adiciono essa rotina.

## Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado (canal stable).
- Para rodar no iOS: um Mac com Xcode instalado (e uma conta Apple Developer para
  rodar em dispositivo físico ou publicar na App Store).
- Para rodar no Android: Android Studio ou apenas o Android SDK/emulador.

## Como colocar para rodar

Este pacote contém apenas a pasta `lib/` e o `pubspec.yaml` — as pastas nativas
(`ios/`, `android/`, etc.) precisam ser geradas pelo próprio Flutter na sua máquina,
porque elas dependem da versão do Flutter/Xcode instalada aí.

```bash
# 1. Extraia este zip, entre na pasta do projeto
cd agildo_financas

# 2. Gere as pastas nativas (ios/, android/, etc.) no lugar
flutter create . --project-name agildo_financas --org com.agildosoft

# 3. Baixe as dependências
flutter pub get

# 4. Rode no simulador/emulador ou dispositivo conectado
flutter run
```

O comando `flutter create .` não sobrescreve o `lib/` nem o `pubspec.yaml` que já
existem — ele só completa o que falta (pastas de plataforma, ícone padrão, etc.).

## Rodando no iOS especificamente

```bash
open ios/Runner.xcworkspace
```

e rode a partir do Xcode (ou `flutter run -d <device_id>`), ajustando o Bundle
Identifier e o Team de assinatura na aba "Signing & Capabilities".

## Estrutura do projeto

```
lib/
  main.dart                          # equivalente ao main.cpp
  database_helper.dart               # equivalente ao DatabaseManager
  models.dart                        # Lancamento, Divida, DespesaFixa, Resumo
  utils/
    formatters.dart                  # formatarMoeda, hojeISO, mesAtualISO
  widgets/
    app_button.dart
    toggle_chip.dart
    summary_card.dart
  dialogs/
    editar_lancamento_dialog.dart
    editar_despesa_fixa_dialog.dart
    despesas_fixas_dialog.dart
  screens/
    home_screen.dart                 # equivalente à ApplicationWindow do Main.qml
```

## Observação sobre validação

Este código foi escrito e revisado cuidadosamente, mas **não foi compilado** neste
ambiente (não há Flutter/Dart SDK disponível aqui). Ao rodar `flutter pub get` e
`flutter run` pela primeira vez, se aparecer algum erro de compilação, me envie a
mensagem que eu corrijo rapidamente.
