#include "gitbackend.h"
#include <QDir>
#include <QUrl>
#include <QFile>
#include <QTextStream>
#include <QEventLoop>
#include <QTimer>
#include <QDebug>
#include <QVariantList>

GitBackend::GitBackend(QObject *parent) : QObject(parent) {
}

bool GitBackend::isGitAvailable() const {
    QProcess testProcess;
    testProcess.start("git", QStringList() << "--version");
    testProcess.waitForFinished(1000);
    return (testProcess.exitCode() == 0);
}

bool GitBackend::isRepoInitialized() {
    if (m_currentRepoPath.isEmpty())
        return false;
    QDir repoDir(m_currentRepoPath);
    if (!repoDir.exists())
        return false;
    return repoDir.exists(".git");
}

void GitBackend::setRepoPath(const QString &path) {
    QString cleaned = cleanPath(path);
    if (m_currentRepoPath != cleaned) {
        m_currentRepoPath = cleaned;
        emit currentRepoPathChanged();
        emit repoInitializedChanged();
        qDebug() << "[GitBackend] repo path set:" << m_currentRepoPath;
    }
}

QVariantMap GitBackend::initRepo(bool createGitIgnore, const QString &branchName) {
    QStringList args;
    args << "init";
    QString branch = branchName.trimmed();
    if (!branch.isEmpty())
        args << "-b" << branch;

    QVariantMap result = runGitCmd(args);

    if (result["status"] == "error" && !branch.isEmpty()
        && result["message"].toString().contains("unknown option", Qt::CaseInsensitive)) {
        result = runGitCmd(QStringList() << "init");
        if (result["status"] == "success") {
            runGitCmd(QStringList() << "symbolic-ref" << "HEAD" << "refs/heads/" + branch);
        }
    }

    if (result["status"] == "success" && createGitIgnore) {
        writeGitIgnore(m_currentRepoPath);
        result["output"] = result["output"].toString() + "\n.gitignore created";
    }
    emit repoInitializedChanged();
    return result;
}

QVariantMap GitBackend::getStatus() {
    QVariantMap result = runGitCmd(QStringList() << "status" << "-s");
    if (result["status"] != "success")
        return result;

    QString raw = result["output"].toString();
    QStringList lines = raw.split("\n", Qt::SkipEmptyParts);
    QVariantList list;

    for (const QString &line : lines) {
        if (line.length() < 4) continue;

        QString stateCode = line.left(3).trimmed();
        QString filePath = line.mid(3).trimmed();

        QVariantMap item;
        item["state"] = stateCode;
        item["isUntracked"] = (stateCode == "??");

        if (stateCode == "R" && filePath.contains(" -> ")) {
            int arrowIdx = filePath.indexOf(" -> ");
            item["file"] = filePath.mid(arrowIdx + 4);
            item["oldFile"] = filePath.left(arrowIdx);
        } else {
            item["file"] = filePath;
        }

        list.append(item);
    }

    result["list"] = list;
    return result;
}

QVariantMap GitBackend::getBranches() {
    QVariantMap result = runGitCmd(QStringList()
        << "for-each-ref"
        << "--sort=-committerdate"
        << "--format=%(refname)%09%(refname:short)%09%(objectname:short)%09%(committerdate:format:%m-%d %H:%M)%09%(HEAD)%09%(upstream:track)"
        << "refs/heads" << "refs/remotes");

    if (result["status"] != "success")
        return result;

    QString raw = result["output"].toString();
    QVariantList list;

    if (!raw.isEmpty()) {
        QStringList lines = raw.split("\n", Qt::SkipEmptyParts);
        for (const QString &line : lines) {
            QStringList parts = line.split("\t");
            if (parts.size() < 5) continue;

            QString fullRef = parts[0].trimmed();
            QString name = parts[1].trimmed();
            if (name.isEmpty() || fullRef.endsWith("/HEAD"))
                continue;

            QVariantMap item;
            item["name"] = name;
            item["hash"] = parts[2].trimmed();
            item["date"] = parts[3].trimmed();
            item["isCurrent"] = (parts[4].trimmed() == "*");
            item["tracking"] = (parts.size() >= 6) ? parts[5].trimmed() : QString();
            item["type"] = fullRef.startsWith("refs/remotes/") ? "remote" : "local";
            list.append(item);
        }
    }

    result["list"] = list;
    return result;
}

