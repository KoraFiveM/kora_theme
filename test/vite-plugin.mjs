import assert from "node:assert/strict"
import kora_theme from "../vite-plugin.mjs"

const production = kora_theme()
production.configResolved({ command: "build" })
assert.equal(
  production.transformIndexHtml.handler('__KORA_THEME_BASE__/theme.css'),
  'https://cfx-nui-kora_theme/theme.css',
)

const development = kora_theme()
development.configResolved({ command: "serve" })
assert.equal(
  development.transformIndexHtml.handler('__KORA_THEME_BASE__/theme.js'),
  '/@kora_theme/theme.js?v=5',
)

let middleware
development.configureServer({ middlewares: { use: (handler) => { middleware = handler } } })
const headers = {}
let body
await middleware(
  { url: "/@kora_theme/theme.css?v=2" },
  {
    setHeader: (name, value) => { headers[name] = value },
    end: (value) => { body = value },
  },
  () => { throw new Error("theme request unexpectedly fell through") },
)
assert.match(String(headers["Content-Type"]), /text\/css/)
assert.match(String(body), /--font-sans:/)
assert.doesNotMatch(String(body), /--primary:/)

await middleware(
  { url: "/@kora_theme/theme.json" },
  {
    setHeader: (name, value) => { headers[name] = value },
    end: (value) => { body = value },
  },
  () => { throw new Error("theme.json request unexpectedly fell through") },
)
assert.match(String(headers["Content-Type"]), /application\/json/)
assert.equal(JSON.parse(String(body)).colors.primary, "#95FF00")

for (const [url, type, check] of [
  ["/@kora_theme/fonts/fonts.css", /text\/css/, (value) => assert.match(String(value), /@font-face/)],
  ["/@kora_theme/fonts/catalog.json", /application\/json/, (value) => assert.ok(JSON.parse(String(value)).fonts.length > 0)],
  ["/@kora_theme/fonts/inter/inter-latin-wght-normal.woff2", /font\/woff2/, (value) => assert.equal(value.subarray(0, 4).toString(), "wOF2")],
]) {
  await middleware(
    { url },
    {
      setHeader: (name, value) => { headers[name] = value },
      end: (value) => { body = value },
    },
    () => { throw new Error(`${url} unexpectedly fell through`) },
  )
  assert.match(String(headers["Content-Type"]), type)
  check(body)
}

let missing = false
await middleware({ url: "/@kora_theme/fonts/nope.woff2" }, {}, () => { missing = true })
assert.equal(missing, true)
let traversal = false
await middleware({ url: "/@kora_theme/fonts/../theme_loader.lua" }, {}, () => { traversal = true })
assert.equal(traversal, true)

let passed = false
await middleware({ url: "/ordinary.js" }, {}, () => { passed = true })
assert.equal(passed, true)

console.log("kora_theme Vite helper: 17 assertions passed")
