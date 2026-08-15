# Quickshell 剪切板历史前端（已实现）

> 本文档描述**当前已落地**的剪切板历史选择器（Clipboard Picker）实现现状。代码是唯一事实来源；如与本文档冲突，以 `modules/clipboard/clipboard.qml`、`exec-sh/cliphist-info.sh` 等实际代码为准。

## 1. 概述与现状

`~/.config/quickshell` 项目已实现一个**剪切板历史选择器**，与 AppLauncher、通知中心并列的覆盖层模块。用户按下 `SUPER + V` 后，全屏覆盖层弹出：顶部是标题、搜索框、清空全部按钮、关闭按钮，下方是剪切板历史列表（文本 / 图片 / 文件三类条目混排）。已实现功能：

- 搜索过滤（模块内自带 `fuzzyMatch`，与 AppLauncher 同源逻辑）
- 键盘导航：上下选择、`Enter` 复制并关闭、`Shift+Enter` 复制不关闭、`Esc` 关闭、`Delete` 删除
- 鼠标导航：点击条目复制并关闭、行内删除按钮
- 图片缩略图预览（脚本已把任意格式统一转成 PNG 缓存）、文件路径展示
- 类型标签（文本 / 图片 / 文件）与「清空全部」（`cliphist wipe` + 清缓存目录）
- 通过 `cliphist delete <id>` 删除历史条目，删除后本地即时移除，不打断视图
- 与现有主题（`Colors` 单例）、动画、`band-diagonal` shader 背景一致

后端数据源为 `exec-sh/cliphist-info.sh`（读取 `cliphist list` 输出 JSON 数组）。前端只负责展示与交互，不新增 shell 脚本——复制 / 删除命令全部在 QML 内以项目既有 `Process` + `sh -c` 范式内联实现。

---

## 2. 后端数据契约与依赖

### 2.1 依赖链关系图

```
wl-paste --type text --watch cliphist store    (hyprland.lua L43, 常驻写入)
wl-paste --type image --watch cliphist store   (hyprland.lua L44, 常驻写入)
        │  每次剪贴板变化自动写入
        ▼
cliphist DB ($XDG_RUNTIME_DIR/cliphist/db，hyprland.lua L75 设 CLIPHIST_DB_PATH)
        │  cliphist list 读取
        ▼
exec-sh/cliphist-info.sh  ──stdout──►  JSON 数组
        │                                   │
        │  Quickshell Process (command=[/home/kiki/.config/quickshell/exec-sh/cliphist-info.sh], running=false)
        │  stdout: StdioCollector { onStreamFinished → JSON.parse (try/catch) }
        ▼
Modules.Clipboard:  historyList[]  ──过滤──►  searchedList[]  ──►  ListView model
        │
        ├── 复制 text  : printf '%s\t%s' <id> <preview> | cliphist decode | wl-copy   （还原原始字节）
        ├── 复制 image : wl-copy --type image/png < <content 路径>                     （读脚本归一化的 PNG 缓存，mime 恒为 image/png）
        ├── 复制 file  : printf '%s\r\n' <uri> | wl-copy --type text/uri-list          （URI 逐段 encodeURIComponent）
        ├── 删除单条   : echo <id> | cliphist delete
        └── 清空全部   : cliphist wipe && rm -rf -- "$XDG_RUNTIME_DIR/quickshell/clipboard"/*
```

### 2.2 JSON 数组契约（cliphist-info.sh 输出）

每个元素固定**五字段**，`id` 为数字（但脚本用字符串输出）：

| 字段 | 类型 | 含义 |
| --- | --- | --- |
| `id` | string(数字) | cliphist 条目 id，用于 `cliphist decode` / `cliphist delete` |
| `type` | `"text"` \| `"image"` \| `"file"` | 条目分类 |
| `mime` | string | 条目的 MIME（image 恒为 `image/png`；text 为 `text/plain`；file 为真实 MIME） |
| `content` | string | text=正文；image=脚本归一化后的 PNG 缓存绝对路径 `${XDG_RUNTIME_DIR}/quickshell/clipboard/<sha256>.png`；file=原始文件绝对路径 |
| `preview` | string | cliphist 原始预览串（text 类型即正文） |

### 2.3 后端脚本分类规则（cliphist-info.sh）

