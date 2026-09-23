import QtQuick
import QtQuick.Shapes
import qs
import qs.services
import "../lib/orbit.mjs" as O

Item {
    id: root

    property string icon: ""
    property bool scanning: false
    property real t: 0

    signal clicked

    readonly property real rimOuter: width / 2 + Tokens.haloRimOffset

    width: Tokens.haloSize
    height: Tokens.haloSize

    Shape {
        preferredRendererType: Shape.CurveRenderer
        id: glow
        anchors.centerIn: parent
        width: root.width + 80
        height: width

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: glow.width / 2
                centerY: glow.height / 2
                centerRadius: glow.width / 2
                focalX: glow.width / 2
                focalY: glow.height / 2
                GradientStop {
                    position: 0
                    color: Theme.glow
                }
                GradientStop {
                    position: root.width / glow.width
                    color: Theme.glow
                }
                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }
            PathAngleArc {
                centerX: glow.width / 2
                centerY: glow.height / 2
                radiusX: glow.width / 2
                radiusY: glow.height / 2
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    Repeater {
        model: 3
        delegate: Rectangle {
            required property int index
            readonly property var ring: O.sonarRing(root.t, index, root.scanning)
            anchors.centerIn: parent
            width: root.rimOuter * 2
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1.5
            border.color: Theme.sonar
            scale: ring.scale
            opacity: ring.opacity
        }
    }

    Shape {
        preferredRendererType: Shape.CurveRenderer
        id: disc
        visible: !Resin.enabled
        anchors.fill: parent

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: disc.width / 2
                centerY: disc.height * 0.35
                centerRadius: disc.width * 0.7
                focalX: disc.width / 2
                focalY: disc.height * 0.35
                GradientStop {
                    position: 0
                    color: Qt.lighter(Theme.surface, 1.5)
                }
                GradientStop {
                    position: 1
                    color: Theme.base
                }
            }
            PathAngleArc {
                centerX: disc.width / 2
                centerY: disc.height / 2
                radiusX: disc.width / 2
                radiusY: disc.height / 2
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    Glass {
        visible: Resin.enabled
        anchors.fill: parent
        radius: width / 2
        inner: true
    }

    Shape {
        preferredRendererType: Shape.CurveRenderer
        id: rim
        anchors.centerIn: parent
        width: root.rimOuter * 2
        height: width
        rotation: O.haloRotation(root.t)

        ShapePath {
            strokeWidth: -1
            fillRule: ShapePath.OddEvenFill
            fillGradient: ConicalGradient {
                centerX: rim.width / 2
                centerY: rim.height / 2
                angle: 90
                GradientStop {
                    position: 0
                    color: "transparent"
                }
                GradientStop {
                    position: 0.12
                    color: "transparent"
                }
                GradientStop {
                    position: 0.2
                    color: Theme.accentHi
                }
                GradientStop {
                    position: 0.34
                    color: "transparent"
                }
                GradientStop {
                    position: 0.5
                    color: "transparent"
                }
                GradientStop {
                    position: 0.62
                    color: Theme.accent
                }
                GradientStop {
                    position: 0.76
                    color: "transparent"
                }
                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }
            PathAngleArc {
                centerX: rim.width / 2
                centerY: rim.height / 2
                radiusX: rim.width / 2
                radiusY: rim.height / 2
                startAngle: 0
                sweepAngle: 360
            }
            PathAngleArc {
                centerX: rim.width / 2
                centerY: rim.height / 2
                radiusX: rim.width / 2 - Tokens.haloRim
                radiusY: rim.height / 2 - Tokens.haloRim
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    Glyph {
        anchors.centerIn: parent
        text: root.icon
        size: 48
        color: Theme.accentHi
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
