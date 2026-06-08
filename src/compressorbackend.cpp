#include "CompressorBackend.h"
#include <QFile>
#include <QFileInfo>
#include <QTextStream>
#include <QDebug>
#include <QCoreApplication>
#include <QTimer>
#include <QUrl>
#include <QDir>
#include <QStandardPaths>


// ============================================
// 配置常量 (Config Constants)
// ============================================
static const char* EXTRACT_SCRIPT = "extract_skeleton.py";  // Python 脚本名
static const char* OUTPUT_FILE = "project_map.md";           // 临时输出文件
static const int MIN_ANIMATION_MS = 1000;                    // 最小动画时长(ms)
static const int PROCESS_TIMEOUT_MS = 300000;                 // 进程超时(60秒)

// ============================================
// 构造与析构 (Constructor & Destructor)
// ============================================
CompressorBackend::CompressorBackend(QObject *parent)
    : QObject(parent)
    , m_process(new QProcess(this))
    , m_isRunning(false)
    , m_timer()
    , m_currentProjectPath()
    , m_currentMode(false)
{
    // ========== 1. 标准输出监听 ==========
    // 捕获 Python 脚本的 print() 输出，用于进度更新
    connect(m_process, &QProcess::readyReadStandardOutput, this, [this]() {
        QString output = QString::fromUtf8(m_process->readAllStandardOutput()).trimmed();
        if (!output.isEmpty()) {
            qDebug() << "[Compressor] Python输出:" << output.left(100);
            emit progressUpdated(output);
        }
    });

    // ========== 2. 标准错误监听 ==========
    // 捕获 Python 的错误输出，用于诊断问题
    connect(m_process, &QProcess::readyReadStandardError, this, [this]() {
        QString errorOutput = QString::fromUtf8(m_process->readAllStandardError()).trimmed();
        if (!errorOutput.isEmpty()) {
            qWarning() << "[Compressor] Python错误:" << errorOutput;
            // 存储错误信息用于后续诊断
            m_lastError = errorOutput;
        }
    });

    // ========== 3. 进程完成处理 ==========
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this](int exitCode, QProcess::ExitStatus exitStatus) {

                qint64 elapsedMs = m_timer.elapsed();
                qDebug() << "[Compressor] 进程结束"
                         << "退出码:" << exitCode
                         << "状态:" << (exitStatus == QProcess::NormalExit ? "正常" : "崩溃")
                         << "耗时:" << elapsedMs << "ms"
                         << "项目:" << m_currentProjectPath;

                QString content;
                bool success = false;

                // ---------- 成功路径 ----------
                if (exitStatus == QProcess::NormalExit && exitCode == 0) {
                    // 构建输出文件路径
                    QString outputFilePath = QDir(m_process->workingDirectory())
                                                 .absoluteFilePath(OUTPUT_FILE);

                    QFileInfo fileInfo(outputFilePath);
                    if (!fileInfo.exists()) {
                        content = QString("⚠️ 脚本执行成功，但未找到输出文件\n"
                                          "预期路径: %1\n"
                                          "可能原因: 脚本未生成文件或路径错误")
                                      .arg(outputFilePath);
                    } else {
                        QFile file(outputFilePath);

                        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
                            QTextStream in(&file);
                            // 修复：Qt6 中移除了 setCodec，直接读取即可（默认 UTF-8）
                            content = in.readAll();
                            file.close();

                            // 🆕 验证内容质量
                            if (content.trimmed().isEmpty()) {
                                content = "⚠️ 压缩结果为空\n可能原因: 项目中没有支持的文件类型";
                                success = false;
                            } else {
                                success = true;

                                // 🆕 输出统计信息
                                int lineCount = content.count('\n');
                                qDebug() << "[Compressor] 压缩完成"
                                         << "大小:" << content.size() << "bytes"
                                         << "行数:" << lineCount;
                            }

                            // 🚀 核心：立即删除临时文件防止污染
                            if (file.exists()) {
                                file.remove();
                                qDebug() << "[Compressor] 已清理临时文件:" << outputFilePath;
                            }
                        } else {
                            content = QString("❌ 无法读取输出文件: %1\n错误: %2")
                                          .arg(outputFilePath, file.errorString());
                        }
                    }
                }
                // ---------- 失败路径 ----------
                else {
                    QString errorType = (exitStatus == QProcess::CrashExit) ? "崩溃" : "异常退出";
                    content = QString("❌ 压缩脚本%1 (退出码: %2)\n\n"
                                      "项目路径: %3\n"
                                      "最后错误: %4\n\n"
                                      "💡 常见解决方案:\n"
                                      "1. 确认 Python 3 已安装: python --version\n"
                                      "2. 检查项目路径是否有效\n"
                                      "3. 查看控制台错误日志")
                                  .arg(errorType)
                                  .arg(exitCode)
                                  .arg(m_currentProjectPath)
                                  .arg(m_lastError.isEmpty() ? "无" : m_lastError);
                }

                // ========== 动画时长控制 ==========
                // 确保加载动画至少显示 3 秒，避免闪烁
                qint64 remain = MIN_ANIMATION_MS - elapsedMs;

                if (remain > 0) {
                    // 如果执行太快，延迟补足动画时长
                    QTimer::singleShot(remain, this, [this, content, success]() {
                        finishProcess(content, success);
                    });
                } else {
                    // 已经超过 3 秒，直接完成
                    finishProcess(content, success);
                }
            });

    // 🆕 进程错误处理
    connect(m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        qWarning() << "[Compressor] 进程错误:" << error;

        switch (error) {
        case QProcess::FailedToStart:
            m_lastError = "无法启动 Python 解释器\n"
                          "请确认: python 命令在 PATH 中可用";
            break;
        case QProcess::Timedout:
            m_lastError = QString("进程超时 (%1秒)").arg(PROCESS_TIMEOUT_MS / 1000);
            break;
        default:
            m_lastError = "进程运行时错误";
        }
    });
}

