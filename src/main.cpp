#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include "DatabaseManager.h"

int main(int argc, char *argv[])
{
    // "Basic" deixava os botões com texto claro em fundo claro (baixo contraste).
    // "Material" já resolve isso nos controles padrão (TextField, ComboBox etc.);
    // os botões customizados no QML têm cor própria e não dependem do estilo.
    QQuickStyle::setStyle("Material");

    QGuiApplication app(argc, argv);
    app.setApplicationName("Agildo Finanças");
    app.setOrganizationName("AgildoSoft");

    DatabaseManager dbManager;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("db", &dbManager);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);

    engine.loadFromModule("AgildoFinancas", "Main");

    return app.exec();
}