- **`file://` 前缀**：urldecode → trim；文件存在且为图片 → 转 PNG 缓存，`type=image`；文件存在但非图片 → `type=file`（content=原路径，mime=真实 MIME）；**原文件不存在** → 降级为 `type=text`（content=解码后的路径字符串）。
- **绝对路径（`/*`）**：文件存在且为图片 → 转 PNG 缓存，`type=image`；非图片 → `type=file`；**文件不存在** → 不写该分支，保持默认 `type=text`（content=原预览串）。
- **cliphist 二进制图片**（预览含 `binary data` / `[[ binary data`）：`cliphist decode` 到临时文件，检测为图片 → 转 PNG 缓存，`type=image`；解码失败 / 非图片 → 降级 `type=text`。
- 图片归一化：`get_mime`（`file --brief --mime-type`）判断 `image/*`；PNG 直接 `cp`，其它格式用 `magick` 转成 PNG；输出校验 `image/png` 后才接受；文件名用 `sha256sum` 内容哈希，相同图片不重复生成。所有图片类型最终 `mime=image/png`，因此前端复制图片**硬编码 `image/png`**，无需按扩展名推断。

### 2.4 已知坑（前端必须容错）

- 脚本 `escape_json` **未处理 `\b \f` 以及其它控制字符**：极端剪贴板内容可能破坏 JSON。前端解析必须 `try/catch`，失败时 `console.error` 原始输出并展示错误兜底 UI。
- 脚本每次运行都会 `mkdir -p` 缓存目录；二进制图片条目若缓存不存在会调用 `cliphist decode` 写缓存（打开时首次会稍慢，之后秒开）。
- 缓存目录位于 `${XDG_RUNTIME_DIR}/quickshell/clipboard`，**重启后清空**：但脚本每次运行会按需重建，所以只要前端每次打开都重跑脚本，图片 `content` 指向的缓存文件就一定存在。
- 文本条目 `preview` 即正文，但可能含换行 / Tab，直接展示要设置 `elide` 与 `maximumLineCount`，不能当单行字符串假设。
- `cliphist list` 输出 `id<TAB>preview`，脚本 `IFS=$'\t' read -r id preview` 只按第一个 Tab 切分，preview 可含任意字符——这已由脚本处理，前端无需关心。

---

## 3. 架构与文件

遵循 AppLauncher 的「单文件模块」模式：模块根 `Item` 内嵌 `PanelWindow` 覆盖层 + `Process` + `GlobalShortcut`。

### 3.1 新建文件

| 文件 | 职责 |
| --- | --- |
| `modules/clipboard/clipboard.qml` | 模块根（状态、数据 Process、复制/删除命令、过滤、funcInTimer）+ 覆盖层 PanelWindow（搜索框、ListView、delegate、快捷键）。 |
| `docs/clipboard-frontend-plan.md` | 本文档。 |

### 3.2 已修改文件（当前接线现状）

| 文件 | 实际改动点 |
| --- | --- |
| `modules/qmldir` | 末尾追加一行注册：`Clipboard 1.0 clipboard/clipboard.qml`（当前为 L10） |
| `shell.qml` | ① Timer（L234）追加 `clipboard.funcInTimer(4e-3);`；② 模块实例化区（L249-251）追加 `Modules.Clipboard { id: clipboard }` |
| `~/.config/hypr/hyprland.lua` | ① 程序声明区（L23）追加 `local clipboard = "quickshell:toggle-clipboard"`；② 键位区（L245）追加 `hl.bind(mainMod .. " + V", hl.dsp.global(clipboard))`；③ 末尾 layer_rule（L384-389）追加 `^quickshell-clipboard$` 的 blur 规则 |

> **说明（与旧计划的差异）**：旧计划里的「bar 联动隐藏」**未实现**——`shell.qml` 中没有 `barVisible` 属性，`Modules.Bar` 的实例化也没有引用 `clipboard.clipboardVisible`。`clipboard.qml` 虽定义了 `clipboardVisible` 属性（派生自 `clipboardPanel.visible`），但当前没有任何代码消费它（AppLauncher 的 `launcherVisible`、通知中心的 `centerVisible` 同样未被 bar 消费）。即：覆盖层打开时 bar 不会自动隐藏。
>
> 不新增 shell 脚本。复制/删除命令在 QML 内以 `Process { command:["sh","-c", ...] }` 内联，转义由 QML 内 `shellQuote` 完成（见 §6）。

### 3.3 模块注册

`modules/qmldir`（`module Modules`）末尾已追加：

```
Clipboard 1.0 clipboard/clipboard.qml
```

`shell.qml` 顶部 `import "./modules" as Modules` 已存在，无需改动。

---

## 4. 数据流与状态管理

### 4.1 模块根状态（clipboard.qml 内）

