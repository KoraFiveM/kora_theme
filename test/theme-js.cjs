const assert = require("node:assert/strict")
const path = require("node:path")

const values = new Map()
const listeners = {}
let fetches = 0
let readyPings = 0

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
  return { ok: true, json: async () => ({ colors: {
    background: "#101010", surface: "#171717", surfacePopover: "#1B1B1B",
    surfaceRaised: "#242424", surfaceHover: "#2A2A2A", foreground: "#F5F5F5",
    mutedForeground: "#949494", border: "#343434", borderStrong: "#444444",
    control: "#666666", controlHover: "#7A7A7A", primary: "#95FF00",
    success: "#22C55E", warning: "#F59E0B", danger: "#EF4444", info: "#D4D4D4", armour: "#3B9EFF",
  } }) }
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
  console.log("qbtheme browser loader: 12 assertions passed")
})
