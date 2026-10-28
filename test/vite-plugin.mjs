import assert from "node:assert/strict"
import qbtheme from "../vite-plugin.mjs"

const production = qbtheme()
production.configResolved({ command: "build" })
assert.equal(
  production.transformIndexHtml.handler('__QBTHEME_BASE__/theme.css'),
  'https://cfx-nui-kora_theme/theme.css',
)

const development = qbtheme()
development.configResolved({ command: "serve" })
assert.equal(
  development.transformIndexHtml.handler('__QBTHEME_BASE__/theme.js'),
  '/@qbtheme/theme.js?v=3',
)

let middleware
development.configureServer({ middlewares: { use: (handler) => { middleware = handler } } })
const headers = {}
let body
await middleware(
  { url: "/@qbtheme/theme.css?v=2" },
  {
    setHeader: (name, value) => { headers[name] = value },
    end: (value) => { body = value },
  },
  () => { throw new Error("theme request unexpectedly fell through") },
)
assert.match(String(headers["Content-Type"]), /text\/css/)
assert.match(String(body), /--primary:/)

let passed = false
await middleware({ url: "/ordinary.js" }, {}, () => { passed = true })
assert.equal(passed, true)

console.log("qbtheme Vite helper: 6 assertions passed")
