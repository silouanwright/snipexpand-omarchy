const assert = require("node:assert/strict")
console.assert = assert
const fs = require("fs")
const vm = require("vm")

const source = fs.readFileSync("Model.js", "utf8").replace(/^\.pragma library\s*/, "")
const model = {
  qsTr: value => ({
    arg: replacement => String(value).replace("%1", replacement),
    toString: () => value
  })
}
vm.runInNewContext(source, model)

const status = model.parseStatus('{"running":true,"enabled":false,"version":"1.2.3","injection_backend":"wayland","triggers":4,"files":2,"config_valid":true}')
console.assert(status.running && !status.enabled && status.backend === "wayland" && status.triggers === 4)
console.assert(model.parseCliVersion("snipexpand 0.2.5") === "0.2.5")
console.assert(model.versionAtLeast("0.2.5", "0.2.5"))
console.assert(model.versionAtLeast("0.3.0", "0.2.5"))
console.assert(!model.versionAtLeast("0.2.4", "0.2.5"))
console.assert(!model.versionAtLeast("unknown", "0.2.5"))

const snippets = [
  { trigger: ";mail", label: "Email address", replacement: "hello@example.com" },
  { trigger: ";sig", replacement: "Best regards", search_terms: ["closing"] }
]
console.assert(model.filterSnippets(snippets, "MAIL").length === 1)
console.assert(model.filterSnippets(snippets, "address")[0].trigger === ";mail")
console.assert(model.filterSnippets(snippets, "regards")[0].trigger === ";sig")
console.assert(model.filterSnippets(snippets, "closing")[0].trigger === ";sig")
console.assert(model.preview("first\nsecond", 20) === "first second")
console.assert(model.parsePacks('[{"name":"arrows","enabled":true}]').packs[0].name === "arrows")
console.log("Model checks passed")

assert.equal(model.parseGroups('[{"name":"work","enabled":false,"members":3,"available":0}]').groups[0].enabled, false)
for (const input of ['null', '{}', 'bad', '[{"name":"work","enabled":"false"}]']) {
  assert(model.parseGroups(input).error)
}
assert.equal(model.filterSnippets([{trigger:";on"},{trigger:";off",available:false}], "").length, 1)
assert.equal(model.filterSnippets([{trigger:";off",available:false}], "off").length, 0)
