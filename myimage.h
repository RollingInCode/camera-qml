#ifndef MYIMAGE_H
#define MYIMAGE_H

#include <QByteArray>
#include <QString>

class MyImage
{
public:
    MyImage(const QString &id = "", const QByteArray &data = QByteArray());
    void setData(const QByteArray &data);
    void setId(const QString &id);
    QByteArray data() const;
    QString id() const;
private:
    QByteArray mData;
    QString mId;
};



#endif // MYIMAGE_H
