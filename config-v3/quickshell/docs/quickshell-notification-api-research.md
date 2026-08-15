# Quickshell 消息通知 API 调研 (v0.3.0)

## 1. 核心类型

### Notification

通知对象，代表一条已接收到的系统通知。

**属性：**

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| `actions` | `list<NotificationAction>` | 该通知携带的动作列表 |
| `appName` | `string` | 来源应用的名称 |
| `summary` | `string` | 通知标题/摘要 |
| `body` | `string` | 通知正文 |
| `urgency` | `int` | 紧急程度（对应 Freedesktop 规范：0 = low, 1 = normal, 2 = critical） |
| `appIcon` | `string` | 应用图标 |
| `image` | `QQuickItem*` | 通知附带的图像 |
| `resident` | `bool` | 是否为常驻通知（不会自动超时消失） |

**方法：**

- `dismiss()` — 仅关闭通知，不向来源应用发送任何信号
- `expire()` — 主动让通知过期关闭
- `sendInlineReply(replyText)` — 发送内联回复文本给来源应用

**注意：** Notification 上**没有** `activate()` 或 `defaultAction()` 方法。触发"默认动作"需要手动从 `actions` 列表中查找。

### NotificationAction

单个通知动作对象。

**属性：**

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| `identifier` | `string` | 动作标识符（见下文 Freedesktop 规范中的 "default"） |
| `label` | `string` | 动作显示文本 |

**方法：**

- `Q_INVOKABLE void invoke()` — 向来源应用发送 D-Bus `ActionInvoked` 信号；对于非 resident 通知，调用后会自动关闭通知

### NotificationServer

通知服务端。

**属性：**

- `actionsSupported` — 是否支持通知动作
- `actionIconsSupported` — 是否支持动作图标
- `notifications` (`list`) — 当前全部通知
- `notificationsCount` — 当前通知数量

## 2. Freedesktop 通知规范中的"默认动作"

Freedesktop Desktop Notifications 规范中，`identifier` 为 `"default"` 的动作表示**点击通知体**时应触发的行为。

- 发送方（QQ、Discord 等应用）在调用 D-Bus `Notify` 方法时注册 `"default"` action，该动作随后会出现在 `notification.actions` 列表中
- Quickshell 只是透传 action identifier，**不做任何特殊处理**——`"default"` 不会自动绑定到点击事件，需要开发者自己判断并调用

## 3. 点击通知体 vs 点击关闭按钮

| 行为 | 方式 | 效果 |
| --- | --- | --- |
| 关闭按钮 | 调用 `dismiss()` | 仅关闭通知，**不**通知来源应用 |
| 点击通知体 | 找到 `identifier === "default"` 的 action 并调用 `invoke()` | 触发来源应用的对应操作（如打开对话窗口），非 resident 通知自动关闭 |
| 兜底 | 找不到 "default" 时退化为 `dismiss()` | 仅关闭通知 |

**`invoke()` 的内部流程：**

1. 发送 D-Bus `ActionInvoked(id, identifier)` 信号给来源应用
2. 若通知非 resident，自动 `close`

**安全性：**

`invoke()` 内部有 `isRetained()` 守卫，不会对已销毁（destroyed）的通知重复操作，因此可以安全地在点击处理器中调用。

## 4. 实现方案

点击通知体时遍历 `actions` 查找 `"default"` 动作并 `invoke()`；找不到则退化为 `dismiss()`。X（关闭）按钮保持 `dismiss()` 不变。

**QML 示例：**

```qml
// 点击通知体
function activateNotification(notification) {
    if (!notification) return;
    for (let i = 0; i < notification.actions.length; i++) {
        const action = notification.actions[i];
        if (action.identifier === "default") {
            action.invoke();
            return;
        }
    }
    // 没有 "default" 动作时退化为仅关闭
    notification.dismiss();
}
```

```qml
// 关闭按钮（保持不变）
onClicked: {
    notification.dismiss();
}
```

## 5. 参考来源

- https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.Notifications/Notification/
- https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.Notifications/NotificationAction/
- https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.Notifications/NotificationServer/
- https://dueno.pages.freedesktop.org/xdg-specs/notification-spec/notification-spec-latest.html
- https://github.com/quickshell-mirror/quickshell/tree/master/src/services/notifications
