pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../"

Rectangle {
    id: systemStats

    required property var barRoot
    property bool canExpand

    property bool expand: false
    property real targetWidth: expand ? 355 : 64
    property real expandBarHeight: expand ? 95 + statsColumn.height + 20 : 64
    property real targetHeight: expandBarHeight
    property real targetPuppyIconHeight: expand ? 95 : 64
    property real targetPuppyIconFontSize: expand ? 42 : 28
    property real targetSystemStatsRectY: expand ? 95 : -20 - statsColumn.height
    property real bandOffset: 0
    property real whRatio: width / height

    function funcInTimer(offsetInterval) {
        bandOffset += offsetInterval;
        bandOffset %= 1 + systemStats.whRatio;
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
    Behavior on targetPuppyIconHeight {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutSine
        }
    }
    Behavior on targetPuppyIconFontSize {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutSine
        }
    }
    Behavior on targetSystemStatsRectY {
        SpringAnimation {
            spring: 4
            damping: 0.25
        }
    }

    implicitWidth: targetWidth
    implicitHeight: targetHeight
    color: "transparent"
    clip: true

    TapHandler {
        onTapped: {
            if (!systemStats.expand && !systemStats.canExpand) {
                statsIconText.aniStage = 1;
                statsIconTextAniTimer.interval = 0;
                statsIconTextAniTimer.restart();
                return;
            }
            systemStats.expand = !systemStats.expand;
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
            property real w: systemStats.width
            property real h: systemStats.height
            property real r: Math.min(32, Math.min(systemStats.height, systemStats.width) / 2)
            property real offset: systemStats.bandOffset
            property vector4d bg1: Colors.hexToRGBA01(Colors.bg1)
            property vector4d bg2: Colors.hexToRGBA01(Colors.bg2)
            property vector4d bg3: Colors.hexToRGBA01(Colors.bg3)

            fragmentShader: "../../../shaders/band-diagonal.frag.qsb"
        }
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        height: Math.min(systemStats.targetPuppyIconHeight, systemStats.height)
        z: 1

        Text {
            id: statsIconText

            readonly property real desX: (parent.width - implicitWidth) / 2
            property int aniStage: 0

            Behavior on x {
                SpringAnimation {
                    spring: 4
                    damping: 0.2
                }
            }

            Timer {
                id: statsIconTextAniTimer

                onTriggered: {
                    switch (statsIconText.aniStage) {
                    case 0:
                        statsIconText.x = statsIconText.desX;
                        statsIconTextAniTimer.interval = 0;
                        break;
                    case 1:
                        statsIconText.x = statsIconText.desX - 10;
                        statsIconText.aniStage = 2;
                        statsIconTextAniTimer.interval = 100;
                        statsIconTextAniTimer.restart();
                        break;
                    case 2:
                        statsIconText.x = statsIconText.desX + 10;
                        statsIconText.aniStage = 0;
                        statsIconTextAniTimer.restart();
                        break;
                    }
                }
            }

            x: desX
            y: (parent.height - implicitHeight) / 2
            font {
                family: Colors.font
                pixelSize: systemStats.targetPuppyIconFontSize
            }
            color: Colors.fg1
            text: "󰩃"
        }
    }

    // --- Start ---
    ColumnLayout {
        id: statsColumn

        x: 20
        y: systemStats.targetSystemStatsRectY
        spacing: 6
        opacity: systemStats.expand ? 1 : 0
        scale: systemStats.expand ? 1 : 0

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

        // --- CPU Stats ---
        RowLayout {
            id: cpuStats

            spacing: 0

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 25
                Layout.preferredHeight: cpuIcon.height
                color: "transparent"

                Text {
                    id: cpuIcon

                    x: (parent.width - implicitWidth) / 2
                    y: (parent.height - implicitHeight) / 2
                    font {
                        family: Colors.font
                        pixelSize: 24
                    }
                    color: Colors.fg1
                    text: ""
                }
            }
            Item {
                Layout.preferredWidth: 10
                Layout.preferredHeight: 1
            }
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 120
                Layout.preferredHeight: 14
                radius: Math.min(width, height) / 2
                color: Colors.fg1

                Rectangle {
                    Behavior on width {
                        SpringAnimation {
                            spring: 4
                            damping: 0.2
                        }
                    }

                    anchors.verticalCenter: parent.verticalCenter
                    x: 4
                    width: {
                        const usage = systemStats.barRoot.cpuUsagePercent;
                        return 112 * usage * 1e-2;
                    }
                    height: 6
                    radius: Math.min(width, height) / 2
                    color: Colors.bg1
                }
            }
            Item {
                Layout.preferredWidth: 10
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: `${systemStats.barRoot.cpuUsagePercent.toFixed(1)}`
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: "%"
            }
            Item {
                Layout.preferredWidth: 10
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: `${systemStats.barRoot.cpuAvgFreqGHz.toFixed(1)}`
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: "GHz"
            }
        }
        // --- Memory Stats ---
        RowLayout {
            id: memStats

            property real totalGB: systemStats.barRoot.memTotalKB / 1024 / 1024
            property real usedGB: systemStats.barRoot.memUsedKB / 1024 / 1024

            spacing: 0

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 25
                Layout.preferredHeight: memIcon.height
                color: "transparent"

                Text {
                    id: memIcon

                    x: (parent.width - implicitWidth) / 2
                    y: (parent.height - implicitHeight) / 2
                    font {
                        family: Colors.font
                        pixelSize: 24
                    }
                    color: Colors.fg1
                    text: ""
                }
            }
            Item {
                Layout.preferredWidth: 10
                Layout.preferredHeight: 1
            }
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 120
                Layout.preferredHeight: 14
                radius: Math.min(width, height) / 2
                color: Colors.fg1

                Rectangle {
                    Behavior on width {
                        SpringAnimation {
                            spring: 4
                            damping: 0.2
                        }
                    }

                    anchors.verticalCenter: parent.verticalCenter
                    x: 4
                    width: {
                        if (memStats.totalGB <= 0 || memStats.usedGB <= 0) {
                            return 0;
                        }

                        const usage = memStats.usedGB / memStats.totalGB;
                        return (112 * usage).toFixed(2);
                    }
                    height: 6
                    radius: Math.min(width, height) / 2
                    color: Colors.bg1
                }
            }
            Item {
                Layout.preferredWidth: 10
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: `${memStats.usedGB.toFixed(1)}`
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: "/"
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: `${memStats.totalGB.toFixed(1)}`
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: "GB"
            }
        }
        // --- Battery Stats ---
        RowLayout {
            id: batteryStats

            spacing: 0
            visible: systemStats.barRoot.hasBattery

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 25
                Layout.preferredHeight: batteryIcon.height
                color: "transparent"

                Text {
                    id: batteryIcon

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing: Easing.InOutSine
                        }
                    }

                    x: (parent.width - implicitWidth) / 2
                    y: (parent.height - implicitHeight) / 2
                    font {
                        family: Colors.font
                        pixelSize: 24
                    }
                    color: systemStats.barRoot.acOnline === 1 ? Colors.btc : Colors.fg1
                    text: systemStats.barRoot.acOnline === 1 ? "󰂄" : "󱟞"
                }
            }
            Item {
                Layout.preferredWidth: 10
                Layout.preferredHeight: 1
            }
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 120
                Layout.preferredHeight: 14
                radius: Math.min(width, height) / 2
                color: Colors.fg1

                Rectangle {
                    Behavior on width {
                        SpringAnimation {
                            spring: 4
                            damping: 0.2
                        }
                    }

                    anchors.verticalCenter: parent.verticalCenter
                    x: 4
                    width: {
                        return (112 * systemStats.barRoot.batteryCapacity / 100).toFixed(2);
                    }
                    height: 6
                    radius: Math.min(width, height) / 2
                    color: Colors.bg1
                }
            }
            Item {
                Layout.preferredWidth: 10
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: `${systemStats.barRoot.batteryCapacity}`
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: "%"
            }
            Item {
                Layout.preferredWidth: 10
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 24
                }
                color: systemStats.barRoot.acOnline === 1 ? Colors.btc : Colors.fg1
                text: systemStats.barRoot.acOnline === 1 ? "󰚥" : "󰚦"
            }
        }
        // --- Divider ---
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 355 - statsColumn.x * 2
            Layout.preferredHeight: 30

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: 2.5
                radius: Math.min(width, height) / 2
                color: Colors.fg1
            }
        }
        // --- Network Stats ---
        RowLayout {
            id: networkStats

            property int downloadCounter: smartUnit(systemStats.barRoot.downloadSpeedBps)
            property int uploadCounter: smartUnit(systemStats.barRoot.uploadSpeedBps)

            function smartUnit(speed) {
                let counter = 0;
                while (counter < 4) {
                    if (speed >= 1000) {
                        speed /= 1000;
                        counter++;
                    } else {
                        break;
                    }
                }
                return counter;
            }

            spacing: 0

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 25
                Layout.preferredHeight: networkIcon.height
                color: "transparent"

                Text {
                    id: networkIcon

                    anchors.centerIn: parent
                    font {
                        family: Colors.font
                        pixelSize: 24
                    }
                    color: Colors.fg1
                    text: "󰖈"
                }
            }
            Item {
                Layout.preferredWidth: 10
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: {
                    let downloadSpeed = systemStats.barRoot.downloadSpeedBps;
                    for (let i = 0; i < networkStats.downloadCounter; i++) {
                        downloadSpeed /= 1e3;
                    }
                    return `${downloadSpeed.toFixed(1)}`;
                }
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: {
                    switch (networkStats.downloadCounter) {
                    case 0:
                        return "Bps";
                    case 1:
                        return "KBps";
                    case 2:
                        return "MBps";
                    case 3:
                        return "GBps";
                    case 4:
                        return "TBps";
                    default:
                        return "N/A";
                    }
                }
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: ""
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: "/"
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: {
                    let uploadSpeed = systemStats.barRoot.uploadSpeedBps;
                    for (let i = 0; i < networkStats.uploadCounter; i++) {
                        uploadSpeed /= 1e3;
                    }
                    return `${uploadSpeed.toFixed(1)}`;
                }
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: {
                    switch (networkStats.uploadCounter) {
                    case 0:
                        return "Bps";
                    case 1:
                        return "KBps";
                    case 2:
                        return "MBps";
                    case 3:
                        return "GBps";
                    case 4:
                        return "TBps";
                    default:
                        return "N/A";
                    }
                }
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: ""
            }
        }
        // --- Temperature ---
        RowLayout {
            id: temperature

            spacing: 0

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 25
                Layout.preferredHeight: tempIcon.height
                color: "transparent"

                Text {
                    id: tempIcon

                    x: (parent.width - implicitWidth) / 2
                    y: (parent.height - implicitHeight) / 2
                    font {
                        family: Colors.font
                        pixelSize: 24
                    }
                    color: Colors.fg1
                    text: ""
                }
            }
            Item {
                Layout.preferredWidth: 10
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: `${systemStats.barRoot.cpuTemp.toFixed(1)}`
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: "󰔄"
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 22
                }
                color: Colors.fg1
                text: ""
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: "/"
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: `${systemStats.barRoot.gpuTemp.toFixed(1)}`
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: "󰔄"
            }
            Item {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 1
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                font {
                    family: Colors.font
                    pixelSize: 24
                }
                color: Colors.fg1
                text: "󰢮"
            }
        }
    }
}
