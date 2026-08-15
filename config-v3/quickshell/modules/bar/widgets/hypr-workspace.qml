pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import "../../../"

Rectangle {
    id: hyprWorkspace

    property real refreshPhase: 0
    property real refreshOffset: 0
    property real refreshDistance: 1 + width / height
    property int curWorkspace: Hyprland.focusedWorkspace?.id ?? -1
    property var visibleWS: {
        var out = [1, 2];
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id > 2 && (ws.focused || ws.toplevels.values.length > 0)) {
                out.push(ws.id);
            }
        }
        return out;
    }
    property real normalInterval: 35
    property real focusedInterval: 45
    property real selectorX: {
        var interval = 0;
        if (curWorkspace > 1) {
            interval = (visibleWS.indexOf(curWorkspace) - 1) * normalInterval + focusedInterval;
        }
        return 14 + interval;
    }
    property real wsbgWidth: {
        var interval = 0;
        if (visibleWS.indexOf(curWorkspace) == 0 || visibleWS.indexOf(curWorkspace) == visibleWS.length - 1) {
            interval = focusedInterval + (visibleWS.length - 2) * normalInterval;
        } else {
            interval = 2 * focusedInterval + (visibleWS.length - 3) * normalInterval;
        }
        return 36 + 28 + interval;
    }

    function funcInTimer(phaseInterval, stopPos) {
        var eased = 0.0;
        hyprWorkspace.refreshPhase += phaseInterval;
        hyprWorkspace.refreshPhase %= 1;
        if (hyprWorkspace.refreshPhase < stopPos) {
            eased = 0.5 - 0.5 * Math.cos(Math.PI * (hyprWorkspace.refreshPhase + 1 - stopPos)) - (0.5 - 0.5 * Math.cos(Math.PI * (1 - stopPos)));
        } else {
            eased = 0.5 - 0.5 * Math.cos(Math.PI * (hyprWorkspace.refreshPhase - stopPos)) + (0.5 - 0.5 * Math.cos(Math.PI * stopPos));
        }
        hyprWorkspace.refreshOffset = eased * hyprWorkspace.refreshDistance;
    }

    Behavior on selectorX {
        SpringAnimation {
            spring: 4
            damping: 0.2
        }
    }
    Behavior on wsbgWidth {
        SpringAnimation {
            spring: 4
            damping: 0.2
        }
    }

    implicitWidth: wsbgWidth
    implicitHeight: 64
    color: "transparent"

    Item {
        anchors.fill: parent
        z: 0
        layer.enabled: true
        layer.effect: ShaderEffect {
            property real w: hyprWorkspace.width
            property real h: hyprWorkspace.height
            property real r: Math.min(32, Math.min(hyprWorkspace.height, hyprWorkspace.width) / 2)
            property real offset: hyprWorkspace.refreshOffset
            property vector4d bg: Colors.hexToRGBA01(Colors.bg1)
            property vector4d fg: Colors.hexToRGBA01(Colors.fg3)

            fragmentShader: "../../../shaders/refresh-diagonal.frag.qsb"
        }
    }

    Rectangle {
        id: selector

        anchors.verticalCenter: parent.verticalCenter
        x: hyprWorkspace.selectorX
        z: 1
        width: 36
        height: 36
        radius: 18
        color: Colors.fg1
    }

    Repeater {
        model: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

        delegate: Rectangle {
            id: wsRect

            required property var modelData

            property int wsIndex: hyprWorkspace.visibleWS.indexOf(modelData)

            Behavior on x {
                SpringAnimation {
                    spring: 4
                    damping: 0.2
                }
            }
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

            anchors.verticalCenter: parent.verticalCenter
            width: hyprWorkspace.normalInterval
            height: width
            x: {
                var focusIndex = hyprWorkspace.visibleWS.indexOf(hyprWorkspace.curWorkspace);

                var interval = 0;
                if (wsIndex > 0) {
                    if (hyprWorkspace.curWorkspace < modelData) {
                        if (focusIndex == 0 || focusIndex == hyprWorkspace.visibleWS.length - 1) {
                            interval = (wsIndex - 1) * hyprWorkspace.normalInterval + hyprWorkspace.focusedInterval;
                        } else {
                            interval = (wsIndex - 2) * hyprWorkspace.normalInterval + 2 * hyprWorkspace.focusedInterval;
                        }
                    } else if (hyprWorkspace.curWorkspace == modelData) {
                        interval = (wsIndex - 1) * hyprWorkspace.normalInterval + hyprWorkspace.focusedInterval;
                    } else {
                        interval = wsIndex * hyprWorkspace.normalInterval;
                    }
                } else if (wsIndex < 0) {
                    interval = hyprWorkspace.wsbgWidth / 2;
                }
                return 14 + (36 - width) / 2 + interval;
            }
            z: 2
            color: "transparent"
            opacity: (wsIndex >= 0) ? 1 : 0
            scale: (wsIndex >= 0) ? 1 : 0

            Text {
                property bool isFocused: hyprWorkspace.curWorkspace === wsRect.modelData

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                        easing: Easing.InOutSine
                    }
                }

                anchors.centerIn: parent
                font {
                    Behavior on pixelSize {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutSine
                        }
                    }

                    family: Colors.font
                    pixelSize: isFocused ? 18 : 20
                }
                color: isFocused ? Colors.fg2 : Colors.fg1
                text: wsRect.modelData
            }

            Process {
                id: changeWSProc

                command: ["bash", "-c", `hyprctl dispatch 'hl.dsp.focus({ workspace = ${wsRect.modelData} })'`]
                running: false
            }

            TapHandler {
                enabled: wsRect.wsIndex >= 0

                onTapped: {
                    changeWSProc.running = true;
                }
            }
        }
    }
}
