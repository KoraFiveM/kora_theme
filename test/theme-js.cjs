const assert = require("node:assert/strict")
const path = require("node:path")

const values = new Map()
const listeners = {}
let fetches = 0
let readyPings = 0
let catalogFetches = 0
let readyFonts
const catalog = JSON.parse(require("node:fs").readFileSync(path.join(__dirname, "..", "fonts", "catalog.json"), "utf8"))
const stackOf = (id) => catalog.fonts.find((font) => font.id === id).stack
// The browser loader must take every colour from theme.json, so the fixture is the real file.
let themeJson = JSON.parse(require("node:fs").readFileSync(path.join(__dirname, "..", "theme.json"), "utf8"))

global.document = {
  documentElement: {
    style: { setProperty: (name, value) => values.set(name, value), removeProperty: (name) => values.delete(name) },
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
    return { ok: true, json: async () => ({ overrides: "#22C55E", ...(readyFonts ? { fonts: readyFonts } : {}) }) }
  }
  if (url === "https://cfx-nui-kora_theme/fonts/catalog.json") {
    catalogFetches += 1
    return { ok: true, json: async () => catalog }
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

  // Default theme.json fonts leave theme.css in charge and skip the catalog.
  assert.equal(catalogFetches, 0)
  assert.equal(values.has("--font-sans"), false)

  // theme.json fonts: catalog ids, custom family lists, rejected CSS.
  const warn = console.warn
  const warnings = []
  console.warn = (message) => warnings.push(message)
  themeJson = { colors: { primary: "#1E90FF" }, fonts: { body: "Poppins", heading: "default", mono: "url(evil)" } }
  await window.QBTheme.refresh()
  assert.equal(catalogFetches, 1)
  assert.equal(values.get("--font-sans"), stackOf("poppins"))
  assert.equal(values.get("--font-heading"), stackOf("poppins"), "default heading follows the body font")
  assert.equal(values.has("--font-mono"), false, "invalid mono value is ignored")
  assert.equal(warnings.length, 1)
  themeJson = { colors: { primary: "#1E90FF" }, fonts: { body: "Arial, \"Helvetica Neue\"", heading: "oswald", mono: "a;}body{" } }
  await window.QBTheme.refresh()
  assert.equal(values.get("--font-sans"), `Arial, "Helvetica Neue", ${catalog.defaults.sans}`)
  assert.equal(values.get("--font-heading"), stackOf("oswald"))
  assert.equal(values.has("--font-mono"), false)
  console.warn = warn

  // qbtheme:fonts from the Lua bridge (/config) wins over theme.json; a
  // "default" source keeps the theme.json value.
  listeners.message({ origin: "https://untrusted.example", data: { action: "qbtheme:fonts", data: { body: { stack: "Evil", source: "config" } } } })
  assert.equal(values.get("--font-sans"), `Arial, "Helvetica Neue", ${catalog.defaults.sans}`)
  listeners.message({ origin: "nui://game", data: { action: "qbtheme:fonts", data: {
    body: { id: "roboto", stack: stackOf("roboto"), source: "config" },
    heading: { id: "default", stack: catalog.defaults.sans, source: "default" },
    mono: { id: "jetbrains-mono", stack: stackOf("jetbrains-mono"), source: "config" },
  } } })
  assert.equal(values.get("--font-sans"), stackOf("roboto"))
  assert.equal(values.get("--font-heading"), stackOf("oswald"), "default server heading keeps theme.json")
  assert.equal(values.get("--font-mono"), stackOf("jetbrains-mono"))
  listeners.message({ origin: "nui://game", data: { action: "qbtheme:fonts", data: { body: { stack: "x; } body { color: red", source: "config" } } } })
  assert.equal(values.get("--font-sans"), `Arial, "Helvetica Neue", ${catalog.defaults.sans}`, "unsafe server stack is ignored")
  listeners.message({ origin: "nui://game", data: { action: "qbtheme:fonts", data: null } })
  assert.equal(values.has("--font-mono"), false, "clearing server fonts restores theme.json/theme.css")

  // A freshly opened UI receives the /config fonts in the qbtheme:ready response.
  themeJson = { colors: { primary: "#1E90FF" } }
  readyFonts = { body: { id: "montserrat", stack: stackOf("montserrat"), source: "config" } }
  await window.QBTheme.refresh()
  assert.equal(values.has("--font-sans"), false)
  delete require.cache[require.resolve(path.join(__dirname, "..", "theme.js"))]
  require(path.join(__dirname, "..", "theme.js"))
  await new Promise((resolve) => setImmediate(resolve))
  assert.equal(values.get("--font-sans"), stackOf("montserrat"))
  assert.equal(values.get("--font-heading"), stackOf("montserrat"))
  console.log("qbtheme browser loader: 36 assertions passed")
})
