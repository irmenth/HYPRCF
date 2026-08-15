pragma Singleton

import QtQuick
import Quickshell.Io
import Quickshell

Item {
    id: root

    property var usageMap: ({})
    property var sortedApps: []

    function load() {
        try {
            let text = usageFile.text();
            if (text && text.length > 0) {
                usageMap = JSON.parse(text);
            }
        } catch (e) {}
    }
    function save() {
        usageFile.setText(JSON.stringify(usageMap, null, 4));
    }
    function rebuild() {
        let apps = [...DesktopEntries.applications.values];

        apps.sort((a, b) => {
            let countA = usageMap[a.id] ?? 0;
            let countB = usageMap[b.id] ?? 0;

            if (countA !== countB) {
                return countB - countA;
            }

            return a.name.localeCompare(b.name);
        });

        sortedApps = apps;
    }
    function launch(app) {
        let id = app.id;

        if (!(id in usageMap) && id !== "undefined") {
            usageMap[id] = 0;
        }
        usageMap[id]++;
        save();
        app.execute();
    }

    FileView {
        id: usageFile

        path: "/home/kiki/.config/quickshell/modules/applauncher/app-list.json"

        onLoaded: {
            root.load();
        }
    }

    Connections {
        target: DesktopEntries

        function onApplicationsChanged() {
            root.rebuild();
        }
    }
}
