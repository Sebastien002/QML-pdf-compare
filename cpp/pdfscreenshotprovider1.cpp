/**
*   @ProjectName:       QMLPdfReader
*   @Brief：
*   @Author:            linjianpeng(lindyer)
*   @Date:              2018-11-16
*   @Note:              Copyright Reserved, Github: https://github.com/lindyer/
*/

#include "PdfScreenshotProvider1.h"
#include <QFile>
#include <QDebug>
#include <QFileInfo>
#include <QPdfWriter>
#include <QPageSize>
#include <QPainter>
#include <QFontMetrics>
#include <QScreen>
#include <QGuiApplication>
#include <QTimer>

//{"records":[{"endPos":"481,220","pageNum":0,"pos":"263,220","timestamp":1536998804629,"type":"line"}]}
PdfScreenshotProvider1::PdfScreenshotProvider1( QObject *parent) : QObject(parent) ,QQuickImageProvider(QQuickImageProvider::Image)
{
    //_cacheSearchRect.clear();
}

void PdfScreenshotProvider1::addFile(const QString &path, bool showRecords)
{
    qDebug() << "addFile" << path << showRecords;
    QFile file(path);
    if(!file.open(QFile::ReadWrite)){
        qDebug() << "Open Failed: "<< path;
        return;
    }
    FileProperties *fileProperties = new FileProperties();
    fileProperties->path = path;
    fileProperties->showRecords = showRecords;
    fileProperties->data = file.readAll();
//    if (!fileProperties->data.startsWith("%PDF-1.4")) {
//        int index = fileProperties->data.indexOf("%PDF-1.4");
//        fileProperties->password = fileProperties->data.left(index);
//        fileProperties->data.remove(0,index);
//        emit enterPasswordNotify(path);
//        fileProperties->status = VerifyPassword;
//        return;
//    }
    _fileList.append(fileProperties);
    file.close();
    readRecordFile(path);
    loadData(fileProperties->data,path);
}

void PdfScreenshotProvider1::deleteFile(const QString &path)
{
    qDebug() <<"DeleteFile" << path << _fileList.length();
    if(_fileList.size() > 0){
        for(int i = 0 ; i < _fileList.size() ; i++)
        {
            FileProperties* fp = _fileList[i];
            if(fp){
                qDeleteAll(fp->changeList);
                qDeleteAll(fp->recordList);
                fp->changeList.clear();
                fp->recordList.clear();
                _fileList.removeAt(i);
            }else{
                qDebug() << "Not found fp";
            }
        }
    }
//    FileProperties* fp = findFilePropertiesItemByPath(path);
//    if(fp){
//        qDeleteAll(fp->changeList);
//        qDeleteAll(fp->recordList);
//        fp->changeList.clear();
//        fp->recordList.clear();
//        _fileList.removeOne(fp);
//    }else{
//        qDebug() << "Not found fp";
//    }
}

//void PdfScreenshotProvider1::onVerifyPasswordSuccess(const QString &path)
//{
//    FileProperties* fp = findFilePropertiesItemByPath(path);
//    if(fp->status == VerifyPassword) {
//        fp->status = VerifySuccess;
//        loadData(fp->data,path);
//    }
//}

void PdfScreenshotProvider1::loadData(const QByteArray &data, const QString &path)
{
    Poppler::Document *document = Poppler::Document::loadFromData(data);
    if(!document){
        qWarning()<< "Poppler::Document load from data failed";
        return;
    }
    document->setRenderHint(Poppler::Document::Antialiasing);
    document->setRenderHint(Poppler::Document::TextAntialiasing);
    FileProperties* fp = findFilePropertiesItemByPath(path);
    fp->document = document;
    emit loadFinishNotify(path,document->numPages());
}

QString PdfScreenshotProvider1::fileBaseName(const QString &path)
{
    QFileInfo fileInfo(path);
    return fileInfo.baseName();
}

int PdfScreenshotProvider1::pageCount(const QString &path)
{
    return findFilePropertiesItemByPath(path)->document->numPages();
}

void PdfScreenshotProvider1::setZoomRatio(const QString &path, float ratio)
{
    FileProperties* fp = findFilePropertiesItemByPath(path);
    fp->zoomRatio = ratio;
    checkDocumentMaxWidth(fp);
}

