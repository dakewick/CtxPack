#pragma once

#include <QObject>
#include <QProcess>
#include <QString>
#include <QVariantMap>
#include <QStringList>

class GitBackend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentRepoPath READ currentRepoPath NOTIFY currentRepoPathChanged)
    Q_PROPERTY(bool isGitAvailable READ isGitAvailable)
    Q_PROPERTY(bool hasRepo READ isRepoInitialized NOTIFY repoInitializedChanged)

public:
    explicit GitBackend(QObject *parent = nullptr);

    QString currentRepoPath() const { return m_currentRepoPath; }
    Q_INVOKABLE bool isGitAvailable() const;
    Q_INVOKABLE bool isRepoInitialized();

    Q_INVOKABLE void setRepoPath(const QString &path);

    Q_INVOKABLE QVariantMap initRepo(bool createGitIgnore = true, const QString &branchName = QString());
    Q_INVOKABLE QVariantMap getStatus();
    Q_INVOKABLE QVariantMap getBranches();
    Q_INVOKABLE QVariantMap createBranch(const QString &branchName);
    Q_INVOKABLE QVariantMap deleteBranch(const QString &branchName, bool force = false);
    Q_INVOKABLE QVariantMap checkoutBranch(const QString &branchName);
    Q_INVOKABLE QVariantMap mergeBranch(const QString &sourceBranch);
    Q_INVOKABLE QVariantMap abortMerge();
    Q_INVOKABLE QVariantMap commitChanges(const QString &message);

    Q_INVOKABLE QVariantMap addFile(const QString &file);
    Q_INVOKABLE QVariantMap discardFile(const QString &file);

    Q_INVOKABLE QVariantMap getCommitHistory(int limit = 10);
    Q_INVOKABLE QVariantMap resetToCommit(const QString &hash);

    Q_INVOKABLE QVariantMap getTags();
    Q_INVOKABLE QVariantMap createTag(const QString &name, const QString &message, const QString &hash);
    Q_INVOKABLE QVariantMap deleteTag(const QString &name);

signals:
    void currentRepoPathChanged();
    void repoInitializedChanged();

private:
    QString m_currentRepoPath;

    QVariantMap runGitCmd(const QStringList &args, int timeoutMs = 5000);
    QString cleanPath(const QString &path) const;
    void writeGitIgnore(const QString &repoPath);
};
