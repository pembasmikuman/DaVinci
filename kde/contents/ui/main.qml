import QtQuick
import QtWebEngine
import org.kde.plasma.plasmoid

WallpaperItem {
    id: root

    WebEngineView {
        id: web
        anchors.fill: parent
        url: Qt.resolvedUrl("index.html")
        backgroundColor: "#0a0a0a"
    }

    // The desktop icons layer sits on top of the wallpaper and swallows hover,
    // so the page never sees the mouse. Put an empty item above everything in
    // the window; its HoverHandler doesn't block, so icons still get hover.
    Component {
        id: tracker
        Item {
            property alias hovered: hh.hovered
            property alias point: hh.point
            anchors.fill: parent
            z: 1e9
            HoverHandler {
                id: hh
                blocking: false
                onHoveredChanged: if (!hovered) web.runJavaScript("mouse.x=mouse.y=-1e4")
            }
        }
    }

    property Item sceneRoot: Window.window ? Window.window.contentItem : null
    property QtObject handler
    onSceneRootChanged: {
        if (handler) handler.destroy()
        handler = sceneRoot ? tracker.createObject(sceneRoot) : null
    }
    Component.onDestruction: if (handler) handler.destroy()

    // Read the position each frame while the mouse is on the desktop.
    Timer {
        property real lastX: -1
        property real lastY: -1
        interval: 16
        repeat: true
        running: root.handler !== null && root.handler.hovered
        onTriggered: {
            const p = root.mapFromItem(null, root.handler.point.scenePosition)
            if (p.x === lastX && p.y === lastY) return
            lastX = p.x; lastY = p.y
            web.runJavaScript(`mouse.x=${p.x};mouse.y=${p.y};lastMove=performance.now()`)
        }
    }
}
