pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../"
import "../"

Item {
    id: launcherRoot

    property bool launcherVisible: applauncher.visible
    property string time: ""
    property real bandOffset: 0

    function funcInTimer(offsetInterval) {
        bandOffset += offsetInterval;
        bandOffset %= 1 + Screen.width / Screen.height;
    }

    PanelWindow {
        id: applauncher

        property var searchedList: []

        function toggle() {
            visible = !visible;
        }

        onVisibleChanged: {
            if (visible) {
                AppList.rebuild();
                inputField.text = "";
                appsGrid.currentIndex = 0;
                searchedList = [...AppList.sortedApps];
            }
        }

        anchors {
            top: false
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
        implicitHeight: 2 * Screen.height
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        visible: false

        Item {
            anchors.fill: parent
            z: 0
            layer.enabled: true
            layer.effect: ShaderEffect {
                property real w: Screen.width
                property real h: Screen.height
                property real r: 0
                property real offset: launcherRoot.bandOffset
                property vector4d bg1: Colors.hexToRGBA01(Colors.bg1)
                property vector4d bg2: Colors.hexToRGBA01(Colors.bg2)
                property vector4d bg3: Colors.hexToRGBA01(Colors.bg3)

                fragmentShader: "../../shaders/band-diagonal.frag.qsb"
            }
        }

        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0

            Item {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 100 + (applauncher.height - Screen.height) / 2
            }
            Text {
                Layout.alignment: Qt.AlignCenter
                font {
                    family: Colors.font
                    pixelSize: 48
                }
                color: Colors.fg1
                text: launcherRoot.time
            }
            Item {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 50
            }
            TextField {
                id: inputField

                property bool isTyping: false

                function fuzzyMatch(pattern, text) {
                    pattern = pattern.toLowerCase();
                    text = text.toLowerCase();

                    const arr = new Array(26).fill(0);
                    let shouldMatch = 0;
                    for (let i = 0; i < pattern.length; i++) {
                        const charCode = pattern.charCodeAt(i);
                        if (charCode >= 97 && charCode <= 122) {
                            arr[charCode - 97]++;
                            shouldMatch++;
                        }
                    }

                    let matchCount = 0;
                    for (let i = 0; i < text.length; i++) {
                        const charCode = text.charCodeAt(i);
                        if (charCode >= 97 && charCode <= 122) {
                            const index = charCode - 97;
                            if (arr[index] > 0) {
                                arr[index]--;
                                matchCount++;
                            }
                        }

                        if (matchCount === shouldMatch) {
                            return true;
                        }
                    }

                    return false;
                }

                onTextChanged: {
                    isTyping = true;
                    typingTimer.restart();

                    let tempList = [...AppList.sortedApps];
                    if (text.length > 0) {
                        for (let i = 0; i < tempList.length; i++) {
                            const app = tempList[i];
                            if (fuzzyMatch(text, app.id) || fuzzyMatch(text, app.name)) {
                                continue;
                            }

                            tempList.splice(i, 1);
                            i--;
                        }
                    }
                    applauncher.searchedList = tempList;
                }

                Timer {
                    id: typingTimer

                    interval: 1000

                    onTriggered: {
                        inputField.isTyping = false;
                    }
                }

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 300
                Layout.preferredHeight: 40
                font {
                    family: Colors.font
                    pixelSize: 24
                }
                focus: true
                color: Colors.fg1
                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.y + parent.height + 5
                        width: parent.width
                        height: 5
                        radius: Math.min(width, height) / 2
                        color: Colors.fg3
                    }
                }
                cursorDelegate: Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 15
                    radius: Math.min(4, height) / 2
                    color: Colors.fg4

                    SequentialAnimation on height {
                        loops: Animation.Infinite
                        running: !inputField.isTyping
                        NumberAnimation {
                            to: 0
                            duration: 200
                            easing: Easing.InOutSine
                        }
                        NumberAnimation {
                            to: 0
                            duration: 200
                        }
                        NumberAnimation {
                            to: inputField.height - 10
                            duration: 200
                            easing: Easing.InOutSine
                        }
                        NumberAnimation {
                            to: inputField.height - 10
                            duration: 400
                        }
                    }

                    onHeightChanged: {
                        if (inputField.isTyping) {
                            height = inputField.height - 10;
                        }
                    }
                }

                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Escape:
                        applauncher.visible = false;
                        event.accepted = true;
                        break;
                    case Qt.Key_Return:
                        appsGrid.launchCurApp();
                        event.accepted = true;
                        break;
                    case Qt.Key_Left:
                        appsGrid.leftSel();
                        event.accepted = true;
                        break;
                    case Qt.Key_Right:
                        appsGrid.rightSel();
                        event.accepted = true;
                        break;
                    case Qt.Key_Up:
                        appsGrid.upSel();
                        event.accepted = true;
                        break;
                    case Qt.Key_Down:
                        appsGrid.downSel();
                        event.accepted = true;
                        break;
                    }
                }
            }
            Item {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 100
            }
            Rectangle {
                id: appsRect

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: Screen.width - 300
                Layout.preferredHeight: 4 * appsGrid.cellHeight
                color: "transparent"

                GridView {
                    id: appsGrid

                    function launchCurApp() {
                        AppList.launch(applauncher.searchedList[currentIndex]);
                        applauncher.visible = false;
                    }
                    function leftSel() {
                        currentIndex = Math.max(0, currentIndex - 1);
                    }
                    function rightSel() {
                        currentIndex = Math.min(applauncher.searchedList.length - 1, currentIndex + 1);
                    }
                    function upSel() {
                        currentIndex = currentIndex - 7 >= 0 ? currentIndex - 7 : currentIndex;
                    }
                    function downSel() {
                        currentIndex = currentIndex + 7 < applauncher.searchedList.length ? currentIndex + 7 : currentIndex;
                    }

                    model: applauncher.searchedList
                    snapMode: GridView.SnapToRow
                    anchors.fill: parent
                    cellWidth: width / 7
                    cellHeight: 0.8 * cellWidth
                    clip: true
                    highlight: Rectangle {
                        Behavior on x {
                            SpringAnimation {
                                spring: 6.5
                                damping: 0.35
                            }
                        }
                        Behavior on y {
                            SpringAnimation {
                                spring: 6.5
                                damping: 0.35
                            }
                        }

                        width: 200
                        height: width
                        radius: Math.min(width / 2, 40)
                        x: appsGrid.currentItem.x + (appsGrid.currentItem.width - width) / 2
                        y: appsGrid.currentItem.y + (appsGrid.currentItem.height - height) / 2
                        color: Colors.fg3
                    }
                    highlightFollowsCurrentItem: false

                    delegate: Item {
                        id: app

                        required property var modelData
                        required property int index

                        width: appsGrid.cellWidth
                        height: appsGrid.cellHeight

                        ColumnLayout {
                            anchors.centerIn: parent

                            Image {
                                Layout.alignment: Qt.AlignCenter
                                Layout.preferredWidth: 72
                                Layout.preferredHeight: 72
                                sourceSize {
                                    width: 128
                                    height: 128
                                }
                                source: {
                                    const iconPath = app.modelData.icon;
                                    if (iconPath.startsWith("image://")) {
                                        return iconPath;
                                    }
                                    return Quickshell.iconPath(iconPath);
                                }
                            }
                            Item {
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: 20
                            }
                            Rectangle {
                                Layout.alignment: Qt.AlignCenter
                                Layout.preferredWidth: Math.min(appNameText.width, appNameText.contentWidth) + 20
                                Layout.preferredHeight: appNameText.height + 10
                                radius: Math.min(Math.min(width, height) / 2, 10)
                                color: Colors.fg3

                                Text {
                                    id: appNameText

                                    anchors.centerIn: parent
                                    width: 120
                                    font {
                                        family: Colors.font
                                        pixelSize: 18
                                    }
                                    color: Colors.fg1
                                    text: app.modelData.name
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                }
                            }
                        }
                        TapHandler {
                            onTapped: {
                                appsGrid.currentIndex = app.index;
                                AppList.launch(app.modelData);
                                applauncher.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }

    GlobalShortcut {
        name: "toggle-applauncher"

        onPressed: {
            applauncher.toggle();
        }
    }
}
