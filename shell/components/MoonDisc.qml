import QtQuick

Canvas {
    id: root

    property real fraction: 0.5
    property real phase: 0.25
    property bool south: false
    property color lit: "#ece6d6"
    property color shade: "#1a1b22"
    property real earthshine: 0.18

    readonly property var maria: [[0.36, 0.34, 0.16], [0.56, 0.3, 0.11], [0.62, 0.52, 0.14], [0.42, 0.6, 0.09], [0.3, 0.52, 0.07], [0.7, 0.36, 0.06]]

    onFractionChanged: requestPaint()
    onPhaseChanged: requestPaint()
    onSouthChanged: requestPaint()
    onLitChanged: requestPaint()
    onShadeChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const r = Math.min(width, height) / 2 - 0.5;
        const cx = width / 2;
        const cy = height / 2;
        const waxing = root.phase < 0.5;
        const right = waxing !== root.south;
        const dir = right ? 1 : -1;
        const k = dir * r * (1 - 2 * root.fraction);
        const kappa = 0.5523;

        ctx.beginPath();
        ctx.arc(cx, cy, r, 0, Math.PI * 2);
        ctx.fillStyle = Qt.rgba(root.shade.r, root.shade.g, root.shade.b, 1);
        ctx.fill();
        ctx.fillStyle = Qt.rgba(root.lit.r, root.lit.g, root.lit.b, root.earthshine * (1 - root.fraction));
        ctx.fill();

        ctx.save();
        ctx.beginPath();
        ctx.moveTo(cx, cy - r);
        ctx.arc(cx, cy, r, -Math.PI / 2, Math.PI / 2, !right);
        ctx.bezierCurveTo(cx + k * kappa, cy + r, cx + k, cy + r * kappa, cx + k, cy);
        ctx.bezierCurveTo(cx + k, cy - r * kappa, cx + k * kappa, cy - r, cx, cy - r);
        ctx.closePath();
        const g = ctx.createRadialGradient(cx - dir * r * 0.25, cy - r * 0.2, r * 0.1, cx, cy, r);
        g.addColorStop(0, Qt.lighter(root.lit, 1.08));
        g.addColorStop(0.75, root.lit);
        g.addColorStop(1, Qt.darker(root.lit, 1.35));
        ctx.fillStyle = g;
        ctx.fill();
        ctx.clip();
        for (const m of root.maria) {
            const mx = root.south ? width - m[0] * width : m[0] * width;
            const my = root.south ? height - m[1] * height : m[1] * height;
            const mg = ctx.createRadialGradient(mx, my, 0, mx, my, m[2] * width);
            mg.addColorStop(0, Qt.rgba(0, 0, 0, 0.16));
            mg.addColorStop(1, Qt.rgba(0, 0, 0, 0));
            ctx.fillStyle = mg;
            ctx.fillRect(0, 0, width, height);
        }
        ctx.restore();
    }
}
