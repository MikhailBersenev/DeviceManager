import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: listRoot
    required property var deviceManager
    color: "#FFFFFF"
    radius: 14
    border.color: "#D7E0ED"
    border.width: 1

    function iconGlyph(iconName) {
        return iconName === "usb" ? "🔌" : "🖧"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: qsTr("Search by name, path, or HWID")
            color: "#243247"
            placeholderTextColor: "#8A98AD"
            text: deviceManager ? deviceManager.searchText : ""
            onTextEdited: {
                if (deviceManager) {
                    deviceManager.setSearchText(text)
                }
            }
            background: Rectangle {
                radius: 10
                color: "#F9FBFF"
                border.color: searchField.activeFocus ? "#7DA2E8" : "#D2DDEA"
                border.width: 1
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { label: qsTr("All"), value: "all" },
                    { label: qsTr("USB"), value: "usb" },
                    { label: qsTr("COM"), value: "com" }
                ]

                delegate: Button {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.label
                    checkable: true
                    checked: deviceManager ? deviceManager.filterType === modelData.value : false
                    onClicked: {
                        if (deviceManager) {
                            deviceManager.setFilterType(modelData.value)
                        }
                    }

                    contentItem: Text {
                        text: parent.text
                        color: parent.checked ? "#1F2D45" : "#6B7C96"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 10
                        color: parent.checked ? "#DCE9FF" : (parent.hovered ? "#EEF4FF" : "#F7FAFF")
                        border.color: parent.checked ? "#8CAEEA" : "#D0DBEA"
                        border.width: 1
                        Behavior on color {
                            ColorAnimation { duration: 90 }
                        }
                    }
                }
            }
        }

        ListView {
            id: deviceList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: deviceManager ? deviceManager.model : null
            clip: true
            spacing: 6
            onCurrentIndexChanged: {
                if (deviceManager && currentIndex !== deviceManager.selectedIndex) {
                    deviceManager.selectIndex(currentIndex)
                }
            }
            Component.onCompleted: {
                if (deviceManager) {
                    currentIndex = deviceManager.selectedIndex
                }
            }

            Connections {
                target: deviceManager

                function onSelectedIndexChanged() {
                    if (deviceList.currentIndex !== deviceManager.selectedIndex) {
                        deviceList.currentIndex = deviceManager.selectedIndex
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            delegate: Rectangle {
                required property string deviceType
                required property string name
                required property string description
                required property string path
                required property string icon
                required property int index

                width: ListView.view.width
                height: 66
                radius: 10
                color: ListView.isCurrentItem ? "#DDE9FF" : (mouseArea.containsMouse ? "#EEF4FF" : "#F8FBFF")
                border.color: ListView.isCurrentItem ? "#87ABE8" : "#D3DEED"
                border.width: 1

                Behavior on color {
                    ColorAnimation { duration: 80 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Label {
                        text: listRoot.iconGlyph(icon)
                        font.pixelSize: 20
                        color: "#4B628A"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: name
                            color: "#1E2B40"
                            font.pixelSize: 14
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Label {
                            text: description
                            color: "#6A7A92"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Label {
                            text: path
                            color: "#8192AA"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Label {
                        text: deviceType.toUpperCase()
                        color: "#4A6FAF"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (deviceManager) {
                            deviceManager.selectIndex(index)
                        }
                    }
                }
            }

            footer: Item {
                width: parent.width
                height: parent.count === 0 ? 120 : 0

                Label {
                    anchors.centerIn: parent
                    visible: parent.height > 0
                    text: qsTr("No devices found for current filter")
                    color: "#7D8EA6"
                    font.pixelSize: 13
                }
            }
        }
    }
}
