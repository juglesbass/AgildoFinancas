#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include "DatabaseManager.h"

int main(int argc, char *argv[])
{
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
