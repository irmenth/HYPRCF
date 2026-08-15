pragma Singleton

import QtQuick
import Quickshell.Io

Item {
    id: root

    property var statsMap: ({})
    property bool loadSuccess: false

    function load() {
        try {
            let text = statsFile.text();
            if (text && text.length > 0) {
                statsMap = JSON.parse(text);
                root.loadSuccess = true;
            }
        } catch (e) {}
    }
    function save() {
        statsFile.setText(JSON.stringify(statsMap, null, 4));
    }
    function updateStat(name, stat) {
        if (!(name in statsMap) || name === "undefined" || statsMap[name] === stat) {
            return;
        }

        statsMap[name] = stat;
        save();
    }
    function getStat(name) {
        if (!(name in statsMap) && name !== "undefined") {
            statsMap[name] = false;
            save();
        }
        return statsMap[name];
    }

    FileView {
        id: statsFile

        path: "/home/kiki/.config/quickshell/modules/bar/widgets-expand-stats.json"

        onLoaded: {
            root.load();
        }
    }
}
