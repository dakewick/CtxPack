#pragma once

#include <QObject>
#include <QProcess>
#include <QString>
#include <QElapsedTimer>

class CompressorBackend : public QObject {
    Q_OBJECT
    // ✅ 必须添加这一行，否则 QML 无法访问 isRunning
    Q_PROPERTY(bool isRunning READ isRunning NOTIFY isRunningChanged)

public:
    explicit CompressorBackend(QObject *parent = nullptr);
    bool isRunning() const { return m_isRunning; } // ✅ 添加 getter
    Q_INVOKABLE void startCompression(const QString &projectPath, bool isLinuxMode);
    Q_INVOKABLE bool saveToFile(const QString &savePath, const QString &content);
    Q_INVOKABLE void cancelCompression();  // 取消压缩

signals:
    void isRunningChanged();
    void progressUpdated(const QString &statusText);
    // ✅ 保持2个参数
    void compressionFinished(const QString &resultMarkdown, bool success);

private:
    QProcess *m_process;
    bool m_isRunning;
    QElapsedTimer m_timer;
    void finishProcess(const QString &content, bool success);
    QString m_currentProjectPath;  // 当前项目路径
    bool m_currentMode;            // 当前模式
    QString m_lastError;           // 最后一次错误
};