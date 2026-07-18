#ifndef CHATBACKEND_H
#define CHATBACKEND_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QJsonArray>
#include <QJsonObject>

class ChatBackend : public QObject
{
    Q_OBJECT
    // ⚡ 核心增强：将 API 和模型注册为 QML 属性，实现前后端数据流绝对配准
    Q_PROPERTY(QString apiUrl READ apiUrl NOTIFY configChanged)
    Q_PROPERTY(QString modelName READ modelName NOTIFY configChanged)

public:
    explicit ChatBackend(QObject *parent = nullptr);

    Q_INVOKABLE void sendMessage(const QString &text);
    Q_INVOKABLE void clearHistory();

    // 🎯 补回遗漏的声明：让 QML 也能获取对话统计信息
    Q_INVOKABLE QJsonObject getConversationStats() const;

    // 读写接口
    QString apiUrl() const { return m_currentApiUrl; }
    QString modelName() const { return m_currentModelName; }

    Q_INVOKABLE bool saveConfig(const QString &url, const QString &model);
    Q_INVOKABLE void loadConfig();

signals:
    void messageReceived(const QString &text);
    void configChanged(); // ⚙️ 属性刷新信号

private:
    QNetworkAccessManager *m_networkManager;
    QJsonArray m_messageHistory;

    QString m_currentApiUrl;
    QString m_currentModelName;
};

#endif // CHATBACKEND_H