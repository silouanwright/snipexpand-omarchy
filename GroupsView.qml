import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

Column {
  id: root
  property var groups: []
  property bool supported: true
  property bool loading: false
  property bool busy: false
  property bool paused: false
  property string errorText: ""
  property string pendingFocusName: ""
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  signal setEnabled(string name, bool enabled)
  signal refreshRequested()
  signal openConfigRequested()
  signal backRequested()
  spacing: Style.space(9)

  onVisibleChanged: if (!visible) pendingFocusName = ""
  onGroupsChanged: {
    if (!pendingFocusName || !visible) return
    const name = pendingFocusName
    pendingFocusName = ""
    Qt.callLater(function() {
      for (let index = 0; index < root.groups.length; index++) {
        if (root.groups[index].name === name) {
          groupList.currentIndex = index
          groupList.positionViewAtIndex(index, ListView.Contain)
          if (groupList.currentItem) groupList.currentItem.forceActiveFocus()
          break
        }
      }
    })
  }

  function focusFirst() { backButton.forceActiveFocus() }

  PanelSectionHeader {
    text: qsTr("PERSONAL GROUPS")
    foreground: root.foreground
    fontFamily: root.fontFamily
  }
  Text {
    width: parent.width
    text: !root.supported ? qsTr("Update SnipExpand to 0.5.0 or newer to manage groups.")
      : root.loading ? qsTr("Loading groups…")
      : root.paused ? qsTr("Expansion is paused. Group choices are saved for when you resume.")
      : qsTr("Choose which personal snippet collections are enabled.")
    textFormat: Text.PlainText
    wrapMode: Text.WordWrap
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }
  ListView {
    id: groupList
    width: parent.width
    height: Math.min(contentHeight, Style.space(280))
    clip: true
    spacing: Style.space(6)
    model: root.supported ? root.groups : []
    ScrollBar.vertical: ScrollBar {}
    delegate: Toggle {
      required property var modelData
      required property int index
      width: groupList.width - Style.space(12)
      label: modelData.name
      description: modelData.enabled
        ? qsTr("Enabled · %1 of %2 snippets available before app filters").arg(modelData.available).arg(modelData.members)
        : qsTr("Disabled · %1 snippets").arg(modelData.members)
      checked: modelData.enabled
      enabled: !root.busy && !root.loading
      foreground: root.foreground
      fontFamily: root.fontFamily
      Accessible.role: Accessible.CheckBox
      Accessible.name: label
      Accessible.description: description
      Accessible.checked: checked
      Accessible.onToggleAction: clicked()
      onClicked: {
        root.pendingFocusName = modelData.name
        root.setEnabled(modelData.name, !modelData.enabled)
      }
      onActiveFocusChanged: if (activeFocus) groupList.positionViewAtIndex(index, ListView.Contain)
    }
  }
  Text {
    visible: root.supported && !root.loading && !root.errorText && root.groups.length === 0
    width: parent.width
    text: qsTr("No personal groups yet. Define snippet_groups in config.yml to collect files or folders.")
    textFormat: Text.PlainText
    wrapMode: Text.WordWrap
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
  }
  Text {
    visible: root.errorText !== ""
    width: parent.width
    text: root.errorText
    textFormat: Text.PlainText
    wrapMode: Text.WrapAnywhere
    color: Color.urgent
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }
  Flow {
    width: parent.width
    spacing: Style.space(6)
    Button {
      id: backButton
      text: qsTr("Back")
      bordered: true
      focusable: true
      foreground: root.foreground
      fontFamily: root.fontFamily
      onClicked: root.backRequested()
    }
    Button {
      text: qsTr("Open config")
      bordered: true
      focusable: true
      foreground: root.foreground
      fontFamily: root.fontFamily
      onClicked: root.openConfigRequested()
    }
    Button {
      visible: root.supported
      text: qsTr("Refresh")
      bordered: true
      focusable: true
      enabled: !root.loading && !root.busy
      foreground: root.foreground
      fontFamily: root.fontFamily
      onClicked: root.refreshRequested()
    }
  }
}
