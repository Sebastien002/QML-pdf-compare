/**
*   @ProjectName:       QMLPdfReader
*   @Brief：
*   @Author:            linjianpeng(lindyer)
*   @Date:              2018-11-16
*   @Note:              Copyright Reserved, Github: https://github.com/lindyer/
*/

#include "cpp/pdfscreenshotprovider.h"
#include "cpp/pdfscreenshotprovider1.h"
#include "cpp/global.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

PdfScreenshotProvider *g_pdfScreenShotProvider = nullptr;
PdfScreenshotProvider1 *g_pdfScreenShotProvider1 = nullptr;

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
//    QDate date(2020,8,13);
//    if(QDate::currentDate() >= date){
//        return -1;
//    }
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    g_pdfScreenShotProvider = new PdfScreenshotProvider();
    g_pdfScreenShotProvider1 = new PdfScreenshotProvider1();

    engine.addImageProvider("PdfScreenshot",g_pdfScreenShotProvider);
    engine.addImageProvider("PdfScreenshot1",g_pdfScreenShotProvider1);
    engine.rootContext()->setContextProperty("pdfUtil",g_pdfScreenShotProvider);
    engine.rootContext()->setContextProperty("pdfUtil1",g_pdfScreenShotProvider1);
    engine.rootContext()->setContextProperty("global",Global::instance());
    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
