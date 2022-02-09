#ifndef MYIMAGESAVE_H
#define MYIMAGESAVE_H

#include <QObject>
#include <QList>
#include "myimage.h"

class MyImageSave : public QObject
{
    Q_OBJECT
public:
    MyImageSave(QObject *parent = nullptr);
    Q_INVOKABLE bool savePicture(const QString &id, QObject *objectImage);
    Q_INVOKABLE bool writePicture();
private:
    QList<MyImage> mImages;
};

#endif // MYIMAGESAVE_H
