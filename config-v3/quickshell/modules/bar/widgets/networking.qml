pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Networking
import "../../../"

Rectangle {
    id: networking

    property bool canExpand

    property bool expand: false
    property real targetWidth: expand ? menuCol.targetWidth + 20 : 64
    property real expandBarHeight: expand ? 72 + menuCol.height + 10 : 64
    property real targetHeight: expandBarHeight
    property real targetWifiRectHeight: expand ? 90 : 64
    property real targetWifiFontSize: expand ? 36 : 26
    property real targetMenuColY: expand ? 72 : -10 - menuCol.height
    property real bandOffset: 0

    property WifiDevice wifiDevice: Networking.devices.values.find(device => device.type === DeviceType.Wifi)
    property var networks: {
        if (wifiDevice === undefined) {
            return [];
        }

        return wifiDevice.networks.values;
    }
    property real signalStrength: {
        if (wifiDevice === undefined || !wifiDevice.connected) {
            return -1;
        }

        for (const nw of wifiDevice.networks.values) {
            if (nw.connected) {
                return nw.signalStrength;
            }
        }

        return -1;
    }

    function funcInTimer(offsetInterval) {
        networking.bandOffset += offsetInterval;
        networking.bandOffset %= 1 + networking.width / networking.height;
    }
    function setFocus(val) {
        pwdTextField.focus = val;
    }

    onExpandChanged: {
        networking.wifiDevice.scannerEnabled = expand;
        if (!expand) {
            pwdRect.showPwdRect = false;
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
    Behavior on targetWifiFontSize {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutSine
        }
    }
    Behavior on targetWifiRectHeight {
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
            if (!networking.expand && !networking.canExpand) {
                wifiIconText.aniStage = 1;
                wifiIconTextAniTimer.interval = 0;
                wifiIconTextAniTimer.restart();
                return;
            }
            networking.expand = !networking.expand;
        }
    }

    Item {
        anchors.fill: parent
        z: 0
        layer.enabled: true
        layer.effect: ShaderEffect {
            property real w: networking.width
            property real h: networking.height
            property real r: Math.min(32, Math.min(networking.height, networking.width) / 2)
            property real offset: networking.bandOffset
            property vector4d bg1: Colors.hexToRGBA01(Colors.fg5)
            property vector4d bg2: Colors.hexToRGBA01(Colors.fg4)
            property vector4d bg3: Colors.hexToRGBA01(Colors.fg1)

            fragmentShader: "../../../shaders/band-diagonal.frag.qsb"
        }
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        height: Math.min(networking.targetWifiRectHeight, networking.height)
        z: 1

        Text {
            id: wifiIconText

            readonly property real desX: (parent.width - implicitWidth) / 2
            property int aniStage: 0

            Behavior on x {
                SpringAnimation {
                    spring: 4
                    damping: 0.2
                }
            }

            Timer {
                id: wifiIconTextAniTimer

                onTriggered: {
                    switch (wifiIconText.aniStage) {
                    case 0:
                        wifiIconText.x = wifiIconText.desX;
                        wifiIconTextAniTimer.interval = 0;
                        break;
                    case 1:
                        wifiIconText.x = wifiIconText.desX - 10;
                        wifiIconText.aniStage = 2;
                        wifiIconTextAniTimer.interval = 100;
                        wifiIconTextAniTimer.restart();
                        break;
                    case 2:
                        wifiIconText.x = wifiIconText.desX + 10;
                        wifiIconText.aniStage = 0;
                        wifiIconTextAniTimer.restart();
                        break;
                    }
                }
            }

            x: desX
            y: (parent.height - implicitHeight) / 2
            font {
                family: Colors.font
                pixelSize: networking.targetWifiFontSize
            }
            color: Colors.fg2
            text: {
                if (networking.wifiDevice.connected) {
                    if (networking.signalStrength < 0) {
                        return "󰤯";
                    } else if (networking.signalStrength <= 0.25) {
                        return "󰤟";
                    } else if (networking.signalStrength <= 0.5) {
                        return "󰤢";
                    } else if (networking.signalStrength <= 0.75) {
                        return "󰤥";
                    } else {
                        return "󰤨";
                    }
                } else {
                    if (Networking.wifiEnabled) {
                        return "󰤯";
                    } else {
                        return "󰤮";
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: menuCol

        property real targetWidth: networksRect.hasHeight ? 250 : 200

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
        height: switchRect.Layout.preferredHeight + (networksRect.hasHeight ? (12 + networksRect.Layout.preferredHeight) : 0) + (pwdRect.showPwdRect ? (8 + pwdRect.Layout.preferredHeight) : 0)
        y: networking.targetMenuColY
        z: 2
        spacing: 0
        opacity: networking.expand ? 1 : 0
        scale: networking.expand ? 1 : 0
        enabled: networking.expand

        Rectangle {
            id: switchRect

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: menuCol.width
            Layout.preferredHeight: 40
            color: "transparent"

            Text {
                x: (networksRect.hasHeight ? 20 : 10)
                y: switchRect.height / 2 + 2 - height / 2
                font {
                    family: Colors.font
                    pixelSize: 20
                }
                color: Colors.fg2
                text: networking.wifiDevice.name
            }

            Rectangle {
                x: parent.width - width - (networksRect.hasHeight ? 20 : 10)
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
                    x: Networking.wifiEnabled ? parent.width - (parent.height - height) / 2 - width : (parent.height - height) / 2
                    color: Colors.fg1
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        Networking.wifiEnabled = !Networking.wifiEnabled;
                    }
                }
            }
        }
        Item {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 12
            visible: networksRect.hasHeight
        }
        Rectangle {
            id: networksRect

            property bool hasHeight: networking.wifiDevice.networks.values.length > 0

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
            Layout.preferredHeight: networksList.height
            color: "transparent"
            opacity: hasHeight ? 1 : 0
            scale: hasHeight ? 1 : 0

            ListView {
                id: networksList

                property real networkRectHeight: 45
                property var pwdNetwork

                anchors.centerIn: parent
                width: parent.width
                height: Math.max(0, Math.min(3, networking.networks.length) * (networksList.networkRectHeight + spacing) - spacing)
                snapMode: ListView.SnapToItem
                clip: true
                spacing: 8
                model: ScriptModel {
                    values: networking.networks
                }

                delegate: Rectangle {
                    id: networkRect

                    required property var modelData

                    property bool showForget: false
                    property real forgetSpace: showForget ? -55 : 0
                    property bool needPwd: !(networkRect.modelData.security === WifiSecurityType.Open || networkRect.modelData.security === WifiSecurityType.Owe || networkRect.modelData.security === WifiSecurityType.Unknown)

                    Connections {
                        target: networking

                        function onExpandChanged() {
                            if (!networking.expand) {
                                networkRect.showForget = false;
                            }
                        }
                    }
                    Connections {
                        target: networkRect.modelData

                        function onStateChanged() {
                            switch (networkRect.modelData.state) {
                            case ConnectionState.Connecting:
                                connectIconText.aniStage = 1;
                                connectIconAniTimer.interval = 0;
                                connectIconAniTimer.restart();
                                break;
                            case ConnectionState.Disconnecting:
                                connectIconText.aniStage = 3;
                                connectIconAniTimer.interval = 0;
                                connectIconAniTimer.restart();
                                break;
                            case ConnectionState.Disconnected:
                            case ConnectionState.Connected:
                                connectIconText.aniStage = 0;
                                break;
                            }
                        }
                        function onConnectionFailed(err) {
                            networkRect.modelData.forget();
                            connectRect.colAniStage = 1;
                            connectRectColAniTimer.interval = 0;
                            connectRectColAniTimer.restart();
                        }
                    }

                    width: networksRect.width
                    height: networksList.networkRectHeight
                    color: "transparent"

                    Rectangle {
                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.InOutSine
                            }
                        }

                        width: networksList.networkRectHeight
                        height: networksList.networkRectHeight
                        x: parent.width - width
                        radius: Math.min(width, height) / 2
                        color: Colors.bg2
                        enabled: networkRect.showForget
                        scale: networkRect.showForget ? 1 : 0

                        Text {
                            id: forgetIconText

                            readonly property real desY: (parent.height - implicitHeight) / 2
                            property int aniStage: 0

                            Behavior on y {
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
                                        forgetIconText.y = forgetIconText.desY;
                                        forgetIconAniTimer.interval = 0;
                                        break;
                                    case 1:
                                        forgetIconText.y = forgetIconText.desY - 5;
                                        forgetIconText.aniStage = 2;
                                        forgetIconAniTimer.interval = 100;
                                        forgetIconAniTimer.restart();
                                        break;
                                    case 2:
                                        forgetIconText.y = forgetIconText.desY + 5;
                                        forgetIconText.aniStage = 0;
                                        forgetIconAniTimer.restart();
                                        break;
                                    }
                                }
                            }

                            x: (parent.width - implicitWidth) / 2
                            y: desY
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
                                forgetIconText.aniStage = 1;
                                forgetIconAniTimer.interval = 0;
                                forgetIconAniTimer.restart();
                                networkRect.modelData.forget();
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

                        width: networkRect.forgetSpace + networksRect.width
                        height: networksList.networkRectHeight
                        radius: Math.min(width, height) / 2
                        color: Colors.bg2

                        Text {
                            id: networkNameText

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                    easing.type: Easing.InOutSine
                                }
                            }

                            anchors.verticalCenter: parent.verticalCenter
                            x: 15
                            width: networkRect.forgetSpace + 150 - x
                            font {
                                family: Colors.font
                                pixelSize: 14
                            }
                            color: networkRect.modelData.state === ConnectionState.Connected ? Colors.btc : Colors.fg1
                            text: networkRect.modelData.name
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            id: networkInfoRow

                            anchors.verticalCenter: parent.verticalCenter
                            x: parent.width - width - 10
                            spacing: 10

                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                font {
                                    family: Colors.font
                                    pixelSize: 14
                                }
                                color: Colors.fg1
                                visible: networkRect.needPwd
                                text: networkRect.needPwd ? "" : ""
                            }
                            Text {
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                        easing.type: Easing.InOutSine
                                    }
                                }

                                Layout.alignment: Qt.AlignVCenter
                                font {
                                    family: Colors.font
                                    pixelSize: 16
                                }
                                color: {
                                    if (networkRect.modelData.signalStrength <= 0.25) {
                                        return Colors.err;
                                    } else if (networkRect.modelData.signalStrength <= 0.5) {
                                        return Colors.wrn;
                                    } else if (networkRect.modelData.signalStrength <= 0.75) {
                                        return Colors.fg1;
                                    } else {
                                        return Colors.btc;
                                    }
                                }
                                text: {
                                    if (networkRect.modelData.signalStrength <= 0.25) {
                                        return "󰤟";
                                    } else if (networkRect.modelData.signalStrength <= 0.5) {
                                        return "󰤢";
                                    } else if (networkRect.modelData.signalStrength <= 0.75) {
                                        return "󰤥";
                                    } else {
                                        return "󰤨";
                                    }
                                }
                            }
                            Rectangle {
                                id: connectRect

                                property int colAniStage: 0
                                property color desColor: networkRect.modelData.state === ConnectionState.Connected ? Colors.btc : Colors.fg1

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                        easing.type: Easing.InOutSine
                                    }
                                }

                                Timer {
                                    id: connectRectColAniTimer

                                    property int blinkCount: 0

                                    onTriggered: {
                                        switch (connectRect.colAniStage) {
                                        case 0:
                                            connectRect.color = connectRect.desColor;
                                            connectRectColAniTimer.interval = 0;
                                            blinkCount = 0;
                                            break;
                                        case 1:
                                            connectRect.color = Colors.err;
                                            connectRect.colAniStage = 2;
                                            connectRectColAniTimer.interval = 250;
                                            connectRectColAniTimer.restart();
                                            break;
                                        case 2:
                                            blinkCount++;
                                            connectRect.color = connectRect.desColor;
                                            if (blinkCount < 3) {
                                                connectRect.colAniStage = 1;
                                            } else {
                                                connectRect.colAniStage = 0;
                                                connectRectColAniTimer.interval = 0;
                                            }
                                            connectRectColAniTimer.restart();
                                            break;
                                        }
                                    }
                                }

                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: networksList.networkRectHeight - 20
                                Layout.preferredHeight: networksList.networkRectHeight - 20
                                radius: Math.min(width, height) / 2
                                color: desColor

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
                                    text: "󱘖"
                                }
                            }
                        }

                        MouseArea {
                            width: networkInfoRow.x + connectRect.x - 6
                            height: parent.height

                            onClicked: {
                                networkRect.showForget = !networkRect.showForget;
                            }
                        }

                        MouseArea {
                            width: parent.width - x
                            height: parent.height
                            x: networkInfoRow.x + connectRect.x - 6

                            onClicked: {
                                switch (networkRect.modelData.state) {
                                case ConnectionState.Connected:
                                    networkRect.modelData.disconnect();
                                    break;
                                case ConnectionState.Disconnected:
                                    if (networkRect.modelData.known || !networkRect.needPwd) {
                                        networkRect.modelData.connect();
                                    } else {
                                        pwdRect.showPwdRect = true;
                                        networksList.pwdNetwork = networkRect.modelData;
                                    }
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
        Item {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 8
            visible: pwdRect.showPwdRect
        }
        Rectangle {
            id: pwdRect

            property bool showPwdRect: false

            onShowPwdRectChanged: {
                if (!showPwdRect) {
                    pwdTextField.text = "";
                }
            }

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
            Layout.preferredHeight: 45
            radius: Math.min(width, height) / 2
            color: Colors.bg2
            scale: showPwdRect ? 1 : 0
            opacity: showPwdRect ? 1 : 0

            Text {
                anchors.verticalCenter: parent.verticalCenter
                x: 15
                font {
                    family: Colors.font
                    pixelSize: 14
                }
                color: Colors.fg1
                text: "密码:"
            }

            TextField {
                id: pwdTextField

                property bool isTyping: false

                onTextChanged: {
                    isTyping = true;
                    typingTimer.restart();
                }

                Timer {
                    id: typingTimer

                    interval: 1000

                    onTriggered: {
                        pwdTextField.isTyping = false;
                    }
                }

                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x - 45
                height: parent.height
                x: 60
                font {
                    family: Colors.font
                    pixelSize: 14
                }
                color: Colors.fg1
                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                }
                cursorDelegate: Rectangle {
                    id: cursorRect

                    property int aniStage: 0

                    Component.onCompleted: {
                        cursorRect.aniStage = 1;
                        cursorAniTimer.interval = 0;
                        cursorAniTimer.restart();
                    }

                    Connections {
                        target: pwdTextField

                        function onIsTypingChanged() {
                            if (pwdTextField.isTyping) {
                                cursorRect.aniStage = 0;
                                cursorAniTimer.interval = 0;
                                cursorAniTimer.restart();
                            } else {
                                cursorRect.aniStage = 1;
                                cursorAniTimer.interval = 0;
                                cursorAniTimer.restart();
                            }
                        }
                    }
                    Connections {
                        target: pwdTextField

                        function onFocusChanged() {
                            if (pwdTextField.focus) {
                                cursorRect.aniStage = 1;
                                cursorAniTimer.interval = 0;
                                cursorAniTimer.restart();
                            } else {
                                cursorRect.aniStage = 0;
                                cursorAniTimer.interval = 0;
                                cursorAniTimer.restart();
                            }
                        }
                    }

                    Timer {
                        id: cursorAniTimer

                        onTriggered: {
                            switch (cursorRect.aniStage) {
                            case 0:
                                cursorRect.opacity = 1;
                                cursorAniTimer.interval = 0;
                                break;
                            case 1:
                                cursorRect.opacity = 0;
                                cursorRect.aniStage = 2;
                                cursorAniTimer.interval = 500;
                                cursorAniTimer.restart();
                                break;
                            case 2:
                                cursorRect.opacity = 1;
                                cursorRect.aniStage = 1;
                                cursorAniTimer.restart();
                                break;
                            }
                        }
                    }

                    onHeightChanged: {
                        height = 4;
                    }
                    onYChanged: {
                        y = pwdTextField.height / 2 + 2;
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.InOutSine
                        }
                    }

                    width: 10
                    height: 4
                    radius: Math.min(2, Math.min(width, height)) / 2
                    y: pwdTextField.height / 2 + 2
                    color: Colors.fg4
                }

                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Escape:
                        if (pwdRect.showPwdRect) {
                            pwdRect.showPwdRect = false;
                        } else {
                            networking.expand = false;
                        }
                        event.accept = true;
                        break;
                    case Qt.Key_Return:
                        networksList.pwdNetwork.connectWithPsk(pwdTextField.text);
                        pwdRect.showPwdRect = false;
                        event.accept = true;
                        break;
                    }
                }
            }

            Text {
                x: parent.width - width - 18
                y: (parent.height - implicitHeight) / 2
                font {
                    family: Colors.font
                    pixelSize: 16
                }
                color: Colors.fg1
                text: "<"
            }
        }
    }
}
