#ifndef GLOBAL_H
#define GLOBAL_H

/**
*   @ProjectName:       QMLPdfReader
*   @Brief：
*   @Author:            linjianpeng(lindyer)
*   @Date:              2018-11-16
*   @Note:              Copyright Reserved, Github: https://github.com/lindyer/
*/

#include "utils/json.h"

#include <QObject>
#include <QDebug>
#include <QFileInfo>
#include <QScreen>
#include <QUrl>
#include "pdfscreenshotprovider.h"
#include "pdfscreenshotprovider1.h"

class PdfScreenshotProvider;
class PdfScreenshotProvider1;

extern PdfScreenshotProvider *g_pdfScreenShotProvider;
extern PdfScreenshotProvider1 *g_pdfScreenShotProvider1;

#define FILE_BASENAME []()->QString{ QFileInfo fi(__FILE__); return fi.baseName(); }
#define xDebug qDebug() << QString("%1(%2)[%3]").arg(FILE_BASENAME()).arg(__FUNCTION__).arg(__LINE__)



class Global: public QObject
{
    Q_OBJECT
private:
    Global();

public slots:
    static Global *instance();
    QString urlBaseName(const QUrl &url);
    QString urlPath(const QUrl &url);
    float fontSizeRatio();

private:
    void loadConfig();
    const QString configFile = "app.conf";
    Json *json = nullptr;
    static Global* global;
};

#endif // GLOBAL_H