// ============================================
// 公共接口 (Public Interface)
// ============================================

/**
 * @brief 启动代码压缩流程
 *
 * @param projectPath QML 传递的文件夹路径 (可能带 file:/// 前缀)
 * @param isLinuxMode 是否启用 Linux 特殊处理模式
 *
 * 执行流程:
 * 1. 路径转换: QML URL → 本地文件路径
 * 2. 启动 python extract_skeleton.py <projectPath>
 * 3. 等待进程完成 (捕获 stdout/stderr)
 * 4. 读取生成的 project_map.md
 * 5. 延迟动画后触发 compressionFinished 信号
 *
 * 前置条件:
 * - 未在运行中 (!m_isRunning)
 * - Python 3 已安装并在 PATH 中
 * - extract_skeleton.py 与可执行文件在同一目录
 *
 * 副作用:
 * - m_isRunning → true (触发 isRunningChanged)
 * - 在工作目录生成 project_map.md (完成后删除)
 *
 * @see compressionFinished 信号
 * @see progressUpdated 进度更新信号
 */
void CompressorBackend::startCompression(const QString &projectPath, bool isLinuxMode) {
    // ========== 状态检查 ==========
    if (m_isRunning) {
        qWarning() << "[Compressor] 已有压缩任务在运行，忽略重复请求";
        emit progressUpdated("⚠️ 当前有任务正在执行，请稍后...");
        return;
    }

    // ========== 1. 路径转换 ==========
    // QML FolderDialog 返回的路径可能是 file:///C:/Users/...
    QString localPath = QUrl(projectPath).toLocalFile();
    if (localPath.isEmpty()) {
        localPath = projectPath;  // 降级：直接使用原始路径
    }

    // ========== 2. 路径验证 ==========
    QFileInfo projectDir(localPath);
    if (!projectDir.exists() || !projectDir.isDir()) {
        QString errorMsg = QString("❌ 无效的项目路径: %1\n"
                                   "请确认文件夹是否存在").arg(localPath);
        qWarning() << "[Compressor]" << errorMsg;
        emit compressionFinished(errorMsg, false);
        return;
    }

    // ========== 3. 脚本路径检查 ==========
   QString scriptPath = QCoreApplication::applicationDirPath() + "/" + EXTRACT_SCRIPT;
    QFileInfo scriptFile(scriptPath);
    if (!scriptFile.exists()) {
        QString errorMsg = QString("❌ 找不到压缩脚本: %1\n"
                                   "请确认文件存在于程序目录").arg(scriptPath);
        qWarning() << "[Compressor]" << errorMsg;
        emit compressionFinished(errorMsg, false);
        return;
    }

    // ========== 4. 启动压缩 ==========
    m_currentProjectPath = localPath;
    m_currentMode = isLinuxMode;
    m_isRunning = true;
    m_lastError.clear();

    qDebug() << "[Compressor] 开始压缩"
             << "项目:" << localPath
             << "脚本:" << scriptPath
             << "模式:" << (isLinuxMode ? "Linux" : "标准");

    emit isRunningChanged();
    emit progressUpdated("🚀 启动解析引擎...");

    m_timer.start(); // 开始计时
    m_process->setWorkingDirectory(localPath);

    // 🆕 设置进程超时
    m_process->setProcessChannelMode(QProcess::SeparateChannels);

    // 构造参数列表
    QStringList arguments;
    arguments << "-X" << "utf8"     // 强制 UTF-8 编码，防止 Emoji 错误
              << scriptPath          // Python 脚本路径
              << localPath;          // 要分析的项目路径

    // 🆕 尝试使用 python3，失败则降级到 python
    QString pythonCmd = "python";
    QProcess testProcess;
    testProcess.start("python3", QStringList() << "--version");
    testProcess.waitForFinished(1000);
    if (testProcess.exitCode() == 0) {
        pythonCmd = "python3";  // Linux/macOS 优先使用 python3
    }

    qDebug() << "[Compressor] 执行命令:" << pythonCmd << arguments;
    m_process->start(pythonCmd, arguments);

    // 🆕 启动监控定时器（防止进程挂死）
    QTimer::singleShot(PROCESS_TIMEOUT_MS, this, [this]() {
        if (m_isRunning && m_process->state() != QProcess::NotRunning) {
            qWarning() << "[Compressor] 进程超时，强制终止";
            m_process->kill();
            finishProcess("⏱️ 压缩超时，项目可能过大或脚本陷入死循环", false);
        }
    });
}

