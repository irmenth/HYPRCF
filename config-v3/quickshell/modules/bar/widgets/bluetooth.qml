pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../../../"

Rectangle {
    id: bluetooth

    property bool canExpand

    property bool expand: false
    property real targetWidth: expand ? menuCol.targetWidth + 20 : 64
    property real expandBarHeight: expand ? 72 + menuCol.height + 10 : 64
    property real targetHeight: expandBarHeight
    property real targetBTRectHeight: expand ? 90 : 64
    property real targetBTFontSize: expand ? 40 : 30
    property real targetMenuColY: expand ? 72 : -10 - menuCol.height
    property real bandOffset: 0

    property var devices: Bluetooth.devices.values.filter(item => (item.deviceName.length > 0) && (item.icon !== ""))
    property int connectedDevicesLen: {
        let len = 0;
        for (const d of devices) {
            if (d.state === BluetoothDeviceState.Connected) {
                len++;
            }
        }
        return len;
    }
    property bool adapterBusy: Bluetooth.defaultAdapter.state === BluetoothAdapterState.Enabling || Bluetooth.defaultAdapter.state === BluetoothAdapterState.Disabling

    function funcInTimer(offsetInterval) {
        bluetooth.bandOffset += offsetInterval;
        bluetooth.bandOffset %= 1 + bluetooth.width / bluetooth.height;
    }

    onExpandChanged: {
        if (Bluetooth.defaultAdapter.state !== BluetoothAdapterState.Enabled) {
            return;
        }

        if (expand) {
            if (!Bluetooth.defaultAdapter.discovering) {
                Bluetooth.defaultAdapter.discovering = true;
            }
        } else {
            Bluetooth.defaultAdapter.discovering = false;
        }
    }

    Connections {
        target: Bluetooth.defaultAdapter

        function onStateChanged() {
            if (Bluetooth.defaultAdapter.state === BluetoothAdapterState.Enabled && !Bluetooth.defaultAdapter.discovering) {
                Bluetooth.defaultAdapter.discovering = true;
            }
        }
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
    Behavior on targetBTFontSize {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutSine
        }
    }
    Behavior on targetBTRectHeight {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutSine
        }
    }
    Behavior on targetMenuColY {
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
            if (!bluetooth.expand && !bluetooth.canExpand) {
                btIconText.aniStage = 1;
                btIconTextAniTimer.interval = 0;
                btIconTextAniTimer.restart();
                return;
            }
            bluetooth.expand = !bluetooth.expand;
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
            property real w: bluetooth.width
            property real h: bluetooth.height
            property real r: Math.min(32, Math.min(bluetooth.height, bluetooth.width) / 2)
            property real offset: bluetooth.bandOffset
            property vector4d bg1: Colors.hexToRGBA01(Colors.fg5)
            property vector4d bg2: Colors.hexToRGBA01(Colors.fg4)
            property vector4d bg3: Colors.hexToRGBA01(Colors.fg1)

            fragmentShader: "../../../shaders/band-diagonal.frag.qsb"
        }
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        height: Math.min(bluetooth.targetBTRectHeight, bluetooth.height)
        z: 1

        Text {
            id: btIconText

            readonly property real desX: (parent.width - implicitWidth) / 2
            property int aniStage: 0

            Behavior on x {
                SpringAnimation {
                    spring: 4
                    damping: 0.2
                }
            }

            Timer {
                id: btIconTextAniTimer

                onTriggered: {
                    switch (btIconText.aniStage) {
                    case 0:
                        btIconText.x = btIconText.desX;
                        btIconTextAniTimer.interval = 0;
                        break;
                    case 1:
                        btIconText.x = btIconText.desX - 10;
                        btIconText.aniStage = 2;
                        btIconTextAniTimer.interval = 100;
                        btIconTextAniTimer.restart();
                        break;
                    case 2:
                        btIconText.x = btIconText.desX + 10;
                        btIconText.aniStage = 0;
                        btIconTextAniTimer.restart();
                        break;
                    }
                }
            }

            x: desX
            y: (parent.height - implicitHeight) / 2
            font {
                family: Colors.font
                pixelSize: bluetooth.targetBTFontSize
            }
            color: Colors.fg2
            text: Bluetooth.defaultAdapter?.state === BluetoothAdapterState.Enabled ? (bluetooth.connectedDevicesLen > 0 ? "󰂱" : "󰂯") : "󰂲"
        }
    }

    ColumnLayout {
        id: menuCol

        property real targetWidth: devicesRect.hasHeight ? 250 : 200

        Behavior on width {
            NumberAnimation {
                duration: 250
                easing.type: Easing.InOutSine
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

        anchors.horizontalCenter: parent.horizontalCenter
        width: targetWidth
        height: switchRect.Layout.preferredHeight + (devicesRect.hasHeight ? (spacing + devicesRect.Layout.preferredHeight) : 0)
        y: bluetooth.targetMenuColY
        z: 2
        spacing: 12
        opacity: bluetooth.expand ? 1 : 0
        scale: bluetooth.expand ? 1 : 0
        enabled: bluetooth.expand

        Rectangle {
            id: switchRect

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: menuCol.width
            Layout.preferredHeight: 40
            color: "transparent"

            Text {
                x: (devicesRect.hasHeight ? 20 : 10)
                y: switchRect.height / 2 + 2 - height / 2
                font {
                    family: Colors.font
                    pixelSize: 20
                }
                color: Colors.fg2
                text: Bluetooth.defaultAdapter?.name ?? ""
            }

            Rectangle {
                x: parent.width - width - (devicesRect.hasHeight ? 20 : 10)
                y: switchRect.height / 2 + 2 - height / 2
                width: 50
                height: 30
                color: Colors.bg2
                radius: Math.min(width, height) / 2

                Rectangle {
                    Behavior on x {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutSine
                        }
                    }

                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    radius: Math.min(width, height) / 2
                    x: (Bluetooth.defaultAdapter?.enabled ?? false) ? parent.width - (parent.height - height) / 2 - width : (parent.height - height) / 2
                    color: Colors.fg1
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        if (bluetooth.adapterBusy) {
                            return;
                        }

                        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
                    }
                }
            }
        }
        Rectangle {
            id: devicesRect

            property bool hasHeight: bluetooth.devices.length > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutSine
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutSine
                }
            }

            Layout.preferredWidth: parent.width
            Layout.preferredHeight: devicesList.height
            color: "transparent"
            opacity: hasHeight ? 1 : 0
            scale: hasHeight ? 1 : 0

            ListView {
                id: devicesList

                property real deviceRectHeight: 45

                anchors.centerIn: parent
                width: parent.width
                height: Math.max(0, Math.min(3, bluetooth.devices.length) * (devicesList.deviceRectHeight + spacing) - spacing)
                snapMode: ListView.SnapToItem
                clip: true
                spacing: 8
                model: ScriptModel {
                    values: bluetooth.devices
                }

                delegate: Rectangle {
                    id: deviceRect

                    required property var modelData

                    property bool showForget: false
                    property real forgetSpace: showForget ? -55 : 0
                    property bool forgetting: false

                    Connections {
                        target: bluetooth

                        function onExpandChanged() {
                            if (!bluetooth.expand) {
                                deviceRect.showForget = false;
                            }
                        }
                    }
                    Connections {
                        target: deviceRect.modelData

                        function onStateChanged() {
                            switch (deviceRect.modelData.state) {
                            case BluetoothDeviceState.Connecting:
                                connectIconText.aniStage = 1;
                                connectIconAniTimer.interval = 0;
                                connectIconAniTimer.restart();
                                break;
                            case BluetoothDeviceState.Disconnecting:
                                connectIconText.aniStage = 3;
                                connectIconAniTimer.interval = 0;
                                connectIconAniTimer.restart();
                                break;
                            case BluetoothDeviceState.Disconnected:
                            case BluetoothDeviceState.Connected:
                                connectIconText.aniStage = 0;
                                break;
                            }
                        }
                    }

                    onScaleChanged: {
                        if (deviceRect.scale === 0 || deviceRect.opacity === 0) {
                            deviceRect.modelData.forget();
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.InOutSine
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.InOutSine
                        }
                    }

                    width: devicesRect.width
                    height: devicesList.deviceRectHeight
                    color: "transparent"
                    scale: forgetting ? 0 : 1
                    opacity: forgetting ? 0 : 1

                    Rectangle {
                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.InOutSine
                            }
                        }

                        width: devicesList.deviceRectHeight
                        height: devicesList.deviceRectHeight
                        x: parent.width - width
                        radius: Math.min(width, height) / 2
                        color: Colors.bg2
                        enabled: deviceRect.showForget
                        scale: deviceRect.showForget ? 1 : 0

                        Text {
                            id: forgetIconText

                            readonly property real desX: (parent.width - implicitWidth) / 2
                            property int aniStage: 0

                            Behavior on x {
                                SpringAnimation {
                                    spring: 4
                                    damping: 0.2
                                }
                            }

                            Timer {
                                id: forgetIconAniTimer

                                onTriggered: {
                                    switch (forgetIconText.aniStage) {
                                    case 0:
                                        forgetIconText.x = forgetIconText.desX;
                                        forgetIconAniTimer.interval = 0;
                                        break;
                                    case 1:
                                        forgetIconText.x = forgetIconText.desX - 5;
                                        forgetIconText.aniStage = 2;
                                        forgetIconAniTimer.interval = 100;
                                        forgetIconAniTimer.restart();
                                        break;
                                    case 2:
                                        forgetIconText.x = forgetIconText.desX + 5;
                                        forgetIconText.aniStage = 0;
                                        forgetIconAniTimer.restart();
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
                            color: Colors.err
                            text: ""
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                if (deviceRect.modelData.state === BluetoothDeviceState.Disconnected) {
                                    deviceRect.forgetting = true;
                                    deviceRect.showForget = false;
                                } else {
                                    forgetIconText.aniStage = 1;
                                    forgetIconAniTimer.interval = 0;
                                    forgetIconAniTimer.restart();
                                }
                            }
                        }
                    }

                    Rectangle {
                        Behavior on width {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.InOutSine
                            }
                        }

                        width: deviceRect.forgetSpace + devicesRect.width
                        height: devicesList.deviceRectHeight
                        radius: Math.min(width, height) / 2
                        color: Colors.bg2

                        Text {
                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                    easing.type: Easing.InOutSine
                                }
                            }

                            anchors.verticalCenter: parent.verticalCenter
                            width: deviceRect.forgetSpace + 200 - x
                            x: 15
                            font {
                                family: Colors.font
                                pixelSize: 14
                            }
                            color: deviceRect.modelData.state === BluetoothDeviceState.Connected ? Colors.btc : Colors.fg1
                            text: deviceRect.modelData.name
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            id: connectRect

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                    easing.type: Easing.InOutSine
                                }
                            }

                            anchors.verticalCenter: parent.verticalCenter
                            x: parent.width - width - 10
                            width: parent.height - 20
                            height: parent.height - 20
                            radius: Math.min(width, height) / 2
                            color: deviceRect.modelData.state === BluetoothDeviceState.Connected ? Colors.btc : Colors.fg1

                            Text {
                                id: connectIconText

                                readonly property real desY: (parent.height - implicitHeight) / 2
                                readonly property real desX: (parent.width - implicitWidth) / 2
                                property int aniStage: 0

                                Behavior on x {
                                    SpringAnimation {
                                        spring: 4
                                        damping: 0.2
                                    }
                                }
                                Behavior on y {
                                    SpringAnimation {
                                        spring: 4
                                        damping: 0.2
                                    }
                                }

                                Timer {
                                    id: connectIconAniTimer

                                    onTriggered: {
                                        switch (connectIconText.aniStage) {
                                        case 0:
                                            connectIconText.x = connectIconText.desX;
                                            connectIconText.y = connectIconText.desY;
                                            connectIconAniTimer.interval = 0;
                                            break;
                                        case 1:
                                            connectIconText.y = connectIconText.desY - 2;
                                            connectIconText.aniStage = 2;
                                            connectIconAniTimer.interval = 150;
                                            connectIconAniTimer.restart();
                                            break;
                                        case 2:
                                            connectIconText.y = connectIconText.desY + 2;
                                            connectIconText.aniStage = 1;
                                            connectIconAniTimer.restart();
                                            break;
                                        case 3:
                                            connectIconText.x = connectIconText.desX - 2;
                                            connectIconText.aniStage = 4;
                                            connectIconAniTimer.interval = 150;
                                            connectIconAniTimer.restart();
                                            break;
                                        case 4:
                                            connectIconText.x = connectIconText.desX + 2;
                                            connectIconText.aniStage = 3;
                                            connectIconAniTimer.restart();
                                            break;
                                        }
                                    }
                                }

                                x: desX
                                y: desY
                                font {
                                    family: Colors.font
                                    pixelSize: 14
                                }
                                color: Colors.fg2
                                text: "󰂱"
                            }
                        }

                        MouseArea {
                            width: connectRect.x - 6
                            height: parent.height

                            onClicked: {
                                deviceRect.showForget = !deviceRect.showForget;
                            }
                        }

                        MouseArea {
                            width: parent.width - x
                            height: parent.height
                            x: connectRect.x - 6

                            onClicked: {
                                switch (deviceRect.modelData.state) {
                                case BluetoothDeviceState.Connected:
                                    deviceRect.modelData.disconnect();
                                    break;
                                case BluetoothDeviceState.Disconnected:
                                    deviceRect.modelData.connect();
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
