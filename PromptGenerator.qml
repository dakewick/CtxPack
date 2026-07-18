import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    // 向主窗体发送返回信号
    signal backRequested()

    // 代码雷达后端 (由 Main.qml 注入)
    property var codeRadarBackend: null

    // 内部固化调色板
    QtObject {
        id: localPalette
        readonly property color bgTop: "#121826"
        readonly property color bgBottom: "#0A0E17"
        readonly property color neonCyan: "#00B4D8"
        readonly property color neonGreen: "#00C853"
        readonly property color panelBg: "#171E2E"
        readonly property color textMain: "#CBD5E1"
        readonly property color textDim: "#64748B"
    }

    Component.onCompleted: {
        generatePrompt()
    }

    // 提示词生成核心逻辑
    function generatePrompt() {
        if (!id_cbVersion || !id_txtReq || !id_txtOutput) {
            return
        }

        var activeRules = []
        if (id_chkModern.checked) activeRules.push("* 【语法规范】强制使用现代 C++ (C++17/20) 及 Qt 6 推荐语法。")
        if (id_chkLoop.checked) activeRules.push("* 【事件驱动】禁止长循环阻塞，须用事件驱动或异步设计。")
        if (id_chkMem.checked) activeRules.push("* 【内存安全】跨线程销毁强制使用 deleteLater；严格管理对象父子树。")
        if (id_chkQml.checked) activeRules.push("* 【QML所有权】C++向QML传递QObject指针时，必须显式声明 QQmlEngine::CppOwnership。")
        if (id_chkMvc.checked) activeRules.push("* 【架构解耦】遵循 MVC/MVVM 架构，C++ 端只负责业务逻辑与数据准备，绝对不直接操作 UI。")
        if (id_chkRobust.checked) activeRules.push("* 【健壮性】代码必须具备强健壮性（涵盖指针判空、通信超时异常处理）。")

        var rulesStr = activeRules.length > 0 ? activeRules.join("\n") : "* 遵循 Qt 官方最佳实践即可。"
        var codeLogSection = id_txtCodeLog.text.trim() !== "" ? "【现有代码/报错日志】\n" + id_txtCodeLog.text + "\n\n" : ""

        var formatStr = "【专家级剖析】：包含代码、底层机制剖析及排查步骤。"
        if (id_rbDiff.checked) formatStr = "【补丁模式 (Diff)】：仅输出需修改/新增的代码片段，极致节约 Token。"
        else if (id_rbBrief.checked) formatStr = "【极简代码片段】：仅输出核心实现代码，省略基础 #include。"
        else if (id_rbFull.checked) formatStr = "【完整工程文件】：输出 .h 和 .cpp，适合直接集成。"

        var prompt =
            "【身份设定】\n" +
            "你是一位拥有 10 年以上经验的 Qt 软件架构师与现代 C++ 专家。\n\n" +
            "【背景 Context】\n" +
            "- 框架版本：" + id_cbVersion.currentText + "\n" +
            "- 目标平台：" + id_cbPlatform.currentText + " | 编译器：" + id_cbToolchain.currentText + "\n" +
            "- 构建工具：" + id_cbBuild.currentText + "\n" +
            "- 整体架构：" + id_cbArch.currentText + "\n" +
            "- 图形后端：" + id_cbGraphics.currentText + "\n\n" +
            "【任务 Task】\n" +
            "请帮我完成 [ " + id_cbCategory.currentText + " ] 相关的开发任务。具体需求如下：\n" +
            id_txtReq.text + "\n\n" +
            codeLogSection +
            "【约束 Constraint】\n" +
            rulesStr + "\n\n" +
            "【反幻觉与兜底指令】\n" +
            "1. 绝不伪造 API：如果你无法 100% 确定某个 Qt API 是否存在，绝不允许自行编造。\n" +
            "2. 严格限制依赖：只允许使用 Qt 原生模块与目标环境对应的 C++ 标准库。\n\n" +
            "【格式 Format】\n" +
            formatStr

        id_txtOutput.text = prompt
    }

    Rectangle {
        anchors.fill: parent
        color: localPalette.bgBottom
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Button {
                id: btnBack
                text: "< 返回主控台"
                Layout.preferredHeight: 32
                Layout.preferredWidth: 130
                contentItem: Text {
                    text: btnBack.text
                    color: btnBack.pressed ? "#121826" : localPalette.neonCyan
                    font.family: "Courier New"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: btnBack.pressed ? localPalette.neonCyan : "transparent"
                    border.color: localPalette.neonCyan
                    border.width: 1
                    radius: 2
                    Behavior on color { ColorAnimation { duration: 100 } }
                }
                onClicked: root.backRequested()
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "🚀 CtxPack // PROMPT_GEAR"
                font.pixelSize: 16
                font.bold: true
                font.family: "Courier New"
                color: localPalette.neonCyan
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                width: parent.width - 10
                spacing: 10

                GroupBox {
                    id: grpContext
                    title: "【背景 Context】项目环境"
                    Layout.fillWidth: true
                    background: Rectangle { color: localPalette.panelBg; border.color: localPalette.textDim; radius: 4 }
                    label: Text { text: grpContext.title; color: localPalette.neonCyan; font.bold: true }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4

                        RowLayout {
                            Text { text: "Qt 版本:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbVersion; model: ["Qt 6.x (现代标准)", "Qt 5.15 (遗留维护)", "PyQt6/PySide6"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                        RowLayout {
                            Text { text: "目标平台:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbPlatform; model: ["Windows", "Linux", "macOS", "跨平台通用"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                        RowLayout {
                            Text { text: "工具链:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbToolchain; model: ["MSVC", "GCC/MinGW", "Clang"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                        RowLayout {
                            Text { text: "构建系统:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbBuild; model: ["CMake", "qmake", "Qbs"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                        RowLayout {
                            Text { text: "核心架构:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbArch; model: ["QML 前端 + C++ 后端", "纯 QWidget 桌面端", "无头服务端 (Console)", "Qt for Embedded Linux", "Qt for WebAssembly"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                        RowLayout {
                            Text { text: "图形后端:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbGraphics; model: ["Qt RHI (默认)", "OpenGL", "Vulkan", "纯软件渲染"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                    }
                }

                GroupBox {
                    id: grpTask
                    title: "【任务 Task】需求设定"
                    Layout.fillWidth: true
                    background: Rectangle { color: localPalette.panelBg; border.color: localPalette.textDim; radius: 4 }
                    label: Text { text: grpTask.title; color: localPalette.neonCyan; font.bold: true }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4
                        CyberComboBox { id: id_cbCategory; model: ["UI 与动画", "C++/QML 混合编程", "跨线程与并发", "硬件与网络通信", "内存排错与架构", "数据库与本地存储", "CMake 工程配置"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        Text { text: "具体需求说明:"; color: localPalette.textMain }
                        TextArea {
                            id: id_txtReq
                            placeholderText: "输入重构或增量需求..."
                            color: localPalette.textMain
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            wrapMode: TextEdit.Wrap
                            background: Rectangle { color: localPalette.bgBottom; border.color: localPalette.textDim }
                            onTextChanged: root.generatePrompt()
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "现有代码/日志 (选填):"; color: localPalette.textMain }
                            Item { Layout.fillWidth: true }

                            // ==========================================
                            // ⚡ 核心修复：单例且静态的【复制代码】按钮
                            // ==========================================
                            Button {
                                id: btnCopyLog
                                text: "📋 复制代码"
                                Layout.preferredHeight: 26

                                Timer {
                                    id: logCopyTimer
                                    interval: 1500
                                    repeat: false
                                    onTriggered: btnCopyLog.text = "📋 复制代码"
                                }

                                contentItem: Text {
                                    text: btnCopyLog.text
                                    color: btnCopyLog.pressed ? "#121826" : localPalette.neonCyan
                                    font.family: "Courier New"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    color: btnCopyLog.pressed ? localPalette.neonCyan : "transparent"
                                    border.color: localPalette.neonCyan
                                    border.width: 1
                                    radius: 2
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                                onClicked: {
                                    if (id_txtCodeLog.text.trim() === "") return;

                                    id_txtCodeLog.selectAll()
                                    id_txtCodeLog.copy()
                                    id_txtCodeLog.deselect()

                                    btnCopyLog.text = "[ ✔_COPIED ]"
                                    logCopyTimer.start()
                                }
                            }

                            Button {
                                id: btnRadar
                                text: "📡 代码雷达"
                                Layout.preferredHeight: 26
                                contentItem: Text {
                                    text: btnRadar.text
                                    color: btnRadar.pressed ? "#121826" : localPalette.neonGreen
                                    font.family: "Courier New"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    color: btnRadar.pressed ? localPalette.neonGreen : "transparent"
                                    border.color: localPalette.neonGreen
                                    border.width: 1
                                    radius: 2
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                                onClicked: radarPopup.open()
                            }
                        }
                        TextArea {
                            id: id_txtCodeLog
                            placeholderText: "粘贴相关源码或崩溃日志..."
                            color: localPalette.textMain
                            Layout.fillWidth: true
                            Layout.preferredHeight: 60
                            font.family: "Courier New"
                            font.pixelSize: 11
                            wrapMode: TextEdit.Wrap
                            background: Rectangle { color: localPalette.bgBottom; border.color: localPalette.textDim }
                            onTextChanged: root.generatePrompt()
                        }
                    }
                }

                // ==========================================
                // 内部组件定义
                // ==========================================
                component CyberCheckBox : CheckBox {
                    id: cChk
                    contentItem: Text {
                        text: cChk.text
                        font.family: "Microsoft YaHei"
                        font.pixelSize: 13
                        color: cChk.checked ? localPalette.neonCyan : (cChk.hovered ? "#FFFFFF" : localPalette.textMain)
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: cChk.indicator.width + cChk.spacing
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                component CyberRadioButton : RadioButton {
                    id: cRad
                    contentItem: Text {
                        text: cRad.text
                        font.family: "Microsoft YaHei"
                        font.pixelSize: 13
                        color: cRad.checked ? localPalette.neonCyan : (cRad.hovered ? "#FFFFFF" : localPalette.textMain)
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: cRad.indicator.width + cRad.spacing
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                component CyberComboBox : ComboBox {
                    id: control
                    contentItem: Text {
                        leftPadding: 10
                        rightPadding: control.indicator.width + control.spacing
                        text: control.displayText
                        font.family: "Courier New"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: localPalette.neonCyan
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    background: Rectangle {
                        implicitWidth: 120
                        implicitHeight: 32
                        color: localPalette.bgBottom
                        border.color: control.pressed || control.popup.visible ? localPalette.neonGreen : Qt.alpha(localPalette.neonCyan, 0.5)
                        border.width: 1
                        radius: 2
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }
                    indicator: Text {
                        x: control.width - width - control.rightPadding + 5
                        y: control.topPadding + (control.availableHeight - height) / 2
                        text: "▼"
                        font.pixelSize: 10
                        color: control.pressed || control.popup.visible ? localPalette.neonGreen : localPalette.neonCyan
                    }
                    popup: Popup {
                        y: control.height - 1
                        width: control.width
                        implicitHeight: contentItem.implicitHeight
                        padding: 1
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: control.popup.visible ? control.delegateModel : null
                            currentIndex: control.highlightedIndex
                            ScrollIndicator.vertical: ScrollIndicator { }
                        }
                        background: Rectangle {
                            color: localPalette.panelBg
                            border.color: localPalette.neonCyan
                            border.width: 1
                            radius: 2
                        }
                    }
                    delegate: ItemDelegate {
                        width: control.width
                        padding: 10
                        contentItem: Text {
                            text: modelData
                            color: highlighted ? localPalette.bgBottom : localPalette.textMain
                            font.family: "Microsoft YaHei"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: highlighted ? localPalette.neonCyan : "transparent"
                        }
                        highlighted: control.highlightedIndex === index
                    }
                }

                GroupBox {
                    id: grpConstraint
                    title: "【约束 Constraint】高阶防雷"
                    Layout.fillWidth: true
                    background: Rectangle { color: localPalette.panelBg; border.color: localPalette.textDim; radius: 4 }
                    label: Text { text: grpConstraint.title; color: localPalette.neonCyan; font.bold: true }

                    palette.windowText: localPalette.textMain
                    palette.base: localPalette.bgBottom
                    palette.button: localPalette.bgTop

                    ColumnLayout {
                        spacing: 1
                        CyberCheckBox { id: id_chkModern; text: "现代 C++ / Qt 6 推荐语法"; checked: true; onCheckedChanged: root.generatePrompt() }
                        CyberCheckBox { id: id_chkLoop; text: "基于事件驱动 (防异步阻塞)"; checked: true; onCheckedChanged: root.generatePrompt() }
                        CyberCheckBox { id: id_chkMem; text: "跨线程安全调用 (deleteLater)"; checked: true; onCheckedChanged: root.generatePrompt() }
                        CyberCheckBox { id: id_chkQml; text: "QML 传递所有权声明 (防 GC)"; checked: true; onCheckedChanged: root.generatePrompt() }
                        CyberCheckBox { id: id_chkMvc; text: "MVC 严格解耦 (C++ 不操纵UI)"; checked: true; onCheckedChanged: root.generatePrompt() }
                        CyberCheckBox { id: id_chkRobust; text: "包含完善边界异常/指针判空"; checked: true; onCheckedChanged: root.generatePrompt() }
                    }
                }

                GroupBox {
                    id: grpFormat
                    title: "【格式 Format】交付样式"
                    Layout.fillWidth: true
                    background: Rectangle { color: localPalette.panelBg; border.color: localPalette.textDim; radius: 4 }
                    label: Text { text: grpFormat.title; color: localPalette.neonCyan; font.bold: true }

                    palette.windowText: localPalette.textMain
                    palette.base: localPalette.bgBottom
                    palette.button: localPalette.bgTop

                    ColumnLayout {
                        spacing: 1
                        CyberRadioButton { id: id_rbDiff; text: "补丁模式 (Diff) [推荐本地模型]"; checked: true; onCheckedChanged: root.generatePrompt() }
                        CyberRadioButton { id: id_rbBrief; text: "极简核心代码片段"; onCheckedChanged: root.generatePrompt() }
                        CyberRadioButton { id: id_rbFull; text: "完整文件配置 (.h/.cpp)"; onCheckedChanged: root.generatePrompt() }
                        CyberRadioButton { id: id_rbExpert; text: "专家级底层机制剖析"; onCheckedChanged: root.generatePrompt() }
                    }
                }
            }
        }

        // ==========================================
        // 底部：终极提示词输出区域
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            spacing: 6

            Text {
                text: "🔥 生成的终极提示词:"
                color: localPalette.neonCyan
                font.bold: true
                font.pixelSize: 14
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 8
                    background: Rectangle { color: localPalette.bgBottom }
                    contentItem: Rectangle { color: localPalette.neonCyan; radius: 4 }
                }

                TextArea {
                    id: id_txtOutput
                    readOnly: true
                    wrapMode: TextArea.Wrap
                    font.family: "Courier New"
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    color: localPalette.neonGreen
                    selectionColor: localPalette.neonGreen
                    selectedTextColor: "#121826"

                    background: Rectangle {
                        color: localPalette.panelBg
                        border.color: localPalette.neonCyan
                        radius: 4
                    }
                }
            }

            Button {
                id: btnCopyPrompt
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                text: "📋 一键复制提示词"

                contentItem: Text {
                    text: btnCopyPrompt.text
                    color: btnCopyPrompt.pressed ? "#121826" : localPalette.neonCyan
                    font.family: "Courier New"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: btnCopyPrompt.pressed ? localPalette.neonCyan : "transparent"
                    border.color: localPalette.neonCyan
                    border.width: 1
                    radius: 2
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                onClicked: {
                    id_txtOutput.selectAll()
                    id_txtOutput.copy()
                    id_txtOutput.deselect()

                    var originalText = text
                    text = "[ ✔_COPIED ]"
                    var t = Qt.createQmlObject('import QtQuick 2.0; Timer { interval: 1500; repeat: false; }', btnCopyPrompt)
                    t.triggered.connect(function() { text = originalText; t.destroy() })
                    t.start()
                }
            }
        }
    }

    // ==========================================
    // 📡 代码雷达搜索弹窗
    // ==========================================
    Popup {
        id: radarPopup
        anchors.centerIn: parent
        width: parent.width * 0.85
        height: parent.height * 0.8
        modal: true
        closePolicy: Popup.CloseOnEscape

        background: Rectangle {
            color: localPalette.panelBg
            border.color: localPalette.neonGreen
            border.width: 1
            radius: 4
        }

        onOpened: {
            radarInput.text = ""
            radarResultText.text = ""
            radarInput.forceActiveFocus()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Text {
                text: "📡 代码雷达 // CODE_RADAR"
                color: localPalette.neonGreen
                font.family: "Courier New"
                font.pixelSize: 16
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                TextField {
                    id: radarInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    placeholderText: "输入搜索词，如 void"
                    placeholderTextColor: localPalette.textDim
                    color: localPalette.neonCyan
                    font.family: "Courier New"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    leftPadding: 10
                    background: Rectangle {
                        color: localPalette.bgBottom
                        border.color: Qt.alpha(localPalette.neonCyan, 0.5)
                        border.width: 1
                        radius: 2
                    }
                    Keys.onReturnPressed: btnSearch.clicked()
                }

                Button {
                    id: btnSearch
                    text: "🔍 搜索"
                    Layout.preferredHeight: 34
                    Layout.preferredWidth: 80
                    contentItem: Text {
                        text: btnSearch.text
                        color: btnSearch.pressed ? "#121826" : localPalette.neonGreen
                        font.family: "Courier New"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: btnSearch.pressed ? localPalette.neonGreen : "transparent"
                        border.color: localPalette.neonGreen
                        border.width: 1
                        radius: 2
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    onClicked: {
                        if (!codeRadarBackend) {
                            radarResultText.text = "[ERR] 后端未就绪"
                            return
                        }
                        if (radarInput.text.trim() === "") {
                            radarResultText.text = "[ERR] 搜索词不能为空"
                            return
                        }
                        radarResultText.text = "⏳ 正在扫描..."
                        btnSearch.enabled = false

                        var ret = codeRadarBackend.searchCodeRadar(codeRadarBackend.currentProjectPath, radarInput.text.trim())
                        btnSearch.enabled = true

                        if (ret.status === "error") {
                            radarResultText.text = "❌ " + ret.message
                            return
                        }

                        var count = ret.count
                        var lines = []
                        lines.push("🔍 共命中 " + count + " 处:\n")
                        var results = ret.results
                        if (results && results.length > 0) {
                            for (var i = 0; i < results.length; i++) {
                                var r = results[i]
                                lines.push("━━━━━━━━━━━━━━━━━━━━━━")
                                lines.push("📄 " + r.file + " : " + r.line + " 行")
                                lines.push("```\n" + r.code + "\n```\n")
                            }
                        } else {
                            lines.push("未找到匹配项")
                        }
                        radarResultText.text = lines.join("\n")
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 8
                    background: Rectangle { color: localPalette.bgBottom }
                    contentItem: Rectangle { color: localPalette.neonGreen; radius: 4 }
                }

                TextArea {
                    id: radarResultText
                    readOnly: true
                    wrapMode: TextArea.Wrap
                    font.family: "Courier New"
                    font.pixelSize: 12
                    color: localPalette.neonGreen
                    background: Rectangle {
                        color: localPalette.bgBottom
                        border.color: Qt.alpha(localPalette.neonGreen, 0.3)
                        border.width: 1
                        radius: 2
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    text: "📥 一键导入到代码区"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    contentItem: Text {
                        text: parent.text
                        color: parent.pressed ? "#121826" : localPalette.neonCyan
                        font.family: "Courier New"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.pressed ? localPalette.neonCyan : "transparent"
                        border.color: localPalette.neonCyan
                        border.width: 1
                        radius: 2
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    onClicked: {
                        var preview = radarResultText.text
                        if (preview && preview.indexOf("❌") !== 0 && preview.indexOf("[ERR]") !== 0 && preview.indexOf("⏳") !== 0) {
                            // 追加防粘连逻辑
                            if (id_txtCodeLog.text.trim() === "") {
                                id_txtCodeLog.text = preview
                            } else {
                                id_txtCodeLog.text += "\n\n" + preview
                            }
                        }
                        radarPopup.close()
                    }
                }

                Button {
                    text: "取消"
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 36
                    contentItem: Text {
                        text: parent.text
                        color: parent.pressed ? "#121826" : localPalette.textDim
                        font.family: "Courier New"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.pressed ? localPalette.textDim : "transparent"
                        border.color: localPalette.textDim
                        border.width: 1
                        radius: 2
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    onClicked: radarPopup.close()
                }
            }
        }
    }
}