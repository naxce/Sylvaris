import QtQuick

Item {
    id: root

    property string source: ""
    property real radius: width / 2
    property color fallbackColor: "transparent"
    readonly property bool ready: canvas.loaded

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.fallbackColor
        visible: !canvas.loaded
    }

    Canvas {
        id: canvas

        property bool loaded: false

        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onImageLoaded: {
            loaded = isImageLoaded(root.source);
            requestPaint();
        }
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            if (!loaded)
                return;
            ctx.drawImage(root.source, 0, 0, width, height);
            ctx.globalCompositeOperation = "destination-in";
            ctx.beginPath();
            ctx.roundedRect(0, 0, width, height, root.radius, root.radius);
            ctx.fill();
            ctx.globalCompositeOperation = "source-over";
        }
    }

    onSourceChanged: {
        canvas.loaded = false;
        canvas.requestPaint();
        if (root.source !== "")
            canvas.loadImage(root.source);
    }

    Component.onCompleted: {
        if (root.source !== "")
            canvas.loadImage(root.source);
    }
}
