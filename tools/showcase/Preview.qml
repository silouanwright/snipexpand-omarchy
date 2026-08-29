import QtQuick
import qs.Commons
import qs.Ui

BorderSurface {
  id: root

  implicitWidth: Style.space(380)
  implicitHeight: content.implicitHeight + padding * 2
  color: Color.popups.background
  borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
  padding: Style.spacing.popupPadding
  radius: Style.cornerRadius

  readonly property color foreground: Color.popups.text
  readonly property color dim: Qt.darker(foreground, 1.45)

  Component {
    id: heroIcon
    Text {
      text: "󰗊"
      color: Color.accent
      font.family: Style.font.family
      font.pixelSize: Style.font.display
    }
  }

  Column {
    id: content
    anchors.fill: parent
    anchors.margins: root.padding
    spacing: Style.space(12)

    PanelHero {
      iconComponent: heroIcon
      title: qsTr("SnipExpand")
      meta: qsTr("Running · Wayland · 211 triggers")
      detail: "v0.2.2"
      foreground: root.foreground
      fontFamily: Style.font.family
    }

    TextField {
      width: parent.width
      placeholderText: qsTr("Search triggers and expansions")
      foreground: root.foreground
    }

    Row {
      spacing: Style.space(6)
      Button {
        text: qsTr("Add")
        iconText: "󰐕"
        bordered: true
        foreground: root.foreground
      }
      Button {
        text: qsTr("Diagnostics")
        iconText: "󰒡"
        bordered: true
        foreground: root.foreground
      }
      Button {
        text: qsTr("Restart")
        iconText: "󰑓"
        bordered: true
        foreground: root.foreground
      }
    }

    Repeater {
      model: [
        { trigger: ";mail", kind: qsTr("GENERATED"), replacement: "hello@example.com", selected: true },
        { trigger: ";shrug", kind: qsTr("YAML"), replacement: "¯\\_(ツ)_/¯", selected: false },
        { trigger: ";sig", kind: qsTr("YAML"), replacement: "Best regards, Alex Example", selected: false }
      ]

      delegate: BorderSurface {
        required property var modelData
        width: parent.width
        implicitHeight: Style.space(50)
        color: modelData.selected ? Style.selectedFillFor(root.foreground, Color.accent) : "transparent"
        borderSpec: modelData.selected
          ? Border.controlSpec("selected", root.foreground, Color.accent)
          : Border.none()
        radius: Style.cornerRadius

        Column {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          anchors.margins: Style.space(10)
          spacing: Style.space(2)
          Row {
            Text {
              text: modelData.trigger
              color: root.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              font.bold: true
            }
            Text {
              text: "  " + modelData.kind
              color: modelData.kind === qsTr("GENERATED") ? Color.accent : root.dim
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
          Text {
            width: parent.width
            text: modelData.replacement
            color: root.dim
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }
        }
      }
    }
  }
}
