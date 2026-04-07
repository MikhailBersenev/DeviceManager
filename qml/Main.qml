import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

ApplicationWindow {
    id: root
    property var backend: deviceManager
    width: 1200
    height: 760
    minimumWidth: 980
    minimumHeight: 620
    visible: true
    title: qsTr("DeviceManager")
    color: "#F3F6FB"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TopBar {
            Layout.fillWidth: true
            deviceManager: root.backend
            onRefreshClicked: {
                if (root.backend) {
                    root.backend.refresh_devices()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#F3F6FB"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                DeviceListPanel {
                    id: listPanel
                    deviceManager: root.backend
                    Layout.fillHeight: true
                    Layout.preferredWidth: 480
                }

                DeviceDetailsPanel {
                    id: detailsPanel
                    deviceManager: root.backend
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }

        Label {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 8
            text: "Copyright (C) Mikhail Bersenev, 2026. Licensed under GPL v3.0."
            color: "#7A879A"
            font.pixelSize: 11
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }
    }
}
