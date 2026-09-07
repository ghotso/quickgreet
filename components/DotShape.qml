import QtQuick

// One password-dot shape, picked by name, on a single Canvas — no matter how
// many shapes the caller cycles through. Every shape here is a parametric
// curve sampled by angle: circle is the base case, squircle bends it toward a
// superellipse, gem is that same superellipse rotated 45°, and wobbly/clover
// ripple the plain radius. ring reuses the circle path stroked instead of
// filled, so it needs no shape of its own.
//
// PasswordField picks `shape` from `index` alone — see its comment on why
// that must never depend on the character a dot stands for.
Item {
    id: root

    property color color: "black"
    property string shape: "circle" // circle | squircle | gem | wobbly | ring | clover

    // Headroom over the logical box: once a shape is sized to match a circle's
    // *area* rather than its bounding box (see onPaint below), gem/wobbly/
    // clover all sample a little outside that box on their widest point. This
    // keeps that from being clipped by the canvas's own pixel bounds instead
    // of just landing in the unused spacing between dots.
    readonly property real margin: 1.4

    Canvas {
        id: canvas
        width: root.width * root.margin
        height: root.height * root.margin
        anchors.centerIn: parent

        readonly property int steps: 360

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: root
            function onColorChanged(): void {
                canvas.requestPaint();
            }
            function onShapeChanged(): void {
                canvas.requestPaint();
            }
        }

        function squirclePoint(t: real, n: real): point {
            const ct = Math.cos(t), st = Math.sin(t);
            return Qt.point(Math.sign(ct) * Math.pow(Math.abs(ct), 2 / n), Math.sign(st) * Math.pow(Math.abs(st), 2 / n));
        }

        // The raw, unscaled point for one sample angle — everything here
        // stays a pure function of the angle and the shape name, never of
        // anything password-related.
        function rawPoint(name: string, t: real): point {
            switch (name) {
            case "squircle":
                return squirclePoint(t, 4);
            case "gem": {
                const p = squirclePoint(t, 4);
                const c = Math.SQRT1_2;
                return Qt.point(p.x * c - p.y * c, p.x * c + p.y * c);
            }
            case "wobbly": {
                const r = 1 + 0.12 * Math.cos(5 * t);
                return Qt.point(r * Math.cos(t), r * Math.sin(t));
            }
            case "clover": {
                const r = 1 + 0.18 * Math.cos(4 * t);
                return Qt.point(r * Math.cos(t), r * Math.sin(t));
            }
            default: // circle, and ring's underlying path
                return Qt.point(Math.cos(t), Math.sin(t));
            }
        }

        // Shoelace area of the sampled outline. Sizing every shape to match
        // this against a circle's — rather than fitting each to the same
        // bounding box — is what keeps gem and clover from reading lighter
        // than circle and squircle in the same row: fitted to the box, their
        // diagonal pinch leaves them with visibly less ink.
        function rawArea(pts: list<point>): real {
            let s = 0;
            for (let i = 0; i < pts.length; i++) {
                const a = pts[i], b = pts[(i + 1) % pts.length];
                s += a.x * b.y - b.x * a.y;
            }
            return Math.abs(s) / 2;
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            const logicalR = root.width / 2;
            if (logicalR <= 0)
                return;

            const isRing = root.shape === "ring";
            const lineWidth = logicalR * 0.4;
            // Ring's stroke is centred on its path, so pull the path in by
            // half the line width first — otherwise the stroke's outer edge
            // would sit further out than every filled shape's.
            const targetR = isRing ? logicalR - lineWidth / 2 : logicalR;

            const pts = [];
            for (let i = 0; i < steps; i++)
                pts.push(rawPoint(isRing ? "circle" : root.shape, (i / steps) * Math.PI * 2));

            // One scale factor for both axes — scaling x and y independently
            // would shear a rotated shape like gem.
            const scale = Math.sqrt(Math.PI / rawArea(pts)) * targetR;

            const cx = width / 2, cy = height / 2;
            ctx.beginPath();
            for (let i = 0; i < pts.length; i++) {
                const x = cx + pts[i].x * scale, y = cy + pts[i].y * scale;
                if (i === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            ctx.closePath();

            if (isRing) {
                ctx.strokeStyle = root.color;
                ctx.lineWidth = lineWidth;
                ctx.stroke();
            } else {
                ctx.fillStyle = root.color;
                ctx.fill();
            }
        }
    }
}
