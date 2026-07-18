import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import App.Backend 1.0  // 👈 1. 导入你在 main.cpp 中注册的模块

Window {
    width: 400; height: 600
    title: "AI 助手对话"
    color: "#1E1E1E"

    ListModel { id: chatModel }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 10
        ListView {
            Layout.fillWidth: true; Layout.fillHeight: true
            model: chatModel
            delegate: Rectangle {
                width: ListView.view.width; height: childrenRect.height + 20
                color: "transparent"
                Text {
                    text: model.text; color: model.isAi ? "#64B4FF" : "#FFFFFF"
                    font.pixelSize: 14; anchors.left: model.isAi ? parent.left : undefined; anchors.right: model.isAi ? undefined : parent.right
                    wrapMode: Text.Wrap; width: parent.width * 0.8
                }
            }
        }
        // 👈 2. 实例化 ChatBackend 并赋予 id
            ChatBackend {
                id: chatBackend
            }
        RowLayout {
            TextField { id: input; Layout.fillWidth: true; placeholderText: "输入内容..."; color: "white" }
            Button {
                text: "发送"; onClicked: {
                    chatModel.append({"text": input.text, "isAi": false})
                    chatBackend.sendMessage(input.text)
                    input.clear()
                }
            }
        }
    }

    Connections {
        target: chatBackend
        function onMessageReceived(text) { chatModel.append({"text": text, "isAi": true}) }
    }
}