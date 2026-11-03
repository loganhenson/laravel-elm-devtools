import { parse } from './js/parser.js'

if (chrome.devtools.panels.themeName === 'dark') {
  document.documentElement.classList.add('dark')
}

const app = Elm.Main.init({ node: document.getElementById('app') })

// In debug mode Laravel Elm posts the current page to its window:
//   window.postMessage({ type: 'laravel-elm-devtools', data: { page, url, props, state, ports } })
// and posts it again when it receives a `laravel-elm-devtools-connect` event.
//
// The panel reads those messages with devtools.inspectedWindow.eval, which needs no extension
// permissions (no content script, no host permissions). The first poll in each document installs
// a small hook that keeps the latest message, and asks Laravel Elm to post its current page; later
// polls return the latest message when it changed. `doc` changes on every full page load.
const HOOK = '__laravelElmDevtools'
const POLL_MS = 250

const pollExpression = (doc, seq) => `(() => {
  let hook = window.${HOOK}
  if (!hook) {
    hook = window.${HOOK} = { doc: Math.random().toString(36).slice(2), seq: 0, latest: null }
    window.addEventListener('message', (event) => {
      if (event.source === window && event.data && event.data.type === 'laravel-elm-devtools') {
        hook.seq++
        hook.latest = event.data.data
      }
    })
    window.dispatchEvent(new CustomEvent('laravel-elm-devtools-connect'))
  }
  const changed = hook.doc !== ${JSON.stringify(doc)} || hook.seq !== ${seq}
  return { doc: hook.doc, seq: hook.seq, latest: changed ? hook.latest : undefined }
})()`

let doc = null
let seq = -1
let polling = false

function poll() {
  if (polling || document.hidden) {
    return
  }
  polling = true

  chrome.devtools.inspectedWindow.eval(pollExpression(doc, seq), (result, error) => {
    polling = false

    // Pages DevTools can't script (chrome://, the Web Store, a page that is still loading).
    if (error || !result) {
      if (doc !== null) {
        doc = null
        seq = -1
        app.ports.pageNavigated.send(null)
      }
      return
    }

    if (result.doc !== doc) {
      // A new document (full page load): clear the panel until it posts a Laravel Elm page.
      doc = result.doc
      seq = -1
      app.ports.pageNavigated.send(null)
    }

    if (result.seq !== seq && result.latest) {
      seq = result.seq
      send(result.latest)
    }
  })
}

// Laravel Elm sends the state as a `Debug.toString` string; parse it here so the panel can
// show it as a tree (and fall back to the raw string if it can't).
function parseState(state) {
  if (typeof state !== 'string') {
    return null
  }

  try {
    return { ast: parse(state) }
  } catch (error) {
    return { error: error.message, raw: state }
  }
}

function send(data) {
  app.ports.receivePage.send({
    page: data.page ?? '',
    url: data.url ?? '',
    props: data.props ?? null,
    state: parseState(data.state),
    ports: Array.isArray(data.ports) ? data.ports : [],
  })
}

// The refresh button: ask Laravel Elm to post its current page again.
app.ports.requestPage.subscribe(() => {
  chrome.devtools.inspectedWindow.eval("window.dispatchEvent(new CustomEvent('laravel-elm-devtools-connect'))")
  poll()
})

document.addEventListener('visibilitychange', poll)
setInterval(poll, POLL_MS)
poll()
