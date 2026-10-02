import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Panel {
  id: root

  property string view: "list"
  property var selectedSnippet: null
  property string pendingDeleteTrigger: ""
  property string pendingRemovePack: ""
  property int selectedIndex: 0

  readonly property color foreground: bar ? bar.barForeground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.45)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property var visibleSnippets: controller.filteredSnippets
  readonly property bool editing: view === "edit"
  readonly property bool diagnosing: view === "doctor"
  readonly property bool managingGroups: view === "groups"
  readonly property bool managingPacks: view === "packs"

  function showList() {
    view = "list"
    selectedSnippet = null
    pendingDeleteTrigger = ""
    Qt.callLater(function() { searchField.forceActiveFocus() })
  }

  function startAdd() {
    selectedSnippet = null
    view = "edit"
    labelField.text = ""
    triggerField.text = ""
    replacementField.text = ""
    Qt.callLater(function() { triggerField.forceActiveFocus() })
  }

  function startEdit(snippet) {
    if (!snippet) return
    if (!snippet.editable) {
      controller.openSource(snippet.source)
      return
    }
    selectedSnippet = snippet
    view = "edit"
    labelField.text = snippet.label || ""
    triggerField.text = snippet.trigger
    replacementField.text = snippet.replacement
    Qt.callLater(function() { replacementField.forceActiveFocus(); replacementField.selectAll() })
  }

  function pasteSnippet(snippet) {
    if (!snippet) return
    root.close()
    controller.pasteSnippet(snippet.trigger, snippet.source)
  }

  function showDoctor() {
    view = "doctor"
    controller.diagnose()
  }

  function showPacks() {
    view = "packs"
    controller.refreshPacks()
    Qt.callLater(function() { packSourceField.forceActiveFocus() })
  }

  function showGroups() {
    view = "groups"
    controller.errorText = ""
    controller.refreshGroups()
    Qt.callLater(function() { groupsView.focusFirst() })
  }

  function saveEditor() {
    if (selectedSnippet) controller.updateSnippet(selectedSnippet.trigger, labelField.text, replacementField.text)
    else controller.addSnippet(triggerField.text, labelField.text, replacementField.text)
  }

  function requestDelete(snippet) {
    if (!snippet || !snippet.editable) return
    pendingDeleteTrigger = snippet.trigger
    deleteDialog.selectedIndex = 0
    deleteDialog.opened = true
  }

  function requestRemovePack(name) {
    pendingRemovePack = name
    packRemoveDialog.selectedIndex = 0
    packRemoveDialog.opened = true
  }

  function moveSelection(delta) {
    if (visibleSnippets.length === 0) return
    selectedIndex = Math.max(0, Math.min(visibleSnippets.length - 1, selectedIndex + delta))
    snippetList.positionViewAtIndex(selectedIndex, ListView.Contain)
  }

  moduleName: "io.github.silouanwright.snipexpand"
  ipcTarget: "snipexpand-panel"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: {
    if (opened) {
      controller.refresh()
      showList()
    } else {
      deleteDialog.opened = false
      controller.clearPrivateData()
      view = "list"
    }
  }

  SnipExpandController {
    id: controller
    onActionSucceeded: function(kind) {
      if (kind === "add" || kind === "edit") root.showList()
      if (kind === "remove") root.pendingDeleteTrigger = ""
      if (kind === "pack") packSourceField.text = ""
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    active: controller.running && controller.expansionEnabled
    text: ""
    labelVisible: false
    hasVisualContent: true
    fixedWidth: vertical ? -1 : Style.bar.iconSlot
    tooltipText: !controller.availabilityKnown
      ? qsTr("Checking SnipExpand")
      : (!controller.available
        ? qsTr("SnipExpand is not installed")
        : (controller.running
          ? (controller.expansionEnabled
            ? qsTr("SnipExpand is running with %1 triggers").arg(controller.triggerCount)
            : qsTr("SnipExpand is paused"))
          : qsTr("SnipExpand is stopped")))
    Accessible.role: Accessible.Button
    Accessible.name: tooltipText
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) controller.refresh()
      else root.toggle()
    }

    SnipExpandIcon {
      anchors.centerIn: parent
      size: Style.font.icon
      color: controller.running && controller.expansionEnabled ? root.foreground : root.dim
    }
  }

  Component {
    id: heroIcon
    SnipExpandIcon {
      color: controller.running && controller.expansionEnabled ? Color.accent : root.dim
      size: Style.font.display
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: root.managingGroups ? groupsView : (root.editing ? replacementField : searchField)
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    Item {
      anchors.fill: parent
      Keys.onPressed: function(event) {
        if (deleteDialog.opened && deleteDialog.handleKey(event)) {
          event.accepted = true
          return
        }
        if (packRemoveDialog.opened && packRemoveDialog.handleKey(event)) {
          event.accepted = true
          return
        }
        if (event.key === Qt.Key_Escape) {
          if (root.editing || root.diagnosing || root.managingPacks || root.managingGroups) root.showList()
          else root.close()
          event.accepted = true
        }
      }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(12)

        PanelHero {
          id: hero
          iconComponent: heroIcon
          title: qsTr("SnipExpand")
          meta: !controller.availabilityKnown
            ? qsTr("Checking installation")
            : (!controller.available
              ? qsTr("Not installed")
              : (controller.running
                ? (controller.expansionEnabled
                  ? qsTr("Running · %1 · %2 triggers").arg(controller.backend || qsTr("active")).arg(controller.triggerCount)
                  : qsTr("Paused · %1 triggers").arg(controller.triggerCount))
                : qsTr("Service stopped")))
          foreground: root.foreground
          fontFamily: root.fontFamily
          trailingControl: Component {
            Button {
              text: controller.expansionEnabled ? qsTr("Pause") : qsTr("Resume")
              bordered: true
              focusable: true
              enabled: controller.running && !controller.busy
              foreground: hero.foreground
              fontFamily: hero.fontFamily
              onClicked: controller.toggleExpansion()
            }
          }
        }

        Column {
          visible: controller.availabilityKnown && !controller.available
          width: parent.width
          spacing: Style.space(8)

          Text {
            width: parent.width
            text: qsTr("Install SnipExpand before enabling this plugin.")
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }
          Button {
            text: qsTr("Open SnipExpand")
            bordered: true
            focusable: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: Qt.openUrlExternally("https://github.com/silouanwright/snipexpand")
          }
        }

        Column {
          visible: controller.available && !controller.compatible
          width: parent.width
          spacing: Style.space(8)

          Text {
            width: parent.width
            text: qsTr("SnipExpand %1 or newer is required. Installed: %2")
              .arg(controller.minimumVersion)
              .arg(controller.installedVersion || qsTr("unknown"))
            color: Color.urgent
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }
          Button {
            text: qsTr("Update SnipExpand")
            bordered: true
            focusable: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: Qt.openUrlExternally("https://github.com/silouanwright/snipexpand/releases")
          }
        }

        Column {
          visible: controller.compatible && root.view === "list"
          width: parent.width
          spacing: Style.space(9)

          TextField {
            id: searchField
            width: parent.width
            text: controller.query
            placeholderText: qsTr("Search triggers and expansions")
            foreground: root.foreground
            Accessible.name: qsTr("Search snippets")
            onTextChanged: {
              controller.query = text
              root.selectedIndex = 0
            }
            Keys.onDownPressed: root.moveSelection(1)
            Keys.onUpPressed: root.moveSelection(-1)
            Keys.onReturnPressed: function(event) {
              if (!root.visibleSnippets.length) return
              var snippet = root.visibleSnippets[root.selectedIndex]
              if (event.modifiers & Qt.ControlModifier) root.startEdit(snippet)
              else root.pasteSnippet(snippet)
            }
          }

          Flow {
            width: parent.width
            spacing: Style.space(6)

            Button {
              text: qsTr("Add")
              iconText: "󰐕"
              bordered: true
              focusable: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.startAdd()
            }
            Button {
              text: qsTr("Diagnostics")
              iconText: "󰒡"
              bordered: true
              focusable: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.showDoctor()
            }
            Button {
              text: qsTr("Groups")
              bordered: true
              focusable: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.showGroups()
            }
            Button {
              text: qsTr("Packs")
              iconText: "󰏗"
              bordered: true
              focusable: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.showPacks()
            }
          }

          Text {
            visible: controller.errorText !== ""
            width: parent.width
            text: controller.errorText
            color: Color.urgent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          ListView {
            id: snippetList
            width: parent.width
            height: Math.min(contentHeight, Style.space(330))
            clip: true
            spacing: Style.space(4)
            model: root.visibleSnippets
            currentIndex: root.selectedIndex

            delegate: Button {
              required property var modelData
              required property int index
              width: snippetList.width
              height: Style.space(68)
              leftAlign: true
              bordered: false
              hasCursor: index === root.selectedIndex
              foreground: root.foreground
              fontFamily: root.fontFamily
              Accessible.name: qsTr("%1 expands to %2").arg(modelData.trigger).arg(controller.preview(modelData.replacement))
              onHovered: function(isHovered) { if (isHovered) root.selectedIndex = index }
              onClicked: root.pasteSnippet(modelData)

              Column {
                anchors.left: parent.left
                anchors.leftMargin: Style.space(10)
                anchors.right: parent.right
                anchors.rightMargin: Style.space(10)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(2)

                Text {
                  width: parent.width
                  text: modelData.label || modelData.trigger
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  elide: Text.ElideRight
                }
                Text {
                  width: parent.width
                  text: qsTr("Expansion: %1").arg(controller.preview(modelData.replacement))
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
                Text {
                  width: parent.width
                  text: qsTr("Trigger: %1").arg(modelData.trigger)
                  color: Color.accent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }
            }
          }

          Text {
            visible: root.visibleSnippets.length === 0
            width: parent.width
            text: controller.query ? qsTr("No matching snippets") : qsTr("No snippets configured")
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignHCenter
          }

          Text {
            visible: root.visibleSnippets.length > 0
            width: parent.width
            text: qsTr("Enter inserts · Ctrl+Enter edits")
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignHCenter
          }
        }

        GroupsView {
          id: groupsView
          visible: controller.compatible && root.managingGroups
          width: parent.width
          groups: controller.groups
          supported: controller.groupsSupported
          loading: controller.groupsLoading
          busy: controller.busy
          errorText: controller.groupError || controller.errorText
          paused: !controller.expansionEnabled
          foreground: root.foreground
          fontFamily: root.fontFamily
          onSetEnabled: function(name, enabled) { controller.setGroupEnabled(name, enabled) }
          onRefreshRequested: controller.refreshGroups()
          onOpenConfigRequested: controller.openConfig()
          onBackRequested: root.showList()
        }

        Column {
          visible: controller.compatible && root.managingPacks
          width: parent.width
          spacing: Style.space(9)

          PanelSectionHeader {
            text: qsTr("SNIPPET PACKS")
            foreground: root.foreground
            fontFamily: root.fontFamily
          }
          Row {
            width: parent.width
            spacing: Style.space(6)
            TextField {
              id: packSourceField
              width: parent.width - installPackButton.width - parent.spacing
              placeholderText: qsTr("espanso:arrows or Git URL")
              foreground: root.foreground
              Accessible.name: qsTr("Pack source")
              Keys.onReturnPressed: controller.installPack(text)
            }
            Button {
              id: installPackButton
              text: controller.busy ? qsTr("Working…") : qsTr("Install")
              bordered: true
              active: true
              focusable: true
              enabled: !controller.busy
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: controller.installPack(packSourceField.text)
            }
          }
          ListView {
            width: parent.width
            height: Math.min(contentHeight, Style.space(330))
            clip: true
            spacing: Style.space(6)
            model: controller.packs

            delegate: Rectangle {
              required property var modelData
              width: ListView.view.width
              height: Style.space(92)
              radius: Style.cornerRadius
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
              border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.18)

              Column {
                anchors.fill: parent
                anchors.margins: Style.space(9)
                spacing: Style.space(4)
                Text {
                  width: parent.width
                  text: modelData.title + "  " + modelData.version
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  elide: Text.ElideRight
                }
                Text {
                  width: parent.width
                  text: modelData.enabled ? qsTr("Enabled") : qsTr("Disabled")
                  color: modelData.enabled ? Color.accent : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
                Row {
                  spacing: Style.space(5)
                  Button {
                    text: modelData.enabled ? qsTr("Disable") : qsTr("Enable")
                    bordered: true
                    focusable: true
                    enabled: !controller.busy
                    foreground: root.foreground
                    fontFamily: root.fontFamily
                    onClicked: modelData.enabled
                      ? controller.disablePack(modelData.name)
                      : controller.enablePack(modelData.name)
                  }
                  Button {
                    text: qsTr("Update")
                    bordered: true
                    focusable: true
                    enabled: !controller.busy
                    foreground: root.foreground
                    fontFamily: root.fontFamily
                    onClicked: controller.updatePack(modelData.name)
                  }
                  Button {
                    text: qsTr("Remove")
                    bordered: true
                    focusable: true
                    enabled: !controller.busy
                    foreground: Color.urgent
                    fontFamily: root.fontFamily
                    onClicked: root.requestRemovePack(modelData.name)
                  }
                }
              }
            }
          }
          Text {
            visible: controller.packs.length === 0
            width: parent.width
            text: qsTr("No snippet packs installed")
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignHCenter
          }
          Text {
            visible: controller.errorText !== ""
            width: parent.width
            text: controller.errorText
            color: Color.urgent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
          Button {
            text: qsTr("Back")
            bordered: true
            focusable: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.showList()
          }
        }

        Column {
          visible: controller.compatible && root.editing
          width: parent.width
          spacing: Style.space(9)

          PanelSectionHeader {
            text: root.selectedSnippet ? qsTr("EDIT GENERATED SNIPPET") : qsTr("ADD GENERATED SNIPPET")
            foreground: root.foreground
            fontFamily: root.fontFamily
          }
          TextField {
            id: labelField
            width: parent.width
            placeholderText: qsTr("Label, such as Email address")
            foreground: root.foreground
            Accessible.name: qsTr("Snippet label")
            Keys.onReturnPressed: triggerField.enabled
              ? triggerField.forceActiveFocus()
              : replacementField.forceActiveFocus()
          }
          TextField {
            id: triggerField
            width: parent.width
            placeholderText: qsTr("Trigger, such as ;mail")
            enabled: !root.selectedSnippet
            foreground: root.foreground
            Accessible.name: qsTr("Snippet trigger")
            Keys.onReturnPressed: replacementField.forceActiveFocus()
          }
          TextField {
            id: replacementField
            width: parent.width
            placeholderText: qsTr("Expansion text")
            foreground: root.foreground
            Accessible.name: qsTr("Snippet expansion")
            Keys.onReturnPressed: root.saveEditor()
          }
          Text {
            width: parent.width
            text: qsTr("Use \\n for line breaks and $|$ for the final cursor position.")
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
          Row {
            spacing: Style.space(6)
            Button {
              text: controller.busy ? qsTr("Saving…") : qsTr("Save")
              bordered: true
              active: true
              focusable: true
              enabled: !controller.busy
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.saveEditor()
            }
            Button {
              text: qsTr("Cancel")
              bordered: true
              focusable: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.showList()
            }
            Button {
              visible: root.selectedSnippet !== null
              text: qsTr("Delete")
              bordered: true
              focusable: true
              foreground: Color.urgent
              fontFamily: root.fontFamily
              onClicked: root.requestDelete(root.selectedSnippet)
            }
          }
        }

        Column {
          visible: controller.compatible && root.diagnosing
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: qsTr("DIAGNOSTICS")
            foreground: root.foreground
            fontFamily: root.fontFamily
          }
          Repeater {
            model: controller.doctorChecks
            delegate: Row {
              required property var modelData
              width: parent.width
              spacing: Style.space(8)
              Text {
                text: modelData.ok ? "󰄬" : "󰅙"
                color: modelData.ok ? Color.accent : Color.urgent
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
              }
              Column {
                width: parent.width - Style.space(28)
                Text {
                  width: parent.width
                  text: modelData.label
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                }
                Text {
                  visible: !!modelData.detail
                  width: parent.width
                  text: modelData.detail || ""
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.WordWrap
                }
                Text {
                  visible: !!modelData.fix
                  width: parent.width
                  text: modelData.fix || ""
                  color: Color.accent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.WordWrap
                }
              }
            }
          }
          Row {
            spacing: Style.space(6)
            Button {
              text: qsTr("Back")
              bordered: true
              focusable: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.showList()
            }
            Button {
              text: qsTr("Run again")
              bordered: true
              focusable: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: controller.diagnose()
            }
            Button {
              text: qsTr("Open config")
              bordered: true
              focusable: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: controller.openConfig()
            }
          }
          Button {
            text: controller.busy && controller.actionKind === "restart" ? qsTr("Restarting…") : qsTr("Restart service")
            bordered: true
            focusable: true
            enabled: !controller.busy
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: controller.restart()
          }
          Text {
            visible: controller.errorText !== "" || controller.actionMessage !== ""
            width: parent.width
            text: controller.errorText || controller.actionMessage
            textFormat: Text.PlainText
            color: controller.errorText ? Color.urgent : root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }
      }

      ConfirmDialog {
        id: deleteDialog
        anchors.fill: parent
        message: qsTr("Delete %1?").arg(root.pendingDeleteTrigger)
        cancelText: qsTr("Cancel")
        confirmText: qsTr("Delete")
        foreground: root.foreground
        fontFamily: root.fontFamily
        onCanceled: {
          opened = false
          root.pendingDeleteTrigger = ""
        }
        onConfirmed: {
          opened = false
          controller.removeSnippet(root.pendingDeleteTrigger)
          root.showList()
        }
      }

      ConfirmDialog {
        id: packRemoveDialog
        anchors.fill: parent
        message: qsTr("Remove pack %1?").arg(root.pendingRemovePack)
        cancelText: qsTr("Cancel")
        confirmText: qsTr("Remove")
        foreground: root.foreground
        fontFamily: root.fontFamily
        onCanceled: {
          opened = false
          root.pendingRemovePack = ""
        }
        onConfirmed: {
          opened = false
          controller.removePack(root.pendingRemovePack)
          root.pendingRemovePack = ""
        }
      }
    }
  }
}