```qml
Item {
    id: clipRoot

    property bool clipboardVisible: clipboardPanel.visible      // 派生绑定（跟踪覆盖层可见性；当前未被外部消费）
    property bool parseError: false            // JSON 解析失败标志
    property var historyList: []               // 后端全量数据
    property var searchedList: []              // 过滤后视图（ListView model）
    property real bandOffset: 0                // shader 偏移（由 shell 定时器驱动）
```

`bandOffset` 动画与 AppLauncher 一致：`funcInTimer` 里累加取模，shader 背景消费它。注意模数为 `1 + clipCard.width / clipCard.height`（clipboard.qml L23），与 AppLauncher 用 `Screen.width / Screen.height` 不同，因为本模块的 shader 作用在卡片（`clipCard`）上而非全屏。

### 4.2 数据拉取（按需触发）

统计脚本是 `running: true` 持续拉取；剪切板历史**不适合持续轮询**（理由见 §4.4），因此把「模式 A（StdioCollector + JSON.parse）」与「模式 B（running=false，按需置 true）」结合：

```qml
Process {
    id: clipInfoProc

    command: ["/home/kiki/.config/quickshell/exec-sh/cliphist-info.sh"]
    running: false                       // 仅打开/清空后按需重跑

    stdout: StdioCollector {
        onStreamFinished: {
            const trimmed = text.trim();
            if (!trimmed) {
                return;
            }

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
```

> 脚本路径绝对路径硬编码，与 shell.qml L28 / L61 / L92 等一致。

### 4.3 过滤（复用 fuzzyMatch）

`applyFilter()` 在每次数据到达 / 搜索文本变化时被调用，生成 `searchedList`：

```qml
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
```

`fuzzyMatch` 逻辑与 `applauncher.qml` 的 fuzzyMatch（见 `modules/applauncher/applauncher.qml` L102 附近）同源：字符计数模糊匹配，全小写比对；命中 `[a-z]` 字符计数（`shouldMatch`），在 text 中顺序消费，全部命中即匹配。本模块内嵌了一份实现，未直接引用 AppLauncher 的函数。

### 4.4 刷新策略（实现结论）

| 时机 | 行为 | 理由 |
| --- | --- | --- |
| 每次打开（`onVisibleChanged` 触发 `clipRoot.refresh()`，即 `clipInfoProc.running = true`） | 全量重拉 | 保证历史最新；图片缓存也顺带按需重建 |
| 打开期间 | **不轮询** | ① 前端复制动作会被 `wl-paste --watch cliphist store` 重新捕获，轮询会把刚复制的条目顶上列表，持续抖动；② 每 16ms 级重跑脚本代价高 |
| 删除单条后 | 本地即时 `filter`（historyList 与 searchedList 同步）+ **不**立即重拉 | 立即反馈，避免列表抖动与选中态漂移；下一次打开自然对齐 |
| 清空全部后 | 本地清空两列表 + `currentIndex = -1` + **不**立即重拉 | 见上；`cliphist wipe` 由命令异步执行 |
| 选中态 | 打开时 `currentIndex = 0`；过滤/删除后收敛到 `Math.max(0, len-1)` | 过滤/删除后选中始终落在合法区间，不越界 |

**结论：只在打开时全量刷新，打开期间不刷新。** 这是本模块的关键取舍，规避了「复制→重拉→列表位移→误触」的抖动问题。

打开时 `onVisibleChanged` 还会先把 `searchedList` 置为旧 `historyList` 的拷贝（用旧数据先行渲染，新数据到达后 `applyFilter` 覆盖），并把 `searchField.text` 清空、焦点移到搜索框。

---

## 5. UI 结构与布局

覆盖层采用「居中卡片 + shader 背景」布局：`PanelWindow` 全屏透明，内含一个居中的 `clipCard` 矩形，卡片内部是 ColumnLayout（Header 行 + 分隔线 + ListView + 兜底文案）。列表项结构与通知中心 ListView 近似。

### 5.1 覆盖层骨架

```qml
PanelWindow {
    id: clipboardPanel

    visible: false
    anchors { top: false; bottom: false; left: true; right: true }
    margins { top: 0; bottom: 0; left: 0; right: 0 }
    implicitHeight: 2 * Screen.height
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: true
    WlrLayershell.namespace: "quickshell-clipboard"   // 匹配 hyprland blur 规则（hyprland.lua L384-389）

    onVisibleChanged: {
        if (!visible) {
            return;
        }
        clipRoot.refresh();                            // 打开即重拉
        searchField.text = "";
        clipRoot.searchedList = [...clipRoot.historyList]; // 先用旧数据渲染，新数据到达后 applyFilter
        clipListView.currentIndex = 0;
        searchField.forceActiveFocus();
    }
```

