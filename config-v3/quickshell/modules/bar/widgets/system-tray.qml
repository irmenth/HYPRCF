pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import "../../../"

Rectangle {
    id: systemTray

    required property var bar
    property bool canExpand

    property bool expand: false
    property real targetWidth: expand ? (SystemTray.items.values.length + 1) * (14 + 30) - 14 + 2 * 17 : 64
    property bool showMenu: false
    property real showMenuHeight: 0
    property real expandBarHeight: showMenu ? showMenuHeight : 64
    property real targetMenuRectY: showMenu ? 64 + 10 : -10
    property real bandOffset: 0

    function funcInTimer(offsetInterval, phaseInterval, stopPos) {
        bandOffset += offsetInterval;
        bandOffset %= 1 + width / height;
        menuRect.funcInTimer(phaseInterval, stopPos);
    }

    Behavior on targetWidth {
        SpringAnimation {
            spring: 4
            damping: 0.25
        }
    }
    Behavior on targetMenuRectY {
        SpringAnimation {
            spring: 4
            damping: 0.25
        }
    }

    implicitWidth: targetWidth
    implicitHeight: 64
    color: "transparent"

    TapHandler {
        onTapped: {
            if (!systemTray.expand && !systemTray.canExpand) {
                trayIconText.aniStage = 1;
                trayIconTextAniTimer.interval = 0;
                trayIconTextAniTimer.restart();
                return;
            }
            systemTray.expand = !systemTray.expand;
            if (!systemTray.expand) {
                menuRect.curItem = null;
            }
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            if (menuRect.curItem !== null) {
                menuRect.curItem = null;
            } else {
                expand = false;
            }
        }
    }

    Item {
        anchors.fill: parent
        z: 0
        layer.enabled: true
        layer.effect: ShaderEffect {
            property real w: systemTray.width
            property real h: systemTray.height
            property real r: Math.min(32, Math.min(systemTray.width, systemTray.height) / 2)
            property real offset: systemTray.bandOffset
            property vector4d bg1: Colors.hexToRGBA01(Colors.bg1)
            property vector4d bg2: Colors.hexToRGBA01(Colors.bg2)
            property vector4d bg3: Colors.hexToRGBA01(Colors.bg3)

            fragmentShader: "../../../shaders/band-diagonal.frag.qsb"
        }
    }

    Text {
        id: trayIconText

        readonly property real desX: Math.min(17 + (30 - width) / 2, (systemTray.width - width) / 2)
        property int aniStage: 0

        Behavior on x {
            SpringAnimation {
                spring: 4
                damping: 0.2
            }
        }

        Timer {
            id: trayIconTextAniTimer

            onTriggered: {
                switch (trayIconText.aniStage) {
                case 0:
                    trayIconText.x = trayIconText.desX;
                    trayIconTextAniTimer.interval = 0;
                    break;
                case 1:
                    trayIconText.x = trayIconText.desX - 10;
                    trayIconText.aniStage = 2;
                    trayIconTextAniTimer.interval = 100;
                    trayIconTextAniTimer.restart();
                    break;
                case 2:
                    trayIconText.x = trayIconText.desX + 10;
                    trayIconText.aniStage = 0;
                    trayIconTextAniTimer.restart();
                    break;
                }
            }
        }

        x: desX
        y: (parent.height - implicitHeight) / 2
        z: 1
        font {
            family: Colors.font
            pixelSize: 30
        }
        color: Colors.fg1
        text: "󰄛"
    }

    Rectangle {
        id: menuRect

        property real refreshPhase: 0
        property real refreshOffset: 0
        property real refreshDistance: 1 + width / height
        property real targetWidth: 0
        property real targetHeight: 0
        property SystemTrayItem curItem
        property real curItemCenter: 0

        function funcInTimer(phaseInterval, stopPos) {
            var eased = 0.0;
            menuRect.refreshPhase += phaseInterval;
            menuRect.refreshPhase %= 1;
            if (menuRect.refreshPhase < stopPos) {
                eased = 0.5 - 0.5 * Math.cos(Math.PI * (menuRect.refreshPhase + 1 - stopPos)) - (0.5 - 0.5 * Math.cos(Math.PI * (1 - stopPos)));
            } else {
                eased = 0.5 - 0.5 * Math.cos(Math.PI * (menuRect.refreshPhase - stopPos)) + (0.5 - 0.5 * Math.cos(Math.PI * stopPos));
            }
            menuRect.refreshOffset = eased * menuRect.refreshDistance;
        }

        onCurItemChanged: {
            if (curItem === null) {
                systemTray.showMenu = false;
                pageStack.clear();
                return;
            }

            systemTray.showMenu = true;
            if (pageStack.depth > 0) {
                pageStack.pop(null);
                pageStack.replace(pageComponet, {
                    menuObject: curItem.menu,
                    depth: pageStack.depth,
                    title: curItem.title
                });
            } else {
                pageStack.push(pageComponet, {
                    menuObject: curItem.menu,
                    depth: pageStack.depth + 1,
                    title: curItem.title
                });
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
        Behavior on width {
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

        x: Math.max(-systemTray.x, curItemCenter - width / 2)
        y: systemTray.targetMenuRectY
        width: targetWidth
        height: targetHeight
        scale: systemTray.showMenu ? 1 : 0
        opacity: systemTray.showMenu ? 1 : 0
        color: "transparent"
        clip: true

        Item {
            anchors.fill: parent
            z: 0
            layer.enabled: true
            layer.effect: ShaderEffect {
                property real w: menuRect.width
                property real h: menuRect.height
                property real r: Math.min(32, Math.min(menuRect.height, menuRect.width) / 2)
                property real offset: menuRect.refreshOffset
                property vector4d bg: Colors.hexToRGBA01(Colors.bg1)
                property vector4d fg: Colors.hexToRGBA01(Colors.fg3)

                fragmentShader: "../../../shaders/refresh-diagonal.frag.qsb"
            }
        }

        StackView {
            id: pageStack

            onCurrentItemChanged: {
                if (currentItem === null) {
                    return;
                }

                if (currentItem.colWidth > 0 && currentItem.colHeight > 0) {
                    menuRect.targetWidth = currentItem.colWidth + 36;
                    menuRect.targetHeight = currentItem.colHeight + 36;
                    systemTray.showMenuHeight = 64 + 10 + menuRect.targetHeight;
                }
            }

            pushEnter: Transition {
                XAnimator {
                    from: pageStack.width
                    to: 0
                    duration: 200
                    easing.type: Easing.InOutSine
                }
            }
            pushExit: Transition {
                XAnimator {
                    from: 0
                    to: -pageStack.width
                    duration: 200
                    easing.type: Easing.InOutSine
                }
            }
            popEnter: Transition {
                XAnimator {
                    from: -pageStack.width
                    to: 0
                    duration: 200
                    easing.type: Easing.InOutSine
                }
            }
            popExit: Transition {
                XAnimator {
                    from: 0
                    to: pageStack.width
                    duration: 200
                    easing.type: Easing.InOutSine
                }
            }
            replaceEnter: Transition {
                YAnimator {
                    from: pageStack.height
                    to: 0
                    duration: 200
                    easing.type: Easing.InOutSine
                }
            }
            replaceExit: Transition {
                YAnimator {
                    from: 0
                    to: -pageStack.height
                    duration: 200
                    easing.type: Easing.InOutSine
                }
            }

            anchors.fill: parent

            Component {
                id: pageComponet

                Item {
                    id: page

                    required property var menuObject
                    required property int depth
                    required property string title

                    property real colWidth: pageColumn.width
                    property real colHeight: pageColumn.height

                    QsMenuOpener {
                        id: opener

                        menu: page.menuObject
                    }

                    ColumnLayout {
                        id: pageColumn

                        onWidthChanged: {
                            if (page.depth === pageStack.depth) {
                                menuRect.targetWidth = width + 36;
                            }
                        }
                        onHeightChanged: {
                            if (page.depth === pageStack.depth) {
                                menuRect.targetHeight = height + 36;
                                systemTray.showMenuHeight = 64 + 10 + menuRect.targetHeight;
                            }
                        }

                        anchors.horizontalCenter: parent.horizontalCenter
                        y: (menuRect.targetHeight - height) / 2
                        z: 1
                        spacing: 15

                        Rectangle {
                            id: pageHeader

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.InOutSine
                                }
                            }

                            Layout.preferredWidth: pageHeaderText.width + 20
                            Layout.preferredHeight: pageHeaderText.height + 10
                            radius: Math.min(width, height) / 2
                            color: Colors.fg1
                            transformOrigin: Item.TopLeft
                            scale: headerMA.containsMouse ? 1 : 0.9

                            RowLayout {
                                id: pageHeaderText

                                anchors.centerIn: parent

                                Text {
                                    Layout.alignment: Qt.AlignVCenter
                                    font {
                                        family: Colors.font
                                        pixelSize: 18 / 0.9
                                    }
                                    color: Colors.fg2
                                    text: page.depth > 1 ? "󰸾" : "󰹁"
                                }
                                Text {
                                    Layout.alignment: Qt.AlignVCenter
                                    font {
                                        family: Colors.font
                                        pixelSize: 14 / 0.9
                                    }
                                    color: Colors.fg2
                                    text: page.title
                                    visible: text !== ""
                                }
                            }

                            MouseArea {
                                id: headerMA

                                anchors.fill: parent
                                hoverEnabled: true

                                onClicked: {
                                    if (pageStack.depth > 1) {
                                        pageStack.pop();
                                    } else {
                                        menuRect.curItem = null;
                                    }
                                }
                            }
                        }
                        ListView {
                            id: pageList

                            model: opener.children
                            Layout.preferredWidth: {
                                let w = pageColumn.width;
                                for (let i = 0; i < count; i++) {
                                    w = Math.max(w, itemAtIndex(i)?.termWidth ?? 0);
                                }
                                return w;
                            }
                            Layout.preferredHeight: Math.min(8, count) * 25
                            snapMode: ListView.SnapToItem
                            clip: true

                            delegate: Rectangle {
                                id: term

                                required property var modelData

                                property real termWidth: termRow.width
                                property bool hasIcon: (modelData?.icon ?? "") !== ""
                                property bool hasText: (modelData?.text ?? "") !== ""
                                property bool hasCheckBox: (modelData?.buttonType ?? QsMenuButtonType.None) !== QsMenuButtonType.None
                                property bool checked: (modelData?.checkState ?? Qt.CheckState.Unchecked) !== Qt.CheckState.Unchecked

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.InOutSine
                                    }
                                }

                                width: pageList.width
                                height: 25
                                color: "transparent"
                                transformOrigin: Item.Left
                                scale: ((!term.hasIcon) && (!term.hasText)) ? 0.9 : (termMA.containsMouse ? 1 : 0.9)

                                RowLayout {
                                    id: termRow

                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: term.hasIcon || term.hasText
                                    spacing: 6

                                    Rectangle {
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.preferredWidth: 16 / 0.9
                                        Layout.preferredHeight: width
                                        radius: Math.min(width, height)
                                        border {
                                            width: 2
                                            color: Colors.fg1
                                        }
                                        color: "transparent"
                                        visible: term.hasCheckBox

                                        Rectangle {
                                            Behavior on scale {
                                                NumberAnimation {
                                                    duration: 200
                                                    easing.type: Easing.InOutSine
                                                }
                                            }

                                            x: (parent.width - width) / 2
                                            y: (parent.height - height) / 2
                                            width: 6 / 0.9
                                            height: width
                                            radius: Math.min(width, height)
                                            color: Colors.fg1
                                            scale: term.checked ? 1 : 0
                                        }
                                    }
                                    Item {
                                        Layout.preferredWidth: 2
                                        Layout.preferredHeight: 1
                                        visible: term.hasCheckBox
                                    }
                                    Image {
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.preferredWidth: 16 / 0.9
                                        Layout.preferredHeight: width
                                        sourceSize {
                                            width: 32
                                            height: 32
                                        }
                                        source: {
                                            if (!term.hasIcon) {
                                                return "";
                                            }

                                            const icon = term.modelData.icon;
                                            if (icon === "image://icon/input-keyboard" || icon === "input-keyboard") {
                                                return "/usr/share/icons/Papirus-Dark/16x16/devices/input-keyboard.svg";
                                            }
                                            // Paths and URLs load directly; failures are caught by status.
                                            if (icon.startsWith("image://") || icon.startsWith("file://") || icon.includes("/"))
                                                return icon;
                                            // Bare names: the check overload returns "" when the icon is
                                            // not in the theme, so garbage never reaches the provider.
                                            return Quickshell.iconPath(icon, true);
                                        }
                                        // Only show when the source has actually loaded successfully.
                                        visible: term.hasIcon && status === Image.Ready
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignVCenter
                                        font {
                                            family: Colors.font
                                            pixelSize: 14 / 0.9
                                        }
                                        color: Colors.fg1
                                        text: term.hasText ? term.modelData.text : ""
                                        visible: term.hasText
                                    }
                                }

                                MouseArea {
                                    id: termMA

                                    anchors.fill: parent
                                    hoverEnabled: true

                                    onClicked: {
                                        if ((!term.hasIcon) && (!term.hasText)) {
                                            return;
                                        }

                                        if (term.modelData.hasChildren) {
                                            pageStack.push(pageComponet, {
                                                menuObject: term.modelData,
                                                depth: pageStack.depth + 1,
                                                title: term.modelData.text
                                            });
                                        } else {
                                            term.modelData.triggered();
                                            if (!term.hasCheckBox) {
                                                menuRect.curItem = null;
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width / 0.9
                                    height: 2 / 0.9
                                    radius: Math.min(width, height) / 2
                                    color: Colors.fg1
                                    visible: (!term.hasIcon) && (!term.hasText)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Repeater {
        model: SystemTray.items
        clip: true

        delegate: Rectangle {
            id: trayIcon

            required property var modelData
            required property int index

            property real targetX: 47 + 7 + index * (37 + 7)

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
            width: 44
            height: width
            x: systemTray.expand ? targetX : 20
            opacity: systemTray.expand ? 1 : 0
            scale: systemTray.expand ? 1 : 0
            color: "transparent"
            enabled: systemTray.expand

            Image {
                id: trayImg

                readonly property real desY: (parent.height - height) / 2
                property bool aniPlayed: false
                property int aniStage: 0

                onSourceChanged: {
                    if (aniPlayed) {
                        aniPlayed = false;
                        return;
                    }

                    trayImg.aniStage = 1;
                    trayImgAniTimer.interval = 0;
                    trayImgAniTimer.restart();
                }

                Behavior on y {
                    SpringAnimation {
                        spring: 4
                        damping: 0.2
                    }
                }

                Timer {
                    id: trayImgAniTimer

                    onTriggered: {
                        switch (trayImg.aniStage) {
                        case 0:
                            trayImg.y = trayImg.desY;
                            trayImgAniTimer.interval = 0;
                            break;
                        case 1:
                            trayImg.y = trayImg.desY - 10;
                            trayImg.aniStage = 2;
                            trayImgAniTimer.interval = 100;
                            trayImgAniTimer.restart();
                            break;
                        case 2:
                            trayImg.y = trayImg.desY + 10;
                            trayImg.aniStage = 0;
                            trayImgAniTimer.restart();
                            break;
                        }
                    }
                }

                anchors.horizontalCenter: parent.horizontalCenter
                y: desY
                width: 23
                height: 23
                sourceSize {
                    width: 32
                    height: 32
                }
                source: {
                    const icon = trayIcon.modelData.icon;
                    if (icon === "image://icon/input-keyboard-symbolic" || icon === "input-keyboard-symbolic") {
                        return "/usr/share/icons/Papirus-Dark/16x16/devices/input-keyboard.svg";
                    }
                    // Paths and URLs load directly; failures are caught by status.
                    if (icon.startsWith("image://") || icon.startsWith("file://") || icon.includes("/"))
                        return icon;
                    // Bare names: the check overload returns "" when the icon is
                    // not in the theme, so garbage never reaches the provider.
                    return Quickshell.iconPath(icon, true);
                }
                // Only show when the source has actually loaded successfully.
                visible: status === Image.Ready
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: mouse => {
                    switch (mouse.button) {
                    case Qt.LeftButton:
                        if (!trayIcon.modelData.onlyMenu) {
                            trayIcon.modelData.activate();
                        }
                        break;
                    case Qt.RightButton:
                        if (trayIcon.modelData.hasMenu) {
                            if (systemTray.showMenu && trayIcon.modelData === menuRect.curItem) {
                                menuRect.curItem = null;
                            } else {
                                menuRect.curItem = trayIcon.modelData;
                                menuRect.curItemCenter = trayIcon.targetX + trayIcon.width / 2;
                            }
                        }
                        break;
                    }
                    trayImg.aniStage = 1;
                    trayImgAniTimer.interval = 0;
                    trayImgAniTimer.restart();
                    trayImg.aniPlayed = true;
                }
            }
        }
    }
}
