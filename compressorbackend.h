#pragma once

#include <QObject>
#include <QProcess>
#include <QString>
#include <QElapsedTimer>
#include <QVariantMap>

class CompressorBackend : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isRunning READ isRunning NOTIFY isRunningChanged)
    Q_PROPERTY(QString currentProjectPath READ currentProjectPath NOTIFY currentProjectPathChanged)

public:
    explicit CompressorBackend(QObject *parent = nullptr);
    bool isRunning() const { return m_isRunning; }
    QString currentProjectPath() const { return m_currentProjectPath; }
    Q_INVOKABLE void startCompression(const QString &projectPath, bool isLinuxMode);
    Q_INVOKABLE bool saveToFile(const QString &savePath, const QString &content);
    Q_INVOKABLE void cancelCompression();

    Q_INVOKABLE QVariantMap searchCodeRadar(const QString &projectDir, const QString &target);

signals:
    void isRunningChanged();
    void currentProjectPathChanged();
    void progressUpdated(const QString &statusText);
    void compressionFinished(const QString &resultMarkdown, bool success);

private:
    QProcess *m_process;
    bool m_isRunning;
    QElapsedTimer m_timer;
    void finishProcess(const QString &content, bool success);
    QString m_currentProjectPath;
    bool m_currentMode;
    QString m_lastError;

    QString resolvePython() const;
};