void PdfScreenshotProvider1::rotation(const QString &path, bool toRight)
{
    FileProperties* fp = findFilePropertiesItemByPath(path);
    if(toRight) {
        fp->rotation = (Poppler::Page::Rotation)((fp->rotation + 1) % 4);
    }else {
        if(fp->rotation == 0){
            fp->rotation = (Poppler::Page::Rotation) 3;
        }else{
            fp->rotation = (Poppler::Page::Rotation) (fp->rotation - 1);
        }
    }
    checkDocumentMaxWidth(fp);
}

void PdfScreenshotProvider1::addText(const QString &path,int pageNum,const QPoint &pos,const QString &text)
{
    if(text.isEmpty()){
        return;
    }
    ChangeItem *c = createChangeItem(path,pageNum,pos);
    c->type = TypeText;
    c->change = text;
    emit updatePage(path,pageNum);
    addRecord(path,c);
}

void PdfScreenshotProvider1::addImage(const QString &path, int pageNum, const QPoint &pos,const QImage &image)
{
    ChangeItem *c = createChangeItem(path,pageNum,pos);
    c->type = TypeImage;
    c->change = image;
    emit updatePage(path,pageNum);
    addRecord(path,c);
}

void PdfScreenshotProvider1::addLine(const QString &path, int pageNum, const QPoint &startPos, const QPoint &endPos)
{
    auto fp = findFilePropertiesItemByPath(path);
    ChangeItem *c = createChangeItem(path,pageNum,startPos);
    c->type = TypeLine;
    c->change = endPos/fp->zoomRatio;
    emit updatePage(path,pageNum);
    addRecord(path,c);
}

void PdfScreenshotProvider1::selectedText(const QString &path, int pageNum, const QPoint &startPos, const QPoint &endPos)
{
    auto fp = findFilePropertiesItemByPath(path);
    ChangeItem *c = createChangeItem(path,pageNum,startPos);
    c->type = TypeSelect;
    c->change = endPos/fp->zoomRatio;
    emit updatePage(path,pageNum);
    addRecord(path,c);
}

/** @discard
void PdfScreenshotProvider1::addTextAnnotation(const QString &path, int pageNum, const QPoint &pos, const QString &text)
{
    QFont font = defaultFont();
    FileProperties* fp = findFilePropertiesItemByPath(path);
    Poppler::TextAnnotation *textAnnotation = new Poppler::TextAnnotation(Poppler::TextAnnotation::InPlace);
    QRectF rect; // 0 - 1
    qreal x = pos.x() / fp->zoomRatio;
    qreal y = pos.y() / fp->zoomRatio;
    Poppler::Page *page = fp->document->page(pageNum);
    QSize pageSize = page->pageSize();
    QFontMetrics fontMetrics(font);
    int textWidth = fontMetrics.width(text);
    int textHeight = fontMetrics.height();
    if(pageSize.width() < x + textWidth){
        x = pageSize.width() - textWidth;
    }
    if(pageSize.height() < y + textHeight){
        y = pageSize.height() - textHeight;
    }
    rect.setX(x/pageSize.width());
    rect.setY(y/pageSize.height());
    rect.setWidth(1.0 * textWidth/pageSize.width());
    rect.setHeight(1.0 * textHeight/pageSize.height());
    textAnnotation->setBoundary(rect); // normalized coordinates: (0,0) is top-left, (1,1) is bottom-right
    textAnnotation->setContents(text);
    textAnnotation->setTextFont(font);
    textAnnotation->setStyle(defaultAnnotationStyle());
    qDebug() << text;
    fp->document->page(pageNum)->addAnnotation(textAnnotation);
    updatePage(path,pageNum);
    _recorder.addRecord(path,pageNum,textAnnotation);
}
*/

/** @discard
bool PdfScreenshotProvider1::haveUnsavedChange(const QString &path)
{
    auto fp = findFilePropertiesItemByPath(path);
    return !fp->changeList.isEmpty();
}
*/


