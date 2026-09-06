const assert = require("node:assert/strict")
const path = require("node:path")

const values = new Map()
const listeners = {}
let fetches = 0
let tokensAvailable = false
const timers = []

global.document = {
  documentElement: {
    style: { setProperty: (name, value) => values.set(name, value) },
  },
}
global.window = {
  GetParentResourceName: () => "consumer",
  addEventListener: (name, callback) => { listeners[name] = callback },
  setTimeout: (callback, delay) => {
    assert.equal(delay, 250)
    timers.push(callback)
    return timers.length
  },
}
global.fetch = async (url, options) => {
  fetches += 1
  assert.equal(url, "https://consumer/qbtheme:ready")
  assert.equal(options.method, "POST")
  return { ok: tokensAvailable, json: async () => ({ primary: "348 83.3% 47.1%", background: "0 0% 6.3%" }) }
}

require(path.join(__dirname, "..", "theme.js"))

setImmediate(async () => {
  assert.equal(fetches, 1)
  assert.equal(timers.length, 1)
  tokensAvailable = true
  timers.shift()()
  await new Promise(setImmediate)
  assert.equal(fetches, 2)
  assert.equal(values.get("--primary"), "348 83.3% 47.1%")

  listeners.message({ origin: "https://untrusted.example", data: { action: "qbtheme:tokens", data: { primary: "bad" } } })
  assert.equal(values.get("--primary"), "348 83.3% 47.1%")

  listeners.message({ origin: "nui://game", data: { action: "qbtheme:tokens", data: {
    primary: "262.1 83.3% 57.8%",
    "Bad!": "ignored",
    warning: 123,
    info: "x".repeat(161),
  } } })
  assert.equal(values.get("--primary"), "262.1 83.3% 57.8%")
  assert.equal(values.has("--Bad!"), false)
  assert.equal(values.has("--warning"), false)
  assert.equal(values.has("--info"), false)

  await window.QBTheme.refresh()
  assert.equal(fetches, 3)

  delete window.GetParentResourceName
  await window.QBTheme.refresh()
  assert.equal(fetches, 3)
  console.log("qbtheme browser loader: 12 assertions passed")
})
