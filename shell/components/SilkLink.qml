import QtQuick
import QtQuick.Shapes
import qs.services

Shape {
    id: root

    property var geometry: ({
            sx: 0,
            sy: 0,
            qx: 0,
            qy: 0,
            ex: 0,
            ey: 0
        })

    ShapePath {
        strokeColor: Theme.silk
        strokeWidth: 2
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        startX: root.geometry.sx
        startY: root.geometry.sy

        PathQuad {
            controlX: root.geometry.qx
            controlY: root.geometry.qy
            x: root.geometry.ex
            y: root.geometry.ey
        }
    }
}
