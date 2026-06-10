import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.VirtualKeyboard
import App.Backend 1.0

Window {
    id: root
    width: 1000
    height: 760
    visible: true
    title: "CtxPack v1.0.0 // AUTOMATION CORE BY dakewick"

    // 🎯 核心设置 1：隐去 Windows 默认标题栏，并将根窗口设置为完全透明
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"

    // ==========================================
    // 0. 全局调色板 (护眼机甲绿)
    // ==========================================
    QtObject {
        id: palette
        readonly property color bgTop: "#121826"
        readonly property color bgBottom: "#0A0E17"
        readonly property color neonCyan: "#00B4D8"
        readonly property color neonGreen: "#00C853" // 主战亮绿
        readonly property color neonRed: "#E63946"
        readonly property color panelBg: "#171E2E"   // 实心极暗底板
        readonly property color textMain: "#CBD5E1"
        readonly property color textDim: "#64748B"
    }

    // ==========================================
    // 1. 全局弹窗与后端
    // ==========================================
    FolderDialog {
        id: folderDialog
        title: "[SYS.REQ] SELECT_TARGET_DIRECTORY"
        onAccepted: {
            compressorBackend.startCompression(selectedFolder, false)
        }
    }

    CompressorBackend {
        id: compressorBackend
        onCompressionFinished: function(resultMarkdown, success) {
            if (success) {
                resultArea.text = resultMarkdown
                // ⚡ 极简绝杀：强制底层文本引擎立刻排版并触发重绘
                resultArea.cursorPosition = resultMarkdown.length
                resultArea.cursorPosition = 0
                btnGoToChat.visible = true
            } else {
                resultArea.text = "[ERR_CRITICAL] COMPRESSION_FAILED:\n" + resultMarkdown
                btnGoToChat.visible = false
            }
        }
    }

    ChatBackend {
        id: chatBackend
        onMessageReceived: function(text) {
            chatModel.append({"text": text, "isAi": true})
        }
    }

    ListModel { id: chatModel }

    // ==========================================
    // 2. 主装甲外壳（实现 16px 的平滑圆角修剪）
    // ==========================================
    Rectangle {
        id: mainShell
        anchors.fill: parent
        radius: 16
        clip: true
        gradient: Gradient {
            GradientStop { position: 0.0; color: palette.bgTop }
            GradientStop { position: 1.0; color: palette.bgBottom } // 🟢 已彻底修复重叠语法
        }

        // 🎯 核心设置 2：高效率系统原生窗口拖拽器
        DragHandler {
            acceptedButtons: Qt.LeftButton
            onActiveChanged: {
                if (active) {
                    root.startSystemMove()
                }
            }
        }

        // ==========================================
        // 🚥 右上角自定义控制钮组
        // ==========================================
        Row {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 18
            anchors.rightMargin: 18
            spacing: 10
            z: 100

            // 🟡 1. 最小化按钮
            Rectangle {
                width: 20; height: 20; radius: 10
                color: minMouse.containsMouse ? "#ffbd2e" : "#4a402a"
                Behavior on color { ColorAnimation { duration: 120 } }
                Rectangle {
                    width: 8; height: 1.5
                    color: minMouse.containsMouse ? "#121826" : Qt.alpha(palette.textDim, 0.6)
                    anchors.centerIn: parent
                }
                MouseArea {
                    id: minMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.showMinimized()
                }
            }

            // 🟢 2. 最大化按钮
            Rectangle {
                width: 20; height: 20; radius: 10
                color: maxMouse.containsMouse ? palette.neonGreen : "#2a4a30"
                Behavior on color { ColorAnimation { duration: 120 } }
                Rectangle {
                    width: 7; height: 7
                    color: "transparent"
                    border.color: maxMouse.containsMouse ? "#121826" : Qt.alpha(palette.textDim, 0.6)
                    border.width: 1.5
                    anchors.centerIn: parent
                }
                MouseArea {
                    id: maxMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (root.visibility === Window.Maximized) {
                            root.showNormal()
                        } else {
                            root.showMaximized()
                        }
                    }
                }
            }

            // 🔴 3. 关闭按钮
            Rectangle {
                width: 20; height: 20; radius: 10
                color: closeMouse.containsMouse ? palette.neonRed : "#4a2a2a"
                Behavior on color { ColorAnimation { duration: 120 } }
                Item {
                    width: 8; height: 8
                    anchors.centerIn: parent
                    Rectangle { width: 8; height: 1.5; rotation: 45; anchors.centerIn: parent; color: closeMouse.containsMouse ? "#121826" : Qt.alpha(palette.textDim, 0.6) }
                    Rectangle { width: 8; height: 1.5; rotation: -45; anchors.centerIn: parent; color: closeMouse.containsMouse ? "#121826" : Qt.alpha(palette.textDim, 0.6) }
                }
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Qt.quit()
                }
            }
        }

        // ==========================================
        // 3. 页面布局主体
        // ==========================================
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            anchors.topMargin: 45
            spacing: 20

            // 页面 1：代码压缩页面
            Item {
                id: compressorPage
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    HudFrame {
                        Layout.fillWidth: true
                        Layout.maximumHeight: 70
                        Layout.preferredHeight: 70
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 20
                            StatusDot { glowColor: palette.neonGreen }
                            Text {
                                text: "CtxPack.MDL // CORE_COMPRESSOR // BY dakewick"
                                font.family: "Courier New"
                                font.pixelSize: 18
                                font.weight: Font.Bold
                                color: palette.textMain
                                Layout.fillWidth: true
                            }
                            CyberButton {
                                btnText: "[ INIT_SCAN_DIR ]"
                                baseColor: palette.neonGreen
                                Layout.preferredWidth: 180
                                Layout.preferredHeight: 40
                                onClicked: folderDialog.open()
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        RadarBackground {
                            id: radarSys
                            anchors.fill: parent
                            isScanning: compressorBackend.isRunning
                        }

                        HudFrame {
                            id: resultPanel
                            anchors.fill: parent
                            opacity: compressorBackend.isRunning ? 0 : 1
                            Behavior on opacity { NumberAnimation { duration: 300 } }

                            ScrollView {
                                anchors.fill: parent
                                anchors.margins: 16
                                clip: true
                                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                                background: Rectangle { color: "transparent" }

                                TextArea {
                                    id: resultArea
                                    readOnly: true
                                    wrapMode: TextArea.Wrap
                                    font.family: "Courier New"
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                    color: palette.neonGreen
                                    selectionColor: palette.neonGreen
                                    selectedTextColor: "#121826"
                                    renderType: Text.NativeRendering
                                    clip: true

                                    background: Rectangle {
                                        color: palette.panelBg
                                        border.color: Qt.alpha(palette.neonGreen, 0.5)
                                        border.width: 1
                                        radius: 2
                                    }
                                    text: ">> AWAITING_INPUT_STREAM... (支持拖拽工程文件夹至窗口任意位置直接解析)"
                                }
                            }
                        }
                    }

                    // ==========================================
                    // 💾 核心新增：另存为文件对话框
                    // ==========================================
                    FileDialog {
                        id: saveProjectMapDialog
                        title: "[SYS.REQ] SAVE_MAP_STREAM_TO_FILE"
                        currentFile: "file:///project_map.md"
                        fileMode: FileDialog.SaveFile
                        nameFilters: ["Markdown files (*.md)", "Text files (*.txt)"]
                        onAccepted: {
                            // 1. 剥离纯净的本地保存物理路径
                            var rawUrl = selectedFile.toString()
                            var cleanSavePath = ""
                            if (rawUrl.startsWith("file:///")) {
                                cleanSavePath = rawUrl.substring(8)
                            } else if (rawUrl.startsWith("file:")) {
                                cleanSavePath = rawUrl.substring(5)
                            } else {
                                cleanSavePath = rawUrl
                            }
                            cleanSavePath = decodeURIComponent(cleanSavePath)

                            // 2. 直接调用 C++ 后台原生的 saveToFile 驱动进行硬核写入
                            var fileSaved = compressorBackend.saveToFile(cleanSavePath, resultArea.text)
                            if (fileSaved) {
                                // 临时将文本框顶端提示刷新，作为成功的视觉反馈
                                resultArea.insert(0, ">> [SYS.INFO] FILE_SAVE_SUCCESS_AT: " + cleanSavePath + "\n\n")
                            }
                        }
                    }

                    // ==========================================
                    // 🚥 底部控制台：四大核心操作链路（AI 链接 | 提示词生成器 | 一键复制 | 另存为）
                    // ==========================================
                    Item {
                        Layout.fillWidth: true
                        Layout.maximumHeight: 50
                        Layout.preferredHeight: 50

                        RowLayout {
                            id: bottomButtonsLayout
                            anchors.fill: parent
                            anchors.leftMargin: parent.width * 0.05
                            anchors.rightMargin: parent.width * 0.05
                            spacing: 12

                            // 1. 核心链路：AI 链接 (模块 A)
                            CyberButton {
                                id: btnGoToChat
                                visible: true
                                btnText: ">>> AI_LINK <<<"
                                baseColor: palette.neonGreen
                                Layout.fillWidth: true
                                Layout.preferredWidth: 3
                                Layout.preferredHeight: 42
                                onClicked: {
                                    compressorPage.visible = false
                                    chatPage.visible = true
                                    chatBackend.clearHistory()
                                    chatModel.clear()
                                    var promptText = "请阅读以下代码上下文，稍后我会向你提问：\n\n" + resultArea.text
                                    chatModel.append({"text": "[SYS] UPLOADING_CONTEXT_TO_NEURAL_NET...", "isAi": false})
                                    chatBackend.sendMessage(promptText)
                                }
                            }

                            // ⚡ 核心新增：打开独立提示词生成器页面
                            CyberButton {
                                id: btnOpenPromptSelector
                                btnText: "[ PROMPT_GEN ]"
                                baseColor: palette.neonCyan
                                Layout.fillWidth: true
                                Layout.preferredWidth: 3
                                Layout.preferredHeight: 42
                                onClicked: modePopup.open()

                                Popup {
                                    id: modePopup
                                    parent: btnOpenPromptSelector
                                    y: -150
                                    x: 0
                                    width: parent.width
                                    modal: true
                                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                                    background: Rectangle {
                                        color: palette.panelBg
                                        border.color: palette.neonCyan
                                        radius: 4
                                    }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        spacing: 2

                                        Button {
                                            text: "Qt 开发"
                                            Layout.fillWidth: true
                                            palette.buttonText: palette.neonCyan
                                            background: Rectangle { color: hovered ? palette.bgTop : "transparent" }
                                            onClicked: {
                                                modePopup.close()
                                                chatPage.visible = false
                                                promptPage.visible = true
                                                promptPage.refreshPrompt()
                                            }
                                        }

                                        Button {
                                            text: "嵌入式开发"
                                            Layout.fillWidth: true
                                            palette.buttonText: palette.textDim
                                            background: Rectangle { color: hovered ? palette.bgTop : "transparent" }
                                        }
                                        Button {
                                            text: "Linux 开发"
                                            Layout.fillWidth: true
                                            palette.buttonText: palette.textDim
                                            background: Rectangle { color: hovered ? palette.bgTop : "transparent" }
                                        }
                                    }
                                }
                            }

                            // 2. 极客链路：一键快速拷走
                            CyberButton {
                                id: btnQuickCopy
                                btnText: "[ COPY ]"
                                baseColor: palette.textDim
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: 42
                                onClicked: {
                                    resultArea.selectAll()
                                    resultArea.copy()
                                    resultArea.deselect()
                                    var originalText = btnText
                                    btnText = "[ ✔_COPIED ]"
                                    var t = animationTimer
                                    if (!t) {
                                        t = Qt.createQmlObject('import QtQuick 2.0; Timer { interval: 1500; repeat: false; }', btnQuickCopy)
                                    }
                                    t.triggered.connect(function() { btnText = originalText })
                                    t.start()
                                }
                            }  // ← 这里只闭合 CyberButton，不闭合 RowLayout

                            // 3. 工业链路：本地文件数据持久化
                            CyberButton {
                                id: btnSaveFile
                                btnText: "[ SAVE ]"
                                baseColor: palette.textDim
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: 42
                                onClicked: saveProjectMapDialog.open()
                            }
                        } // ← 闭合 RowLayout
                    } // ← 闭合底部控制台 Item

                } // ← 闭合 compressorPage 内部的 ColumnLayout
            } // ← 闭合 compressorPage



            // 页面 2：AI 聊天页面
            Item {
                id: chatPage
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: false

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    HudFrame {
                        Layout.fillWidth: true
                        Layout.maximumHeight: 65
                        Layout.preferredHeight: 65
                        accentColor: palette.neonGreen
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 20
                            CyberButton {
                                btnText: "< DISCONNECT"
                                baseColor: palette.textDim
                                Layout.preferredWidth: 120
                                Layout.preferredHeight: 35
                                onClicked: {
                                    chatPage.visible = false
                                    compressorPage.visible = true
                                }
                            }
                            StatusDot { glowColor: palette.neonGreen }
                            Text {
                                text: "NEURAL_LINK_ACTIVE"
                                font.family: "Courier New"
                                font.pixelSize: 18
                                font.weight: Font.Bold
                                color: palette.neonGreen
                                Layout.fillWidth: true
                            }
                            CyberButton {
                                btnText: "PURGE_MEM"
                                baseColor: palette.neonRed
                                Layout.preferredWidth: 120
                                Layout.preferredHeight: 35
                                onClicked: {
                                    chatBackend.clearHistory()
                                    chatModel.clear()
                                }
                            }
                        }
                    }

                    ListView {
                        id: chatListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: chatModel
                        spacing: 16
                        clip: true
                        ScrollBar.vertical: ScrollBar {
                            background: Rectangle { color: palette.panelBg; width: 4 }
                            contentItem: Rectangle { color: palette.neonGreen; radius: 2 }
                        }

                        delegate: Item {
                            width: chatListView.width
                            height: msgContainer.height
                            HudFrame {
                                id: msgContainer
                                width: Math.min(msgText.implicitWidth + 30, chatListView.width * 0.8)
                                height: msgText.implicitHeight + 20
                                accentColor: palette.neonGreen
                                color: palette.panelBg
                                anchors.right: model.isAi ? undefined : parent.right
                                anchors.left: model.isAi ? parent.left : undefined

                                Text {
                                    id: msgText
                                    text: (model.isAi ? "[AI] " : "[USR] ") + model.text
                                    color: model.isAi ? palette.neonGreen : palette.neonCyan
                                    font.family: "Courier New"
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                    wrapMode: Text.Wrap
                                    width: parent.width - 30
                                    anchors.centerIn: parent
                                }
                            }
                        }
                        onCountChanged: {
                            chatListView.positionViewAtEnd()
                        }
                    }

                    // ==========================================
                    // ⚙️ 工业级重构：大尺寸、全自适应高度 API 配置弹窗
                    // ==========================================
                    Dialog {
                        id: apiConfigDialog
                        title: "[CtxPack.CONFIG] OLLAMA_NET_ENDPOINT // BY dakewick"
                        anchors.centerIn: parent
                        width: 520
                        modal: true
                        standardButtons: Dialog.Save | Dialog.Cancel

                        background: Rectangle {
                            color: palette.panelBg
                            border.color: palette.textDim
                            border.width: 1
                            radius: 8
                        }

                        header: Rectangle {
                            color: "transparent"
                            height: 45
                            Text {
                                text: apiConfigDialog.title
                                color: palette.textMain
                                font.family: "Courier New"
                                font.bold: true
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 18
                            }
                        }

                        // 🎯 斩杀硬编码硬伤核心 1：每次配置弹窗弹起时，强制用 C++ 底层当前实际生效的值刷新输入框
                        onOpened: {
                            apiUrlInput.text = chatBackend.apiUrl
                            apiModelInput.text = chatBackend.modelName
                        }

                        contentItem: ColumnLayout {
                            spacing: 12
                            implicitHeight: apiColumn.implicitHeight

                            Column {
                                id: apiColumn
                                width: parent.width
                                spacing: 14

                                // --- 第一组：URL 配置 ---
                                Text {
                                    text: "ENTER_LOCAL_OLLAMA_URL:"
                                    color: palette.textDim
                                    font.family: "Courier New"
                                    font.pixelSize: 12
                                }

                                TextField {
                                    id: apiUrlInput
                                    width: 484
                                    height: 38
                                    color: palette.neonCyan
                                    font.family: "Courier New"
                                    font.pixelSize: 14
                                    leftPadding: 12
                                    verticalAlignment: TextInput.AlignVCenter
                                    background: Rectangle {
                                        color: palette.bgBottom
                                        border.color: Qt.rgba(0,180,216,0.5)
                                        border.width: 1
                                    }
                                }

                                Item { width: 1; height: 4 }

                                // --- 第二组：模型名称配置 ---
                                Text {
                                    text: "ENTER_TARGET_MODEL_NAME:"
                                    color: palette.textDim
                                    font.family: "Courier New"
                                    font.pixelSize: 12
                                }

                                TextField {
                                    id: apiModelInput
                                    width: 484
                                    height: 38
                                    color: palette.neonCyan
                                    font.family: "Courier New"
                                    font.pixelSize: 14
                                    leftPadding: 12
                                    verticalAlignment: TextInput.AlignVCenter
                                    background: Rectangle {
                                        color: palette.bgBottom
                                        border.color: Qt.rgba(0,180,216,0.5)
                                        border.width: 1
                                    }
                                }

                                Item { width: 1; height: 6 }

                                Text {
                                    text: "💡 配置将以 JSON 格式固化至本地磁盘 config.json。"
                                    color: Qt.rgba(palette.textDim, 0.7)
                                    font.pixelSize: 12
                                    font.family: "Microsoft YaHei"
                                }
                            }
                        }

                        // 🎯 斩杀硬编码硬伤核心 2：点击保存时，直接命令 chatBackend 压进绝对执行目录
                        onAccepted: {
                            var success = chatBackend.saveConfig(apiUrlInput.text, apiModelInput.text)
                            if (success) {
                                chatModel.append({
                                    "text": "[CtxPack.INFO] NEW_API_AND_MODEL_LOCKED_BY_DAKEWICK.",
                                    "isAi": false
                                })
                            }
                        }
                    }

                    // ==========================================
                    // 🚥 聊天页面底部输入栏（完美对齐：输入框 → 发送 → 灰色设置）
                    // ==========================================
                    HudFrame {
                        Layout.fillWidth: true
                        Layout.maximumHeight: 70
                        Layout.preferredHeight: 70
                        accentColor: palette.neonGreen
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 12

                            TextField {
                                id: chatInput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                placeholderText: "AWAITING_COMMAND_STRING..."
                                placeholderTextColor: palette.textDim
                                color: palette.neonGreen
                                font.family: "Courier New"
                                font.pixelSize: 16
                                font.weight: Font.Bold
                                leftPadding: 15
                                palette.base: palette.bgBottom
                                palette.text: palette.neonGreen

                                background: Rectangle {
                                    color: palette.bgBottom
                                    border.color: Qt.alpha(palette.neonGreen, 0.6)
                                    border.width: 1
                                    radius: 2
                                }
                                Keys.onReturnPressed: {
                                    sendBtn.clicked()
                                }
                            }

                            // 绿色发送按钮
                            CyberButton {
                                id: sendBtn
                                btnText: "EXECUTE"
                                baseColor: palette.neonGreen
                                Layout.preferredWidth: 100
                                Layout.fillHeight: true
                                onClicked: {
                                    if (chatInput.text.trim() === "") return
                                    chatModel.append({"text": chatInput.text, "isAi": false})
                                    chatBackend.sendMessage(chatInput.text)
                                    chatInput.clear()
                                }
                            }

                            // ⚙️ 核心新增：灰色的本地 API 配置按钮
                            CyberButton {
                                id: btnSettings
                                btnText: "⚙"
                                baseColor: palette.textDim // 使用高档的灰色
                                Layout.preferredWidth: 45
                                Layout.fillHeight: true
                                onClicked: {
                                    apiConfigDialog.open()
                                }
                            }
                        }
                    }
                } // ✅ 精确闭合 chatPage 内部 ColumnLayout
            } // ✅ 精确闭合 chatPage 本身，完美形成兄弟节点

            // ==========================================
            // 页面 3：提示词生成器专属页面
            // ==========================================
            PromptGenerator {
                id: promptPage
                // ✅ 作为主 ColumnLayout 的合法子节点，使用 Layout 属性完美自适应
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: false

                onBackRequested: {
                    promptPage.visible = false
                    compressorPage.visible = true
                }
            }
        } // ✅ 这里精确闭合整个主外壳内部的最高层 ColumnLayout (之前导致 Crash 就是这附近错乱)

        // ==========================================
        // 🧲 核心新增：全局悬浮文件夹拖拽扫描响应层
        // ==========================================
        DropArea {
            id: globalDropArea
            anchors.fill: parent
            keys: ["text/uri-list"]

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 200, 83, 0.06)
                border.color: palette.neonGreen
                border.width: 2
                radius: 16
                visible: globalDropArea.containsDrag
                z: 999

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    Text { text: "🛸"; font.pixelSize: 42; Layout.alignment: Qt.AlignHCenter }
                    Text {
                        text: "投放代码工程文件夹以注入硬核解析引擎"
                        color: palette.neonGreen
                        font.family: "Courier New"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            onDropped: (drop) => {
                if (drop.hasUrls) {
                    var rawUrl = drop.urls[0].toString()
                    var cleanPath = ""
                    if (rawUrl.startsWith("file:///")) {
                        cleanPath = rawUrl.substring(8)
                    } else if (rawUrl.startsWith("file:")) {
                        cleanPath = rawUrl.substring(5)
                    } else {
                        cleanPath = rawUrl
                    }
                    cleanPath = decodeURIComponent(cleanPath)
                    compressorBackend.startCompression(cleanPath, false)
                    drop.acceptProposedAction()
                }
            }
        }
    } // ✅ 精确闭合 mainShell 主外壳装甲 Rectangle

    // ==========================================
    // 4. 核心组件库定义
    // ==========================================
    component StatusDot : Rectangle {
        id: sDot
        width: 10; height: 10; radius: 5
        property color glowColor: palette.neonGreen
        color: glowColor
        layer.enabled: true
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: true
            NumberAnimation { to: 0.3; duration: 1000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
        }
    }

    component HudFrame : Rectangle {
        property color accentColor: palette.neonGreen
        color: palette.panelBg
        border.color: Qt.alpha(accentColor, 0.8)
        border.width: 1

        Repeater {
            model: 4
            Item {
                anchors.fill: parent
                Rectangle {
                    width: 16; height: 2; color: accentColor
                    anchors.top: (index === 0 || index === 1) ? parent.top : undefined
                    anchors.bottom: (index === 2 || index === 3) ? parent.bottom : undefined
                    anchors.left: (index === 0 || index === 2) ? parent.left : undefined
                    anchors.right: (index === 1 || index === 3) ? parent.right : undefined
                }
                Rectangle {
                    width: 2; height: 16; color: accentColor
                    anchors.top: (index === 0 || index === 1) ? parent.top : undefined
                    anchors.bottom: (index === 2 || index === 3) ? parent.bottom : undefined
                    anchors.left: (index === 0 || index === 2) ? parent.left : undefined
                    anchors.right: (index === 1 || index === 3) ? parent.right : undefined
                }
            }
        }
    }

    component CyberButton : Button {
        id: cBtn
        property color baseColor: palette.neonGreen
        property string btnText: "BUTTON"
        contentItem: Text {
            text: cBtn.btnText
            color: cBtn.pressed ? "#121826" : cBtn.baseColor
            font.family: "Courier New"
            font.pixelSize: 15
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: cBtn.pressed ? cBtn.baseColor : "transparent"
            border.color: cBtn.baseColor
            border.width: 1
            Behavior on color { ColorAnimation { duration: 100 } }
        }
    }

    component RadarBackground : Item {
        id: radar
        property bool isScanning: false
        opacity: isScanning ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 600 } }

        Canvas {
            id: radarCanvas
            anchors.fill: parent
            property real angle: 0
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var cx = width / 2
                var cy = height / 2
                var r = Math.min(cx, cy) - 10

                ctx.strokeStyle = "rgba(0, 200, 83, 0.2)"
                ctx.lineWidth = 1
                ctx.beginPath()
                ctx.moveTo(cx, 0)
                ctx.lineTo(cx, height)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(0, cy)
                ctx.lineTo(width, cy)
                ctx.stroke()

                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, Math.PI * 2)
                ctx.stroke()

                ctx.beginPath()
                ctx.arc(cx, cy, r * 0.66, 0, Math.PI * 2)
                ctx.stroke()

                ctx.beginPath()
                ctx.arc(cx, cy, r * 0.33, 0, Math.PI * 2)
                ctx.stroke()

                if (radar.isScanning) {
                    var sweep = Math.PI / 2
                    for (var i = 0; i < 30; i++) {
                        ctx.beginPath()
                        ctx.moveTo(cx, cy)
                        var a1 = angle - (i * sweep / 30)
                        var a2 = angle - ((i + 1) * sweep / 30)
                        ctx.arc(cx, cy, r, a1, a2, true)
                        ctx.fillStyle = "rgba(0, 200, 83, " + (0.4 * (1.0 - i/30.0)) + ")"
                        ctx.fill()
                    }
                }
            }

            Timer {
                interval: 16
                running: radar.isScanning
                repeat: true
                onTriggered: {
                    radarCanvas.angle = (radarCanvas.angle + 0.15) % (Math.PI * 2)
                    radarCanvas.requestPaint()
                }
            }
        } // Canvas 闭合
    } // RadarBackground 闭合

} // Window (root) 闭合