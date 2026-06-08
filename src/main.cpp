#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow> // 🚀 引入 Window 控制
#include "CompressorBackend.h"
#include "ChatBackend.h"

int main(int argc, char *argv[])
{
    // 用环境变量强行锁定为 Basic 基础样式
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
    qputenv("QT_VIRTUALKEYBOARD_STYLE", "dark");

    QGuiApplication app(argc, argv);

    // 注册后端 C++ 模块到 QML
    qmlRegisterType<CompressorBackend>("App.Backend", 1, 0, "CompressorBackend");
    qmlRegisterType<ChatBackend>("App.Backend", 1, 0, "ChatBackend");

    QQmlApplicationEngine engine;

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);

    engine.loadFromModule("AIAgent_ContextCompressor", "Main");

    return app.exec();
}