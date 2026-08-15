import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import "./widgets" as Widgets
import "../"

Item {
    id: barRoot

    property var shell
    required property var notifModule

    property var expandWidgetStack: []
    // data property
    property string time: shell.time
    property string dayofweek: shell.dayofweek
    property string date: shell.date
    property int memTotalKB: shell.memTotalKB
    property int memUsedKB: shell.memUsedKB
    property real cpuUsagePercent: shell.cpuUsagePercent
    property real cpuAvgFreqGHz: shell.cpuAvgFreqGHz
    property real cpuTemp: shell.cpuTemp
    property real gpuTemp: shell.gpuTemp
    property real downloadSpeedBps: shell.downloadSpeedBps
    property real uploadSpeedBps: shell.uploadSpeedBps
    property bool hasBattery: shell.hasBattery
    property int acOnline: shell.acOnline
    property int batteryCapacity: shell.batteryCapacity

    function funcInTimer() {
        systemStats.funcInTimer(8e-3);
        hyprWorkspace.funcInTimer(8e-3, 0.35);
        clock.funcInTimer(8e-3);
        systemTray.funcInTimer(8e-3, 8e-3, 0.35);
        bluetooth.funcInTimer(8e-3);
        networking.funcInTimer(8e-3);
        volume.funcInTimer(8e-3);
        brightness.funcInTimer(8e-3);
        notificationButton.funcInTimer(8e-3, 0.35);
    }
    function dynamicHeight() {
        let max = Math.max(0, systemStats.expandBarHeight);
        max = Math.max(max, clock.expandBarHeight);
        max = Math.max(max, systemTray.expandBarHeight);
        max = Math.max(max, bluetooth.expandBarHeight);
        max = Math.max(max, networking.expandBarHeight);
        return Math.max(64, max) + 20;
    }

    Connections {
        target: BarWidgetsExpandStats

        function onLoadSuccessChanged() {
            if (BarWidgetsExpandStats.loadSuccess) {
                systemStats.expand = BarWidgetsExpandStats.getStat("systemStats");
                clock.expand = BarWidgetsExpandStats.getStat("clock");
                systemTray.expand = BarWidgetsExpandStats.getStat("systemTray");
                bluetooth.setExpand(BarWidgetsExpandStats.getStat("bluetooth"));
                networking.setExpand(BarWidgetsExpandStats.getStat("networking"));
                volume.expand = BarWidgetsExpandStats.getStat("volume");
                brightness.expand = BarWidgetsExpandStats.getStat("brightness");
            }
        }
    }
    Connections {
        target: systemStats

        function onExpandChanged() {
            BarWidgetsExpandStats.updateStat("systemStats", systemStats.expand);
            if (systemStats.expand) {
                leftWidgetsRow.expandedCount++;
                barRoot.expandWidgetStack.push(systemStats);
            } else {
                leftWidgetsRow.expandedCount--;
                barRoot.expandWidgetStack = barRoot.expandWidgetStack.filter(item => item !== systemStats);
                systemStats.focus = false;
            }
            let len = barRoot.expandWidgetStack.length;
            if (len > 0) {
                barRoot.expandWidgetStack[len - 1].focus = true;
            }
        }
        function onExpandBarHeightChanged() {
            if (systemStats.expandBarHeight > 0) {
                placeHolder.implicitHeight = barRoot.dynamicHeight();
            }
        }
    }
    Binding {
        target: placeHolder
        property: "implicitHeight"
        value: systemTray.expandBarHeight > 0 ? barRoot.dynamicHeight() : 0
        delayed: true
    }
    Connections {
        target: systemTray

        function onExpandChanged() {
            BarWidgetsExpandStats.updateStat("systemTray", systemTray.expand);
            if (systemTray.expand) {
                leftWidgetsRow.expandedCount++;
                barRoot.expandWidgetStack.push(systemTray);
            } else {
                leftWidgetsRow.expandedCount--;
                barRoot.expandWidgetStack = barRoot.expandWidgetStack.filter(item => item !== systemTray);
                systemTray.focus = false;
            }
            let len = barRoot.expandWidgetStack.length;
            if (len > 0) {
                barRoot.expandWidgetStack[len - 1].focus = true;
            }
        }
    }
    Connections {
        target: clock

        function onExpandChanged() {
            BarWidgetsExpandStats.updateStat("clock", clock.expand);
            if (clock.expand) {
                midWidgetsRow.expandedCount++;
                barRoot.expandWidgetStack.push(clock);
            } else {
                midWidgetsRow.expandedCount--;
                barRoot.expandWidgetStack = barRoot.expandWidgetStack.filter(item => item !== clock);
                clock.focus = false;
            }
            let len = barRoot.expandWidgetStack.length;
            if (len > 0) {
                barRoot.expandWidgetStack[len - 1].focus = true;
            }
        }
        function onExpandBarHeightChanged() {
            if (clock.expandBarHeight > 0) {
                placeHolder.implicitHeight = barRoot.dynamicHeight();
            }
        }
    }
    Binding {
        target: placeHolder
        property: "implicitHeight"
        value: bluetooth.expandBarHeight > 0 ? barRoot.dynamicHeight() : 0
        delayed: true
    }
    Connections {
        target: bluetooth

        function onExpandChanged() {
            BarWidgetsExpandStats.updateStat("bluetooth", bluetooth.expand);
            if (bluetooth.expand) {
                rightWidgetsRow.expandedCount++;
                barRoot.expandWidgetStack.push(bluetooth);
            } else {
                rightWidgetsRow.expandedCount--;
                barRoot.expandWidgetStack = barRoot.expandWidgetStack.filter(item => item !== bluetooth);
                bluetooth.focus = false;
            }
            let len = barRoot.expandWidgetStack.length;
            if (len > 0) {
                barRoot.expandWidgetStack[len - 1].focus = true;
            }
        }
    }
    Binding {
        target: placeHolder
        property: "implicitHeight"
        value: networking.expandBarHeight > 0 ? barRoot.dynamicHeight() : 0
        delayed: true
    }
    Connections {
        target: networking

        function onExpandChanged() {
            BarWidgetsExpandStats.updateStat("networking", networking.expand);
            if (networking.expand) {
                rightWidgetsRow.expandedCount++;
                barRoot.expandWidgetStack.push(networking);
            } else {
                rightWidgetsRow.expandedCount--;
                barRoot.expandWidgetStack = barRoot.expandWidgetStack.filter(item => item !== networking);
                networking.focus = false;
            }
            let len = barRoot.expandWidgetStack.length;
            if (len > 0) {
                barRoot.expandWidgetStack[len - 1].focus = true;
            }
        }
    }
    Connections {
        target: volume

        function onExpandChanged() {
            BarWidgetsExpandStats.updateStat("volume", volume.expand);
            if (volume.expand) {
                rightWidgetsRow.expandedCount++;
                barRoot.expandWidgetStack.push(volume);
            } else {
                rightWidgetsRow.expandedCount--;
                barRoot.expandWidgetStack = barRoot.expandWidgetStack.filter(item => item !== volume);
                volume.focus = false;
            }
            let len = barRoot.expandWidgetStack.length;
            if (len > 0) {
                barRoot.expandWidgetStack[len - 1].focus = true;
            }
        }
    }
    Connections {
        target: brightness

        function onExpandChanged() {
            BarWidgetsExpandStats.updateStat("brightness", brightness.expand);
            if (brightness.expand) {
                rightWidgetsRow.expandedCount++;
                barRoot.expandWidgetStack.push(brightness);
            } else {
                rightWidgetsRow.expandedCount--;
                barRoot.expandWidgetStack = barRoot.expandWidgetStack.filter(item => item !== brightness);
                brightness.focus = false;
            }
            let len = barRoot.expandWidgetStack.length;
            if (len > 0) {
                barRoot.expandWidgetStack[len - 1].focus = true;
            }
        }
    }

    PanelWindow {
        id: bar

        Component.onCompleted: {
            AppList;
            BarWidgetsExpandStats;
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        margins {
            top: 20
            bottom: 0
            left: 0
            right: 0
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: false
        focusable: true

        RowLayout {
            id: leftWidgetsRow

            readonly property int maxExpandCount: 1
            property int expandedCount: 0

            x: 50
            spacing: 25
            Widgets.SystemStats {
                id: systemStats

                barRoot: barRoot
                canExpand: leftWidgetsRow.expandedCount < leftWidgetsRow.maxExpandCount
                Layout.alignment: Qt.AlignTop
            }
            Widgets.SystemTray {
                id: systemTray

                bar: bar
                canExpand: leftWidgetsRow.expandedCount < leftWidgetsRow.maxExpandCount
                Layout.alignment: Qt.AlignTop
            }
            Widgets.HyprWorkspace {
                id: hyprWorkspace

                Layout.alignment: Qt.AlignTop
            }
        }
        RowLayout {
            id: midWidgetsRow

            readonly property int maxExpandCount: 1
            property int expandedCount: 0

            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 25

            Widgets.Clock {
                id: clock

                barRoot: barRoot
                canExpand: midWidgetsRow.expandedCount < midWidgetsRow.maxExpandCount
                Layout.alignment: Qt.AlignTop
            }
            Widgets.NotificationButton {
                id: notificationButton

                notifModule: barRoot.notifModule
                Layout.alignment: Qt.AlignTop
            }
        }
        RowLayout {
            id: rightWidgetsRow

            readonly property int maxExpandCount: 2
            property int expandedCount: 0

            x: bar.width - 50 - width
            spacing: 25

            Loader {
                id: bluetooth

                readonly property bool expand: item !== null ? item.expand : false
                readonly property real expandBarHeight: item !== null ? item.expandBarHeight : 64

                function funcInTimer(val) {
                    if (bluetooth.item !== null) {
                        bluetooth.item.funcInTimer(val);
                    }
                }
                function setExpand(val) {
                    if (item !== null) {
                        item.expand = val;
                    }
                }

                Connections {
                    target: rightWidgetsRow

                    function onExpandedCountChanged() {
                        if (bluetooth.item !== null) {
                            bluetooth.item.canExpand = rightWidgetsRow.expandedCount < rightWidgetsRow.maxExpandCount;
                        }
                    }
                }
                onLoaded: {
                    if (bluetooth.item !== null) {
                        bluetooth.item.canExpand = rightWidgetsRow.expandedCount < rightWidgetsRow.maxExpandCount;
                    }
                }
                onFocusChanged: {
                    if (bluetooth.item !== null) {
                        bluetooth.item.focus = focus;
                    }
                }

                Component {
                    id: bluetoothCmp

                    Widgets.Bluetooth {}
                }

                Layout.alignment: Qt.AlignTop
                sourceComponent: Bluetooth.defaultAdapter ? bluetoothCmp : null
            }
            Loader {
                id: networking

                readonly property bool expand: item !== null ? item.expand : false
                readonly property real expandBarHeight: item !== null ? item.expandBarHeight : 64

                function funcInTimer(val) {
                    if (networking.item !== null) {
                        networking.item.funcInTimer(val);
                    }
                }
                function setExpand(val) {
                    if (item !== null) {
                        item.expand = val;
                    }
                }

                Connections {
                    target: rightWidgetsRow

                    function onExpandedCountChanged() {
                        if (networking.item !== null) {
                            networking.item.canExpand = rightWidgetsRow.expandedCount < rightWidgetsRow.maxExpandCount;
                        }
                    }
                }
                onLoaded: {
                    if (networking.item !== null) {
                        networking.item.canExpand = rightWidgetsRow.expandedCount < rightWidgetsRow.maxExpandCount;
                    }
                }
                onFocusChanged: {
                    if (networking.item !== null) {
                        networking.item.setFocus(focus);
                    }
                }

                Component {
                    id: networkingCmp

                    Widgets.Networking {}
                }

                Layout.alignment: Qt.AlignTop
                sourceComponent: {
                    if (Networking.devices.values.find(device => device.type === DeviceType.Wifi) !== undefined) {
                        return networkingCmp;
                    }
                    return null;
                }
            }
            Widgets.Volume {
                id: volume

                canExpand: rightWidgetsRow.expandedCount < rightWidgetsRow.maxExpandCount
                Layout.alignment: Qt.AlignTop
            }
            Widgets.Brightness {
                id: brightness

                canExpand: rightWidgetsRow.expandedCount < rightWidgetsRow.maxExpandCount
                Layout.alignment: Qt.AlignTop
            }
        }
    }

    PanelWindow {
        id: placeHolder

        anchors {
            top: true
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
        color: "transparent"
        aboveWindows: false
        implicitHeight: 84
    }
}