### 5.2 居中卡片（clipCard）

```qml
Rectangle {
    id: clipCard

    anchors.centerIn: parent
    width: Math.min(clipboardPanel.width - 40, clipColumn.width + 50)
    height: Math.min(clipboardPanel.height - 100, clipColumn.height + 50)
    color: "transparent"
    scale: clipboardPanel.visible ? 1 : 0
    opacity: clipboardPanel.visible ? 1 : 0
    clip: true

    Behavior on scale   { NumberAnimation { duration: 250; easing.type: Easing.InOutSine } }
    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutSine } }
    Behavior on height  { SpringAnimation { spring: 4; damping: 0.25 } }

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
```

- shader 背景作用在**卡片**上（非全屏），`offset` 由 `clipRoot.bandOffset` 驱动（shell 定时器 `clipboard.funcInTimer(4e-3)` 推进）。
- 卡片宽度上限 `clipColumn.width + 50`（600+50），高度上限 `clipColumn.height + 50`，随内容弹性伸缩。

### 5.3 居中内容列（Header + 列表）

`ColumnLayout`（id `clipColumn`，`anchors.centerIn: parent`，宽 600，spacing 20）内部结构：

1. **Header RowLayout**（spacing 16）：
   - 标题 `Text`「剪切板」（`Colors.font` 24px，`Colors.fg1`）。
   - **搜索框胶囊**：外层 `Rectangle`（`Colors.fg3`，高 36，`radius: Math.min(width,height)/2`，fillWidth）内含搜索图标 `Text`（``，x16 垂直居中）+ `TextField`：
     ```qml
     TextField {
         id: searchField
         property bool isTyping: false
         onTextChanged: { isTyping = true; typingTimer.restart(); clipRoot.applyFilter(); }
         Timer {
             id: typingTimer
             interval: 1000
             onTriggered: { searchField.isTyping = false; }
         }
         // Keys.onPressed 见 §6.1
         x: 42
         anchors.verticalCenter: parent.verticalCenter
         width: parent.width - 70
         height: parent.height
         font { family: Colors.font; pixelSize: 16 }
         focus: true
         color: Colors.fg1
         background: Rectangle { anchors.fill: parent; color: "transparent" }
         cursorDelegate: Rectangle {  // 闪烁光标，isTyping 时保持满高
             width: 8; radius: Math.min(2, height) / 2; color: Colors.fg4
             SequentialAnimation on height { loops: Animation.Infinite; running: !searchField.isTyping; ... }
             onHeightChanged: { if (searchField.isTyping) height = searchField.height - 18; }
         }
     }
     ```
     `typingTimer`（1s 防抖）当前仅用于驱动光标闪烁（`isTyping`），**不过滤延迟**——过滤始终在 `onTextChanged` 同步执行。
   - **清空全部按钮**：`Rectangle` 36×36 圆角 18，`Colors.fg3`，内部 `Text`（``，16px，`Colors.err`），`visible: clipRoot.historyList.length > 0`，`TapHandler → clipRoot.deleteAllItems()`。
   - **关闭按钮**：`Rectangle` 36×36 圆角半，`Colors.fg3`，内部 `Text`（``，18px，`Colors.fg1`），`TapHandler → clipboardPanel.visible = false`。
2. **分隔线**：`Rectangle` 高 3，`Colors.fg3`，`radius: Math.min(width,height)/2`。
3. **ListView**（见 §5.4）。
4. **兜底文案**（见 §5.5）。

### 5.4 ListView + delegate（三种 type 渲染）

