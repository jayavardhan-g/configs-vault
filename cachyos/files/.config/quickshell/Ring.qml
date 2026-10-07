// Circular progress ring
import QtQuick

Canvas {
    id: ring
    property real progress: 0          // 0..1
    property real thickness: 8
    property color trackColor: Theme.line
    property color fillColor: Theme.accent

    onProgressChanged: requestPaint()
    onFillColorChanged: requestPaint()
    onTrackColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const r = Math.min(width, height) / 2 - thickness / 2;
        const cx = width / 2, cy = height / 2;
        ctx.lineWidth = thickness;
        ctx.lineCap = "round";
        ctx.strokeStyle = trackColor;
        ctx.beginPath();
        ctx.arc(cx, cy, r, 0, 2 * Math.PI);
        ctx.stroke();
        if (progress > 0) {
            ctx.strokeStyle = fillColor;
            ctx.beginPath();
            ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * Math.min(progress, 1));
            ctx.stroke();
        }
    }
}
