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
    width: 256
    height: 256
    anchors.centerIn: parent
    scale: root.size / 256
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeWidth: -1
      fillColor: root.color
      fillRule: ShapePath.WindingFill
      PathSvg {
        path: "M112,40a8,8,0,0,0-8,8V64H24A16,16,0,0,0,8,80v96a16,16,0,0,0,16,16h80v16a8,8,0,0,0,16,0V48A8,8,0,0,0,112,40ZM24,176V80h80v96ZM248,80v96a16,16,0,0,1-16,16H144a8,8,0,0,1,0-16h88V80H144a8,8,0,0,1,0-16h88A16,16,0,0,1,248,80ZM88,112a8,8,0,0,1-8,8H72v24a8,8,0,0,1-16,0V120H48a8,8,0,0,1,0-16H80A8,8,0,0,1,88,112Z"
      }
    }
  }
}