```qml
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
        Behavior on y { SpringAnimation { spring: 4; damping: 0.2 } }
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

            // ── 文件图标（file 类型）──
            Text {
                Layout.preferredWidth: 40
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font { family: Colors.font; pixelSize: 22 }
                color: Colors.fg5
                text: "󰈔"
                visible: clipItem.modelData.type === "file"
            }

            // ── 中间两行文字 ──
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    font { family: Colors.font; pixelSize: 16 }
                    color: Colors.fg1
                    text: clipItem.modelData.type === "text"
                          ? clipItem.modelData.preview
                          : clipItem.modelData.content.split("/").pop()
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                Text {
                    Layout.fillWidth: true
                    font { family: Colors.font; pixelSize: 12 }
                    color: Colors.fg5
                    text: clipItem.modelData.type === "text"
                          ? clipItem.modelData.content.split("\n")[0]
                          : clipItem.modelData.content
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    visible: (text ?? "") !== ""
                }
            }

            // ── 图片缩略图（image 类型）──
            Image {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: Math.min(90, sourceSize.width * 55 / sourceSize.height)
                Layout.preferredHeight: 55
                asynchronous: true
                visible: clipItem.modelData.type === "image"
                source: clipItem.modelData.content.split("\n")[0]   // content 即 PNG 缓存绝对路径
            }

            // ── 类型标签 ──
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: typeLabel.width + 18
                Layout.preferredHeight: 32
                radius: Math.min(width, height) / 2
                color: Colors.bg4

                Text {
                    id: typeLabel
                    anchors.centerIn: parent
                    font { family: Colors.font; pixelSize: 12 }
                    color: Colors.fg4
                    text: clipItem.modelData.type === "text" ? "文本"
                        : clipItem.modelData.type === "image" ? "图片"
                        : "文件"
                }
            }

            // ── 行内删除按钮 ──
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Math.min(width, height) / 2
                color: Colors.bg4

                Text {
                    x: (parent.width - implicitWidth) / 2
                    y: (parent.height - implicitHeight) / 2
                    font { family: Colors.font; pixelSize: 16 }
                    color: Colors.err
                    text: ""
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { clipRoot.deleteItem(clipItem.index); }
                }
            }
        }

        // ── 整行点击：选中并复制 ──
        TapHandler {
            onTapped: {
                clipListView.currentIndex = clipItem.index;
                clipRoot.copyCurrent();
            }
        }
    }
}
```

要点：
- 图片缩略图**不设 `sourceSize`**，`source` 直接用 `content.split("\n")[0]`（脚本已归一化的 PNG 绝对路径，无需 `file://` 前缀），`asynchronous: true`；宽按 `sourceSize` 比例自适应、上限 90，高 55，避免大图卡列表滚动。
- text 条目主行显示 `preview`（即正文），次行显示 `content`（可能带换行，取第一行）。
- image/file 条目主行显示文件名（`content` 取 basename），次行显示完整路径。
- 选中高亮用 `highlight` + `highlightFollowsCurrentItem: false` + `Behavior on y`（SpringAnimation 4/0.2），手法与 AppLauncher 的 ListView highlight 一致。
- 行内删除按钮用 `MouseArea`（而非 TapHandler）承接点击，避免与整行复制 TapHandler 在重叠区域同时触发；该交互已实测可用。

### 5.5 空状态 / 错误兜底

列表下方放三个互斥的 `Text`（同列底部）：

```qml
// historyList 为空 → 剪切板历史为空
Text { text: "剪切板历史为空"; visible: clipRoot.historyList.length === 0 && !clipRoot.parseError }
// 有历史但过滤无结果 → 无匹配结果
Text { text: "无匹配结果";     visible: clipRoot.historyList.length > 0 && clipRoot.searchedList.length === 0 }
// JSON 解析失败 → 数据加载失败（console.error 已打原始输出）
Text { text: "数据加载失败，请查看日志"; visible: clipRoot.parseError }
```

---

## 6. 交互设计

### 6.1 键盘导航

所有按键统一挂在 `searchField` 的 `Keys.onPressed`（TextField 持有焦点）：

```qml
Keys.onPressed: event => {
    if (event.key === Qt.Key_Return && (event.modifiers & Qt.ShiftModifier)) {
        clipRoot.copyCurrentKeepOpen();      // Shift+Enter 复制但不关闭
        event.accepted = true;
        return;
    }
    switch (event.key) {
    case Qt.Key_Escape:
        clipboardPanel.visible = false;
        event.accepted = true;
        break;
    case Qt.Key_Return:
        clipRoot.copyCurrent();              // Enter 复制并关闭
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
```

> `Shift+Return` 通过 `Keys.onPressed` 顶部的 `if` 分支提前拦截（early return），避免与 switch 里单独 `Qt.Key_Return` 分支冲突。`positionViewAtIndex` 保证选中项可见。

### 6.2 鼠标交互

- 整行 `TapHandler`：设 `currentIndex` → `copyCurrent()`（复制并关闭）。
- 行内删除按钮 `MouseArea`：`deleteItem(index)`，**不关闭覆盖层**，可连续删除。
- Header 清空全部按钮 `TapHandler`：`deleteAllItems()`（本地清空 + `cliphist wipe`），仅在有历史时可见。
- Header 关闭按钮 `TapHandler`：关闭覆盖层。

### 6.3 复制 / 删除命令（核心选型）

#### 复制语义与命令选型总表

