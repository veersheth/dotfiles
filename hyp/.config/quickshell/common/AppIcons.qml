pragma Singleton
import Quickshell
import QtQuick

// Shared app identity/icon resolution. Mango reports WM_CLASS-style app IDs
// while the icon theme uses desktop-file Icon names, so these helpers keep
// dock pins icon-path lookups consistent.
Singleton {
    id: root

    function canonicalId(appId) {
        const raw = String(appId ?? "").trim();
        if (raw === "") return "";
        const lower = raw.toLowerCase();

        if (lower.includes("zen"))             return "zen-browser";
        if (lower.includes("vnc"))             return "tigervnc";
        if (lower === "code" || lower.includes("vscode")) return "vscode";
        if (lower.includes("obsidian"))        return "obsidian";
        if (lower.includes("spotify"))         return "spotify";
        if (lower.includes("nautilus"))        return "org.gnome.Nautilus";
        if (lower.includes("loupe"))           return "org.gnome.Loupe";
        if (lower.includes("firefox"))         return "firefox";
        if (lower.includes("chrome") || lower.includes("chromium")) return "google-chrome";

        if (lower.includes(".")) {
            const last = lower.split(".").pop();
            if (last !== "") return last;
        }
        return lower;
    }

    function iconPath(appId) {
        const raw = String(appId ?? "").trim();
        if (raw === "") return "";
        const canonical = root.canonicalId(raw);
        const lower = raw.toLowerCase();
        const candidates = [];

        function add(value) {
            if (value !== "" && candidates.indexOf(value) === -1)
                candidates.push(value);
        }

        add(raw);
        add(lower);
        add(canonical);
        if (lower.includes("zen"))             add("zen-browser");
        if (lower.includes("vnc"))             add("tigervnc");
        if (lower === "code" || lower.includes("vscode")) add("vscode");
        if (lower.includes("obsidian"))        add("obsidian");
        if (lower.includes("spotify"))         add("spotify-client");
        if (lower.includes("firefox"))         add("firefox");
        if (lower.includes("chrome") || lower.includes("chromium")) add("google-chrome", "chromium");

        for (const candidate of candidates) {
            const path = Quickshell.iconPath(candidate, true);
            if (path !== "") return path;
        }
        return "";
    }

    function desktopId(appId) {
        const raw = String(appId ?? "").trim();
        const lower = raw.toLowerCase();
        if (lower.includes("zen"))                 return "zen-beta";
        if (lower.includes("vnc"))                 return "vncviewer";
        if (lower.includes("obsidian"))            return "md.obsidian.Obsidian";
        if (lower === "code" || lower.includes("vscode")) return "code";
        if (lower.includes("firefox"))             return "firefox";
        if (lower.includes("chromium"))            return "chromium";
        if (lower.includes("chrome"))              return "google-chrome";
        return raw;
    }

    function displayName(appId) {
        const key = root.canonicalId(appId);
        if (key === "") return "Application";
        return key.split(/[-_]/).map(part =>
            part.charAt(0).toUpperCase() + part.slice(1)).join(" ");
    }
}
