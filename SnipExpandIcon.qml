import QtQuick
import QtQuick.Shapes

Item {
  id: root

  property color color: "black"
  property real size: 24

  implicitWidth: size
  implicitHeight: size
  Accessible.ignored: true

  Shape {
    width: 24
    height: 24
    anchors.centerIn: parent
    scale: root.size / 24
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeWidth: 2
      strokeColor: root.color
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      PathSvg {
        path: "M12 20h-1a2 2 0 0 1-2-2 2 2 0 0 1-2 2H6 M13 8h7a2 2 0 0 1 2 2v4a2 2 0 0 1-2 2h-7 M5 16H4a2 2 0 0 1-2-2v-4a2 2 0 0 1 2-2h1 M6 4h1a2 2 0 0 1 2 2 2 2 0 0 1 2-2h1 M9 6v12"
      }
    }
  }
}
