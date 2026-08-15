pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "../../../"

Rectangle {
    id: brightness

    property bool canExpand

    property bool expand: false
    property real targetWidth: expand ? 200 : 64
    property real bandOffset: 0
    property int maxBrightness: parseInt(maxBrightnessFile.text(), 10)
    property int brightness: parseInt(brightnessFile.text(), 10)
    property real brightRatio: this.brightness / maxBrightness
    property real dragRatio: 0

    function funcInTimer(offsetInterval) {
        bandOffset += offsetInterval;
        bandOffset %= 1 + width / height;
    }

    FileView {
        id: brightnessFile

        path: "/sys/class/backlight/amdgpu_bl2/brightness"
        watchChanges: true

        onFileChanged: {
            this.reload();
        }
    }
    FileView {
        id: maxBrightnessFile

        path: "/sys/class/backlight/amdgpu_bl2/max_brightness"
    }

    Behavior on targetWidth {
        SpringAnimation {
            spring: 4
            damping: 0.25
        }
    }

    implicitWidth: targetWidth
    implicitHeight: 64
    color: "transparent"
    clip: true

    TapHandler {
        onTapped: {
            if (!brightness.expand && !brightness.canExpand) {
                brightnessIconText.aniStage = 1;
                brightnessIconTextAniTimer.interval = 0;
                brightnessIconTextAniTimer.restart();
                return;
            }
            brightness.expand = !brightness.expand;
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            expand = false;
        }
    }

    Item {
        anchors.fill: parent
        z: 0
        layer.enabled: true
        layer.effect: ShaderEffect {
            property real w: brightness.width
            property real h: brightness.height
            property real r: Math.min(32, Math.min(brightness.width, brightness.height) / 2)
            property real offset: brightness.bandOffset
            property vector4d bg1: Colors.hexToRGBA01(Colors.bg1)
            property vector4d bg2: Colors.hexToRGBA01(Colors.bg2)
            property vector4d bg3: Colors.hexToRGBA01(Colors.bg3)

            fragmentShader: "../../../shaders/band-diagonal.frag.qsb"
        }
    }

    Text {
        id: brightnessIconText

        readonly property real desX: Math.min(17 + (30 - width) / 2, (brightness.width - width) / 2)
        property int aniStage: 0

        Behavior on x {
            SpringAnimation {
                spring: 4
                damping: 0.2
            }
        }

        Timer {
            id: brightnessIconTextAniTimer

            onTriggered: {
                switch (brightnessIconText.aniStage) {
                case 0:
                    brightnessIconText.x = brightnessIconText.desX;
                    brightnessIconTextAniTimer.interval = 0;
                    break;
                case 1:
                    brightnessIconText.x = brightnessIconText.desX - 10;
                    brightnessIconText.aniStage = 2;
                    brightnessIconTextAniTimer.interval = 100;
                    brightnessIconTextAniTimer.restart();
                    break;
                case 2:
                    brightnessIconText.x = brightnessIconText.desX + 10;
                    brightnessIconText.aniStage = 0;
                    brightnessIconTextAniTimer.restart();
                    break;
                }
            }
        }

        x: desX
        y: (parent.height - implicitHeight) / 2
        z: 1
        font {
            family: Colors.font
            pixelSize: 24
        }
        color: Colors.fg1
        text: {
            if (brightness.brightRatio < 0.25) {
                return "󰃞";
            } else if (brightness.brightRatio < 0.5) {
                return "󰃟";
            } else if (brightness.brightRatio < 0.75) {
                return "󰃝";
            } else {
                return "󰃠";
            }
        }
    }

    Rectangle {
        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutSine
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutSine
            }
        }
        Behavior on x {
            SpringAnimation {
                spring: 4
                damping: 0.2
            }
        }

        anchors.verticalCenter: parent.verticalCenter
        width: 120
        height: 6
        radius: Math.min(width, height) / 2
        x: brightness.expand ? 55 : -55
        opacity: brightness.expand ? 1 : 0
        scale: brightness.expand ? 1 : 0
        color: Colors.fg1

        Rectangle {
            Behavior on x {
                SpringAnimation {
                    spring: 4
                    damping: 0.2
                }
            }

            anchors.verticalCenter: parent.verticalCenter
            x: (parent.width - width) * brightness.brightRatio
            width: 16
            height: width
            radius: Math.min(width, height) / 2
            color: Colors.fg1

            Rectangle {
                width: parent.width / 2
                height: width
                radius: Math.min(width, height) / 2
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
                color: Colors.bg2
            }
        }

        Process {
            id: setBrightnessProc

            running: false
            command: ["sh", "-c", `brightnessctl set ${brightness.dragRatio}%`]
        }

        MouseArea {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: brightness.height
            enabled: brightness.expand

            onPositionChanged: mouse => {
                brightness.dragRatio = Math.min(1, Math.max(0, mouse.x / width)) * 100;
                setBrightnessProc.running = true;
            }
        }
    }
}
