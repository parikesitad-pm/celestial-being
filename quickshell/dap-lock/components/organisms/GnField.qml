pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Particles
import "../atoms"

// The living backdrop: the art, its panels opening, the beams and the GN particles.
Item {
    id: field

    property url art

    // Art is 1672x941 and cropped to fill, so art fractions go through this mapping.
    readonly property real artScale: Math.max(width / 1672, height / 941)
    function artX(f) { return (width - 1672 * artScale) / 2 + f * 1672 * artScale }
    function artY(f) { return (height - 941 * artScale) / 2 + f * 941 * artScale }

    property int nextBeam: 0

    function keystroke(x, y) {
        sparks.burst(4, x, y)
        beams.itemAt(nextBeam).beam.flare(0.55)
        nextBeam = (nextBeam + 1) % beams.count
    }

    function charge() {
        for (let i = 0; i < beams.count; i++)
            beams.itemAt(i).beam.flare(1)
        sparks.burst(90, width / 2, height * 0.8)
        release.stop()
        zoomIn.restart()
    }

    function fail() {
        zoomIn.stop()
        release.restart()
        alarm.restart()
    }

    Item {
        id: charged
        anchors.fill: parent

        Item {
            id: world
            anchors.fill: parent
            scale: 1.07

            Image {
                anchors.fill: parent
                source: field.art
                fillMode: Image.PreserveAspectCrop
                cache: false
            }

            // hyprlock: brightness = 0.9
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.1
            }

            // Panels open from the center outward.
            Repeater {
                model: [
                    { from: 0, to: 0.192, delay: 280 },
                    { from: 0.192, to: 0.384, delay: 140 },
                    { from: 0.384, to: 0.609, delay: 0 },
                    { from: 0.609, to: 0.801, delay: 140 },
                    { from: 0.801, to: 1, delay: 280 }
                ]
                Rectangle {
                    id: panel
                    required property var modelData
                    x: field.artX(modelData.from) - (modelData.from === 0 ? 2 : 0)
                    width: field.artX(modelData.to) - x + 1
                    height: field.height
                    color: Tokens.night

                    SequentialAnimation {
                        running: true
                        PauseAnimation { duration: panel.modelData.delay }
                        OpacityAnimator {
                            target: panel; from: 1; to: 0; duration: Tokens.panelOpen
                            easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.mac
                        }
                    }
                }
            }

            ParticleSystem { id: gn }

            Repeater {
                id: beams
                model: [
                    { at: 0.002, tint: Tokens.green, delay: 300, breath: 5.3, group: "dynames" },
                    { at: 0.192, tint: Tokens.orange, delay: 150, breath: 4.1, group: "kyrios" },
                    { at: 0.384, tint: Tokens.orange, delay: 0, breath: 6.2, group: "kyriosInner" },
                    { at: 0.609, tint: Tokens.blue, delay: 0, breath: 4.7, group: "exia" },
                    { at: 0.801, tint: Tokens.purple, delay: 150, breath: 5.8, group: "virtue" }
                ]
                Item {
                    id: lane
                    required property var modelData
                    readonly property alias beam: pillar

                    Beam {
                        id: pillar
                        x: field.artX(lane.modelData.at) - width / 2
                        y: field.artY(0)
                        height: field.height * 0.8
                        tint: lane.modelData.tint
                        igniteDelay: lane.modelData.delay
                        breathSeconds: lane.modelData.breath
                    }

                    ImageParticle {
                        system: gn
                        groups: [lane.modelData.group]
                        source: "qrc:///particleresources/glowdot.png"
                        color: lane.modelData.tint
                        colorVariation: 0.06
                        alpha: 0.95
                        entryEffect: ImageParticle.Fade
                    }

                    Emitter {
                        system: gn
                        group: lane.modelData.group
                        x: field.artX(lane.modelData.at) - 60
                        y: field.height * 0.45
                        width: 120
                        height: field.height * 0.3
                        emitRate: 13
                        lifeSpan: 6500
                        lifeSpanVariation: 2000
                        size: 16
                        sizeVariation: 9
                        endSize: 3
                        velocity: AngleDirection {
                            angle: 270
                            angleVariation: 26
                            magnitude: 30
                            magnitudeVariation: 14
                        }
                    }
                }
            }

            ImageParticle {
                system: gn
                groups: ["spark", "orbit"]
                source: "qrc:///particleresources/glowdot.png"
                color: Tokens.green
                colorVariation: 0.1
                entryEffect: ImageParticle.Fade
            }

            // A light circling the ring station in the center panel, leaving a short GN trail.
            Emitter {
                id: orbit
                property real phase: 0
                readonly property point center: Qt.point(field.artX(0.4948), field.artY(0.5417))
                readonly property real radiusX: 198 * field.artScale * 1672 / 1920
                readonly property real radiusY: 52 * field.artScale * 941 / 1080

                system: gn
                group: "orbit"
                x: center.x + Math.cos(phase) * radiusX
                y: center.y + Math.sin(phase) * radiusY
                emitRate: 60
                lifeSpan: 1100
                size: 14
                endSize: 2

                NumberAnimation on phase {
                    from: 0; to: Math.PI * 2; duration: 11000
                    loops: Animation.Infinite
                }
            }

            Emitter {
                id: sparks
                system: gn
                group: "spark"
                enabled: false
                lifeSpan: 1100
                lifeSpanVariation: 300
                size: 14
                sizeVariation: 7
                endSize: 1
                velocity: AngleDirection {
                    angle: 270
                    angleVariation: 55
                    magnitude: 85
                    magnitudeVariation: 45
                }
            }

            Wander {
                system: gn
                groups: ["dynames", "kyrios", "kyriosInner", "exia", "virtue"]
                xVariance: 24
                pace: 40
            }

            ScaleAnimator on scale {
                from: 1.07; to: 1; duration: Tokens.settle
                easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.mac
            }
        }

        Rectangle {
            id: alarmTint
            anchors.fill: parent
            color: Tokens.red
            opacity: 0
        }
    }

    SequentialAnimation {
        id: alarm
        OpacityAnimator { target: alarmTint; to: 0.2; duration: 70 }
        OpacityAnimator { target: alarmTint; to: 0; duration: 420 }
    }

    ScaleAnimator {
        id: zoomIn
        target: charged
        to: 1.05
        duration: Tokens.charge
        easing.type: Easing.InQuad
    }

    ScaleAnimator {
        id: release
        target: charged
        to: 1
        duration: Tokens.fadeOut
        easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.mac
    }
}
