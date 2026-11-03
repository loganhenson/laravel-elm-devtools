import { parse } from './js/parser.js'

const tabId = chrome.devtools.inspectedWindow.tabId

if (chrome.devtools.panels.themeName === 'dark') {
  document.documentElement.classList.add('dark')
}

const app = Elm.Main.init({ node: document.getElementById('app') })

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

let lastPage = null

// Messages relayed by content-script.js, from every tab: only show the inspected one.
chrome.runtime.onMessage.addListener((message, sender) => {
  if (message?.source !== 'laravel-elm-devtools' || sender.tab?.id !== tabId) {
    return
  }

  const data = message.data ?? {}
  lastPage = { url: data.url, at: Date.now() }
  app.ports.receivePage.send({
    page: data.page ?? '',
    url: data.url ?? '',
    props: data.props ?? null,
    state: parseState(data.state),
    ports: Array.isArray(data.ports) ? data.ports : [],
  })
})

// Ask Laravel Elm in the inspected page to post its current page again (it listens for this
// event in debug mode). Used when the panel opens and by the refresh button.
app.ports.requestPage.subscribe(() => {
  chrome.devtools.inspectedWindow.eval(
    "window.dispatchEvent(new CustomEvent('laravel-elm-devtools-connect'))"
  )
})

// Navigations (full page loads, and Laravel Elm's own pushState visits). The new page posts
// itself as it boots, and that message can arrive before or after this event: only clear the
// panel when it isn't the page we just received (e.g. navigating to a non-Elm page).
chrome.devtools.network.onNavigated.addListener((url) => {
  let path = url
  try {
    const parsed = new URL(url)
    path = parsed.pathname + parsed.search
  } catch (e) {
    //
  }

  if (lastPage && lastPage.url === path && Date.now() - lastPage.at < 3000) {
    return
  }

  app.ports.pageNavigated.send(null)
})
