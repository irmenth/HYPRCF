pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../"

Rectangle {
    id: clock

    required property var barRoot
    property bool canExpand

    property bool expand: false
    property real targetWidth: expand ? dateRect.width + 10 : 125
    property real expandBarHeight: expand ? 80 + dateRect.height + 5 : 64
    property real targetHeight: expandBarHeight
    property real targetTimeFontSize: expand ? 32 : 25
    property real targetTimeRectHeight: expand ? 90 : 64
    property real targetDateRectY: expand ? 80 : -5 - dateRect.height
    property real rainbowOffset: 0

    function funcInTimer(offsetInterval) {
        clock.rainbowOffset += offsetInterval;
        clock.rainbowOffset %= 1.3 * (1 + clock.width / clock.height);
    }

    Behavior on targetWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.InOutSine
        }
    }
    Behavior on targetHeight {
        SpringAnimation {
            spring: 4
            damping: 0.25
        }
    }
    Behavior on targetTimeFontSize {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutSine
        }
    }
    Behavior on targetTimeRectHeight {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutSine
        }
    }
    Behavior on targetDateRectY {
        SpringAnimation {
            spring: 4
            damping: 0.25
        }
    }

    implicitWidth: targetWidth
    implicitHeight: targetHeight
    color: "transparent"

    TapHandler {
        onTapped: {
            if (!clock.expand && !clock.canExpand) {
                timeText.aniStage = 1;
                timeTextAniTimer.interval = 0;
                timeTextAniTimer.restart();
                return;
            }
            clock.expand = !clock.expand;
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
            property real w: clock.width
            property real h: clock.height
            property real r: Math.min(32, Math.min(clock.height, clock.width) / 2)
            property real offset: clock.rainbowOffset
            property vector4d bg: Colors.hexToRGBA01(Colors.rb1)
            property vector4d rb1: Colors.hexToRGBA01(Colors.rb2)
            property vector4d rb2: Colors.hexToRGBA01(Colors.rb3)

            fragmentShader: "../../../shaders/rainbow-diagonal.frag.qsb"
        }
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        height: Math.min(clock.targetTimeRectHeight, clock.height)
        z: 1

        Text {
            id: timeText

            readonly property real desX: (parent.width - implicitWidth) / 2
            property int aniStage: 0

            Behavior on x {
                SpringAnimation {
                    spring: 4
                    damping: 0.2
                }
            }

            Timer {
                id: timeTextAniTimer

                onTriggered: {
                    switch (timeText.aniStage) {
                    case 0:
                        timeText.x = timeText.desX;
                        timeTextAniTimer.interval = 0;
                        break;
                    case 1:
                        timeText.x = timeText.desX - 10;
                        timeText.aniStage = 2;
                        timeTextAniTimer.interval = 100;
                        timeTextAniTimer.restart();
                        break;
                    case 2:
                        timeText.x = timeText.desX + 10;
                        timeText.aniStage = 0;
                        timeTextAniTimer.restart();
                        break;
                    }
                }
            }

            anchors.verticalCenter: parent.verticalCenter
            x: desX
            font {
                family: Colors.font
                pixelSize: clock.targetTimeFontSize
            }
            color: Colors.fg2
            text: clock.barRoot.time
        }
    }

    Rectangle {
        id: dateRect

        anchors.horizontalCenter: parent.horizontalCenter
        y: clock.targetDateRectY
        z: 2
        width: 45 + Math.max(dayofweekText.implicitWidth, dateText.implicitWidth)
        height: 55 + dayofweekText.height + dateText.height
        radius: 32
        opacity: clock.expand ? 1 : 0
        scale: clock.expand ? 1 : 0
        color: Colors.bg2

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

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            Text {
                id: dayofweekText

                Layout.alignment: Qt.AlignCenter
                font {
                    family: Colors.font
                    pixelSize: 18
                }
                color: Colors.fg1
                text: clock.barRoot.dayofweek
            }
            Text {
                id: dateText

                Layout.alignment: Qt.AlignCenter
                font {
                    family: Colors.font
                    pixelSize: 18
                }
                color: Colors.fg1
                text: clock.barRoot.date
            }
        }
    }
}
