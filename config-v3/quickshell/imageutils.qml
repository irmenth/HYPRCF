pragma Singleton

import Quickshell
import QtQml

// Shared resolver for external (untrusted) image sources: notification icons,
// tray icons, clipboard images, launcher icons, etc.
QtObject {
    // Resolve an external source string into something safe to hand to
    // QtQuick.Image, or "" when it cannot possibly be valid.
    //
    // - "image://icon/<path>": unwraps to file://<path>. The icon provider
    //   paints a purple checkerboard placeholder (with status Ready!) when the
    //   file is missing, which bypasses Image.status filtering; a plain file
    //   load fails with Image.Error instead.
    // - Other paths / URLs: passed through; load failures are caught by
    //   `status === Image.Ready` visibility gates at the call sites.
    // - Bare names: resolved via iconPath(name, true), which returns "" when
    //   the icon is not in the theme, so garbage never reaches the provider.
    function resolveSource(src) {
        if (!src) {
            return "";
        }

        if (src.startsWith("image://icon/")) {
            const id = src.slice("image://icon/".length);
            if (id.includes("/") && !id.includes("?")) {
                return "file://" + id;
            }
            return src;
        }

        if (src.startsWith("image://") || src.startsWith("file://") || src.includes("/")) {
            return src;
        }

        return Quickshell.iconPath(src, true);
    }
}
