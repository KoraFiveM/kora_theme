const assert = require("node:assert/strict")
const path = require("node:path")

const values = new Map()
const listeners = {}
let fetches = 0
let readyPings = 0
// The browser loader must take every colour from theme.json, so the fixture is the real file.
let themeJson = JSON.parse(require("node:fs").readFileSync(path.join(__dirname, "..", "theme.json"), "utf8"))

global.document = {
  documentElement: {
    style: { setProperty: (name, value) => values.set(name, value) },
  },
}
global.window = {
  addEventListener: (name, callback) => { listeners[name] = callback },
  setTimeout: () => { throw new Error("theme.json should load without retry") },
}
global.GetParentResourceName = () => "consumer"
global.fetch = async (url) => {
  if (url === "https://consumer/qbtheme:ready") {
    readyPings += 1
    return { ok: true, json: async () => ({ overrides: "#22C55E" }) }
  }
  fetches += 1
  assert.equal(url, "https://cfx-nui-kora_theme/theme.json")
  return { ok: true, json: async () => themeJson }
}

require(path.join(__dirname, "..", "theme.js"))

setImmediate(async () => {
  assert.equal(fetches, 1)
  assert.equal(readyPings, 1)
  assert.equal(values.get("--primary"), "142.1 70.6% 45.3%")
  assert.equal(values.get("--background"), "0 0% 6.3%")

  listeners.message({ origin: "https://untrusted.example", data: { action: "qbtheme:override", data: "#7C3AED" } })
  assert.equal(values.get("--primary"), "142.1 70.6% 45.3%")

  listeners.message({ origin: "nui://game", data: { action: "qbtheme:override", data: "#7C3AED" } })
  assert.equal(values.get("--primary"), "262.1 83.3% 57.8%")
  assert.equal(values.get("--background"), "0 0% 6.3%")

  listeners.message({ origin: "nui://game", data: { action: "qbtheme:override", data: { primary: "bad", warning: "#FDE047" } } })
  assert.equal(values.get("--primary"), "84.9 100% 50%")
  assert.equal(values.get("--primary-foreground"), "0 0% 6.3%")
  assert.equal(values.get("--warning"), "50.4 97.8% 63.5%")

  await window.QBTheme.refresh()
  assert.equal(fetches, 2)
  assert.equal(values.get("--warning"), "50.4 97.8% 63.5%")

  // Editing theme.json alone changes the output (no embedded fallback palette).
  listeners.message({ origin: "nui://game", data: { action: "qbtheme:override", data: null } })
  themeJson = { colors: { ...themeJson.colors, primary: "#1E90FF" } }
  await window.QBTheme.refresh()
  assert.equal(values.get("--primary"), "209.6 100% 55.9%")
  themeJson = { colors: { primary: "#1E90FF" } }
  values.clear()
  await window.QBTheme.refresh()
  assert.equal(values.get("--primary"), "209.6 100% 55.9%")
  assert.equal(values.has("--background"), false)
  assert.doesNotMatch(require("node:fs").readFileSync(path.join(__dirname, "..", "theme.js"), "utf8"), /#[0-9a-fA-F]{6}/)
  console.log("qbtheme browser loader: 17 assertions passed")
})