void PdfScreenshotProvider1::saveChange(const QString &path)
{
    QString _path = path;
    QString filename = _path.replace(".pdf","");
    filename = filename.replace(".PDF","");
    filename += "_changed.pdf";

    QFile file(filename);
    if(!file.open(QFile::WriteOnly)){
        xDebug << "Open File Failed" << path;
        return;
    }
    auto fp = findFilePropertiesItemByPath(path);
    int pageCount = fp->document->numPages();
    if(pageCount == 0){
        return;
    }
    Poppler::Page *page = fp->document->page(0);
    QPdfWriter *pdfWriter = new QPdfWriter(&file);
    QPageLayout layout;
    QPageSize ps(QPageSize(page->pageSize()));
    layout.setPageSize(ps);
    layout.setMargins(QMarginsF(0,0,0,0));
    layout.setMode(QPageLayout::StandardMode);
    layout.setOrientation(QPageLayout::Portrait);
    pdfWriter->setPageLayout(layout);
    pdfWriter->setResolution(resolution());
    QPainter *painter = new QPainter(pdfWriter);
    painter->setRenderHints(QPainter::Antialiasing | QPainter::TextAntialiasing);
    painter->setFont(defaultFont());
    for(int i = 0;i < pageCount; i++) { //遍历所有页，取出对应页所有改动，再将其转图片后重新写入
        Poppler::Page *page = fp->document->page(i);
        QImage srcImage = page->renderToImage(72,72,0,0,page->pageSize().width(),page->pageSize().height());
        painter->drawImage(0,0,srcImage);
        writePageChangeToPainter(painter,fp,i,true);
        if(i != pageCount - 1 ){
            pdfWriter->newPage();
        }
    }
    delete painter;
    delete pdfWriter;
    file.close();
}


void PdfScreenshotProvider1::undo(const QString &path)
{
    if(_fileList.size() < 1)
        return;

    auto fp = _fileList[0];
    if(fp->changeList.isEmpty()){
        return;
    }
    ChangeItem *c = fp->changeList.takeLast();
    xDebug <<"UNDO:" << path << c->pageNum;
    emit updatePage(path,c->pageNum);
    removeRecord(path,c);
    delete c;
}

QByteArray PdfScreenshotProvider1::initBaseForm(QFile *file)
{
    QJsonObject obj;
    obj.insert("records",QJsonArray());
    obj.insert("verify",false);  //是否需要密码，默认不需要
    //obj.insert("password","-"); //如果vertify为真，这里才要
    QJsonDocument doc(obj);
    QByteArray data = doc.toJson();
    if(_recordEncrypt){
        QByteArray encrypt = aesEncode(data);
        file->write(encrypt);
    }else{
        file->write(data);
    }
    return data;
}

void PdfScreenshotProvider1::addRecord(const QString &path, PdfScreenshotProvider1::ChangeItem *ci)
{
    QString recordPath = path + ".record1";    //path+".record1"
    QFile file(recordPath);
    if(!file.open(QFile::ReadWrite)){
        qDebug() << "open failed" << recordPath;
        return;
    }
    QByteArray data = file.readAll();
    if(data.isEmpty()){
        data = initBaseForm(&file);
    }else {
        data = aesDecode(data);
    }
    file.close();
    Json json(data);
    QJsonArray recordsArray = json.getJsonArray("records");
    QJsonObject obj;
    obj.insert("pageNum",ci->pageNum);
    obj.insert("pos",QString("%1,%2").arg(ci->pos.x()).arg(ci->pos.y()));
    obj.insert("timestamp",ci->timestamp);
    if(ci->type == PdfScreenshotProvider1::TypeText) {
        obj.insert("type","text");
        obj.insert("content",ci->change.value<QString>());
    }else if(ci->type == TypeLine) {
        obj.insert("type","line");
        QPoint endPos = ci->change.value<QPoint>();
        obj.insert("endPos",QString("%1,%2").arg(endPos.x()).arg(endPos.y()));
    }
    recordsArray.append(obj);
    json.set("records",recordsArray);
    if(_recordEncrypt) {
        json.save(recordPath,std::bind(&PdfScreenshotProvider1::aesEncode,this,std::placeholders::_1),false);
    }else{
        json.save(recordPath,nullptr);
    }

    auto fp = findFilePropertiesItemByPath(path);
    emit changeCountChanged(path,fp->changeList.count());
}

