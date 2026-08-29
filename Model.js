.pragma library

function parseJson(raw, fallback, label) {
  try {
    var value = JSON.parse(String(raw || ""))
    return { value: value, error: "" }
  } catch (error) {
    return { value: fallback, error: qsTr("Could not read %1").arg(label) }
  }
}

function parseStatus(raw) {
  var result = parseJson(raw, {}, "SnipExpand status")
  if (result.error) return { running: false, error: result.error }
  var value = result.value
  return {
    running: value.running === true,
    enabled: value.enabled !== false,
    version: String(value.version || ""),
    backend: String(value.injection_backend || ""),
    triggers: Number(value.triggers || 0),
    files: Number(value.files || 0),
    configValid: value.config_valid === true,
    error: ""
  }
}

function parseCliVersion(raw) {
  var match = String(raw || "").match(/(\d+)\.(\d+)\.(\d+)/)
  return match ? match[1] + "." + match[2] + "." + match[3] : ""
}

function versionAtLeast(version, minimum) {
  var current = parseCliVersion(version).split(".").map(Number)
  var required = parseCliVersion(minimum).split(".").map(Number)
  if (current.length !== 3 || required.length !== 3) return false
  for (var index = 0; index < 3; index++) {
    if (current[index] !== required[index]) return current[index] > required[index]
  }
  return true
}

function parseSnippets(raw) {
  var result = parseJson(raw, [], "snippets")
  if (result.error || !(result.value instanceof Array))
    return { snippets: [], error: result.error || qsTr("Could not read snippets") }
  return { snippets: result.value, error: "" }
}

function parseDoctor(raw) {
  var result = parseJson(raw, {}, "diagnostics")
  if (result.error || !(result.value.checks instanceof Array))
    return { ok: false, checks: [], error: result.error || qsTr("Could not read diagnostics") }
  return { ok: result.value.ok === true, checks: result.value.checks, error: "" }
}

function filterSnippets(snippets, query) {
  var needle = String(query || "").trim().toLowerCase()
  if (!needle) return snippets.slice()
  return snippets.filter(function(snippet) {
    return String(snippet.label || "").toLowerCase().indexOf(needle) !== -1
      || String(snippet.trigger || "").toLowerCase().indexOf(needle) !== -1
      || String(snippet.replacement || "").toLowerCase().indexOf(needle) !== -1
      || (snippet.search_terms || []).some(function(term) {
        return String(term).toLowerCase().indexOf(needle) !== -1
      })
  })
}

function preview(text, limit) {
  var value = String(text || "").replace(/\s+/g, " ").trim()
  return value.length > limit ? value.substring(0, limit - 1) + "…" : value
}
