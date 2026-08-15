pragma ComponentBehavior: Bound

import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import QtQuick
import Quickshell
import "../"

Item {
    id: notifRoot

    property string time: ""
    property bool dndEnabled: false
    property int unreadCount: 0
    property var historyList: []
    property var popupItem: null
    property bool popupVisible: false
    property bool centerVisible: false
    property real bandOffset: 0

    function funcInTimer(offsetInterval) {
        centerComponent.funcInTimer(offsetInterval);
        popupComponent.funcInTimer(offsetInterval);
    }

    Process {
        id: initHistoryProc

        command: ["/home/kiki/.config/quickshell/exec-sh/init-notification-history.sh"]

        running: true

        onRunningChanged: {
            if (!running) {
                historyFile.reload();
            }
        }
    }

    FileView {
        id: historyFile

        path: `${Quickshell.env("XDG_RUNTIME_DIR")}/quickshell/notifications/notification-history.json`

        onLoaded: {
            try {
                const text = historyFile.text();
                if (!text) {
                    return;
                }

                const data = JSON.parse(text);
                if (data.history && Array.isArray(data.history)) {
                    notifRoot.historyList = data.history;
                }
            } catch (e) {
                console.warn("Failed to parse notification history:", e);
            }
        }
    }

    function saveHistory() {
        historyFile.setText(JSON.stringify({
            history: historyList
        }, null, 4));
    }

    function deleteHistoryItem(index) {
        let newList = [];
        for (let i = 0; i < historyList.length; i++) {
            if (i !== index) {
                newList.push(historyList[i]);
            }
        }
        historyList = newList;
        saveHistory();
    }

    function clearAllHistory() {
        historyList = [];
        saveHistory();
    }

    function addToHistory(notification) {
        let entry = {
            id: notification.id,
            appName: notification.appName,
            appIcon: notification.appIcon,
            summary: notification.summary,
            body: notification.body,
            image: notification.image,
            urgency: urgencyToString(notification.urgency),
            timestamp: notifRoot.time
        };
        let newList = [entry];
        for (let i = 0; i < historyList.length; i++) {
            newList.push(historyList[i]);
        }
        if (newList.length > 50) {
            newList = newList.slice(0, 50);
        }
        historyList = newList;
        saveHistory();
    }

    function urgencyToString(urgency) {
        switch (urgency) {
        case NotificationUrgency.Low:
            return "Low";
        case NotificationUrgency.Critical:
            return "Critical";
        default:
            return "Normal";
        }
    }

    function showPopup(notification) {
        popupItem = notification;
        popupVisible = true;
        dismissTimer.interval = Math.min(5000, notification.expireTimeout > 0 ? notification.expireTimeout * 1000 : 5000);
        dismissTimer.restart();
    }

    function dismissPopup() {
        popupVisible = false;
        dismissTimer.stop();
        if (popupItem !== null) {
            popupItem.dismiss();
            popupItem = null;
        }
    }

    function invokeNotify() {
        notifRoot.unreadCount = Math.max(0, notifRoot.unreadCount - 1);
        if (popupItem !== null) {
            let inoked = false;
            for (let i = 0; i < popupItem.actions.length; i++) {
                if (popupItem.actions[i].identifier === "default") {
                    popupItem.actions[i].invoke();
                    inoked = true;
                    break;
                }
            }
            if (!inoked) {
                dismissPopup();
            }
        }
    }

    function toggleCenter() {
        centerVisible = !centerVisible;
        if (centerVisible) {
            unreadCount = 0;
        }
    }

    // --- Dismiss Timer ---
    Timer {
        id: dismissTimer

        onTriggered: {
            notifRoot.dismissPopup();
        }
    }

    // --- NotificationServer ---
    NotificationServer {
        id: notifServer
        bodySupported: true
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: true
        inlineReplySupported: false
        persistenceSupported: true
        keepOnReload: true

        onNotification: notification => {
            notification.tracked = true;
            notifRoot.addToHistory(notification);

            if (!notifRoot.dndEnabled) {
                if (notifRoot.popupItem !== null) {
                    notifRoot.popupItem.dismiss();
                    notifRoot.popupItem = null;
                }
                notifRoot.showPopup(notification);
            }

            if (!notifRoot.centerVisible) {
                notifRoot.unreadCount = notifRoot.unreadCount + 1;
            }

            notification.closed.connect(reason => {
                if (notifRoot.popupItem === notification) {
                    notifRoot.popupVisible = false;
                    notifRoot.popupItem = null;
                }
            });
        }
    }

    // --- Popup Toast ---
    NotifPopup {
        id: popupComponent
        notifRoot: notifRoot
    }

    // --- Notification Center ---
    NotifCenter {
        id: centerComponent
        notifRoot: notifRoot
    }

    // --- GlobalShortcut ---
    GlobalShortcut {
        name: "toggle-notification-center"

        onPressed: {
            notifRoot.toggleCenter();
        }
    }
}
