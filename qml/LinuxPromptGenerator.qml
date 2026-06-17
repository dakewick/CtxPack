import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    signal backRequested()

    property var codeRadarBackend: null

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

    function generatePrompt() {
        if (!id_cbDistro || !id_txtReq || !id_txtOutput) {
            return
        }

        var activeRules = []
        if (id_chkPOSIX.checked) activeRules.push("* 【POSIX 兼容】严格遵循 POSIX.1-2008 标准，禁止使用 Linux 特有扩展。")
        if (id_chkFHS.checked) activeRules.push("* 【FHS 规范】文件路径遵从 Filesystem Hierarchy Standard 布局。")
        if (id_chkSecurity.checked) activeRules.push("* 【安全加固】最小权限原则，systemd服务使用 DynamicUser 与 ProtectSystem。")
        if (id_chkLog.checked) activeRules.push("* 【日志规范】结构化日志优先写入 journald，兼容 syslog 协议。")
        if (id_chkSignal.checked) activeRules.push("* 【信号安全】信号处理函数仅置标志位，禁止在信号上下文中 malloc/printf。")
        if (id_chkPipe.checked) activeRules.push("* 【进程通信】管道与 socket 通信必须处理 SIGPIPE 与 EINTR。")

        var rulesStr = activeRules.length > 0 ? activeRules.join("\n") : "* 遵循 Linux 社区最佳实践。"
        var codeLogSection = id_txtCodeLog.text.trim() !== "" ? "【现有代码/报错日志】\n" + id_txtCodeLog.text + "\n\n" : ""

        var formatStr = "【专家级剖析】：包含系统调用链路、内核交互机制及性能分析。"
        if (id_rbDiff.checked) formatStr = "【补丁模式 (Diff)】：仅输出需修改的代码片段，极致节约 Token。"
        else if (id_rbBrief.checked) formatStr = "【极简核心代码】：仅输出关键逻辑与系统调用序列。"
        else if (id_rbFull.checked) formatStr = "【完整工程文件】：输出 Makefile/CMakeLists.txt + 源码 + systemd 配置。"
        else if (id_rbKernel.checked) formatStr = "【内核级深度分析】：包含 sysfs/debugfs 接口设计与 proc 文件系统交互。"

        var prompt =
            "【身份设定】\n" +
            "你是一位拥有 10 年以上经验的 Linux 系统架构师与内核开发者，精通系统编程与 DevOps。\n\n" +
            "【背景 Context】\n" +
            "- 发行版：" + id_cbDistro.currentText + "\n" +
            "- 内核系列：" + id_cbKernel.currentText + "\n" +
            "- CPU 架构：" + id_cbCpuArch.currentText + "\n" +
            "- Init 系统：" + id_cbInit.currentText + "\n" +
            "- 桌面环境：" + id_cbDesktop.currentText + "\n" +
            "- 包管理器：" + id_cbPkg.currentText + "\n" +
            "- 构建系统：" + id_cbBuild.currentText + "\n" +
            "- 容器方案：" + id_cbContainer.currentText + "\n\n" +
            "【任务 Task】\n" +
            "请帮我完成 [ " + id_cbCategory.currentText + " ] 相关的 Linux 开发任务。具体需求如下：\n" +
            id_txtReq.text + "\n\n" +
            codeLogSection +
            "【约束 Constraint】\n" +
            rulesStr + "\n\n" +
            "【反幻觉与兜底指令】\n" +
            "1. 绝不伪造系统调用：若不确定某 syscall 在不同的内核版本中的行为差异，必须注明。\n" +
            "2. 严格限制依赖：优先使用 glibc/musl 与标准 Linux 内核接口，避免外部闭源模块。\n" +
            "3. 必须在代码注释中标注所使用核心 API 的最低内核版本要求（如 Requires Linux >= 5.1）。\n\n" +
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
                text: "🐧 CtxPack // LINUX_GEAR"
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
                    title: "【背景 Context】Linux 环境"
                    Layout.fillWidth: true
                    background: Rectangle { color: localPalette.panelBg; border.color: localPalette.textDim; radius: 4 }
                    label: Text { text: grpContext.title; color: localPalette.neonCyan; font.bold: true }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4

                        RowLayout {
                            Text { text: "发行版:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbDistro; model: ["Ubuntu/Debian", "Arch Linux (Manjaro)", "Fedora/RHEL/CentOS", "openSUSE/SLES", "Alpine Linux (musl)", "Yocto/嵌入式 Linux"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                        RowLayout {
                            Text { text: "内核:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbKernel; model: ["主线 Linux (6.x)", "长期支持 LTS (6.x)", "实时内核 PREEMPT_RT", "RHEL 兼容内核", "自定义编译内核"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                        RowLayout {
                            Text { text: "Init:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbInit; model: ["systemd", "OpenRC", "BusyBox init", "runit / s6"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                        RowLayout {
                            Text { text: "桌面:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbDesktop; model: ["GNOME (Wayland)", "KDE Plasma (Wayland/X11)", "Xfce / LXQt (轻量)", "无头服务器 (CLI)"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                        RowLayout {
                            Text { text: "包管理器:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbPkg; model: ["apt (deb)", "pacman (arch)", "dnf/yum (rpm)", "apk (alpine)", "Portage (gentoo)"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                        RowLayout {
                            Text { text: "CPU 架构:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbCpuArch; model: ["x86_64 (AMD64)", "aarch64 (ARM64)", "RISC-V (RV64GC)", "x86 (32-bit)", "ARMv7 (32-bit)"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                        RowLayout {
                            Text { text: "构建系统:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbBuild; model: ["CMake + GCC", "CMake + Clang", "Makefile + GCC", "Meson + Ninja", "Autotools (./configure)"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                        RowLayout {
                            Text { text: "容器:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbContainer; model: ["Docker / Podman", "LXC / LXD", "Kubernetes (K8s)", "无容器 (裸金属)", "Flatpak / Snap"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
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
                        CyberComboBox { id: id_cbCategory; model: ["Shell 脚本与自动化", "系统服务与 daemon", "Linux 内核模块", "桌面应用 (Qt/GTK)", "网络与安全配置", "容器化与 CI/CD", "性能调优与 Tracing"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        Text { text: "具体需求说明:"; color: localPalette.textMain }
                        TextArea {
                            id: id_txtReq
                            placeholderText: "描述需要实现的系统服务、脚本或内核功能..."
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
                            placeholderText: "粘贴 syslog、dmesg 或源码..."
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
                    title: "【约束 Constraint】规范遵守"
                    Layout.fillWidth: true
                    background: Rectangle { color: localPalette.panelBg; border.color: localPalette.textDim; radius: 4 }
                    label: Text { text: grpConstraint.title; color: localPalette.neonCyan; font.bold: true }
                    palette.windowText: localPalette.textMain
                    palette.base: localPalette.bgBottom
                    palette.button: localPalette.bgTop

                    ColumnLayout {
                        spacing: 1
                        CyberCheckBox { id: id_chkPOSIX; text: "POSIX.1-2008 兼容"; checked: true; onCheckedChanged: root.generatePrompt() }
                        CyberCheckBox { id: id_chkFHS; text: "FHS 文件系统层级规范"; checked: true; onCheckedChanged: root.generatePrompt() }
                        CyberCheckBox { id: id_chkSecurity; text: "systemd 安全加固"; checked: true; onCheckedChanged: root.generatePrompt() }
                        CyberCheckBox { id: id_chkLog; text: "journald 结构化日志"; checked: true; onCheckedChanged: root.generatePrompt() }
                        CyberCheckBox { id: id_chkSignal; text: "信号安全 (防异步)"; checked: true; onCheckedChanged: root.generatePrompt() }
                        CyberCheckBox { id: id_chkPipe; text: "SIGPIPE/EINTR 处理"; checked: true; onCheckedChanged: root.generatePrompt() }
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
                        CyberRadioButton { id: id_rbBrief; text: "极简核心代码"; onCheckedChanged: root.generatePrompt() }
                        CyberRadioButton { id: id_rbFull; text: "完整工程配置 (.c/Makefile/service)"; onCheckedChanged: root.generatePrompt() }
                        CyberRadioButton { id: id_rbKernel; text: "内核级深度分析"; onCheckedChanged: root.generatePrompt() }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            spacing: 6

            Text {
                text: "🔥 生成的 Linux 提示词:"
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

            // 搜索结果预览区
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

            // 底部按钮
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
                            id_txtCodeLog.text = preview
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