QVariantMap GitBackend::mergeBranch(const QString &sourceBranch) {
    QString branch = sourceBranch.trimmed();
    if (branch.isEmpty()) {
        QVariantMap err; err["status"] = "error"; err["message"] = "source branch empty";
        return err;
    }

    QVariantMap result = runGitCmd(QStringList() << "merge" << branch, 15000);

    if (result["status"] == "error") {
        QString msg = result["message"].toString();
        if (msg.contains("CONFLICT", Qt::CaseInsensitive)
            || msg.contains("Automatic merge failed", Qt::CaseInsensitive)) {
            result["status"] = "conflict";
            result["message"] = "合并产生冲突，请手动解决或中止";
            result["detail"] = msg;
        }
    }
    return result;
}

QVariantMap GitBackend::abortMerge() {
    return runGitCmd(QStringList() << "merge" << "--abort");
}

QVariantMap GitBackend::createBranch(const QString &branchName) {
    if (branchName.trimmed().isEmpty()) {
        QVariantMap err; err["status"] = "error"; err["message"] = "branch name empty";
        return err;
    }
    return runGitCmd(QStringList() << "branch" << branchName.trimmed());
}

QVariantMap GitBackend::deleteBranch(const QString &branchName, bool force) {
    if (branchName.trimmed().isEmpty()) {
        QVariantMap err; err["status"] = "error"; err["message"] = "branch name empty";
        return err;
    }
    QString flag = force ? "-D" : "-d";
    return runGitCmd(QStringList() << "branch" << flag << branchName.trimmed());
}

QVariantMap GitBackend::checkoutBranch(const QString &branchName) {
    return runGitCmd(QStringList() << "checkout" << branchName.trimmed());
}

QVariantMap GitBackend::commitChanges(const QString &message) {
    QVariantMap addResult = runGitCmd(QStringList() << "add" << ".");
    if (addResult["status"] == "error") {
        return addResult;
    }
    return runGitCmd(QStringList() << "commit" << "-m" << message);
}

QVariantMap GitBackend::addFile(const QString &file) {
    if (file.trimmed().isEmpty()) {
        QVariantMap err; err["status"] = "error"; err["message"] = "file path empty";
        return err;
    }
    return runGitCmd(QStringList() << "add" << file.trimmed());
}

QVariantMap GitBackend::discardFile(const QString &file) {
    if (file.trimmed().isEmpty()) {
        QVariantMap err; err["status"] = "error"; err["message"] = "file path empty";
        return err;
    }
    return runGitCmd(QStringList() << "restore" << file.trimmed());
}

QVariantMap GitBackend::getCommitHistory(int limit) {
    if (limit <= 0) limit = 10;

    QVariantMap result = runGitCmd(QStringList()
        << "log"
        << "-n" << QString::number(limit)
        << "--pretty=format:%h\t%cd\t%s"
        << "--date=format:%m-%d %H:%M");

    if (result["status"] != "success")
        return result;

    QString raw = result["output"].toString();
    QVariantList list;

    if (!raw.isEmpty()) {
        QStringList lines = raw.split("\n", Qt::SkipEmptyParts);
        for (const QString &line : lines) {
            QStringList parts = line.split("\t");
            if (parts.size() < 3) continue;

            QVariantMap item;
            item["hash"] = parts[0].trimmed();
            item["date"] = parts[1].trimmed();
            item["message"] = QStringList(parts.mid(2)).join("\t").trimmed();
            list.append(item);
        }
    }

    result["list"] = list;
    return result;
}

QVariantMap GitBackend::resetToCommit(const QString &hash) {
    QString cleanHash = hash.trimmed();
    if (cleanHash.isEmpty()) {
        QVariantMap err; err["status"] = "error"; err["message"] = "commit hash empty";
        return err;
    }
    return runGitCmd(QStringList() << "reset" << "--hard" << cleanHash);
}

QVariantMap GitBackend::getTags() {
    QVariantMap result = runGitCmd(QStringList()
        << "tag" << "-l"
        << "--sort=-creatordate"
        << "--format=%(refname:strip=2)%09%(objectname:short)%09%(creatordate:format:%m-%d %H:%M)%09%(subject)");

    if (result["status"] != "success")
        return result;

    QString raw = result["output"].toString();
    QVariantList list;

    if (!raw.isEmpty()) {
        QStringList lines = raw.split("\n", Qt::SkipEmptyParts);
        for (const QString &line : lines) {
            QStringList parts = line.split("\t");
            if (parts.size() < 3) continue;

            QVariantMap item;
            item["name"] = parts[0].trimmed();
            item["hash"] = parts[1].trimmed();
            item["date"] = parts[2].trimmed();
            item["message"] = (parts.size() >= 4)
                ? QStringList(parts.mid(3)).join("\t").trimmed()
                : QString();
            list.append(item);
        }
    }

    result["list"] = list;
    return result;
}

