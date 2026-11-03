// Laravel Elm (in debug mode) posts the current page's props, state and ports to the window.
// Relay them to the Laravel Elm DevTools panel of this tab.
window.addEventListener('message', (event) => {
  if (event.source !== window || event.data?.type !== 'laravel-elm-devtools') {
    return
  }

  try {
    // Rejects when no DevTools panel is open; that's fine.
    chrome.runtime.sendMessage({ source: 'laravel-elm-devtools', data: event.data.data }).catch(() => {})
  } catch (e) {
    // The extension was reloaded or removed while this page was open.
  }
})
