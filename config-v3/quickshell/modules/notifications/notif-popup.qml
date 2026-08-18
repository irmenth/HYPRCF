pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import "../../"

// Notification popup toast PanelWindow.
// Extracted from notifications.qml; accesses parent-level shared state via notifRoot.
PanelWindow {
    id: popup

    required property var notifRoot

    property real bandOffset: 0

    function funcInTimer(offsetInterval) {
        bandOffset += offsetInterval;
        bandOffset %= 1 + popupCard.width / popupCard.height;
    }

    anchors {
        top: true
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
    color: "transparent"
    visible: notifRoot.popupVisible && notifRoot.popupItem !== null
    aboveWindows: true
    implicitHeight: notifRoot.popupVisible ? popupCard.y + popupCard.height : 0

    Rectangle {
        id: popupCard

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

        anchors.horizontalCenter: parent.horizontalCenter
        y: 10
        width: Math.min(popup.width - 40, popupContentColumn.width + 40)
        height: popupContentColumn.height + 40
        color: "transparent"
        scale: popup.notifRoot.popupVisible ? 1 : 0
        opacity: popup.notifRoot.popupVisible ? 1 : 0

        // Shader background (only on the card, not the full PanelWindow)
        Item {
            anchors.fill: parent
            z: 0
            layer.enabled: true
            layer.effect: ShaderEffect {
                property real w: popupCard.width
                property real h: popupCard.height
                property real r: 32
                property real offset: popup.bandOffset
                property vector4d bg1: Colors.hexToRGBA01(Colors.bg1)
                property vector4d bg2: Colors.hexToRGBA01(Colors.bg2)
                property vector4d bg3: Colors.hexToRGBA01(Colors.bg3)

                fragmentShader: "../../shaders/band-diagonal.frag.qsb"
            }
        }

        ColumnLayout {
            id: popupContentColumn

            anchors.centerIn: parent
            width: 400
            spacing: 10
            z: 1

            // --- Header Row ---
            RowLayout {
                Layout.preferredWidth: popupContentColumn.width
                spacing: 10

                Image {
                    property bool hasIcon: (popup.notifRoot.popupItem?.appIcon ?? "") !== ""

                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    // Quickshell's icon provider returns a purple checkerboard for
                    // unresolvable icons with status Ready, so only show when the
                    // source has actually loaded successfully.
                    visible: hasIcon && status === Image.Ready
                    sourceSize {
                        width: 64
                        height: 64
                    }
                    source: {
                        if (!hasIcon) {
                            return "";
                        }

                        const icon = popup.notifRoot.popupItem.appIcon;
                        // Paths and URLs load directly; failures are caught by status.
                        if (icon.startsWith("image://") || icon.startsWith("file://") || icon.includes("/"))
                            return icon;
                        // Bare names: the check overload returns "" when the icon is
                        // not in the theme, so garbage never reaches the provider.
                        return Quickshell.iconPath(icon, true);
                    }
                }
                Text {
                    Layout.preferredWidth: Math.min(implicitWidth, 150)
                    Layout.alignment: Qt.AlignVCenter
                    font {
                        family: Colors.font
                        pixelSize: 18
                    }
                    color: Colors.fg1
                    text: popup.notifRoot.popupItem?.appName ?? ""
                    elide: Text.ElideRight
                    visible: text !== ""
                }
                Item {
                    Layout.fillWidth: true
                }
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: urgencyText.width + 20
                    Layout.preferredHeight: urgencyText.height + 10
                    radius: Math.min(width, height) / 2
                    color: Colors.bg4
                    visible: popup.notifRoot.popupItem !== null

                    Text {
                        id: urgencyText

                        anchors.centerIn: parent
                        font {
                            family: Colors.font
                            pixelSize: 12
                        }
                        color: {
                            if (popup.notifRoot.popupItem === null)
                                return Colors.fg1;
                            switch (popup.notifRoot.popupItem.urgency) {
                            case NotificationUrgency.Critical:
                                return Colors.err;
                            default:
                                return Colors.fg1;
                            }
                        }
                        text: {
                            if (popup.notifRoot.popupItem === null)
                                return "";
                            switch (popup.notifRoot.popupItem.urgency) {
                            case NotificationUrgency.Critical:
                                return "紧急";
                            case NotificationUrgency.Low:
                                return "低";
                            default:
                                return "普通";
                            }
                        }
                    }
                }
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: Math.min(width, height) / 2
                    color: Colors.fg3

                    Text {
                        anchors.centerIn: parent
                        font {
                            family: Colors.font
                            pixelSize: 16
                        }
                        color: Colors.fg1
                        text: ""
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: popup.visible

                        onClicked: {
                            popup.notifRoot.dismissPopup();
                        }
                    }
                }
            }

            ColumnLayout {
                // --- Summary ---
                Text {
                    Layout.preferredWidth: popupContentColumn.width
                    font {
                        family: Colors.font
                        pixelSize: 16
                    }
                    color: Colors.fg1
                    text: popup.notifRoot.popupItem?.summary ?? ""
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    visible: text !== ""
                }
                // --- Body ---
                Text {
                    Layout.preferredWidth: popupContentColumn.width
                    font {
                        family: Colors.font
                        pixelSize: 12
                    }
                    color: Colors.fg1
                    text: popup.notifRoot.popupItem?.body ?? ""
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    visible: text !== ""
                }
            }

            // --- Image ---
            Image {
                property bool hasIcon: (popup.notifRoot.popupItem?.image ?? "") !== ""

                Layout.alignment: Qt.AlignHCenter
                // Guard against 0x0 sourceSize from failed loads producing NaN widths
                Layout.preferredWidth: sourceSize.width > 0 && sourceSize.height > 0
                    ? Math.min(popupContentColumn.width, sourceSize.width * 110 / sourceSize.height)
                    : 0
                Layout.preferredHeight: 110
                source: {
                    if (!hasIcon) {
                        return "";
                    }

                    const src = popup.notifRoot.popupItem.image;
                    // Paths and URLs load directly; failures are caught by status.
                    if (src.startsWith("image://") || src.startsWith("file://") || src.includes("/"))
                        return src;
                    // Bare names: the check overload returns "" when the icon is
                    // not in the theme, so garbage never reaches the provider.
                    return Quickshell.iconPath(src, true);
                }
                // Only show when the source has actually loaded successfully.
                visible: hasIcon && status === Image.Ready
            }
        }

        TapHandler {
            onTapped: {
                popup.notifRoot.invokeNotify();
            }
        }
    }
}
