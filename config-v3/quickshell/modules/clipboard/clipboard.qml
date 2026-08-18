pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../"

Item {
    id: clipRoot

    property bool clipboardVisible: clipboardPanel.visible
    property bool parseError: false
    property var historyList: []
    property var searchedList: []
    property real bandOffset: 0

    function funcInTimer(offsetInterval) {
        bandOffset += offsetInterval;
        bandOffset %= 1 + clipCard.width / clipCard.height;
    }

    function toggle() {
        clipboardPanel.visible = !clipboardPanel.visible;
    }

    function refresh() {
        clipInfoProc.running = true;
    }

    // ---- 过滤（复用 applauncher fuzzyMatch 逻辑，见下）----
    function applyFilter() {
        const q = searchField.text.trim().toLowerCase();
        if (q.length === 0) {
            searchedList = [...historyList];
        } else {
            const out = [];
            for (const it of historyList) {
                if (fuzzyMatch(q, it.preview) || fuzzyMatch(q, it.content) || fuzzyMatch(q, it.type)) {
                    out.push(it);
                }
            }
            searchedList = out;
        }
        if (clipListView.currentIndex > searchedList.length - 1) {
            clipListView.currentIndex = Math.max(0, searchedList.length - 1);
        }
    }

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

    // ---- shell 安全工具 ----
    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    // ---- 复制 ----
    function copyItem(item) {
        const id = String(item.id ?? "");
        const preview = String(item.preview ?? "");

        if (item.type === "text") {
            // 文本：使用完整行解码，阻塞执行
            actionProc.command = ["sh", "-c", `printf '%s\\t%s' ${shellQuote(id)} ${shellQuote(preview)} | cliphist decode | wl-copy`];
        } else if (item.type === "image") {
            // 图片：解析阶段已经统一转换成真正的 PNG
            // wl-copy 明确声明为 image/png
            actionProc.command = ["sh", "-c", `wl-copy --type image/png < ${shellQuote(item.content)}`];
        } else if (item.type === "file") {
            const uri = "file://" + item.content.split("/").map(encodeURIComponent).join("/");

            // 文件：阻塞执行，确保 \r\n 结尾
            actionProc.command = ["sh", "-c", `printf '%s\\r\\n' ${shellQuote(uri)} | wl-copy --type text/uri-list`];
        }

        actionProc.running = true;
    }
    function copyCurrent() {
        const idx = clipListView.currentIndex;

        if (idx < 0 || idx >= searchedList.length)
            return;

        copyItem(searchedList[idx]);
        clipboardPanel.visible = false;
    }
    function copyCurrentKeepOpen() {
        const idx = clipListView.currentIndex;

        if (idx < 0 || idx >= searchedList.length)
            return;

        copyItem(searchedList[idx]);
    }

    // ---- 删除 ----
    function deleteItem(index) {
        if (index < 0 || index >= searchedList.length)
            return;
        const item = searchedList[index];
        const id = String(item.id ?? "");

        deleteProc.command = ["sh", "-c", `echo ${id} | cliphist delete`];
        deleteProc.running = true;

        historyList = historyList.filter(e => String(e.id) !== id);
        searchedList = searchedList.filter(e => String(e.id) !== id);
        if (clipListView.currentIndex > searchedList.length - 1) {
            clipListView.currentIndex = Math.max(0, searchedList.length - 1);
        }
    }
    function deleteAllItems() {
        deleteProc.command = ["sh", "-c", "cliphist wipe && rm -rf -- \"$XDG_RUNTIME_DIR/quickshell/clipboard\"/*"];
        deleteProc.running = true;

        historyList = [];
        searchedList = [];

        clipListView.currentIndex = -1;
    }

    // ---- 数据拉取 ----
    Process {
        id: clipInfoProc

        command: ["/home/kiki/.config/quickshell/exec-sh/cliphist-info.sh"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim();
                if (!trimmed)
                    return;

                try {
                    const data = JSON.parse(trimmed);
                    if (Array.isArray(data)) {
                        clipRoot.historyList = data;
                        clipRoot.parseError = false;
                        clipRoot.applyFilter();
                    }
                } catch (e) {
                    console.error("cliphist-info.sh JSON parse error:", e);
                    console.error("raw output:", trimmed);
                    clipRoot.parseError = true;
                }
            }
        }
    }
    Process {
        id: actionProc
        command: []
        running: false
    }
    Process {
        id: deleteProc
        command: []
        running: false
    }

    // ---- 覆盖层 ----
    PanelWindow {
        id: clipboardPanel

        visible: false
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
        aboveWindows: true
        focusable: true
        WlrLayershell.namespace: "quickshell-clipboard"

        onVisibleChanged: {
            if (!visible) {
                return;
            }
            clipRoot.refresh();
            searchField.text = "";
            clipRoot.searchedList = [...clipRoot.historyList];
            clipListView.currentIndex = 0;
            searchField.forceActiveFocus();
        }

        Rectangle {
            id: clipCard

            Behavior on scale {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.InOutSine
                }
            }
            Behavior on opacity {
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

            anchors.centerIn: parent
            width: Math.min(clipboardPanel.width - 40, clipColumn.width + 50)
            height: Math.min(clipboardPanel.height - 100, clipColumn.height + 50)
            color: "transparent"
            scale: clipboardPanel.visible ? 1 : 0
            opacity: clipboardPanel.visible ? 1 : 0
            clip: true

            Item {
                anchors.fill: parent
                z: 0
                layer.enabled: true
                layer.effect: ShaderEffect {
                    property real w: clipCard.width
                    property real h: clipCard.height
                    property real r: 32
                    property real offset: clipRoot.bandOffset
                    property vector4d bg1: Colors.hexToRGBA01(Colors.bg1)
                    property vector4d bg2: Colors.hexToRGBA01(Colors.bg2)
                    property vector4d bg3: Colors.hexToRGBA01(Colors.bg3)

                    fragmentShader: "../../shaders/band-diagonal.frag.qsb"
                }
            }

            ColumnLayout {
                id: clipColumn

                anchors.centerIn: parent
                width: 600
                spacing: 20

                // --- Header ---
                RowLayout {
                    Layout.preferredWidth: clipColumn.width
                    spacing: 16

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        font {
                            family: Colors.font
                            pixelSize: 24
                        }
                        color: Colors.fg1
                        text: "剪切板"
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        color: Colors.fg3
                        radius: Math.min(width, height) / 2

                        Text {
                            x: 16
                            y: (parent.height - implicitHeight) / 2
                            font {
                                family: Colors.font
                                pixelSize: 16
                            }
                            color: Colors.fg1
                            text: ""
                        }

                        TextField {
                            id: searchField

                            property bool isTyping: false

                            onTextChanged: {
                                isTyping = true;
                                typingTimer.restart();
                                clipRoot.applyFilter();
                            }

                            Timer {
                                id: typingTimer
                                interval: 1000
                                onTriggered: {
                                    searchField.isTyping = false;
                                }
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Return && (event.modifiers & Qt.ShiftModifier)) {
                                    clipRoot.copyCurrentKeepOpen();
                                    event.accepted = true;
                                    return;
                                }
                                switch (event.key) {
                                case Qt.Key_Escape:
                                    clipboardPanel.visible = false;
                                    event.accepted = true;
                                    break;
                                case Qt.Key_Return:
                                    clipRoot.copyCurrent();
                                    event.accepted = true;
                                    break;
                                case Qt.Key_Up:
                                    clipListView.decrementCurrentIndex();
                                    clipListView.positionViewAtIndex(clipListView.currentIndex, ListView.Contain);
                                    event.accepted = true;
                                    break;
                                case Qt.Key_Down:
                                    clipListView.incrementCurrentIndex();
                                    clipListView.positionViewAtIndex(clipListView.currentIndex, ListView.Contain);
                                    event.accepted = true;
                                    break;
                                case Qt.Key_Delete:
                                    clipRoot.deleteItem(clipListView.currentIndex);
                                    event.accepted = true;
                                    break;
                                }
                            }

                            x: 40
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 64
                            height: parent.height
                            font {
                                family: Colors.font
                                pixelSize: 16
                            }
                            focus: true
                            color: Colors.fg1
                            background: Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                            }
                            cursorDelegate: Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 8
                                radius: Math.min(2, height) / 2
                                color: Colors.fg4

                                SequentialAnimation on height {
                                    loops: Animation.Infinite
                                    running: !searchField.isTyping
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
                                        to: searchField.height - 20
                                        duration: 200
                                        easing: Easing.InOutSine
                                    }
                                    NumberAnimation {
                                        to: searchField.height - 20
                                        duration: 400
                                    }
                                }

                                onHeightChanged: {
                                    if (searchField.isTyping) {
                                        height = searchField.height - 20;
                                    }
                                }
                            }
                        }
                    }
                    // Clear all button
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 18
                        color: Colors.fg3
                        visible: clipRoot.historyList.length > 0

                        Text {
                            x: (parent.width - implicitWidth) / 2
                            y: (parent.height - implicitHeight) / 2
                            font {
                                family: Colors.font
                                pixelSize: 16
                            }
                            color: Colors.err
                            text: ""
                        }

                        TapHandler {
                            onTapped: {
                                clipRoot.deleteAllItems();
                            }
                        }
                    }
                    // Close button
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: Math.min(width, height) / 2
                        color: Colors.fg3

                        Text {
                            x: (parent.width - implicitWidth) / 2
                            y: (parent.height - implicitHeight) / 2
                            font {
                                family: Colors.font
                                pixelSize: 18
                            }
                            color: Colors.fg1
                            text: ""
                        }

                        TapHandler {
                            onTapped: {
                                clipboardPanel.visible = false;
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.preferredWidth: clipColumn.width
                    Layout.preferredHeight: 3
                    radius: Math.min(width, height) / 2
                    color: Colors.fg3
                }

                ListView {
                    id: clipListView

                    property real listItemHeight: 70

                    Layout.preferredWidth: clipColumn.width
                    Layout.preferredHeight: Math.min(count * (listItemHeight + spacing), 10 * (listItemHeight + spacing)) - spacing
                    spacing: 16
                    snapMode: ListView.SnapToItem
                    clip: true
                    visible: clipRoot.searchedList.length > 0
                    model: clipRoot.searchedList
                    highlightFollowsCurrentItem: false
                    highlight: Rectangle {
                        Behavior on y {
                            SpringAnimation {
                                spring: 4
                                damping: 0.2
                            }
                        }

                        width: clipListView.width
                        height: clipListView.listItemHeight
                        radius: 20
                        y: clipListView.currentItem ? clipListView.currentItem.y : 0
                        color: Colors.fg3
                    }

                    delegate: Rectangle {
                        id: clipItem

                        required property var modelData
                        required property int index

                        width: clipListView.width
                        height: clipListView.listItemHeight
                        color: "transparent"

                        RowLayout {
                            anchors.centerIn: parent
                            width: parent.width - 36
                            height: parent.height
                            spacing: 16
                            clip: true

                            Text {
                                Layout.preferredWidth: 40
                                Layout.alignment: Qt.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                font {
                                    family: Colors.font
                                    pixelSize: 24
                                }
                                color: Colors.fg5
                                text: "󰈔"
                                visible: clipItem.modelData.type === "file"
                            }

                            ColumnLayout {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    Layout.fillWidth: true
                                    font {
                                        family: Colors.font
                                        pixelSize: 16
                                    }
                                    color: Colors.fg1
                                    text: clipItem.modelData.type === "text" ? clipItem.modelData.preview : clipItem.modelData.content.split("/").pop()
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                                Text {
                                    Layout.fillWidth: true
                                    font {
                                        family: Colors.font
                                        pixelSize: 12
                                    }
                                    color: Colors.fg5
                                    text: clipItem.modelData.type === "text" ? clipItem.modelData.content.split("\n")[0] : clipItem.modelData.content
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    visible: (text ?? "") !== ""
                                }
                            }

                            Image {
                                Layout.alignment: Qt.AlignVCenter
                                // Guard against 0x0 sourceSize from failed loads producing NaN widths
                                Layout.preferredWidth: sourceSize.width > 0 && sourceSize.height > 0
                                    ? Math.min(90, sourceSize.width * 55 / sourceSize.height)
                                    : 0
                                Layout.preferredHeight: 55
                                asynchronous: true
                                // Only show when the source has actually loaded successfully.
                                visible: clipItem.modelData.type === "image" && status === Image.Ready
                                source: {
                                    const src = clipItem.modelData.content.split("\n")[0];
                                    // Paths and URLs load directly; failures are caught by status.
                                    if (src.startsWith("image://") || src.startsWith("file://") || src.includes("/"))
                                        return src;
                                    // Bare names: the check overload returns "" when the icon is
                                    // not in the theme, so garbage never reaches the provider.
                                    return Quickshell.iconPath(src, true);
                                }
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: typeLabel.width + 18
                                Layout.preferredHeight: 32
                                radius: Math.min(width, height) / 2
                                color: Colors.bg4

                                Text {
                                    id: typeLabel
                                    anchors.centerIn: parent
                                    font {
                                        family: Colors.font
                                        pixelSize: 12
                                    }
                                    color: Colors.fg4
                                    text: clipItem.modelData.type === "text" ? "文本" : clipItem.modelData.type === "image" ? "图片" : "文件"
                                }
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                radius: Math.min(width, height) / 2
                                color: Colors.bg4

                                Text {
                                    x: (parent.width - implicitWidth) / 2
                                    y: (parent.height - implicitHeight) / 2
                                    font {
                                        family: Colors.font
                                        pixelSize: 16
                                    }
                                    color: Colors.err
                                    text: ""
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        clipRoot.deleteItem(clipItem.index);
                                    }
                                }
                            }
                        }

                        TapHandler {
                            onTapped: {
                                clipListView.currentIndex = clipItem.index;
                                clipRoot.copyCurrent();
                            }
                        }
                    }
                }

                // 空状态 / 错误兜底
                Text {
                    font {
                        family: Colors.font
                        pixelSize: 18
                    }
                    color: Colors.fg5
                    text: "剪切板历史为空"
                    visible: clipRoot.historyList.length === 0 && !clipRoot.parseError
                }
                Text {
                    font {
                        family: Colors.font
                        pixelSize: 18
                    }
                    color: Colors.fg5
                    text: "无匹配结果"
                    visible: clipRoot.historyList.length > 0 && clipRoot.searchedList.length === 0
                }
                Text {
                    font {
                        family: Colors.font
                        pixelSize: 18
                    }
                    color: Colors.err
                    text: "数据加载失败，请查看日志"
                    visible: clipRoot.parseError
                }
            }
        }
    }

    // ---- 全局快捷键 ----
    GlobalShortcut {
        name: "toggle-clipboard"

        onPressed: {
            clipRoot.toggle();
        }
    }
}
