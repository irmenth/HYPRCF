import Quickshell
import Quickshell.Io
import QtQuick
import "./modules" as Modules

Scope {
    id: root

    property int timerLoopCount: 0
    property string time: ""
    property string dayofweek: ""
    property string date: ""
    property int memTotalKB: 0
    property int memUsedKB: 0
    property real cpuUsagePercent: 0
    property real cpuAvgFreqGHz: 0
    property real cpuTemp: 0
    property real gpuTemp: 0
    property real downloadSpeedBps: 0
    property real uploadSpeedBps: 0
    property bool hasBattery: false
    property int acOnline: 0
    property int batteryCapacity: 0

    Process {
        id: timeDateProc

        command: ["/home/kiki/.config/quickshell/exec-sh/time-date.sh"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim();
                if (!trimmed) {
                    return;
                }

                try {
                    const data = JSON.parse(trimmed);

                    if (data.time) {
                        root.time = data.time;
                    }
                    if (data.dayofweek) {
                        root.dayofweek = data.dayofweek;
                    }
                    if (data.date) {
                        root.date = data.date;
                    }
                } catch (e) {
                    console.error("time-date.sh JSON parse error:", e);
                    console.error("raw output:", text);
                }
            }
        }
    }
    Process {
        id: memStatsProc

        command: ["/home/kiki/.config/quickshell/exec-sh/mem-stats.sh"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim();
                if (!trimmed) {
                    return;
                }

                try {
                    const data = JSON.parse(trimmed);

                    if (typeof data.total_kb === "number" && !isNaN(data.total_kb)) {
                        root.memTotalKB = data.total_kb;
                    }
                    if (typeof data.used_kb === "number" && !isNaN(data.used_kb)) {
                        root.memUsedKB = data.used_kb;
                    }
                    // 如果你以后想显示内存百分比，可以新增 root.memUsedPercent
                    // if (typeof data.used_percent === "number" && !isNaN(data.used_percent)) {
                    //     root.memUsedPercent = data.used_percent;
                    // }
                } catch (e) {
                    console.error("mem-stats.sh JSON parse error:", e);
                    console.error("raw output:", trimmed);
                }
            }
        }
    }
    Process {
        id: cpuStatsProc

        command: ["/home/kiki/.config/quickshell/exec-sh/cpu-stats.sh"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim();
                if (!trimmed) {
                    return;
                }

                try {
                    const data = JSON.parse(trimmed);

                    if (typeof data.usage_percent === "number" && !isNaN(data.usage_percent)) {
                        root.cpuUsagePercent = data.usage_percent;
                    }
                    if (typeof data.freq_ghz === "number" && !isNaN(data.freq_ghz)) {
                        root.cpuAvgFreqGHz = data.freq_ghz;
                    }
                    if (typeof data.temp_c === "number" && !isNaN(data.temp_c)) {
                        root.cpuTemp = data.temp_c;
                    }
                } catch (e) {
                    console.error("cpu-stats.sh JSON parse error:", e);
                    console.error("raw output:", trimmed);
                }
            }
        }
    }
    Process {
        id: gpuStatsProc

        command: ["/home/kiki/.config/quickshell/exec-sh/gpu-stats.sh"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim();
                if (!trimmed) {
                    return;
                }

                try {
                    const data = JSON.parse(trimmed);

                    if (typeof data.temp_c === "number" && !isNaN(data.temp_c)) {
                        root.gpuTemp = data.temp_c;
                    }
                } catch (e) {
                    console.error("gpu-stats.sh JSON parse error:", e);
                    console.error("raw output:", trimmed);
                }
            }
        }
    }
    Process {
        id: networkStatsProc

        command: ["/home/kiki/.config/quickshell/exec-sh/network-stats.sh"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim();
                if (!trimmed) {
                    return;
                }

                try {
                    const data = JSON.parse(trimmed);

                    if (typeof data.download_bps === "number" && !isNaN(data.download_bps)) {
                        root.downloadSpeedBps = data.download_bps;
                    }
                    if (typeof data.upload_bps === "number" && !isNaN(data.upload_bps)) {
                        root.uploadSpeedBps = data.upload_bps;
                    }
                    // 如果你想显示当前网卡名，可以新增一个 root.networkInterface：
                    //
                    // if (typeof data.interface === "string") {
                    //     root.networkInterface = data.interface;
                    // } else {
                    //     root.networkInterface = "";
                    // }
                } catch (e) {
                    console.error("network-stats.sh JSON parse error:", e);
                    console.error("raw output:", trimmed);
                }
            }
        }
    }
    Process {
        id: batteryStatsProc

        command: ["/home/kiki/.config/quickshell/exec-sh/battery-stats.sh"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim();
                if (!trimmed) {
                    return;
                }

                try {
                    const data = JSON.parse(trimmed);

                    root.hasBattery = data.has_battery === true;

                    if (typeof data.ac_online === "number" && !isNaN(data.ac_online)) {
                        root.acOnline = data.ac_online;
                    }
                    if (typeof data.capacity_percent === "number" && !isNaN(data.capacity_percent)) {
                        root.batteryCapacity = data.capacity_percent;
                    }
                } catch (e) {
                    console.error("battery-stats.sh JSON parse error:", e);
                    console.error("raw output:", trimmed);
                }
            }
        }
    }

    Timer {
        interval: 16
        repeat: true
        running: true
        onTriggered: {
            root.timerLoopCount = (root.timerLoopCount + 1) % 625;

            timeDateProc.running = true;
            if (root.timerLoopCount % 62.5 == 0) {
                memStatsProc.running = true;
                cpuStatsProc.running = true;
                gpuStatsProc.running = true;
                networkStatsProc.running = true;
                batteryStatsProc.running = true;
            }

            applauncher.funcInTimer(2e-3);
            notifications.funcInTimer(4e-3);
            clipboard.funcInTimer(4e-3);
            bar.funcInTimer();
        }
    }

    Modules.Applauncher {
        id: applauncher

        time: root.time
    }
    Modules.Notifications {
        id: notifications

        time: root.time
    }
    Modules.Clipboard {
        id: clipboard
    }
    Modules.Bar {
        id: bar

        shell: root
        notifModule: notifications
    }
}