| type | 最终命令（经 `sh -c` 执行） | mime | 选型理由 |
| --- | --- | --- | --- |
| **text** | `printf '%s\t%s' <shellQuote(id)> <shellQuote(preview)> \| cliphist decode \| wl-copy` | 无显式 mime（`wl-copy` 默认 `text/plain`） | `cliphist decode` 需要完整「id+preview」行；还原**原始字节**，不受 preview 截断/换行影响；id、preview 均经 `shellQuote` 单引号包裹 + 内嵌单引号转义 |
| **image** | `wl-copy --type image/png < <shellQuote(content)>` | `image/png`（恒） | 脚本已把所有图片统一转成 PNG 缓存，前端**无需**按扩展名推断 mime；必须**读文件内容**；路径单引号包裹 + `'\''` 转义，杜绝注入 |
| **file** | `printf '%s\r\n' <shellQuote(uri)> \| wl-copy --type text/uri-list` | `text/uri-list` | `text/uri-list` 让文件管理器可「粘贴为文件」；URI 由 `content` 绝对路径逐段 `encodeURIComponent` 拼接成 `file://`；`\r\n` 结尾符合 URI list 规范 |
| **删除单条** | `echo <id> \| cliphist delete` | — | `id` 为纯数字，来自 `cliphist list`，插值进 shell 无注入风险（本命令中 id 未用 `shellQuote` 包裹） |
| **清空全部** | `cliphist wipe && rm -rf -- "$XDG_RUNTIME_DIR/quickshell/clipboard"/*` | — | 同时清空 cliphist 库与本地 PNG 缓存目录，双端一致 |

> 注意：image / file 的复制命令都**经过 `sh -c`**（`<` 重定向、`printf` 均需 shell），而非 argv 直传。file 的 URI 用 `shellQuote` 包裹后拼进 `printf` 格式串。

#### 为什么 image 不用 `cliphist decode <id> | wl-copy`？

`cliphist decode` 输出的是 cliphist 库里存的**原始内容字节**：

- 二进制图片条目（`wl-paste --type image --watch cliphist store` 写入的）decode 确实输出图片字节，可行；
- 但 `file://` 被脚本归为 image 的条目，cliphist 库里存的是 **URL 文本**（如 `file:///home/user/a.png`），decode 出来是一串字符串。若按 `image/png` mime 发给 wl-copy，粘贴方收到的是坏数据。

因此 image 一律从 `content` 指向的 **PNG 缓存文件**读取（脚本保证打开时已生成）。

#### QML 内的 shell 安全工具函数

```qml
// bash 单引号转义：'a'\''b' == a'b（安全拼接进 sh -c）
function shellQuote(s) {
    return "'" + String(s).replace(/'/g, "'\\''") + "'";
}
```

#### 复制动作实现（单个 actionProc 复用）

```qml
Process {
    id: actionProc
    command: []
    running: false
}

function copyCurrent() {
    const idx = clipListView.currentIndex;
    if (idx < 0 || idx >= searchedList.length) return;
    copyItem(searchedList[idx]);
    clipboardPanel.visible = false;      // 关闭覆盖层
}

function copyCurrentKeepOpen() {         // Shift+Enter
    const idx = clipListView.currentIndex;
    if (idx < 0 || idx >= searchedList.length) return;
    copyItem(searchedList[idx]);
}

function copyItem(item) {
    const id = String(item.id ?? "");
    const preview = String(item.preview ?? "");

    if (item.type === "text") {
        // 文本：使用完整行解码，阻塞执行
        actionProc.command = ["sh", "-c", `printf '%s\\t%s' ${shellQuote(id)} ${shellQuote(preview)} | cliphist decode | wl-copy`];
    } else if (item.type === "image") {
        // 图片：解析阶段已经统一转换成真正的 PNG；wl-copy 明确声明 image/png
        actionProc.command = ["sh", "-c", `wl-copy --type image/png < ${shellQuote(item.content)}`];
    } else if (item.type === "file") {
        const uri = "file://" + item.content.split("/").map(encodeURIComponent).join("/");
        // 文件：阻塞执行，确保 \r\n 结尾
        actionProc.command = ["sh", "-c", `printf '%s\\r\\n' ${shellQuote(uri)} | wl-copy --type text/uri-list`];
    }

    actionProc.running = true;
}
```

> 注入安全结论：进入 shell 的唯一外部变量是 **id、preview、content、uri**，全部经 `shellQuote` 单引号转义（id 亦被包裹；仅删除命令 `echo ${id}` 例外，因 id 纯数字）；`content` / `preview` 从不裸拼进命令。

#### 删除动作实现

