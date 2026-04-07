import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: detailsRoot
    required property var deviceManager
    color: "#FFFFFF"
    radius: 14
    border.color: "#D7E0ED"
    border.width: 1

    readonly property var selected: deviceManager ? deviceManager.selectedDevice : ({})
    readonly property bool hasSelection: deviceManager ? deviceManager.selectedIndex >= 0 : false

    function valueFor(key, fallback) {
        const val = selected[key]
        return val && String(val).length > 0 ? String(val) : fallback
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Label {
            text: qsTr("Device Details")
            color: "#1E2B40"
            font.pixelSize: 22
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#E1E8F2"
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 8
                visible: hasSelection

                Label {
                    text: valueFor("name", "-")
                    color: "#1E2B40"
                    font.pixelSize: 20
                    font.bold: true
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                Label {
                    text: valueFor("description", "-")
                    color: "#667893"
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#E1E8F2"
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 8
                    columnSpacing: 14

                    Label { text: qsTr("Type"); color: "#7387A5" }
                    Label { text: valueFor("deviceType", "-").toUpperCase(); color: "#22314A" }

                    Label { text: qsTr("Vendor ID"); color: "#7387A5" }
                    Label { text: valueFor("vid", "-"); color: "#22314A" }

                    Label { text: qsTr("Product ID"); color: "#7387A5" }
                    Label { text: valueFor("pid", "-"); color: "#22314A" }

                    Label { text: qsTr("Manufacturer"); color: "#7387A5" }
                    Label {
                        text: valueFor("manufacturer", "-")
                        color: "#22314A"
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    Label { text: qsTr("Path"); color: "#7387A5" }
                    Label {
                        text: valueFor("path", "-")
                        color: "#22314A"
                        wrapMode: Text.WrapAnywhere
                        Layout.fillWidth: true
                    }

                    Label { text: qsTr("Hardware ID"); color: "#7387A5" }
                    Label {
                        text: valueFor("hardwareId", "-")
                        color: "#22314A"
                        wrapMode: Text.WrapAnywhere
                        Layout.fillWidth: true
                    }

                    Label { text: qsTr("Status"); color: "#7387A5" }
                    Label { text: valueFor("status", "-"); color: "#2D9B47" }
                }
            }

            Label {
                anchors.centerIn: parent
                visible: !hasSelection
                text: qsTr("Select a device to view details")
                color: "#7A8EA8"
                font.pixelSize: 14
            }
        }
    }
}
