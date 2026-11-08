import QtQuick

// Soft elliptical light painted once. Animating its opacity afterwards never repaints it.
Canvas {
    id: sprite

    property color tint

    renderTarget: Canvas.Image
    onPaint: {
        const c = getContext("2d")
        const r = width / 2
        const t = sprite.tint
        c.clearRect(0, 0, width, height)
        c.save()
        c.scale(1, height / width)
        const light = c.createRadialGradient(r, r, 0, r, r, r)
        light.addColorStop(0, Qt.rgba(t.r, t.g, t.b, 0.9))
        light.addColorStop(0.3, Qt.rgba(t.r, t.g, t.b, 0.28))
        light.addColorStop(1, Qt.rgba(t.r, t.g, t.b, 0))
        c.fillStyle = light
        c.fillRect(0, 0, width, width)
        c.restore()
    }
}
