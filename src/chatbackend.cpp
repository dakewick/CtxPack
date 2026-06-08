#include "chatbackend.h"
#include <QFile>
#include <QCoreApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QUrl>
#include <QDebug>
#include <QDateTime>

// ============================================
// 保底硬编码常量 (Fallback Default Constants)
// ============================================
static const char* DEFAULT_OLLAMA_API_URL = "http://172.16.2.67:11434/api/chat";
static const char* DEFAULT_MODEL_NAME = "qwen2.5-coder:14b";
static const int REQUEST_TIMEOUT_MS = 300000;  // 300秒超时
static const char* CONFIG_FILE_NAME = "config.json";

// ============================================
// 构造与析构 (Constructor & Destructor)
// ============================================
ChatBackend::ChatBackend(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_messageHistory()  // 初始化为空数组
{
    // 网络管理器基本超时配置
    m_networkManager->setTransferTimeout(REQUEST_TIMEOUT_MS);

    // ⚡ 核心新增：在构造函数中首先触发一次动态加载，初始化 API 配置
    loadConfig();

    qDebug() << "[CtxPack.Chat] 初始化完成 | 锁定 API 终端:" << m_currentApiUrl
             << "| 模型状态:" << m_currentModelName;
}

// ============================================
// ⚙️ 核心重构：绝对路径下的 JSON 加载器
// ============================================
void ChatBackend::loadConfig() {
    // 强行锁定 .exe 同级目录
    QString configPath = QCoreApplication::applicationDirPath() + "/" + CONFIG_FILE_NAME;
    QFile configFile(configPath);

    if (configFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QByteArray data = configFile.readAll();
        configFile.close();

        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (!doc.isNull() && doc.isObject()) {
            QJsonObject json = doc.object();

            m_currentApiUrl = json.value("ollama_url").toString().trimmed();
            m_currentModelName = json.value("model_name").toString().trimmed();

            if (m_currentApiUrl.isEmpty()) m_currentApiUrl = QString::fromUtf8(DEFAULT_OLLAMA_API_URL);
            if (m_currentModelName.isEmpty()) m_currentModelName = QString::fromUtf8(DEFAULT_MODEL_NAME);

            emit configChanged(); // 🔔 发射信号，强制引发 QML 前端界面数据刷新
            qDebug() << "[CtxPack.Chat] 配置热加载成功，配准物理路径:" << configPath;
            return;
        }
    }

    // 💡 保底机制：若文件打不开或损坏，则自动回退到默认极客开发环境
    m_currentApiUrl = QString::fromUtf8(DEFAULT_OLLAMA_API_URL);
    m_currentModelName = QString::fromUtf8(DEFAULT_MODEL_NAME);
    emit configChanged();
    qDebug() << "[CtxPack.Chat] 未检测到物理配置文件，已自动回退至极客本地环境。";
}

// ============================================
// ⚙️ 核心新增：绝对路径下的 JSON 持久化写入器
// ============================================
bool ChatBackend::saveConfig(const QString &url, const QString &model) {
    QString configPath = QCoreApplication::applicationDirPath() + "/" + CONFIG_FILE_NAME;
    QFile configFile(configPath);

    if (!configFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qCritical() << "[CtxPack.Chat] 物理写盘受阻，无法打开文件:" << configPath;
        return false;
    }

    QJsonObject configObj;
    configObj["ollama_url"] = url.trimmed();
    configObj["model_name"] = model.trimmed();

    QJsonDocument doc(configObj);
    configFile.write(doc.toJson(QJsonDocument::Compact));
    configFile.close();

    // 内存变量即时刷新，免重启立刻生效
    m_currentApiUrl = url.trimmed();
    m_currentModelName = model.trimmed();
    emit configChanged(); // 🔔 同步通知前端

    qDebug() << "[CtxPack.Chat] 配置已成功固化至物理磁盘:" << configPath;
    return true;
}

// ============================================
// 公共接口 (Public Interface)
// ============================================

void ChatBackend::clearHistory() {
    int historySize = m_messageHistory.size();
    m_messageHistory = QJsonArray();
    qDebug() << "[CtxPack.Chat] 已清空对话历史，释放了" << historySize << "条历史神经上下文";
}

void ChatBackend::sendMessage(const QString &text) {
    // ========== 输入验证 ==========
    if (text.trimmed().isEmpty()) {
        qWarning() << "[CtxPack.Chat] 拒绝处理空指令流";
        return;
    }

    // ⚡ 核心增强：每次发送前均刷新一次配置，以做到前端修改、后端立刻不闪退生效！
    loadConfig();

    qDebug() << "[CtxPack.Chat] 接收到外发指令:" << text.left(50) << (text.length() > 50 ? "..." : "");

    // ========== 1. 构建 HTTP 请求 ==========
    QUrl url(m_currentApiUrl);
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Accept", "application/json");

    // ========== 2. 追加用户消息到历史 ==========
    QJsonObject userMsg;
    userMsg["role"] = "user";
    userMsg["content"] = text;
    userMsg["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);
    m_messageHistory.append(userMsg);

    // ========== 3. 构建请求体 ==========
    QJsonObject json;
    json["model"] = m_currentModelName;  // ⚡ 动态注入模型名称
    json["messages"] = m_messageHistory;
    json["stream"] = false;

    QJsonObject options;
    options["temperature"] = 0.5; // 压缩代码提问，稍微调低随机度提高代码分析严谨性
    options["top_p"] = 0.9;
    options["num_ctx"] = 16384;   // ⚡ 考虑 CtxPack 作为大文件代码压缩，上下文窗口强制提升至 16K 防溢出
    json["options"] = options;

    QByteArray requestData = QJsonDocument(json).toJson(QJsonDocument::Compact);

    qDebug() << "[CtxPack.Chat] 数据包提交大小:" << requestData.size() << "bytes"
             << " | 历史流深:" << m_messageHistory.size() << "条";

    // ========== 4. 发送 POST 请求 ==========
    QNetworkReply *reply = m_networkManager->post(request, requestData);

    // 错误处理异步连接
    connect(reply, &QNetworkReply::errorOccurred, this, [this, reply](QNetworkReply::NetworkError error) {
        qWarning() << "[CtxPack.Chat] 物理网络层触发异动，状态码:" << error << " | " << reply->errorString();
    });

    // 上传进度跟踪
    connect(reply, &QNetworkReply::uploadProgress, this, [](qint64 sent, qint64 total) {
        if (total > 0) {
            qDebug() << "[CtxPack.Chat] 大上下文数据包上传进度:" << (sent * 100 / total) << "%";
        }
    });

    // ========== 5. 处理响应 ==========
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        // ---------- 成功路径 ----------
        if (reply->error() == QNetworkReply::NoError) {
            QByteArray responseData = reply->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(responseData);

            if (doc.isNull()) {
                emit messageReceived("❌ [CtxPack] 无法反序列化 AI 节点响应流: " + responseData.left(200));
                return;
            }

            QJsonObject response = doc.object();
            QJsonObject messageObj = response["message"].toObject();
            QString replyText = messageObj["content"].toString();

            if (replyText.isEmpty()) {
                qWarning() << "[CtxPack.Chat] 模型拒绝回答或吐回空白，响应快照:" << responseData.left(500);
                emit messageReceived("⚠️ [CtxPack] 目标 AI 模型返回了空白消息，可能触发了保护，请调整输入重试");
                return;
            }

            qDebug() << "[CtxPack.Chat] 回复流捕获成功，首部摘要:" << replyText.left(80).replace("\n", " ") << "..."
                     << " | 承载包体积:" << responseData.size() << "bytes";

            // ========== 6. 追加 AI 回复到历史 ==========
            QJsonObject aiMsg;
            aiMsg["role"] = "assistant";
            aiMsg["content"] = replyText;
            aiMsg["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);
            aiMsg["model"] = m_currentModelName;  // ⚡ 写入当前实际生效的模型名
            m_messageHistory.append(aiMsg);

            emit messageReceived(replyText);
        }
        // ---------- 失败路径 ----------
        else {
            QString errorMsg = reply->errorString();
            int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

            qCritical() << "[CtxPack.Chat] 数据泵请求崩溃:"
                        << "HTTP_STATUS:" << statusCode
                        << " | 原因:" << errorMsg
                        << " | 载荷拦截:" << reply->readAll().left(500);

            // 根据错误类型提供友好提示
            QString friendlyMsg;
            switch (reply->error()) {
            case QNetworkReply::ConnectionRefusedError:
                friendlyMsg = "🔌 无法建立物理连接\n请确认 dakewick 部署的本地远端 Ollama 进程已启动。\n验证目标终端: " + m_currentApiUrl;
                break;
            case QNetworkReply::TimeoutError:
                friendlyMsg = "⏱️ CtxPack 核心请求超时\n当前压缩的工程上下文过大，目标大模型正在全力编译计算中，或硬件显存发生溢出";
                break;
            case QNetworkReply::ContentNotFoundError:
                friendlyMsg = "🔍 路由解析失败 (404 Not Found)\n请在灰色设置齿轮中复核您的 API 终点路径: " + m_currentApiUrl;
                break;
            case QNetworkReply::InternalServerError:
                friendlyMsg = "💥 远端 Ollama 算力集群内部发生不可逆崩溃\n请检查您本地主机的 Ollama 运行控制台日志";
                break;
            default:
                friendlyMsg = "❌ [CtxPack.ERR] 数据链通信发生故障: " + errorMsg;
            }

            emit messageReceived(friendlyMsg);
        }
    });
}

// ============================================
// 私有辅助方法 (Private Helpers)
// ============================================
QJsonObject ChatBackend::getConversationStats() const {
    QJsonObject stats;
    stats["total_messages"] = m_messageHistory.size();

    int userMsgs = 0, aiMsgs = 0;
    for (const QJsonValue &msg : m_messageHistory) {
        QString role = msg["role"].toString();
        if (role == "user") userMsgs++;
        else if (role == "assistant") aiMsgs++;
    }
    stats["user_messages"] = userMsgs;
    stats["ai_messages"] = aiMsgs;
    stats["model"] = m_currentModelName; // ⚡ 动态反馈当前的统计指标

    return stats;
}