```qml
Process {
    id: deleteProc
    command: []
    running: false
}

function deleteItem(index) {
    if (index < 0 || index >= searchedList.length) return;
    const item = searchedList[index];
    const id = String(item.id ?? "");

    deleteProc.command = ["sh", "-c", `echo ${id} | cliphist delete`];   // id 纯数字，安全
    deleteProc.running = true;

    // 本地即时移除（historyList 与 searchedList 同时删，保持视图一致）
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
```

> 删除后不立即重拉（见 §4.4），本地 splice 保证 UI 即时一致，下一次打开自动对齐 DB。

### 6.4 wl-copy 持久化与重复条目说明

- `hyprland.lua` L45 已常驻 `wl-clip-persist --clipboard regular`：覆盖层是 PanelWindow，复制后即使关闭，剪贴板内容仍保持，无需额外处理。
- `wl-paste --watch cliphist store` 会捕获前端复制动作：若复制的是历史里**非顶部**的条目，它会被重新存为**顶部新条目**（cliphist 只与最近一条做去重）。这是 cliphist 固有行为，无需规避；可作为「置顶最近使用」的天然副作用。

---

## 7. 样式与动画

全部对齐既有惯例：

- **颜色/字体**：一律 `Colors.fg1..fg5` / `bg1..bg4` / `err` 等，字体 `Colors.font`。禁止硬编码色值。
- **shader 背景**：作用在居中卡片 `clipCard` 内的 `Item { layer.enabled: true; layer.effect: ShaderEffect { ... fragmentShader: "../../shaders/band-diagonal.frag.qsb" } }`，`offset` 由 `clipRoot.bandOffset` 驱动（shell 定时器 `clipboard.funcInTimer(4e-3)` 推进，L234）。shader 传入 `w/h`（卡片尺寸）、`r: 32`、`bg1/bg2/bg3`（`Colors.hexToRGBA01`）。
- **卡片动效**：`scale` / `opacity` 用 `NumberAnimation` 250ms `InOutSine`；`height` 用 `SpringAnimation 4/0.25`。
- **选中高亮**：`Behavior on y { SpringAnimation { spring: 4; damping: 0.2 } }`。
- **尺寸/圆角**：内容列宽 600、spacing 20；卡片宽高各加 50 缓冲（宽上限 panel-40、高上限 panel-100）；Header 标题 24px、搜索胶囊高 36、清空/关闭按钮 36×36；列表项高 70、圆角 20、间距 16、最多显示 10 项；缩略图高 55（宽按比例、上限 90）；类型标签高 32；删除按钮 32×32。
- **字体字号**：标题 24，搜索框 16，主行 16，次行 12，类型标签 12，文件图标 22，删除/清空图标 16-18。与项目档位吻合。
- **缩进/命名**：4 空格、camelCase、根 id `clipRoot`、PanelWindow id `clipboardPanel`、卡片 id `clipCard`、ListView id `clipListView`、搜索框 id `searchField`；文件头部 `pragma ComponentBehavior: Bound`。

---

## 8. 边界与容错

| 场景 | 处理 |
| --- | --- |
| cliphist 为空 / `cliphist list` 无输出 | 脚本输出 `[]`，`JSON.parse` 得空数组，展示「剪切板历史为空」 |
| JSON 被控制字符破坏 | `try/catch` + `console.error` + `parseError` 兜底文案（§5.5） |
| 图片缓存文件缺失 / 加载失败 | `Image` 设 `asynchronous`，无效路径只显示空白不崩溃；复制时若缓存文件缺失，`wl-copy` 收到空输入，属可接受降级 |
| 图片大尺寸 | 缩略图 `asynchronous: true` + 按比例限宽；ListView 虚拟化只实例化可见项 |
| 历史列表很长（数百条） | ListView 复用 delegate；过滤为线性扫描 O(n)，500 条内毫秒级 |
| 过滤后无结果 | 「无匹配结果」文案；currentIndex 收敛到合法区间 |
| 删除末尾项 | `currentIndex` 回退到 `Math.max(0, len-1)`，不越界 |
| 清空全部 | 本地清空 + `cliphist wipe` + 清理缓存目录；清空按钮仅在 `historyList.length > 0` 时可见 |
| 搜索时列表抖动 | 打开期间不轮询（§4.4），过滤只改 `searchedList`，选中态收敛 |
| 复制时条目恰好被删 | `cliphist decode` 出错 → wl-copy 收到空串；前端 `id` 缺失时直接 return |
| 覆盖层遮挡 bar | **未做 bar 联动隐藏**：`clipboardVisible` 属性已定义，但 shell.qml / bar.qml 未消费，覆盖层打开时 bar 仍可见 |

