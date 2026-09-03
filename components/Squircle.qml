import QtQuick

// A filled superellipse ("squircle") — a softer, blob-like alternative to a
// rounded rectangle. Hand-drawn on a Canvas, the same approach PasswordField's
// submit chevron uses, rather than pulling in a shapes library for one avatar
// option.
Item {
    id: root

    property color color: "black"
    readonly property real exponent: 4

    Canvas {
        id: canvas
        anchors.fill: parent

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: root
            function onColorChanged(): void {
                canvas.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            const w = width, h = height;
            if (w <= 0 || h <= 0)
                return;

            const a = w / 2, b = h / 2, n = root.exponent, steps = 90;

            ctx.beginPath();
            for (let i = 0; i <= steps; i++) {
                const t = (i / steps) * Math.PI * 2;
                const ct = Math.cos(t), st = Math.sin(t);
                // Superellipse parametrisation: sign(cos)*|cos|^(2/n), same for sin.
                const x = a + a * Math.sign(ct) * Math.pow(Math.abs(ct), 2 / n);
                const y = b + b * Math.sign(st) * Math.pow(Math.abs(st), 2 / n);
                if (i === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            ctx.closePath();
            ctx.fillStyle = root.color;
            ctx.fill();
        }
    }
}