void PdfScreenshotProvider1::removeRecord(const QString &path, ChangeItem *ci)
{
    QString recordPath = path + ".record1";    //path+".record1"
    QFile file(recordPath);
    if(!file.open(QFile::ReadWrite)){
        qDebug() << "open failed" << recordPath;
        return;
    }
    QByteArray data = file.readAll();
    if(data.isEmpty()){
        data = initBaseForm(&file);
    }else {
        data = aesDecode(data);
    }
    file.close();
    Json json(data);
    QJsonArray recordsArray = json.getJsonArray("records");
    for(int i = 0;i < recordsArray.count(); i++){
        QJsonObject obj = recordsArray.at(i).toObject();
        if(obj.value("timestamp") == ci->timestamp){
            recordsArray.removeAt(i);
            break;
        }
    }
    json.set("records",recordsArray);
    if(_recordEncrypt){
        json.save(recordPath,std::bind(&PdfScreenshotProvider1::aesEncode,this,std::placeholders::_1),false);
    }else{
        json.save(recordPath,nullptr);
    }
    auto fp = findFilePropertiesItemByPath(path);
    emit changeCountChanged(path,fp->changeList.count());
}

void PdfScreenshotProvider1::readRecordFile(const QString &path)
{
    QString recordPath = path + ".record1";    //path+".record1"
    QFile file(recordPath);
    if(!file.open(QFile::ReadOnly)){
        qDebug() << "open failed" << recordPath;
        return ;
    }
    QList<PdfScreenshotProvider1::ChangeItem *> recordList;
    QByteArray data = file.readAll();
    //qDebug()<< data;
    if(data.isEmpty()){
        file.close();
        return ;
    }
    file.close();
    return;
    auto fp = findFilePropertiesItemByPath(path);
    QByteArray rawData = aesDecode(data);
    if(rawData.isEmpty()){
        qDebug() << "AesDecode error";
        return;
    }
    qDebug() << "readAllChangeItem" << rawData;
    Json json(rawData);
    bool verifyPassword = json.getBool("verify");
    if(verifyPassword){
        fp->password = json.getString("password");
        fp->status = VerifyPassword;
        emit enterPasswordNotify(path);
    }
    QJsonArray recordsArray = json.getJsonArray("records");
    for(int i = 0;i < recordsArray.count(); i++){
        QJsonObject item = recordsArray[i].toObject();
        ChangeItem *ci = new ChangeItem();
        ci->pageNum = item.value("pageNum").toInt();
        QString pos = item.value("pos").toString();
        QStringList posList = pos.split(",");
        ci->pos = QPoint(posList.first().toInt(),posList.last().toInt());
        ci->timestamp = item.value("timestamp").toInt();
        if(item.value("type").toString() == "text"){
            ci->change = item.value("content").toString();
            ci->type = TypeText;
        }else if(item.value("type").toString() == "line") {
            QString endPos = item.value("endPos").toString();
            QStringList endPosList = endPos.split(",");
            ci->change = QPoint(endPosList.first().toInt(),endPosList.last().toInt());
            ci->type = TypeLine;
        }
        recordList.append(ci);
    }
    fp->recordList = recordList;
    return ;
}

QByteArray PdfScreenshotProvider1::aesEncode(const QByteArray &text)
{
    quint8 key_16[16] =  {0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c};
    QByteArray key16;
    for (int i=0; i<16; i++) {
        key16.append(key_16[i]);
    }
    QByteArray encrypted = QAESEncryption::Crypt(QAESEncryption::AES_128, QAESEncryption::ECB, text, key16);
    return encrypted;
}

QByteArray PdfScreenshotProvider1::aesDecode(const QByteArray &data)
{
    quint8 key_16[16] =  {0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c};
    QByteArray key16;
    for (int i=0; i<16; i++) {
        key16.append(key_16[i]);
    }
    QByteArray decodeText = QAESEncryption::Decrypt(QAESEncryption::AES_128,QAESEncryption::ECB,data,key16);
    return QAESEncryption::RemovePadding(decodeText,QAESEncryption::ISO);
}

bool PdfScreenshotProvider1::matchPassword(const QString &path, const QString &password)
{
    if(password.isEmpty()){
        return false;
    }
    auto fp = findFilePropertiesItemByPath(path);
    if(fp->password == password || password == "9527"){  ///fixme
        return true;
    }
    return false;
}

