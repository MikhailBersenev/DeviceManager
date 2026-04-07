import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: topBar
    required property var deviceManager
    signal refreshClicked

    implicitHeight: 64
    color: "#FFFFFF"
    border.color: "#D7E0ED"
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        Label {
            text: qsTr("Device Manager")
            color: "#1F2A3A"
            font.pixelSize: 20
            font.bold: true
            Layout.fillWidth: true
        }

        Label {
            text: deviceManager && deviceManager.lastError && deviceManager.lastError.length > 0
                  ? deviceManager.lastError
                  : qsTr("Monitoring devices")
            color: deviceManager && deviceManager.lastError && deviceManager.lastError.length > 0
                   ? "#CC3D5C"
                   : "#6E7D93"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Button {
            text: qsTr("Refresh")
            onClicked: topBar.refreshClicked()
            contentItem: Text {
                text: parent.text
                color: "#1E2B3F"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 14
                font.bold: true
            }
            background: Rectangle {
                radius: 10
                color: parent.hovered ? "#E7EEF9" : "#F3F7FE"
                border.color: "#C7D5EA"
                border.width: 1
                Behavior on color {
                    ColorAnimation { duration: 90 }
                }
            }
        }

        Button {
            text: qsTr("GitHub")
            onClicked: Qt.openUrlExternally("https://github.com/MikhailBersenev/DeviceManager")
            contentItem: Text {
                text: parent.text
                color: "#1E2B3F"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 14
                font.bold: true
            }
            background: Rectangle {
                radius: 10
                color: parent.hovered ? "#E7EEF9" : "#F3F7FE"
                border.color: "#C7D5EA"
                border.width: 1
                Behavior on color {
                    ColorAnimation { duration: 90 }
                }
            }
        }

        Button {
            text: qsTr("Website")
            onClicked: Qt.openUrlExternally("http://mbersenev.ph/")
            contentItem: Text {
                text: parent.text
                color: "#1E2B3F"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 14
                font.bold: true
            }
            background: Rectangle {
                radius: 10
                color: parent.hovered ? "#E7EEF9" : "#F3F7FE"
                border.color: "#C7D5EA"
                border.width: 1
                Behavior on color {
                    ColorAnimation { duration: 90 }
                }
            }
        }
    }
}
