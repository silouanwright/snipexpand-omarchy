import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

Item {
  id: root

  property bool available: false
  property bool availabilityKnown: false
  property bool running: false
  property bool configValid: false
  property string version: ""
  property string backend: ""
  property int triggerCount: 0
  property int fileCount: 0
  property var snippets: []
  property var doctorChecks: []
  property bool doctorOk: false
  property string query: ""
  property string errorText: ""
  property string actionKind: ""
  property string actionError: ""
  property string _statusOutput: ""
  property string _listOutput: ""
  property string _doctorOutput: ""

  readonly property bool busy: actionProcess.running
  readonly property var filteredSnippets: Model.filterSnippets(snippets, query)

  signal actionSucceeded(string kind)

  visible: false
  width: 0
  height: 0

  function preview(text) { return Model.preview(text, 74) }

  function checkAvailability() {
    if (!availabilityProcess.running) availabilityProcess.running = true
  }

  function refreshStatus() {
    if (!available || statusProcess.running) return
    _statusOutput = ""
    statusProcess.running = true
  }

  function refresh() {
    if (!available) return
    refreshStatus()
    if (!listProcess.running) {
      _listOutput = ""
      listProcess.running = true
    }
  }

  function clearPrivateData() {
    query = ""
    snippets = []
  }

  function diagnose() {
    if (!available || doctorProcess.running) return
    _doctorOutput = ""
    doctorProcess.running = true
  }

  function addSnippet(trigger, replacement) {
    var cleanTrigger = String(trigger || "").trim()
    if (!cleanTrigger) {
      errorText = qsTr("Trigger is required")
      return
    }
    runAction(["snipexpand", "add", cleanTrigger, String(replacement || "")], "add")
  }

  function updateSnippet(trigger, replacement) {
    runAction(["snipexpand", "add", String(trigger), String(replacement || "")], "edit")
  }

  function removeSnippet(trigger) {
    runAction(["snipexpand", "remove", String(trigger)], "remove")
  }

  function restart() {
    runAction(["systemctl", "--user", "restart", "snipexpand.service"], "restart")
  }

  function openConfig() {
    Quickshell.execDetached(["omarchy-launch-editor", Quickshell.env("HOME") + "/.config/snipexpand"])
  }

  function openSource(path) {
    if (path) Quickshell.execDetached(["omarchy-launch-editor", String(path)])
  }

  function runAction(command, kind) {
    if (busy) return
    actionKind = kind
    actionError = ""
    errorText = ""
    actionProcess.command = command
    actionProcess.running = true
  }

  Process {
    id: availabilityProcess
    command: ["bash", "-c", "command -v snipexpand >/dev/null 2>&1"]
    onExited: function(exitCode) {
      root.availabilityKnown = true
      root.available = exitCode === 0
      if (root.available) root.refreshStatus()
      else {
        root.running = false
        root.snippets = []
      }
    }
  }

  Process {
    id: statusProcess
    command: ["snipexpand", "status", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root._statusOutput = text
        var status = Model.parseStatus(text)
        root.running = status.running === true
        root.version = status.version || ""
        root.backend = status.backend || ""
        root.triggerCount = status.triggers || 0
        root.fileCount = status.files || 0
        root.configValid = status.configValid === true
        if (status.error) root.errorText = status.error
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0 && root._statusOutput === "") root.running = false
    }
  }

  Process {
    id: listProcess
    command: ["snipexpand", "list", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root._listOutput = text
        var result = Model.parseSnippets(text)
        root.snippets = result.snippets
        if (result.error) root.errorText = result.error
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0 && root._listOutput === "") root.errorText = qsTr("Could not load snippets")
    }
  }

  Process {
    id: doctorProcess
    command: ["snipexpand", "doctor", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root._doctorOutput = text
        var result = Model.parseDoctor(text)
        root.doctorOk = result.ok
        root.doctorChecks = result.checks
        if (result.error) root.errorText = result.error
      }
    }
  }

  Process {
    id: actionProcess
    onExited: function(exitCode) {
      if (exitCode === 0) {
        root.actionSucceeded(root.actionKind)
        Qt.callLater(root.refresh)
      } else {
        root.errorText = root.actionError || qsTr("SnipExpand command failed")
      }
    }
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector { waitForEnd: true; onStreamFinished: root.actionError = String(text || "").trim() }
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.checkAvailability()
  }
}