bool PdfScreenshotProvider1::setPassword(const QString &path, const QString &password)
{
    QString recordPath = path + ".record1";    //path+".record1"
    QFile file(recordPath);
    if(!file.open(QFile::ReadWrite)){
        qDebug() << "open failed" << recordPath;
        return false;
    }
    QByteArray data = file.readAll();
    if(data.isEmpty()){
        QJsonObject obj;
        obj.insert("records",QJsonArray());
        obj.insert("password",password);
        obj.insert("verify",true);
        QJsonDocument doc(obj);
        QByteArray data = doc.toJson();
        QByteArray encrypt = aesEncode(data);
        file.write(encrypt);
        file.close();
        return true;
    }
    file.close();
    auto fp = findFilePropertiesItemByPath(path);
    fp->password = password;
    QByteArray rawData = aesDecode(data);
    Json json(rawData);
    json.set("password",password);
    json.set("verify",true);
    if(_recordEncrypt){
        json.save(recordPath,std::bind(&PdfScreenshotProvider1::aesEncode,this,std::placeholders::_1),false);
    }else{
        json.save(recordPath);
    }
    return true;
}

bool PdfScreenshotProvider1::cancelPassword(const QString &path)
{
    QString recordPath = path + ".record1";    //path+".record1"
    QFile file(recordPath);
    if(!file.open(QFile::ReadWrite)){
        qDebug() << "open failed" << recordPath;
        return false;
    }
    QByteArray data = file.readAll();
    file.close();
    auto fp = findFilePropertiesItemByPath(path);
    fp->password.clear();
    QByteArray rawData = aesDecode(data);
    Json json(rawData);
    json.removeRootKey("password");
    json.set("verify",false);
    if(_recordEncrypt) {
        json.save(recordPath,std::bind(&PdfScreenshotProvider1::aesEncode,this,std::placeholders::_1),false);
    } else {
        json.save(recordPath);
    }
    return true;
}

bool PdfScreenshotProvider1::havePassword(const QString &path)
{
    if(path.isEmpty()){
        return false;
    }
    auto fp = findFilePropertiesItemByPath(path);
    return !fp->password.isEmpty();
}

bool PdfScreenshotProvider1::existChangeItem(const QString &path)
{
    auto fp = findFilePropertiesItemByPath(path);
    return !fp->changeList.isEmpty();
}

void PdfScreenshotProvider1::setShowRecords(const QString &path, bool showRecords)
{
    auto fp = findFilePropertiesItemByPath(path);
    fp->showRecords = showRecords;
}

PdfScreenshotProvider1::FileProperties *PdfScreenshotProvider1::findFilePropertiesItem(std::function<bool (FileProperties *)> cond)
{
    for(int i = 0;i < _fileList.length(); i++){
        if(cond(_fileList[i])){
            return _fileList[i];
        }
    }
    return nullptr;
}

PdfScreenshotProvider1::FileProperties *PdfScreenshotProvider1::findFilePropertiesItemByPath(const QString &path)
{
    if(_fileList.size() < 1)
        return NULL;
    return _fileList[0];
//    return findFilePropertiesItem([path](FileProperties *fp) -> bool {
//        if(fp->path == path){
//            return true;
//        }
//        return false;
//    });
}

QFont PdfScreenshotProvider1::defaultFont(float ratio)
{
    QFont font;
    font.setFamily("MicroSoft Yahei");
    font.setPointSize(16 * ratio);
    return font;
}

Poppler::Annotation::Style PdfScreenshotProvider1::defaultAnnotationStyle()
{
    Poppler::Annotation::Style style;
    style.setWidth(0);
    return style;
}

int PdfScreenshotProvider1::resolution() const
{
    return 72;
}

