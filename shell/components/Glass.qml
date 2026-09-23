import QtQuick
import QtQuick.Shapes
import qs
import qs.services

Item {
    id: root

    property real radius: 0
    property bool inner: false
    property bool raised: false
    property bool hot: false
    property bool lit: false
    property color litColor: Theme.accent
    property color offColor: root.inner ? Theme.tint : Theme.surface
    property color offBorder: "transparent"
    property real drift: 0
    property point light: root.rest

    readonly property bool on: Resin.enabled
    readonly property bool panel: !root.inner
    readonly property real bodyAlpha: root.inner ? Resin.layerOpacity : root.raised ? Math.max(Resin.opacity, 0.88) : Resin.opacity
    readonly property real rimAlpha: Resin.rim * (root.inner ? 0.35 : 0.5)
    readonly property point rest: Qt.point(root.width * (0.5 + 0.32 * Math.sin(root.drift * 0.35)), root.height * (0.14 + 0.05 * Math.sin(root.drift * 0.23 + 1.3)))

    HoverHandler {
        id: pointer
        enabled: root.on && root.panel && Resin.sheen > 0
    }

    FrameAnimation {
        running: root.visible && root.on && root.panel && Resin.sheen > 0 && (Resin.flow > 0 || pointer.hovered)
        onTriggered: {
            root.drift += frameTime * Resin.flow;
            const target = pointer.hovered ? pointer.point.position : root.rest;
            const k = Math.min(1, frameTime * 4);
            root.light = Qt.point(root.light.x + (target.x - root.light.x) * k, root.light.y + (target.y - root.light.y) * k);
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.on ? Qt.alpha(root.inner ? Qt.lighter(Theme.pane, 1.35) : Theme.pane, root.bodyAlpha) : root.offColor
        border.width: root.on ? 0 : 1
        border.color: root.offBorder

        Behavior on color {
            ColorAnimation {
                duration: Tokens.stateDuration
            }
        }
    }

    Rectangle {
        visible: root.on && root.panel && Resin.tint > 0
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.alpha(Theme.accent, Resin.tint)
            }
            GradientStop {
                position: 1
                color: "transparent"
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Theme.tintMid
        opacity: root.on && root.hot ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.stateDuration
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.litColor
        opacity: root.lit ? Resin.litAlpha : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.stateDuration
            }
        }
    }

    Shape {
        visible: root.on && root.panel && Resin.sheen > 0
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: root.light.x
                centerY: root.light.y
                focalX: root.light.x
                focalY: root.light.y
                centerRadius: Math.max(root.width, root.height) * 0.55
                GradientStop {
                    position: 0
                    color: Qt.alpha(Theme.accentHi, Resin.sheen * 0.35)
                }
                GradientStop {
                    position: 0.45
                    color: Qt.alpha(Theme.text, Resin.sheen * 0.06)
                }
                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }

            PathRectangle {
                x: 0
                y: 0
                width: root.width
                height: root.height
                radius: root.radius
            }
        }
    }

    Image {
        visible: root.on && root.panel && Resin.grain > 0
        anchors.fill: parent
        anchors.margins: root.radius * 0.3
        source: Qt.resolvedUrl("../assets/grain.png")
        fillMode: Image.Tile
        opacity: Resin.grain
        smooth: false
    }

    Shape {
        visible: root.on && Resin.rim > 0 && root.width > 2 && root.height > 2
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillRule: ShapePath.OddEvenFill
            fillGradient: LinearGradient {
                x1: 0
                y1: 0
                x2: root.width
                y2: root.height
                GradientStop {
                    position: 0
                    color: Qt.alpha(Theme.text, root.rimAlpha)
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(Theme.text, root.rimAlpha * 0.25)
                }
            }

            PathRectangle {
                x: 0
                y: 0
                width: root.width
                height: root.height
                radius: root.radius
            }

            PathRectangle {
                x: 1
                y: 1
                width: root.width - 2
                height: root.height - 2
                radius: Math.max(0, root.radius - 1)
            }
        }
    }
}
