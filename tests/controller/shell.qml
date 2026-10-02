import QtQuick
import Quickshell
ShellRoot {
 id: root
 property int stage: 0
 property int ticks: 0
 SnipExpandController { id: controller }
 Timer {
  interval: 50; running: true; repeat: true
  onTriggered: {
   root.ticks++
   if (root.ticks > 100) { console.error("FAIL controller timed out at stage " + root.stage + ": " + controller.errorText); Qt.exit(1) }
   if (root.stage === 0 && controller.groupsSupported) { root.stage=1; controller.refreshGroups() }
   else if (root.stage === 1 && !controller.groupsLoading && controller.groups.length === 1) {
    if (!controller.groups[0].enabled) { Qt.exit(2); return }
    root.stage=2; controller.setGroupEnabled("work",false)
   } else if (root.stage === 2 && !controller.busy && !controller.groupsLoading && controller.groups.length && !controller.groups[0].enabled) {
    root.stage=3; controller.setGroupEnabled("work",true)
   } else if (root.stage === 3 && !controller.busy && !controller.groupsLoading && controller.groups.length && controller.groups[0].enabled) {
    root.stage=4; controller.setGroupEnabled("missing",false)
   } else if (root.stage === 4 && !controller.busy && !controller.groupsLoading && controller.errorText) {
    if (!controller.groups.length || !controller.groups[0].enabled) { Qt.exit(3); return }
    console.log("PASS controller group enable/disable, authoritative refresh, and failure recovery")
    Qt.quit()
   }
  }
 }
}