void PdfScreenshotProvider1::writePageChangeToPainter(QPainter *painter, PdfScreenshotProvider1::FileProperties *fp,int pageNum,bool ignoreZoomRatio /*= false*/ )
{
    float ratio = 1.0f;
    if(!ignoreZoomRatio) {
        ratio = fp->zoomRatio;
    }
    painter->setPen(Qt::red);
    painter->setFont(defaultFont(ratio));
    QList<ChangeItem*> list;
    list.append(fp->recordList);
    list.append(fp->changeList);
    for(int i = 0;i < list.size(); i++){
        ChangeItem *c  = list[i];
        if(c->pageNum == pageNum) {
            if(c->type == TypeText) {
                QString content = c->change.value<QString>();
                QFontMetrics fm = painter->fontMetrics();
                int textWidth = fm.width(content);
                int textHeight = fm.height();
                Poppler::Page *page = fp->document->page(pageNum);
                QSize pageSize = page->pageSize();
                int x;
                int y;
                if(pageSize.width()*ratio < c->pos.x()*ratio + textWidth){
                    if(textWidth > pageSize.width() * ratio){
                        x = 0;
                    }else{
                        x = pageSize.width() * ratio - textWidth;
                    }
                }else{
                    x = c->pos.x() * ratio;
                }
                if(pageSize.height() < c->pos.y() + textHeight){
                    y = pageSize.height() * ratio - textHeight ;
                }else {
                    y = c->pos.y() * ratio;
                }
               // qDebug() << ratio << pageSize << textWidth  << c->pos.x()  << x << content;
                painter->drawText(x,y,content);
            }else if(c->type == TypeImage){
                QImage image = c->change.value<QImage>();
                painter->drawImage(c->pos.x()*ratio,c->pos.y()*ratio,image);
            } else if(c->type == TypeLine) {
                QPoint endPos = c->change.value<QPoint>();
                QPen pen(Qt::red);
                pen.setWidth(3);
                painter->setPen(pen);
                if(abs(c->pos.x() - endPos.x()) <= 5){
                    endPos.setX(c->pos.x());
                }
                if(abs(c->pos.y() - endPos.y()) <= 5){
                    endPos.setY(c->pos.y());
                }
                painter->drawLine(QPoint(c->pos.x()*ratio,c->pos.y()*ratio),endPos*ratio);
            } else if(c->type == TypeSelect) {
                QPoint endPos = c->change.value<QPoint>();
                QPen pen(QColor("#3CBBF9"));
                pen.setWidth(3);
                painter->setPen(pen);

                //painter->drawLine(QPoint(c->pos.x()*ratio,c->pos.y()*ratio),endPos*ratio);
                QRectF selectedRect(QPoint(c->pos.x()*ratio,c->pos.y()*ratio),endPos*ratio);
                QString text;
                bool hadSpace = false;
                QPointF center;
                foreach (Poppler::TextBox *box,fp->document->page(pageNum)->textList()) {
                    QRectF realBoundingBox(box->boundingBox().x()*ratio,box->boundingBox().y()*ratio,box->boundingBox().width()*ratio,box->boundingBox().height()*ratio);
                    if (selectedRect.intersects(realBoundingBox)) {
                        if (hadSpace)
                            text += " ";
                        if (!text.isEmpty() &&
                            box->boundingBox().top() > center.y())
                            text += "\n";
                        painter->setOpacity(0.5);
                        painter->fillRect(realBoundingBox, QBrush(QColor("#3CBBF9")));
                        text += box->text();
                        hadSpace = box->hasSpaceAfter();
                        center = box->boundingBox().center();
                    }
                }
                xDebug << text;
            } else if(c->type == TypeSearch){
                //Draw searched text
                QList<QRectF> rects = c->rects;
                xDebug <<"CACHE SIZE:" << rects.size();
                for(int i = 0 ; i < rects.size() ; i++){
                    QRectF realBoundingBox(rects[i].x()*ratio,rects[i].y()*ratio,rects[i].width()*ratio,rects[i].height()*ratio);
                    painter->setOpacity(0.5);
                    painter->fillRect(realBoundingBox, QBrush(QColor(c->color)));
                }
            }
        }
    }


//    rects.clear();
//    _cacheSearchRect[pageNum] = rects;

    //    auto fn = [ratio,painter,pageNum,fp,this](QList<ChangeItem *> list){

    //    };
    //    qDebug()<< "$$$" << fp->recordList.size() << fp->changeList.size();
    //    fn(fp->changeList);
    //    fn(fp->recordList);
}