---

## 9. 实现状态（接线清单）

模块已完整实现，各接线点当前位于：

1. **`modules/clipboard/clipboard.qml`**：模块根 + 覆盖层 + 数据/动作 Process + GlobalShortcut（`name: "toggle-clipboard"`，L661-667）。
2. **`modules/qmldir`**（L10）：`Clipboard 1.0 clipboard/clipboard.qml`。
3. **`shell.qml`**：
   - Timer（L234）：`clipboard.funcInTimer(4e-3);`（与 `applauncher.funcInTimer(2e-3)`、`notifications.funcInTimer(4e-3)` 并列）。
   - 模块实例化（L249-251）：`Modules.Clipboard { id: clipboard }`。
   - **没有** `barVisible` 联动（未实现，见 §3.2 说明）。
4. **`~/.config/hypr/hyprland.lua`**：
   - L23：`local clipboard = "quickshell:toggle-clipboard"`。
   - L245：`hl.bind(mainMod .. " + V", hl.dsp.global(clipboard))`（`SUPER + V`）。
   - L384-389：`hl.layer_rule({ match = { namespace = "^quickshell-clipboard$" }, blur = true })`。

验证方式：重启 quickshell（或 hyprland 会话）后，复制几段文本、一张图片、一个文件路径，按 `SUPER + V` 打开——三类条目均显示、图片有缩略图；关键字过滤；方向键选择、Enter 复制并关闭、到目标应用粘贴验证 mime（图片能粘贴为图、文件能粘贴为文件）；Delete 删除条目、列表即时收缩；空历史 / 清空全部兜底文案正常；覆盖层背景有模糊（blur 规则生效）。

---

## 10. 后续可扩展项（简述）

- **置顶 / 收藏**：前端维护 `pinnedIds` 集合（`FileView` + JSON 持久化，仿 `app-list.qml`），排序时置顶并加星标标记。
- **多选复制**：`Ctrl+Click` 多选，批量 `cliphist decode` 拼接或逐个复制。
- **图片预览放大**：`TapHandler` 或 hover 弹出大图浮层（复用 shader 卡片 + `Image`，`scale` 动画）。
- **输入停止后再过滤**：把 `typingTimer`（当前仅驱动光标闪烁 `isTyping`）改为 `onTriggered` 延迟过滤，进一步降耗。
- **匹配高亮**：delegate 内用 `RichText` 对匹配字符着色（`fuzzyMatch` 返回位置）。
- **删除确认 / 撤销**：删除动画 + 短时 `undo`（恢复被删条目）。
- **条目来源应用标识**：结合 `cliphist list` 无法提供来源，可考虑记录复制时活跃窗口（`hyprctl activewindow`）作为元数据。
- **bar 联动隐藏**：若希望覆盖层打开时隐藏 bar，可在 `shell.qml` 的 `Modules.Bar` 上追加 `barVisible` 式条件（当前 `clipboardVisible` 属性已就绪，仅缺消费方）。

---

## 附：参考文件与行号索引

| 参考点 | 位置 |
| --- | --- |
| 后端数据源脚本 | `exec-sh/cliphist-info.sh`（JSON 契约、图片归一化为 PNG：`cache_image_as_png` L51-103） |
| 持续拉 JSON 范式 | `shell.qml` L25-56（time-date Proc + StdioCollector + try/catch） |
| 一次性命令范式 | `modules/bar/widgets/hypr-workspace.qml`、`modules/bar/widgets/brightness.qml`（`Process` + `sh -c`） |
| 覆盖层+搜索+键盘导航+GlobalShortcut 参照 | `modules/applauncher/applauncher.qml`（fuzzyMatch L102、typingTimer L155、background L173、cursorDelegate L186、Keys.onPressed L222、highlight L289、GlobalShortcut L382） |
| 历史列表+图片预览+删除 参照 | `modules/notifications/notif-center.qml`（ListView L277、listItemHeight 70 L280、delegate L290） |
| 模块根+状态+Process 拆分 参照 | `modules/notifications/notifications.qml` |
| 主题单例 | `colors.qml` |
| 模块注册 | `modules/qmldir`（L10 为 Clipboard） |
| hyprland 集成 | `~/.config/hypr/hyprland.lua`（wl-paste L43-44、wl-clip-persist L45、menu/notificationcenter L21-22、clipboard L23、键位 L245、blur 层规则 L384-389、CLIPHIST_DB_PATH L75） |
