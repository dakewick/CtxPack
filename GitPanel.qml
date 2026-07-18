import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: parent ? Math.round(parent.width * 0.78) : 790
    height: Math.round(width * (19 / 25))
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property var gitBackend: null
    property bool hasGit: false
    property bool gitOk: true

    ListModel { id: tagData }

    QtObject {
        id: c
        readonly property color bg: "#0D1117"
        readonly property color panel: "#161B22"
        readonly property color border: "#30363D"
        readonly property color green: "#3FB950"
        readonly property color cyan: "#58A6FF"
        readonly property color orange: "#D29922"
        readonly property color red: "#F85149"
        readonly property color text: "#E6EDF3"
        readonly property color dim: "#8B949E"
        readonly property color bright: "#FFFFFF"
    }

    component StyledMenu: Menu {
        padding: 4
        background: Rectangle {
            implicitWidth: 210
            color: c.panel
            border.color: c.border
            border.width: 1
            radius: 6
        }
    }

    component StyledMenuItem: MenuItem {
        id: smi
        property color textColor: c.text
        implicitHeight: 30
        contentItem: Text {
            text: smi.text
            color: smi.enabled ? smi.textColor : c.dim
            font.family: "Consolas"; font.pixelSize: 11
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            leftPadding: 6
        }
        background: Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 2; anchors.rightMargin: 2
            color: smi.highlighted ? "#1F2A37" : "transparent"
            radius: 3
        }
    }

    StyledMenu {
        id: branchMenu
        property string branchName: ""
        property bool isCurrentBranch: false
        property bool isRemoteBranch: false

        StyledMenuItem {
            text: "➡️ 切换到该分支 (Checkout)"
            enabled: !branchMenu.isCurrentBranch
            onTriggered: {
                if (!gitBackend) return
                var res = gitBackend.checkoutBranch(branchMenu.branchName)
                if (res.status !== "success") branchError.show(friendlyGitError(res.message))
                Qt.callLater(function() { refreshBranches(); refreshChanges() })
            }
        }
        StyledMenuItem {
            text: "🔀 合并到当前分支 (Merge into Current)"
            enabled: !branchMenu.isCurrentBranch
            onTriggered: {
                if (!gitBackend) return
                var res = gitBackend.mergeBranch(branchMenu.branchName)
                if (res.status === "conflict") {
                    conflictDialog.conflictDetail = res.detail !== undefined ? res.detail : res.message
                    conflictDialog.open()
                } else if (res.status !== "success") {
                    branchError.show(friendlyGitError(res.message))
                }
                Qt.callLater(function() { refreshBranches(); refreshChanges() })
            }
        }
        StyledMenuItem {
            text: "🗑️ 删除分支 (Delete)"
            textColor: c.red
            enabled: !branchMenu.isCurrentBranch && !branchMenu.isRemoteBranch
            onTriggered: {
                if (!gitBackend) return
                var res = gitBackend.deleteBranch(branchMenu.branchName, false)
                if (res.status !== "success") branchError.show(friendlyGitError(res.message))
                Qt.callLater(refreshBranches)
            }
        }
    }

    StyledMenu {
        id: changeMenu
        property string filePath: ""

        StyledMenuItem {
            text: "添加到暂存区 (git add)"
            onTriggered: {
                if (!gitBackend) return
                gitBackend.addFile(changeMenu.filePath)
                Qt.callLater(refreshChanges)
            }
        }
        StyledMenuItem {
            text: "撤销修改 (git restore)"
            textColor: c.orange
            onTriggered: {
                confirmDialog.title = "撤销修改确认"
                confirmDialog.message = "将丢弃文件 \"" + changeMenu.filePath + "\" 的所有未提交修改，不可恢复。"
                confirmDialog.confirmText = "确认撤销"
                confirmDialog.confirmColor = c.orange
                confirmDialog.callback = function() {
                    if (!gitBackend) return
                    gitBackend.discardFile(changeMenu.filePath)
                    Qt.callLater(refreshChanges)
                }
                confirmDialog.open()
            }
        }
    }

    StyledMenu {
        id: historyMenu
        property string commitHash: ""
        property string commitMsg: ""

        function hasTag(hash) {
            for (var i = 0; i < tagData.count; i++)
                if (tagData.get(i).hash === hash) return true
            return false
        }

        StyledMenuItem {
            text: "🏷️ 为此版本打标签 (Tag)"
            textColor: c.green
            enabled: !historyMenu.hasTag(historyMenu.commitHash)
            onTriggered: {
                tagDialog.tagHash = historyMenu.commitHash
                tagDialog.tagMsg = historyMenu.commitMsg
                tagDialog.open()
            }
        }
        StyledMenuItem {
            text: "🗑️ 删除此版本标签 (Delete Tag)"
            textColor: c.red
            enabled: historyMenu.hasTag(historyMenu.commitHash)
            onTriggered: {
                if (!gitBackend) return
                var tag = ""
                for (var i = 0; i < tagData.count; i++) {
                    if (tagData.get(i).hash === historyMenu.commitHash) {
                        tag = tagData.get(i).name
                        break
                    }
                }
                confirmDialog.title = "删除标签确认"
                confirmDialog.message = "将永久删除标签 \"" + tag + "\"。"
                confirmDialog.confirmText = "确认删除"
                confirmDialog.confirmColor = c.red
                confirmDialog.callback = function() {
                    var res = gitBackend.deleteTag(tag)
                    if (res.status !== "success")
                        branchError.show("删除失败: " + friendlyGitError(res.message))
                    Qt.callLater(refreshHistory)
                }
                confirmDialog.open()
            }
        }
        StyledMenuItem {
            text: "⚠️ 强制回退到此版本 (Hard Reset)"
            textColor: c.red
            onTriggered: {
                resetConfirmDialog.targetHash = historyMenu.commitHash
                resetConfirmDialog.targetMsg = historyMenu.commitMsg
                resetConfirmDialog.open()
            }
        }
    }

    onOpened: {
        if (gitBackend) {
            gitOk = gitBackend.isGitAvailable
            if (!gitOk) { hasGit = false; return }
            gitBackend.setRepoPath(gitBackend.currentRepoPath)
            hasGit = gitBackend.isRepoInitialized()
            if (hasGit) refreshAll()
        }
    }

    function refreshAll() {
        refreshBranches()
        refreshChanges()
    }
    function friendlyGitError(msg) {
        if (msg.indexOf("not a valid branch name") !== -1)
            return "分支名不合法：不能包含空格及 ~ ^ : ? * [ \\ 等字符"
        if (msg.indexOf("already exists") !== -1)
            return "分支已存在或标签已存在"
        if (msg.indexOf("not fully merged") !== -1)
            return "分支未合并，无法安全删除"
        return msg
    }

    function tagsForCommit(hash) {
        var tags = []
        for (var i = 0; i < tagData.count; i++) {
            var t = tagData.get(i)
            if (t.hash === hash) tags.push(t.name)
        }
        return tags
    }
    function refreshHistory() {
        historyModel.clear()
        tagData.clear()
        if (!hasGit || !gitBackend) return
        var res = gitBackend.getCommitHistory(10)
        if (res.status === "success" && res.list) {
            for (var k = 0; k < res.list.length; k++)
                historyModel.append(res.list[k])
        }
        var tr = gitBackend.getTags()
        if (tr.status === "success" && tr.list) {
            for (var t = 0; t < tr.list.length; t++)
                tagData.append(tr.list[t])
        }
    }
    function refreshBranches() {
        branchModel.clear()
        if (!hasGit || !gitBackend) return
        var res = gitBackend.getBranches()
        if (res.status === "success" && res.list) {
            var i
            for (i = 0; i < res.list.length; i++)
                if (res.list[i].type === "local")
                    branchModel.append(res.list[i])
            for (i = 0; i < res.list.length; i++)
                if (res.list[i].type === "remote")
                    branchModel.append(res.list[i])
        }
    }
    function refreshChanges() {
        changeModel.clear()
        if (!hasGit || !gitBackend) return
        var res = gitBackend.getStatus()
        if (res.status === "success" && res.list) {
            for (var j = 0; j < res.list.length; j++)
                changeModel.append(res.list[j])
        }
    }

    function stateColor(state) {
        switch (state) {
            case "??": return c.dim
            case "M":  return c.orange
            case "A":  return c.green
            case "D":  return c.red
            case "R":  return c.cyan
            default:   return c.dim
        }
    }

    background: Rectangle {
        color: c.bg
        border.color: c.border
        border.width: 1
        radius: 8
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Text {
                text: "[ GIT PANEL ]"
                color: c.green
                font.family: "Consolas"; font.pixelSize: 15; font.weight: Font.Bold
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "[ 🕒 HISTORY ]"
                color: c.orange
                font.family: "Consolas"; font.pixelSize: 11
                visible: hasGit
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        refreshHistory()
                        historyPopup.open()
                    }
                }
            }
            Text {
                text: "[ REFRESH ]"
                color: c.cyan
                font.family: "Consolas"; font.pixelSize: 11
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        hasGit = gitBackend ? gitBackend.isRepoInitialized() : false
                        if (hasGit) refreshAll()
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: c.border }

        ColumnLayout {
            visible: !gitOk
            spacing: 12

            Item { Layout.preferredHeight: 20 }

            Text {
                Layout.fillWidth: true
                text: ">> 未检测到 Git 环境"
                color: c.red
                font.family: "Consolas"; font.pixelSize: 13; font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                text: "本机未安装 Git，或 Git 未加入系统 PATH。\n请安装后重新打开此面板。"
                color: c.text
                font.family: "Consolas"; font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                text: "[ 前往下载: git-scm.com ]"
                color: c.cyan
                font.family: "Consolas"; font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally("https://git-scm.com/downloads")
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 160; Layout.preferredHeight: 32
                color: mouseRecheck.pressed ? c.cyan : "transparent"
                border.color: c.cyan; border.width: 1; radius: 4
                Text {
                    anchors.centerIn: parent
                    text: "[ 重新检测 ]"
                    color: mouseRecheck.pressed ? c.bg : c.cyan
                    font.family: "Consolas"; font.pixelSize: 11
                }
                MouseArea {
                    id: mouseRecheck
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!gitBackend) return
                        gitOk = gitBackend.isGitAvailable
                        if (gitOk) {
                            gitBackend.setRepoPath(gitBackend.currentRepoPath)
                            hasGit = gitBackend.isRepoInitialized()
                            if (hasGit) refreshAll()
                        }
                    }
                }
            }
        }

        ColumnLayout {
            visible: gitOk && !hasGit
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: ">> 当前目录未检测到 Git 仓库"
                color: c.red
                font.family: "Consolas"; font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
            }

            TextField {
                id: initBranchInput
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                placeholderText: "初始分支名称 (留空默认 main)..."
                placeholderTextColor: c.dim
                color: c.text
                font.family: "Consolas"; font.pixelSize: 11
                background: Rectangle {
                    color: c.bg
                    border.color: c.cyan; border.width: 1; radius: 4
                }
            }

            CheckBox {
                id: chkGitIgnore
                checked: true
                contentItem: Text {
                    text: "自动生成标准 .gitignore 文件"
                    color: c.text
                    font.family: "Consolas"; font.pixelSize: 11
                }
                indicator: Rectangle {
                    implicitWidth: 14; implicitHeight: 14
                    color: chkGitIgnore.checked ? c.green : "transparent"
                    border.color: c.green; border.width: 1
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 44
                color: btnInitHover.pressed ? c.green : "transparent"
                border.color: c.green; border.width: 1; radius: 6
                Text {
                    anchors.centerIn: parent
                    text: "[ INIT REPOSITORY ]"
                    color: btnInitHover.pressed ? c.bg : c.green
                    font.family: "Consolas"; font.pixelSize: 14; font.weight: Font.Bold
                }
                MouseArea {
                    id: btnInitHover
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!gitBackend) return
                        var branch = initBranchInput.text.trim()
                        if (branch === "") branch = "main"
                        var res = gitBackend.initRepo(chkGitIgnore.checked, branch)
                        if (res.status === "success") {
                            hasGit = true
                            initBranchInput.text = ""
                            refreshAll()
                        }
                    }
                }
            }
        }

        ColumnLayout {
            visible: gitOk && hasGit
            Layout.fillHeight: true
            spacing: 8

            RowLayout {
                Rectangle { width: 10; height: 10; radius: 5; color: c.green }
                Text {
                    text: "REPOSITORY ACTIVE"
                    color: c.green
                    font.family: "Consolas"; font.pixelSize: 11; font.weight: Font.Bold
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: gitBackend ? gitBackend.currentRepoPath : ""
                    color: c.dim
                    font.family: "Consolas"; font.pixelSize: 9
                    elide: Text.ElideMiddle
                    Layout.maximumWidth: 220
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 4
                    padding: 8
                    background: Rectangle {
                        color: c.panel
                        border.color: c.border; border.width: 1; radius: 6
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 6

                        Text {
                            text: "[ BRANCHES ]"
                            color: c.cyan
                            font.family: "Consolas"; font.pixelSize: 11; font.weight: Font.Bold
                        }

                        ListView {
                            id: branchList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 2
                            model: ListModel { id: branchModel }

                            section.property: "type"
                            section.criteria: ViewSection.FullString
                            section.delegate: Rectangle {
                                width: branchList.width
                                height: 20
                                color: "#1C2128"
                                radius: 3
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 6
                                    text: section === "local" ? "[ 本地 LOCAL ]" : "[ 远程 REMOTE ]"
                                    color: section === "local" ? c.cyan : c.orange
                                    font.family: "Consolas"; font.pixelSize: 9; font.weight: Font.Bold
                                }
                            }

                            delegate: Rectangle {
                                width: branchList.width
                                height: 40
                                color: {
                                    if (branchMouse.containsMouse) return "#1F2A37"
                                    if (model.isCurrent) return "#0D2B1A"
                                    return "transparent"
                                }
                                radius: 3

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8; anchors.rightMargin: 8
                                    anchors.topMargin: 4; anchors.bottomMargin: 4
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        Rectangle { visible: model.isCurrent; width: 7; height: 7; radius: 3.5; color: c.green }
                                        Text {
                                            Layout.fillWidth: true
                                            text: model.name
                                            color: model.isCurrent ? c.green : c.text
                                            font.family: "Consolas"; font.pixelSize: 11
                                            font.weight: Font.Bold; elide: Text.ElideMiddle
                                        }
                                        Text {
                                            visible: model.tracking !== ""
                                            text: model.tracking
                                            color: c.orange; font.family: "Consolas"; font.pixelSize: 9
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Item { Layout.fillWidth: true }
                                        Text { text: model.date; color: c.dim; font.family: "Consolas"; font.pixelSize: 8 }
                                        Text { text: model.hash; color: c.dim; font.family: "Consolas"; font.pixelSize: 8; font.weight: Font.Bold }
                                    }
                                }

                                MouseArea {
                                    id: branchMouse
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.RightButton) {
                                            branchMenu.branchName = model.name
                                            branchMenu.isCurrentBranch = model.isCurrent
                                            branchMenu.isRemoteBranch = (model.type === "remote")
                                            branchMenu.popup()
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            spacing: 6
                            TextField {
                                id: newBranchInput
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                placeholderText: "新分支..."
                                placeholderTextColor: c.dim
                                color: c.text
                                font.family: "Consolas"; font.pixelSize: 10
                                background: Rectangle { color: c.bg; border.color: c.cyan; border.width: 1; radius: 3 }
                            }
                            Rectangle {
                                Layout.preferredWidth: 32; Layout.preferredHeight: 28
                                color: mouseNewBranch.pressed ? c.cyan : "transparent"
                                border.color: c.cyan; border.width: 1; radius: 3
                                Text {
                                    anchors.centerIn: parent; text: "+"
                                    color: c.cyan; font.family: "Consolas"; font.pixelSize: 14; font.weight: Font.Bold
                                }
                                MouseArea {
                                    id: mouseNewBranch
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (gitBackend && newBranchInput.text.trim() !== "") {
                                            var res = gitBackend.createBranch(newBranchInput.text.trim())
                                            if (res.status === "success") { refreshBranches(); newBranchInput.text = "" }
                                            else branchError.show(friendlyGitError(res.message))
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            id: branchError
                            Layout.fillWidth: true; visible: text !== ""
                            color: c.red; font.family: "Consolas"; font.pixelSize: 9; wrapMode: Text.WrapAnywhere
                            function show(msg) { text = msg; branchErrorTimer.restart() }
                            Timer { id: branchErrorTimer; interval: 4000; onTriggered: branchError.text = "" }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 6
                    spacing: 8

                    Frame {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        padding: 8
                        background: Rectangle { color: c.panel; border.color: c.border; border.width: 1; radius: 6 }

                        ColumnLayout {
                            anchors.fill: parent; spacing: 6
                            Text {
                                text: "[ CHANGES ]"
                                color: c.orange; font.family: "Consolas"; font.pixelSize: 11; font.weight: Font.Bold
                            }
                            ListView {
                                id: changeList
                                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                                model: ListModel { id: changeModel }

                                Rectangle {
                                    visible: changeModel.count === 0
                                    anchors.fill: changeList; color: "transparent"
                                    Text {
                                        anchors.centerIn: parent; text: "working tree clean"
                                        color: c.dim; font.family: "Consolas"; font.pixelSize: 11
                                    }
                                }

                                delegate: Rectangle {
                                    width: changeList.width; height: 26
                                    color: changeMouse.containsMouse ? "#1F2A37" : "transparent"; radius: 3
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 6; anchors.rightMargin: 6; spacing: 8
                                        Rectangle {
                                            width: 28; height: 18; radius: 3; color: root.stateColor(model.state)
                                            Text {
                                                anchors.centerIn: parent; text: model.state
                                                color: c.bright; font.family: "Consolas"; font.pixelSize: 9; font.weight: Font.Bold
                                            }
                                        }
                                        Text {
                                            Layout.fillWidth: true; text: model.file; color: c.text
                                            font.family: "Consolas"; font.pixelSize: 11; elide: Text.ElideLeft
                                        }
                                    }
                                    MouseArea {
                                        id: changeMouse
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: function(mouse) {
                                            if (mouse.button === Qt.RightButton) {
                                                changeMenu.filePath = model.file
                                                changeMenu.popup()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Frame {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        padding: 8
                        background: Rectangle { color: c.panel; border.color: c.border; border.width: 1; radius: 6 }

                        RowLayout {
                            anchors.fill: parent; spacing: 8
                            TextField {
                                id: commitMsg
                                Layout.fillWidth: true; Layout.preferredHeight: 36
                                placeholderText: "输入 Commit Message..."
                                placeholderTextColor: c.dim; color: c.text
                                font.family: "Consolas"; font.pixelSize: 12
                                background: Rectangle { color: c.bg; border.color: c.green; border.width: 1; radius: 4 }
                            }
                            Rectangle {
                                Layout.preferredWidth: 80; Layout.preferredHeight: 36
                                color: mouseCommit.pressed ? c.green : "transparent"
                                border.color: c.green; border.width: 1; radius: 4
                                Text {
                                    anchors.centerIn: parent; text: "COMMIT"
                                    color: mouseCommit.pressed ? c.bg : c.green
                                    font.family: "Consolas"; font.pixelSize: 11; font.weight: Font.Bold
                                }
                                MouseArea {
                                    id: mouseCommit
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (!gitBackend || commitMsg.text.trim() === "") return
                                        var res = gitBackend.commitChanges(commitMsg.text.trim())
                                        if (res.status === "success") { commitMsg.text = ""; refreshAll() }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: historyPopup
        width: Math.round(root.width * 0.85)
        height: Math.round(width * (19 / 25))
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: c.bg
            border.color: c.border
            border.width: 1
            radius: 8
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            RowLayout {
                Text {
                    text: "[ COMMIT HISTORY & VERSIONS ]"
                    color: c.orange
                    font.family: "Consolas"; font.pixelSize: 13; font.weight: Font.Bold
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "[ X ]"
                    color: c.dim
                    font.family: "Consolas"; font.pixelSize: 11
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: historyPopup.close()
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: c.border }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 6
                    padding: 6
                    background: Rectangle { color: c.panel; border.color: c.border; border.width: 1; radius: 6 }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4

                        Text {
                            text: "[ COMMITS ]"
                            color: c.cyan
                            font.family: "Consolas"; font.pixelSize: 10; font.weight: Font.Bold
                        }

                        ListView {
                            id: historyList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 0
                            model: ListModel { id: historyModel }

                            Rectangle {
                                visible: historyModel.count === 0
                                anchors.fill: historyList; color: "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "no commits yet"
                                    color: c.dim; font.family: "Consolas"; font.pixelSize: 11
                                }
                            }

                            delegate: Rectangle {
                                width: historyList.width
                                height: 44
                                color: historyMouse.containsMouse ? "#1F2A37" : "transparent"
                                radius: 3

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6; anchors.rightMargin: 6
                                    anchors.topMargin: 3; anchors.bottomMargin: 3
                                    spacing: 1

                                    RowLayout {
                                        spacing: 4
                                        Text {
                                            text: model.hash
                                            color: c.cyan
                                            font.family: "Consolas"; font.pixelSize: 9; font.weight: Font.Bold
                                        }
                                        Text {
                                            text: model.date
                                            color: c.dim
                                            font.family: "Consolas"; font.pixelSize: 8
                                        }
                                        Text {
                                            visible: text !== ""
                                            property string tagNames: root.tagsForCommit(model.hash).join(" ")
                                            text: tagNames !== "" ? "🏷 " + tagNames : ""
                                            color: c.green
                                            font.family: "Consolas"; font.pixelSize: 8; font.weight: Font.Bold
                                            elide: Text.ElideRight
                                            Layout.maximumWidth: 140
                                        }
                                        Item { Layout.fillWidth: true }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: model.message
                                        color: c.text
                                        font.family: "Consolas"; font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width; height: 1
                                    color: c.border; opacity: 0.5
                                }

                                MouseArea {
                                    id: historyMouse
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.RightButton) {
                                            historyMenu.commitHash = model.hash
                                            historyMenu.commitMsg = model.message
                                            historyMenu.popup()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: c.border
                }

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 4
                    padding: 6
                    background: Rectangle { color: c.panel; border.color: c.border; border.width: 1; radius: 6 }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4

                        Text {
                            text: "[ VERSIONS ]"
                            color: c.green
                            font.family: "Consolas"; font.pixelSize: 10; font.weight: Font.Bold
                        }

                        ListView {
                            id: versionList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 0
                            model: tagData

                            Rectangle {
                                visible: tagData.count === 0
                                anchors.fill: versionList; color: "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "no version tags"
                                    color: c.dim; font.family: "Consolas"; font.pixelSize: 11
                                }
                            }

                            delegate: Rectangle {
                                width: versionList.width
                                height: 46
                                color: versionMouse.containsMouse ? "#1F2A37" : "transparent"
                                radius: 3

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6; anchors.rightMargin: 6
                                    anchors.topMargin: 4; anchors.bottomMargin: 4
                                    spacing: 2

                                    RowLayout {
                                        spacing: 4
                                        Text {
                                            text: "🏷 " + model.name
                                            color: c.green
                                            font.family: "Consolas"; font.pixelSize: 10; font.weight: Font.Bold
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: model.date
                                            color: c.dim
                                            font.family: "Consolas"; font.pixelSize: 8
                                        }
                                    }

                                    RowLayout {
                                        spacing: 4
                                        Text {
                                            text: model.hash
                                            color: c.cyan
                                            font.family: "Consolas"; font.pixelSize: 8; font.weight: Font.Bold
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: model.message
                                            color: c.dim
                                            font.family: "Consolas"; font.pixelSize: 8
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width; height: 1
                                    color: c.border; opacity: 0.5
                                }

                                MouseArea {
                                    id: versionMouse
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.RightButton) {
                                            versionMenu.tagName = model.name
                                            versionMenu.tagHash = model.hash
                                            versionMenu.popup()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    StyledMenu {
        id: versionMenu
        property string tagName: ""
        property string tagHash: ""

        StyledMenuItem {
            text: "📌 切换到该版本 (Checkout)"
            enabled: versionMenu.tagHash !== ""
            onTriggered: {
                confirmDialog.title = "进入分离头指针状态"
                confirmDialog.message = "标签指向一个固定的提交记录，切换后将进入 \"detached HEAD\" 状态。\n\n在此状态下提交的代码将不属于任何分支，关闭程序后可能丢失。\n\n建议: 如需修改代码，请先基于此标签创建新分支。"
                confirmDialog.confirmText = "仍然切换"
                confirmDialog.confirmColor = c.orange
                confirmDialog.callback = function() {
                    if (!gitBackend) return
                    gitBackend.checkoutBranch(versionMenu.tagHash)
                    Qt.callLater(function() { refreshBranches(); refreshChanges(); historyPopup.close() })
                }
                confirmDialog.open()
            }
        }
        StyledMenuItem {
            text: "🗑️ 删除此标签 (Delete Tag)"
            textColor: c.red
            onTriggered: {
                confirmDialog.title = "删除标签确认"
                confirmDialog.message = "将永久删除标签 \"" + versionMenu.tagName + "\"，标签指向的提交记录不受影响。"
                confirmDialog.confirmText = "确认删除"
                confirmDialog.confirmColor = c.red
                confirmDialog.callback = function() {
                    if (!gitBackend) return
                    var res = gitBackend.deleteTag(versionMenu.tagName)
                    if (res.status === "success")
                        Qt.callLater(refreshHistory)
                    else
                        branchError.show("删除失败: " + friendlyGitError(res.message))
                }
                confirmDialog.open()
            }
        }
    }

    Popup {
        id: confirmDialog
        width: Math.round(root.width * 0.65)
        height: Math.round(width * (19 / 25))
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property string title: ""
        property string message: ""
        property string confirmText: "确认"
        property color confirmColor: c.red
        property var callback: null

        background: Rectangle {
            color: c.bg
            border.color: confirmDialog.confirmColor
            border.width: 1
            radius: 8
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Text {
                text: confirmDialog.title
                color: confirmDialog.confirmColor
                font.family: "Consolas"; font.pixelSize: 13; font.weight: Font.Bold
            }

            Text {
                Layout.fillWidth: true
                text: confirmDialog.message
                color: c.text
                font.family: "Consolas"; font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                spacing: 8
                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 70; Layout.preferredHeight: 30
                    color: "transparent"
                    border.color: c.dim; border.width: 1; radius: 4
                    Text {
                        anchors.centerIn: parent; text: "取消"
                        color: c.dim; font.family: "Consolas"; font.pixelSize: 11
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: confirmDialog.close()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 90; Layout.preferredHeight: 30
                    color: mouseConfirm.pressed ? confirmDialog.confirmColor : "transparent"
                    border.color: confirmDialog.confirmColor; border.width: 1; radius: 4
                    Text {
                        anchors.centerIn: parent; text: confirmDialog.confirmText
                        color: mouseConfirm.pressed ? c.bg : confirmDialog.confirmColor
                        font.family: "Consolas"; font.pixelSize: 11; font.weight: Font.Bold
                    }
                    MouseArea {
                        id: mouseConfirm
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            confirmDialog.close()
                            if (confirmDialog.callback) confirmDialog.callback()
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: resetConfirmDialog
        width: Math.round(root.width * 0.76)
        height: Math.round(width * (19 / 25))
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        modal: true
        closePolicy: Popup.NoAutoClose

        property string targetHash: ""
        property string targetMsg: ""

        background: Rectangle {
            color: c.bg
            border.color: c.red
            border.width: 1
            radius: 8
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Text {
                text: "[ ⚠️ DANGER ZONE ]"
                color: c.red
                font.family: "Consolas"; font.pixelSize: 13; font.weight: Font.Bold
            }

            Text {
                Layout.fillWidth: true
                text: "警告：强制回退将清空当前所有未提交的代码修改，且仓库状态将倒流至该版本。是否确认？"
                color: c.text
                font.family: "Consolas"; font.pixelSize: 11
                wrapMode: Text.WrapAnywhere
            }

            Text {
                Layout.fillWidth: true
                text: "目标: " + resetConfirmDialog.targetHash + " " + resetConfirmDialog.targetMsg
                color: c.dim
                font.family: "Consolas"; font.pixelSize: 9
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                spacing: 8
                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 80; Layout.preferredHeight: 30
                    color: "transparent"
                    border.color: c.dim; border.width: 1; radius: 4
                    Text {
                        anchors.centerIn: parent
                        text: "取消"
                        color: c.dim
                        font.family: "Consolas"; font.pixelSize: 11
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: resetConfirmDialog.close()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 110; Layout.preferredHeight: 30
                    color: mouseResetConfirm.pressed ? c.red : "transparent"
                    border.color: c.red; border.width: 1; radius: 4
                    Text {
                        anchors.centerIn: parent
                        text: "确认回退"
                        color: mouseResetConfirm.pressed ? c.bg : c.red
                        font.family: "Consolas"; font.pixelSize: 11; font.weight: Font.Bold
                    }
                    MouseArea {
                        id: mouseResetConfirm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!gitBackend || resetConfirmDialog.targetHash === "") return
                            var res = gitBackend.resetToCommit(resetConfirmDialog.targetHash)
                            if (res.status === "success") {
                                resetConfirmDialog.close()
                                historyPopup.close()
                                refreshAll()
                            } else {
                                branchError.show("回退失败: " + friendlyGitError(res.message))
                                resetConfirmDialog.close()
                            }
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: conflictDialog
        width: Math.round(root.width * 0.79)
        height: Math.round(width * (19 / 25))
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        modal: true
        closePolicy: Popup.NoAutoClose

        property string conflictDetail: ""

        background: Rectangle {
            color: c.bg
            border.color: c.red
            border.width: 1
            radius: 8
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
                spacing: 8
                Text {
                    text: "⚠️"
                    font.pixelSize: 18
                }
                Text {
                    text: "[ MERGE CONFLICT ]"
                    color: c.red
                    font.family: "Consolas"; font.pixelSize: 13; font.weight: Font.Bold
                }
            }

            Text {
                Layout.fillWidth: true
                text: "合并产生冲突，自动合并失败。\n你可以手动编辑冲突文件后提交，或中止本次合并恢复原状。"
                color: c.text
                font.family: "Consolas"; font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                Layout.maximumHeight: 40
                text: conflictDialog.conflictDetail
                color: c.dim
                font.family: "Consolas"; font.pixelSize: 8
                wrapMode: Text.WrapAnywhere
                elide: Text.ElideRight
                clip: true
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                spacing: 8
                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 150; Layout.preferredHeight: 30
                    color: "transparent"
                    border.color: c.cyan; border.width: 1; radius: 4
                    Text {
                        anchors.centerIn: parent
                        text: "我知道了 (去手工改代码)"
                        color: c.cyan
                        font.family: "Consolas"; font.pixelSize: 10
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            conflictDialog.close()
                            refreshChanges()
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 140; Layout.preferredHeight: 30
                    color: mouseAbortMerge.pressed ? c.red : "transparent"
                    border.color: c.red; border.width: 1; radius: 4
                    Text {
                        anchors.centerIn: parent
                        text: "中止并撤销合并 (Abort)"
                        color: mouseAbortMerge.pressed ? c.bg : c.red
                        font.family: "Consolas"; font.pixelSize: 10; font.weight: Font.Bold
                    }
                    MouseArea {
                        id: mouseAbortMerge
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (gitBackend) {
                                var res = gitBackend.abortMerge()
                                if (res.status !== "success")
                                    branchError.show(friendlyGitError(res.message))
                            }
                            conflictDialog.close()
                            refreshAll()
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: tagDialog
        width: Math.round(root.width * 0.60)
        height: Math.round(width * (19 / 25))
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property string tagHash: ""
        property string tagMsg: ""

        onOpened: { tagNameInput.text = ""; tagMsgInput.text = ""; tagError.text = "" }

        background: Rectangle {
            color: c.bg
            border.color: c.green
            border.width: 1
            radius: 8
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Text {
                text: "[ 🏷️ CREATE TAG ]"
                color: c.green
                font.family: "Consolas"; font.pixelSize: 13; font.weight: Font.Bold
            }

            Text {
                Layout.fillWidth: true
                text: "为提交 " + tagDialog.tagHash + " 打版本标签\n" + tagDialog.tagMsg
                color: c.dim
                font.family: "Consolas"; font.pixelSize: 9
                elide: Text.ElideRight
            }

            TextField {
                id: tagNameInput
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                placeholderText: "标签名 (如 v1.0.0)..."
                placeholderTextColor: c.dim
                color: c.text
                font.family: "Consolas"; font.pixelSize: 11
                background: Rectangle { color: c.bg; border.color: c.green; border.width: 1; radius: 3 }
            }

            TextField {
                id: tagMsgInput
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                placeholderText: "标签说明 (可选)..."
                placeholderTextColor: c.dim
                color: c.text
                font.family: "Consolas"; font.pixelSize: 11
                background: Rectangle { color: c.bg; border.color: c.dim; border.width: 1; radius: 3 }
            }

            Text {
                id: tagError
                Layout.fillWidth: true
                visible: text !== ""
                color: c.red
                font.family: "Consolas"; font.pixelSize: 9
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                spacing: 8
                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 70; Layout.preferredHeight: 30
                    color: "transparent"
                    border.color: c.dim; border.width: 1; radius: 4
                    Text {
                        anchors.centerIn: parent; text: "取消"
                        color: c.dim; font.family: "Consolas"; font.pixelSize: 11
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: tagDialog.close()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 90; Layout.preferredHeight: 30
                    color: mouseCreateTag.pressed ? c.green : "transparent"
                    border.color: c.green; border.width: 1; radius: 4
                    Text {
                        anchors.centerIn: parent; text: "创建标签"
                        color: mouseCreateTag.pressed ? c.bg : c.green
                        font.family: "Consolas"; font.pixelSize: 11; font.weight: Font.Bold
                    }
                    MouseArea {
                        id: mouseCreateTag
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var name = tagNameInput.text.trim()
                            if (name === "") {
                                tagError.text = "标签名不能为空"
                                return
                            }
                            if (name.indexOf(" ") !== -1) {
                                tagError.text = "标签名不允许包含空格"
                                return
                            }
                            if (!gitBackend) return
                            var res = gitBackend.createTag(name, tagMsgInput.text.trim(), tagDialog.tagHash)
                            if (res.status !== "success") {
                                tagError.text = friendlyGitError(res.message)
                                return
                            }
                            tagDialog.close()
                            Qt.callLater(refreshHistory)
                        }
                    }
                }
            }
        }
    }
}
