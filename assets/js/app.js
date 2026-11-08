// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/tldr"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const embedded = window.self !== window.top

// The reader's summaries, kept in this browser. Safari on a phone reloads
// the page after a switch to another app; the kept ones show at once, and
// the tab id finds the summaries still running on the server
// (docs/decisions/012). Storage can be off, so every access may fail.
const keptName = "tldr_kept"
const keptLimit = 50

const readKept = () => {
  try {
    return JSON.parse(localStorage.getItem(keptName)) || []
  } catch {
    return []
  }
}

// Only the ones for the addresses in the address bar go to the server.
const keptHere = () => {
  let decoded = location.href
  try { decoded = decodeURI(decoded) } catch {}
  return readKept().filter(({url}) => location.href.includes(url) || decoded.includes(url))
}

const tab = (() => {
  const random = () => crypto.randomUUID?.() ?? `${Date.now()}-${Math.random()}`
  try {
    const id = sessionStorage.getItem("tldr_tab") || random()
    sessionStorage.setItem("tldr_tab", id)
    return id
  } catch {
    return random()
  }
})()

// A new summary replaces the kept one of its address and language.
window.addEventListener("phx:tldr:keep", ({detail}) => {
  const others = readKept().filter(({url, language}) =>
    url !== detail.url || language !== detail.language)
  try {
    const kept = [{...detail, saved: Date.now()}, ...others].slice(0, keptLimit)
    localStorage.setItem(keptName, JSON.stringify(kept))
  } catch {}
})

// A function, so every reconnect sends what the browser keeps by then.
const liveSocket = new LiveSocket(embedded ? "/embedded-live" : "/live", Socket, {
  longPollFallbackMs: 2500,
  params: () => ({
    _csrf_token: csrfToken,
    tab,
    kept: keptHere(),
    offset: -new Date().getTimezoneOffset(),
  }),
  hooks: {...colocatedHooks},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#fff"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// The copy button of a summary: the text sits in its data-copy, the word
// it shows for a moment in data-copied, and the word itself in its
// [data-copy-label], beside the icon. The label is taken only when no
// timer runs, so a second click inside 1.5 s restores it too.
window.addEventListener("tldr:copy", ({target}) => {
  const label = target.querySelector("[data-copy-label]") || target
  navigator.clipboard.writeText(target.dataset.copy).then(() => {
    if (!target.copyTimer) target.dataset.label = label.textContent
    label.textContent = target.dataset.copied
    clearTimeout(target.copyTimer)
    target.copyTimer = setTimeout(() => {
      label.textContent = target.dataset.label
      target.copyTimer = null
    }, 1500)
  })
})

// The language switch: remember the choice for the next visit and keep
// the page's lang attribute true. The LiveView switches the words itself.
window.addEventListener("tldr:language", ({detail}) => {
  const name = embedded ? "tldr_embed_language" : "tldr_language"
  const attributes = embedded ? "samesite=none; secure; partitioned" : "samesite=lax"
  document.cookie = `${name}=${detail.language}; path=/; max-age=31536000; ${attributes}`
  document.documentElement.lang = detail.language
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// Safari on a phone freezes the page in the background, and its connection
// can die there without a word. Back on the page, the socket still looks
// open, so Phoenix notices only at its next heartbeat, up to a minute later,
// and a summary that finished meanwhile never shows. So on return we ping,
// and without an answer in time we connect again. The new page process gets
// the summary from its job (docs/decisions/012).
const pingTimeoutMs = 1500
let checking = false

const checkConnection = () => {
  const socket = liveSocket.getSocket()
  // A socket that knows it is closed reconnects by itself.
  if (document.visibilityState !== "visible" || checking || !socket.isConnected()) return
  checking = true
  const timer = setTimeout(() => {
    checking = false
    // Phoenix connects anew right away and lets the dead socket finish closing.
    liveSocket.disconnect()
    liveSocket.connect()
  }, pingTimeoutMs)
  socket.ping(() => {
    clearTimeout(timer)
    checking = false
  })
}

document.addEventListener("visibilitychange", checkConnection)
window.addEventListener("pageshow", checkConnection)
window.addEventListener("online", checkConnection)

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

