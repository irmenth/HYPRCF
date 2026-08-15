pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import "../../"

// Notification center (history) PanelWindow.
// Extracted from notifications.qml; accesses parent-level shared state via notifRoot.
PanelWindow {
    id: center

    required property var notifRoot

    property real bandOffset: 0

    function funcInTimer(offsetInterval) {
        bandOffset += offsetInterval;
        bandOffset %= 1 + centerCard.width / centerCard.height;
    }

    anchors {
        top: false
        bottom: false
        left: true
        right: true
    }
    margins {
        top: 0
        bottom: 0
        left: 0
        right: 0
    }
    implicitHeight: 2 * Screen.height
    color: "transparent"
    visible: notifRoot.centerVisible
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: true
    WlrLayershell.namespace: "quickshell-notification-center"

    onVisibleChanged: {
        if (!visible) {
            notifRoot.centerVisible = false;
        }
    }

    // Centered card
    Rectangle {
        id: centerCard

        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                center.notifRoot.centerVisible = false;
                event.accepted = true;
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 250
                easing.type: Easing.InOutSine
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.InOutSine
            }
        }
        Behavior on height {
            SpringAnimation {
                spring: 4
                damping: 0.25
            }
        }

        anchors.centerIn: parent
        width: Math.min(center.width - 40, centerColumn.width + 50)
        height: Math.min(center.height - 100, centerColumn.height + 50)
        color: "transparent"
        scale: center.notifRoot.centerVisible ? 1 : 0
        opacity: center.notifRoot.centerVisible ? 1 : 0
        clip: true

        // Shader background
        Item {
            anchors.fill: parent
            z: 0
            layer.enabled: true
            layer.effect: ShaderEffect {
                property real w: centerCard.width
                property real h: centerCard.height
                property real r: 32
                property real offset: center.bandOffset
                property vector4d bg1: Colors.hexToRGBA01(Colors.bg1)
                property vector4d bg2: Colors.hexToRGBA01(Colors.bg2)
                property vector4d bg3: Colors.hexToRGBA01(Colors.bg3)

                fragmentShader: "../../shaders/band-diagonal.frag.qsb"
            }
        }

        ColumnLayout {
            id: centerColumn

            anchors.horizontalCenter: parent.horizontalCenter
            y: 25
            width: 600
            spacing: 20

            // --- Header ---
            RowLayout {
                Layout.preferredWidth: centerColumn.width
                spacing: 16

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    font {
                        family: Colors.font
                        pixelSize: 24
                    }
                    color: Colors.fg1
                    text: "通知中心"
                }
                Item {
                    Layout.fillWidth: true
                }
                // DND Toggle
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: dndRow.width + 30
                    Layout.preferredHeight: 36
                    radius: Math.min(width, height) / 2
                    color: center.notifRoot.dndEnabled ? Colors.fg3 : Colors.bg4

                    RowLayout {
                        id: dndRow

                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 18

                            Text {
                                id: dndIcon

                                readonly property real desX: (parent.width - implicitWidth) / 2
                                property int aniStage: 0

                                Behavior on x {
                                    SpringAnimation {
                                        spring: 6
                                        damping: 0.2
                                    }
                                }

                                Timer {
                                    id: dndIconAniTimer

                                    onTriggered: {
                                        switch (dndIcon.aniStage) {
                                        case 0:
                                            dndIcon.x = dndIcon.desX;
                                            dndIconAniTimer.interval = 0;
                                            break;
                                        case 1:
                                            dndIcon.x = dndIcon.desX - 2;
                                            dndIcon.aniStage = 2;
                                            dndIconAniTimer.interval = 100;
                                            dndIconAniTimer.restart();
                                            break;
                                        case 2:
                                            dndIcon.x = dndIcon.desX + 2;
                                            dndIcon.aniStage = 0;
                                            dndIconAniTimer.restart();
                                            break;
                                        }
                                    }
                                }
                                x: desX
                                y: (parent.height - implicitHeight) / 2
                                font {
                                    family: Colors.font
                                    pixelSize: 16
                                }
                                color: Colors.fg1
                                text: center.notifRoot.dndEnabled ? "󰂛" : "󰂞"
                            }
                        }
                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            font {
                                family: Colors.font
                                pixelSize: 14
                            }
                            color: Colors.fg1
                            text: "勿扰"
                        }
                    }

                    TapHandler {
                        onTapped: {
                            center.notifRoot.dndEnabled = !center.notifRoot.dndEnabled;
                            dndIcon.aniStage = 1;
                            dndIconAniTimer.interval = 0;
                            dndIconAniTimer.restart();
                        }
                    }
                }
                // Clear all button
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 18
                    color: Colors.fg3
                    visible: center.notifRoot.historyList.length > 0

                    Text {
                        x: (parent.width - implicitWidth) / 2
                        y: (parent.height - implicitHeight) / 2
                        font {
                            family: Colors.font
                            pixelSize: 16
                        }
                        color: Colors.err
                        text: ""
                    }

                    TapHandler {
                        onTapped: {
                            center.notifRoot.clearAllHistory();
                        }
                    }
                }
                // Close button
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: Math.min(width, height) / 2
                    color: Colors.fg3

                    Text {
                        x: (parent.width - implicitWidth) / 2
                        y: (parent.height - implicitHeight) / 2
                        font {
                            family: Colors.font
                            pixelSize: 18
                        }
                        color: Colors.fg1
                        text: ""
                    }

                    TapHandler {
                        onTapped: {
                            center.notifRoot.centerVisible = false;
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.preferredWidth: centerColumn.width
                Layout.preferredHeight: 3
                radius: Math.min(width, height) / 2
                color: Colors.fg3
            }

            // --- History List ---
            ListView {
                id: historyListView

                property real listItemHeight: 70

                Layout.preferredWidth: centerColumn.width
                Layout.preferredHeight: Math.min(count * (listItemHeight + spacing), 10 * (listItemHeight + spacing)) - spacing
                spacing: 16
                snapMode: ListView.SnapToItem
                clip: true
                model: center.notifRoot.historyList
                visible: center.notifRoot.historyList.length > 0

                delegate: Rectangle {
                    id: historyItem

                    required property var modelData
                    required property int index

                    width: historyListView.width
                    height: historyListView.listItemHeight
                    radius: 20
                    color: Colors.fg3

                    RowLayout {
                        anchors.centerIn: parent
                        width: parent.width - 36
                        height: parent.height
                        spacing: 20
                        clip: true

                        Image {
                            property bool hasIcon: (historyItem.modelData?.appIcon ?? "") !== ""

                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            visible: hasIcon
                            sourceSize {
                                width: 64
                                height: 64
                            }
                            source: {
                                if (!hasIcon) {
                                    return "";
                                }

                                const icon = historyItem.modelData.appIcon;
                                if (icon.startsWith("image://"))
                                    return icon;
                                return Quickshell.iconPath(icon);
                            }
                        }
                        ColumnLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 8

                            Text {
                                Layout.preferredWidth: Math.min(implicitWidth, 100)
                                font {
                                    family: Colors.font
                                    pixelSize: 16
                                }
                                color: Colors.fg1
                                text: historyItem.modelData.appName
                                visible: (text ?? "") !== ""
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.preferredWidth: Math.min(implicitWidth, 50)
                                font {
                                    family: Colors.font
                                    pixelSize: 10
                                }
                                color: Colors.fg1
                                text: historyItem.modelData.timestamp
                                visible: (text ?? "") !== ""
                                elide: Text.ElideRight
                            }
                        }
                        ColumnLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            Text {
                                Layout.preferredWidth: Math.min(implicitWidth, 160)
                                font {
                                    family: Colors.font
                                    pixelSize: 14
                                }
                                color: Colors.fg1
                                text: historyItem.modelData.summary
                                visible: (text ?? "") !== ""
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                font {
                                    family: Colors.font
                                    pixelSize: 12
                                }
                                color: Colors.fg1
                                text: historyItem.modelData.body
                                visible: (text ?? "") !== ""
                                elide: Text.ElideRight
                            }
                        }
                        Image {
                            property bool hasIcon: (historyItem.modelData?.image ?? "") !== ""

                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: Math.min(90, sourceSize.width * 55 / sourceSize.height)
                            Layout.preferredHeight: 55
                            visible: hasIcon
                            source: {
                                if (!hasIcon) {
                                    return "";
                                }

                                return historyItem.modelData.image;
                            }
                        }
                        // Delete button
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: Math.min(width, height) / 2
                            color: Colors.bg4

                            Text {
                                x: (parent.width - implicitWidth) / 2
                                y: (parent.height - implicitHeight) / 2
                                font {
                                    family: Colors.font
                                    pixelSize: 16
                                }
                                color: Colors.fg1
                                text: ""
                            }

                            TapHandler {
                                onTapped: {
                                    center.notifRoot.deleteHistoryItem(historyItem.index);
                                }
                            }
                        }
                    }
                }
            }

            // Empty state
            Text {
                font {
                    family: Colors.font
                    pixelSize: 18
                }
                color: Colors.fg5
                text: "暂无通知"
                visible: center.notifRoot.historyList.length === 0
            }
        }
    }
}
