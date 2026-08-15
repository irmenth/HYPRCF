pragma ComponentBehavior: Bound

import QtQuick
import "../../../"

Rectangle {
    id: notifButton

    required property var notifModule

    property real refreshPhase: 0
    property real refreshOffset: 0
    property real refreshDistance: 1 + width / height

    function funcInTimer(phaseInterval, stopPos) {
        var eased = 0.0;
        notifButton.refreshPhase += phaseInterval;
        notifButton.refreshPhase %= 1;
        if (notifButton.refreshPhase < stopPos) {
            eased = 0.5 - 0.5 * Math.cos(Math.PI * (notifButton.refreshPhase + 1 - stopPos)) - (0.5 - 0.5 * Math.cos(Math.PI * (1 - stopPos)));
        } else {
            eased = 0.5 - 0.5 * Math.cos(Math.PI * (notifButton.refreshPhase - stopPos)) + (0.5 - 0.5 * Math.cos(Math.PI * stopPos));
        }
        notifButton.refreshOffset = eased * notifButton.refreshDistance;
    }

    implicitWidth: 64
    implicitHeight: 64
    color: "transparent"

    Item {
        anchors.fill: parent
        z: 0
        layer.enabled: true
        layer.effect: ShaderEffect {
            property real w: notifButton.width
            property real h: notifButton.height
            property real r: Math.min(32, Math.min(notifButton.height, notifButton.width) / 2)
            property real offset: notifButton.refreshOffset
            property vector4d bg: Colors.hexToRGBA01(Colors.bg1)
            property vector4d fg: Colors.hexToRGBA01(Colors.fg3)

            fragmentShader: "../../../shaders/refresh-diagonal.frag.qsb"
        }
    }

    Text {
        id: bellIcon

        x: (parent.width - implicitWidth) / 2
        y: (parent.height - implicitHeight) / 2
        z: 1
        font {
            family: Colors.font
            pixelSize: 24
        }
        color: Colors.fg1
        text: {
            if (notifButton.notifModule.dndEnabled) {
                return "󰂛";
            } else {
                return "󰂞";
            }
        }
    }

    // Unread badge
    Rectangle {
        x: parent.width - width
        width: Math.max(20, unreadText.width + 12)
        height: 20
        radius: Math.min(width, height) / 2
        color: Colors.btc
        scale: notifButton.notifModule.unreadCount > 0 ? 1 : 0
        opacity: notifButton.notifModule.unreadCount > 0 ? 1 : 0
        clip: true
        z: 2

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

        Text {
            id: unreadText

            x: (parent.width - implicitWidth) / 2
            y: (parent.height - implicitHeight) / 2
            font {
                family: Colors.font
                pixelSize: 12
            }
            color: Colors.fg2
            text: {
                let count = notifButton.notifModule.unreadCount;
                return Math.max(1, count > 99 ? "99+" : String(count));
            }
        }
    }

    TapHandler {
        onTapped: {
            notifButton.notifModule.toggleCenter();
        }
    }
}
