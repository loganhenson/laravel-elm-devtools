window.addEventListener('elm-ready', () => {
  window.addEventListener('message', function (event) {
    if (event.source !== window || event.data.type !== 'laravel-elm-devtools') {
      return
    }

    chrome.runtime.sendMessage(event.data.data)
  })
})

chrome.runtime.onMessage.addListener((message) => {
  if (message.startsWith('laravel-elm-devtools')) {
    window.dispatchEvent(new CustomEvent(message))
  }
})