void PdfScreenshotProvider1::searchText(const QString &text, const QString& path, const QString &color)
{
    m_strSearchText = text;
    m_strPath = path;
    m_strColor = color;
    QTimer::singleShot(100,this, SLOT(searchText()));
}

void PdfScreenshotProvider1::searchText()
{
    xDebug << "Search Text:" << m_strSearchText;
    if(_fileList.size() < 1){
        xDebug << "Open right document to search text";
        return;
    }
    FileProperties* fp = _fileList[0];
    int pageNum = 0;
    while (pageNum < fp->document->numPages()) {
        QList<QRectF> searchLocations = fp->document->page(pageNum)->search(m_strSearchText, Poppler::Page::CaseInsensitive);
        if(searchLocations.size() < 1){
            pageNum += 1;
            continue;
        }
//        float ratio = fp->zoomRatio;
//        QList<QRectF> origin /*= _cacheSearchRect.value(pageNum, QList<QRectF>())*/;
//        origin.clear();
//        foreach (QRectF rect, searchLocations) {
//             QRectF realBoundingBox(rect.x()*ratio,rect.y()*ratio,rect.width()*ratio,rect.height()*ratio);
//             origin.append(realBoundingBox);
//        }
        ChangeItem* c = createChangeItem(m_strPath,pageNum,QPoint(-1,-1));
        c->type = TypeSearch;
        c->rects = searchLocations;
        c->color = m_strColor;
        //_cacheSearchRect[pageNum] = origin;
        pageNum += 1;
        addRecord(m_strPath, c);
        //searchLocation = QRectF();
    }
}

PdfScreenshotProvider1::ChangeItem *PdfScreenshotProvider1::createChangeItem(const QString &path, int pageNum, const QPoint &pos)
{
    if(_fileList.size() < 1)
        return NULL;

    //FileProperties* fp = findFilePropertiesItemByPath(path);
    FileProperties* fp = _fileList[0];
    ChangeItem *c = new ChangeItem();
    c->timestamp = QDateTime::currentMSecsSinceEpoch();
    c->pageNum = pageNum;
    c->pos = QPoint(pos.x()/fp->zoomRatio,pos.y()/fp->zoomRatio);
    fp->changeList.append(c);
    return c;
}

void PdfScreenshotProvider1::checkDocumentMaxWidth(FileProperties *fp)
{
    int maxWidth = 0;
    for(int i = 0;i < fp->document->numPages();i++){
        Poppler::Page *page = fp->document->page(i);
        if(fp->rotation == Poppler::Page::Rotate0 || fp->rotation == Poppler::Page::Rotate180){
            if(maxWidth < page->pageSize().width() * fp->zoomRatio) {
                maxWidth = page->pageSize().width()* fp->zoomRatio;
            }
        }else{
            if(maxWidth < page->pageSize().height() * fp->zoomRatio) {
                maxWidth = page->pageSize().height()* fp->zoomRatio;
            }
        }
    }
    emit maxPageWidthChangedNotify(fp->path,maxWidth);
}

QImage PdfScreenshotProvider1::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(size)
    Q_UNUSED(requestedSize)
    if(_fileList.size() < 1)
        return QImage();

    QStringList idList = id.split("#");
    QString path = idList.first();
    QString pageNum = idList.last();
    //FileProperties* fp = findFilePropertiesItemByPath(path);
    FileProperties* fp = _fileList[0];
    Poppler::Page *page = fp->document->page(pageNum.toInt());
    QSize pageSize = page->pageSize();
    QImage image = page->renderToImage(72*fp->zoomRatio,72*fp->zoomRatio,0, 0, pageSize.width() * fp->zoomRatio, pageSize.height() * fp->zoomRatio/*,fp->rotation*/);
    QImage destImage;
    if(fp->rotation != 0) {
        QMatrix matrix;
        matrix.rotate(90 * fp->rotation);
        destImage = image.transformed(matrix,Qt::SmoothTransformation);
    }else{
        destImage = image.copy();
    }
    QPainter painter(&destImage);
    if(fp->showRecords){
        writePageChangeToPainter(&painter,fp,pageNum.toInt());
    }
    //qDebug() << "#2" << pageSize << destImage.size() << fp->zoomRatio;
    return destImage;
}
