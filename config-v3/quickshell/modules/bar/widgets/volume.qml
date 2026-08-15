pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pipewire
import "../../../"

Rectangle {
    id: volume

    property bool canExpand

    property bool expand: false
    property real targetWidth: expand ? 200 : 64
    property real bandOffset: 0
    property bool muted: Pipewire.ready && Pipewire.defaultAudioSink.audio.muted
    property real volume: Pipewire.ready ? Pipewire.defaultAudioSink.audio.volume : 0

    function funcInTimer(offsetInterval) {
        bandOffset += offsetInterval;
        bandOffset %= 1 + width / height;
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
            if (!volume.expand && !volume.canExpand) {
                volumeIconText.aniStage = 1;
                volumeIconTextAniTimer.interval = 0;
                volumeIconTextAniTimer.restart();
                return;
            }
            volume.expand = !volume.expand;
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
            property real w: volume.width
            property real h: volume.height
            property real r: Math.min(32, Math.min(volume.width, volume.height) / 2)
            property real offset: volume.bandOffset
            property vector4d bg1: Colors.hexToRGBA01(Colors.bg1)
            property vector4d bg2: Colors.hexToRGBA01(Colors.bg2)
            property vector4d bg3: Colors.hexToRGBA01(Colors.bg3)

            fragmentShader: "../../../shaders/band-diagonal.frag.qsb"
        }
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    Text {
        id: volumeIconText

        readonly property real desX: Math.min(17 + (30 - width) / 2, (volume.width - width) / 2)
        property int aniStage: 0

        Behavior on x {
            SpringAnimation {
                spring: 4
                damping: 0.2
            }
        }

        Timer {
            id: volumeIconTextAniTimer

            onTriggered: {
                switch (volumeIconText.aniStage) {
                case 0:
                    volumeIconText.x = volumeIconText.desX;
                    volumeIconTextAniTimer.interval = 0;
                    break;
                case 1:
                    volumeIconText.x = volumeIconText.desX - 10;
                    volumeIconText.aniStage = 2;
                    volumeIconTextAniTimer.interval = 100;
                    volumeIconTextAniTimer.restart();
                    break;
                case 2:
                    volumeIconText.x = volumeIconText.desX + 10;
                    volumeIconText.aniStage = 0;
                    volumeIconTextAniTimer.restart();
                    break;
                }
            }
        }

        x: desX
        y: (parent.height - implicitHeight) / 2
        z: 1
        font {
            family: Colors.font
            pixelSize: {
                if (!volume.muted) {
                    if (volume.volume < 0.33) {
                        return 26;
                    } else if (volume.volume < 0.66) {
                        return 25;
                    } else {
                        return 23;
                    }
                } else {
                    return 24;
                }
            }
        }
        color: Colors.fg1
        text: {
            if (!volume.muted) {
                if (volume.volume < 0.33) {
                    return "";
                } else if (volume.volume < 0.66) {
                    return "";
                } else {
                    return "";
                }
            } else {
                return "";
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton

            onPressed: {
                Pipewire.defaultAudioSink.audio.muted = !volume.muted;
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
        x: volume.expand ? 55 : -55
        opacity: volume.expand ? 1 : 0
        scale: volume.expand ? 1 : 0
        color: Colors.fg1

        Rectangle {
            Behavior on x {
                SpringAnimation {
                    spring: 4
                    damping: 0.2
                }
            }

            anchors.verticalCenter: parent.verticalCenter
            x: (parent.width - width) * volume.volume
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

        MouseArea {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: volume.height
            enabled: volume.expand

            onPositionChanged: mouse => {
                Pipewire.defaultAudioSink.audio.volume = Math.max(Math.min(mouse.x / width, 1), 0);
            }
        }
    }
}
