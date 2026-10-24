import QtQuick
import qs.common
import qs.wallpaper

// Sample the wallpaper strip using the same centered aspect crop as Desktop.
// This never captures the desktop or includes the bar itself in the sample.
Canvas {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080
    property real luminance: 0
    readonly property color solidColor: WallpaperService.isColor ? WallpaperService.colorValue : "black"
    readonly property color foreground: !BarState.transparent ? Theme.foreground
        : luminance > 0.179 ? "#000000" : "#ffffff"
    readonly property string imageUrl: WallpaperService.imagePath.length > 0
        ? "file://" + WallpaperService.imagePath : ""

    width: 128
    height: 4
    opacity: 0
    enabled: false

    function refresh() {
        if (!BarState.transparent) return;
        if (imageUrl.length > 0 && !WallpaperService.isColor && !isImageLoaded(imageUrl))
            loadImage(imageUrl);
        requestPaint();
    }
    function linear(v) {
        return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
    }
    function brightness(r, g, b) {
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b);
    }

    onImageUrlChanged: refresh()
    onScreenWidthChanged: refresh()
    onScreenHeightChanged: refresh()
    onImageLoaded: requestPaint()
    Component.onCompleted: refresh()
    Connections {
        target: BarState
        function onTransparentChanged() { root.refresh() }
        function onBarBottomChanged() { root.refresh() }
    }
    Connections {
        target: WallpaperService
        function onCurrentChanged() { root.refresh() }
    }
    onPaint: {
        if (!BarState.transparent) return;
        if (WallpaperService.isColor) {
            const c = solidColor;
            luminance = brightness(c.r, c.g, c.b);
            return;
        }
        if (!imageUrl.length || !isImageLoaded(imageUrl)) {
            luminance = 0;
            return;
        }
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        const size = ctx.createImageData(imageUrl);
        const scale = Math.max(screenWidth / size.width, screenHeight / size.height);
        const cropWidth = screenWidth / scale;
        const cropHeight = screenHeight / scale;
        const x = (size.width - cropWidth) / 2;
        const y = (size.height - cropHeight) / 2
            + (BarState.barBottom ? (screenHeight - Theme.barHeight) / scale : 0);
        ctx.drawImage(imageUrl, x, y, cropWidth, Theme.barHeight / scale,
                      0, 0, width, height);
        const data = ctx.getImageData(0, 0, width, height).data;
        let total = 0;
        for (let i = 0; i < data.length; i += 4)
            total += brightness(data[i] / 255, data[i + 1] / 255, data[i + 2] / 255);
        luminance = total / (width * height);
    }
}