QVariantMap GitBackend::createTag(const QString &name, const QString &message, const QString &hash) {
    QString tagName = name.trimmed();
    if (tagName.isEmpty()) {
        QVariantMap err; err["status"] = "error"; err["message"] = "tag name empty";
        return err;
    }

    QStringList args;
    args << "tag" << "-a" << tagName;

    if (!hash.trimmed().isEmpty())
        args << hash.trimmed();

    QString msg = message.trimmed();
    if (!msg.isEmpty())
        args << "-m" << msg;
    else
        args << "-m" << tagName; // fallback message

    return runGitCmd(args);
}

QVariantMap GitBackend::deleteTag(const QString &name) {
    QString tagName = name.trimmed();
    if (tagName.isEmpty()) {
        QVariantMap err; err["status"] = "error"; err["message"] = "tag name empty";
        return err;
    }
    return runGitCmd(QStringList() << "tag" << "-d" << tagName);
}

QString GitBackend::cleanPath(const QString &path) const {
    QString localPath = QUrl(path).toLocalFile();
    if (localPath.isEmpty()) {
        localPath = path;
    }
    return QDir::cleanPath(localPath);
}

void GitBackend::writeGitIgnore(const QString &repoPath) {
    QFile file(repoPath + "/.gitignore");
    if (file.exists())
        return;
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream stream(&file);
        stream << "# Qt / C++\n";
        stream << "build/\n";
        stream << "*.user\n";
        stream << "*.exe\n";
        stream << "*.o\n";
        stream << "*.obj\n";
        stream << "moc_*\n";
        stream << "ui_*\n";
        stream << "qrc_*\n";
        stream << "Makefile\n";
        stream << "*.pro.user\n";
        stream << "\n# Python\n";
        stream << "__pycache__/\n";
        stream << "*.py[cod]\n";
        stream << ".venv/\n";
        stream << "venv/\n";
        stream << "*.egg-info/\n";
        stream << "dist/\n";
        stream << "\n# IDE / System\n";
        stream << ".idea/\n";
        stream << ".vscode/\n";
        stream << "*.swp\n";
        stream << "*.swo\n";
        stream << ".DS_Store\n";
        stream << "Thumbs.db\n";
        file.close();
    }
}

QVariantMap GitBackend::runGitCmd(const QStringList &args, int timeoutMs) {
    QVariantMap result;

    if (m_currentRepoPath.isEmpty()) {
        result["status"] = "error";
        result["message"] = "no repo path set, call setRepoPath first";
        return result;
    }

    QDir repoDir(m_currentRepoPath);
    if (!repoDir.exists()) {
        result["status"] = "error";
        result["message"] = "repo path not exist: " + m_currentRepoPath;
        return result;
    }

    QProcess *git = new QProcess();
    git->setWorkingDirectory(m_currentRepoPath);
    git->setProcessChannelMode(QProcess::SeparateChannels);

    QEventLoop loop;
    QTimer timeoutTimer;
    timeoutTimer.setSingleShot(true);
    bool isTimeout = false;

    connect(git, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), &loop, &QEventLoop::quit);
    connect(&timeoutTimer, &QTimer::timeout, [&]() {
        isTimeout = true;
        git->kill();
        loop.quit();
    });

    git->start("git", args);

    if (!git->waitForStarted(2000)) {
        result["status"] = "error";
        result["message"] = "cannot start git process, verify git in PATH";
        git->kill();
        git->deleteLater();
        return result;
    }

    timeoutTimer.start(timeoutMs);
    loop.exec();

    if (isTimeout) {
        result["status"] = "error";
        result["message"] = QString("git command timeout (%1ms)").arg(timeoutMs);
        git->deleteLater();
        return result;
    }

    timeoutTimer.stop();

    QString stdOut = QString::fromUtf8(git->readAllStandardOutput()).trimmed();
    QString stdErr = QString::fromUtf8(git->readAllStandardError()).trimmed();
    int exitCode = git->exitCode();

    if (exitCode != 0 || git->exitStatus() != QProcess::NormalExit) {
        result["status"] = "error";
        QString combined = stdErr;
        if (!stdOut.isEmpty())
            combined = combined.isEmpty() ? stdOut : combined + "\n" + stdOut;
        result["message"] = combined;
        if (result["message"].toString().isEmpty()) {
            result["message"] = QString("git exit error, code: %1").arg(exitCode);
        }
    } else {
        result["status"] = "success";
        result["output"] = stdOut.isEmpty() && !stdErr.isEmpty() ? stdErr : stdOut;
    }

    git->deleteLater();
    return result;
}
