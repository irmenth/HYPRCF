pragma Singleton

import QtQuick

QtObject {
    readonly property string font: "Maple Mono NF CN ExtraBold"
    readonly property color fg1: "#FFFFFFFF"
    readonly property color fg2: "#FF323232"
    readonly property color fg3: "#FF505050"
    readonly property color fg4: "#FFE2E2E2"
    readonly property color fg5: "#FFC6C6C6"
    readonly property color bg1: "#FF1E1E1E"
    readonly property color bg2: "#FF282828"
    readonly property color bg3: fg2
    readonly property color bg4: "#FF3C3C3C"
    readonly property color rb1: "#FFF7F680"
    readonly property color rb2: "#FF42C2FF"
    readonly property color rb3: "#FFFD7979"
    readonly property color btc: "#FF34C759"
    readonly property color err: "#FFFF3B30"
    readonly property color wrn: "#FFFFD60A"

    function hexToRGBA01(hex) {
        hex = hex.toString();
        var c = hex.substring(1);
        var cint = parseInt(c, 16);
        if (c.length <= 6) {
            var r = ((cint >> 16) & 255) / 255;
            var g = ((cint >> 8) & 255) / 255;
            var b = (cint & 255) / 255;
            return Qt.vector4d(r, g, b, 1);
        }
        var r = ((cint >> 24) & 255) / 255;
        var g = ((cint >> 16) & 255) / 255;
        var b = ((cint >> 8) & 255) / 255;
        var a = (cint & 255) / 255;
        return Qt.vector4d(r, g, b, a);
    }
}
