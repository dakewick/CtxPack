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
        if (!id_cbArch || !id_txtReq || !id_txtOutput) {
            return
        }

        var activeRules = []
        if (id_chkMISRA.checked) activeRules.push("* 【MISRA-C】严格遵循 MISRA-C:2012 编码规范，杜绝未定义行为。")
        if (id_chkISR.checked) activeRules.push("* 【中断安全】ISR 中禁止阻塞调用、动态内存分配及浮点运算。")
        if (id_chkMemAlign.checked) activeRules.push("* 【内存对齐】结构体强制指定 packed 属性，DMA 缓冲区需按 32 字节对齐。")
        if (id_chkPower.checked) activeRules.push("* 【低功耗】空闲时强制休眠外设，优先使用等待中断指令(WFI)。")
        if (id_chkRTOS.checked) activeRules.push("* 【RTOS 规范】线程栈大小显式计算，IPC 优先使用消息队列而非全局变量。")
        if (id_chkBoot.checked) activeRules.push("* 【启动安全】看门狗在 main() 入口处立即初始化，失效后 3s 内硬件复位。")
        if (id_chkIsolation.checked) activeRules.push("* 【电气与抗干扰】处理 24V 等高压外部传感器信号时，代码必须配合光耦/二极管隔离架构进行防抖与 NPN/PNP 逻辑适配。")

        var rulesStr = activeRules.length > 0 ? activeRules.join("\n") : "* 遵循嵌入式行业最佳实践。"
        var codeLogSection = id_txtCodeLog.text.trim() !== "" ? "【现有代码/报错日志】\n" + id_txtCodeLog.text + "\n\n" : ""

        var formatStr = "【专家级剖析】：包含 MCU 底层寄存器配置、时序分析及排查步骤。"
        if (id_rbDiff.checked) formatStr = "【补丁模式 (Diff)】：仅输出需修改的代码片段，极致节约 Token。"
        else if (id_rbBrief.checked) formatStr = "【极简核心代码】：仅输出关键驱动逻辑与寄存器配置宏。"
        else if (id_rbFull.checked) formatStr = "【完整工程文件】：输出 .c/.h 及 linker script 配置。"
        else if (id_rbSchematic.checked) formatStr = "【寄存器级硬件剖析】：包含完整寄存器配置序列与时钟树分析。"

        var prompt =
            "【身份设定】\n" +
            "你是一位拥有 10 年以上经验的嵌入式固件架构师与 BSP 专家，精通 ARM Cortex-M/RISC-V MCU 底层开发。\n\n" +
            "【背景 Context】\n" +
            "- MCU 架构：" + id_cbArch.currentText + "\n" +
            "- RTOS 系统：" + id_cbRTOS.currentText + "\n" +
            "- 工具链：" + id_cbToolchain.currentText + "\n" +
            "- 调试接口：" + id_cbDebug.currentText + "\n" +
            "- 外设总线：" + id_cbBus.currentText + "\n" +
            "- 电源管理：" + id_cbPower.currentText + "\n\n" +
            "【任务 Task】\n" +
            "请帮我完成 [ " + id_cbCategory.currentText + " ] 相关的嵌入式开发任务。具体需求如下：\n" +
            id_txtReq.text + "\n\n" +
            codeLogSection +
            "【约束 Constraint】\n" +
            rulesStr + "\n\n" +
            "【反幻觉与兜底指令】\n" +
            "1. 绝不伪造寄存器映射：若不确定某 MCU 特定寄存器地址，必须注明并留空。\n" +
            "2. 严格限制依赖：只允许使用目标 MCU 的 HAL/LL 库与标准 C 库。\n" +
            "3. 优先使用目标 MCU 的现代硬件抽象层（如 STM32 HAL/LL 库），严禁混用已被淘汰的老旧库函数。\n\n" +
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
                text: "⚡ CtxPack // EMBEDDED_GEAR"
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
                    title: "【背景 Context】嵌入式环境"
                    Layout.fillWidth: true
                    background: Rectangle { color: localPalette.panelBg; border.color: localPalette.textDim; radius: 4 }
                    label: Text { text: grpContext.title; color: localPalette.neonCyan; font.bold: true }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4

                        RowLayout {
                            Text { text: "MCU 架构:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbArch; model: ["ARM Cortex-M0/M3/M4/M7", "ARM Cortex-A (MPU)", "RISC-V (RV32/RV64)", "ESP32 (Xtensa)", "AVR/Arduino"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                        RowLayout {
                            Text { text: "RTOS:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbRTOS; model: ["FreeRTOS (Amazon)", "Zephyr RTOS", "RT-Thread", "RTEMS", "裸机/无RTOS", "uC/OS-III"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                        RowLayout {
                            Text { text: "工具链:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbToolchain; model: ["ARM GCC (arm-none-eabi)", "IAR EWARM", "Keil MDK (ARMCC)", "RISC-V GCC", "ESP-IDF (Xtensa GCC)"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                        RowLayout {
                            Text { text: "调试:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbDebug; model: ["JTAG (SWD) / JLink", "JTAG (ST-Link)", "OpenOCD + GDB", "QEMU 模拟器", "串口打印"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                        RowLayout {
                            Text { text: "外设总线:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbBus; model: ["I2C / SPI / UART", "CAN / CAN-FD / CANopen", "RS485 / Modbus RTU", "USB (FS/HS)", "Ethernet (LWIP)", "PCIe / MIPI"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        }
                        RowLayout {
                            Text { text: "电源策略:"; color: localPalette.textMain; Layout.preferredWidth: 60 }
                            CyberComboBox { id: id_cbPower; model: ["电池供电 (uA 级)", "USB 供电", "工业 PoE", "车载电源 (12/24V)"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
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
                        CyberComboBox { id: id_cbCategory; model: ["驱动开发 (HAL/LL)", "低功耗与电源优化", "RTOS 移植与调度", "BSP 板级支持包", "通信协议栈", "Bootloader 开发", "外设 DMA 驱动", "电机闭环控制 (PID/运动规划)"]; Layout.fillWidth: true; onCurrentIndexChanged: root.generatePrompt() }
                        Text { text: "具体需求说明:"; color: localPalette.textMain }
                        TextArea {
                            id: id_txtReq
                            placeholderText: "输入驱动接口、功耗指标或外设需求..."
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
                            placeholderText: "粘贴寄存器配置、异常栈回溯..."
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
                    title: "【约束 Constraint】防雷规范"
                    Layout.fillWidth: true
                    background: Rectangle { color: localPalette.panelBg; border.color: localPalette.textDim; radius: 4 }
                    label: Text { text: grpConstraint.title; color: localPalette.neonCyan; font.bold: true }
                    palette.windowText: localPalette.textMain
                    palette.base: localPalette.bgBottom
                    palette.button: localPalette.bgTop

                    ColumnLayout {
                        spacing: 1
                        CyberCheckBox { id: id_chkMISRA; text: "MISRA-C:2012 编码规范"; checked: true; onCheckedChanged: root.generatePrompt() }
                        CyberCheckBox { id: id_chkISR; text: "中断安全 (ISR 防阻塞)"; checked: true; onCheckedChanged: root.generatePrompt() }
                        CyberCheckBox { id: id_chkMemAlign; text: "内存对齐 & DMA 缓冲区"; checked: true; onCheckedChanged: root.generatePrompt() }
                        CyberCheckBox { id: id_chkPower; text: "WFI 低功耗休眠策略"; checked: true; onCheckedChanged: root.generatePrompt() }
                        CyberCheckBox { id: id_chkRTOS; text: "RTOS IPC 消息队列优先"; checked: true; onCheckedChanged: root.generatePrompt() }
                        CyberCheckBox { id: id_chkBoot; text: "看门狗硬件安全启动"; checked: true; onCheckedChanged: root.generatePrompt() }
                        CyberCheckBox { id: id_chkIsolation; text: "电气隔离与抗干扰 (光耦/防抖/NPN-PNP)"; checked: true; onCheckedChanged: root.generatePrompt() }
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
                        CyberRadioButton { id: id_rbFull; text: "完整工程配置 (.c/.h/linker)"; onCheckedChanged: root.generatePrompt() }
                        CyberRadioButton { id: id_rbSchematic; text: "寄存器级硬件剖析"; onCheckedChanged: root.generatePrompt() }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            spacing: 6

            Text {
                text: "🔥 生成的嵌入式提示词:"
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