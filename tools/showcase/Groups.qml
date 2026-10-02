import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "Project" as Product
BorderSurface {
 implicitWidth: 380
 implicitHeight: content.implicitHeight + 32
 padding: 16
 color: Color.popups.background
 borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, 2)
 Product.GroupsView {
  id: content
  x: 16; y: 16; width: parent.width - 32
  foreground: Color.popups.text
  loading: Quickshell.env("SNIPEXPAND_GROUP_STATE") === "loading"
  errorText: Quickshell.env("SNIPEXPAND_GROUP_STATE") === "error" ? "Could not reach SnipExpand. Refresh to try again." : ""
  supported: Quickshell.env("SNIPEXPAND_GROUP_STATE") !== "unsupported"
  groups: Quickshell.env("SNIPEXPAND_GROUP_STATE") ? [] : [{name:"work",enabled:true,members:12,available:9},{name:"signatures",enabled:false,members:3,available:0},{name:"a_very_long_collection_name_for_overflow",enabled:true,members:200,available:180}]
 }
}