/**
 * @brief 保存压缩结果到文件
 *
 * @param savePath QML FileDialog 返回的保存路径
 * @param content 要保存的 Markdown 内容
 * @return true 保存成功, false 保存失败
 *
 * 使用场景: 用户通过 QML 的保存对话框导出压缩结果
 * 编码: UTF-8 (支持 Emoji 和特殊字符)
 */
bool CompressorBackend::saveToFile(const QString &savePath, const QString &content) {
    // 路径转换
    QString localPath = QUrl(savePath).toLocalFile();
    if (localPath.isEmpty()) {
        localPath = savePath;
    }

    // 🆕 自动添加 .md 扩展名
    if (!localPath.endsWith(".md", Qt::CaseInsensitive) &&
        !localPath.endsWith(".txt", Qt::CaseInsensitive)) {
        localPath += ".md";
    }

    QFile file(localPath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&file);
        // 修复：Qt6 中移除了 setCodec，直接写入即可（默认 UTF-8）
        out << content;
        file.close();

        qDebug() << "[Compressor] 文件已保存:" << localPath
                 << "大小:" << content.size() << "bytes";
        return true;
    }

    qWarning() << "[Compressor] 保存失败:" << localPath << file.errorString();
    return false;
}

// ============================================
// 私有辅助方法 (Private Helpers)
// ============================================

/**
 * @brief 完成压缩流程，重置状态并触发信号
 *
 * @param content 压缩结果文本（成功时）或错误信息（失败时）
 * @param success 是否成功
 *
 * 副作用:
 * - m_isRunning → false
 * - 触发 isRunningChanged 和 compressionFinished 信号
 * - 清理进程状态
 */
void CompressorBackend::finishProcess(const QString &content, bool success) {
    m_isRunning = false;

    // 🆕 清理进程残留
    if (m_process->state() != QProcess::NotRunning) {
        m_process->kill();
        m_process->waitForFinished(1000);
    }

    qDebug() << "[Compressor] 流程结束"
             << "结果:" << (success ? "成功" : "失败")
             << "内容长度:" << content.size();

    emit isRunningChanged();
    emit compressionFinished(content, success);
}

// 🆕 取消当前压缩任务
void CompressorBackend::cancelCompression() {
    if (m_isRunning) {
        qDebug() << "[Compressor] 用户取消压缩";
        if (m_process->state() != QProcess::NotRunning) {
            m_process->kill();
        }
        finishProcess("⏹️ 压缩已取消", false);
    }
}