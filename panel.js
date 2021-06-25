let app = Elm.Main.init({
  node: document.getElementById('app'),
  flags: {},
})

// Create a connection to the background page
let backgroundConnection = chrome.runtime.connect({
  name: 'laravel-elm-devtools'
})

app.ports.connect.subscribe(() => {
  chrome.tabs.query({ active: true, currentWindow: true }, function (tabs) {
    if (tabs?.[0]?.id) {
      chrome.tabs.sendMessage(tabs[0].id, 'laravel-elm-devtools-connect')
    }
  })
})

// Handle responses from the background page, if any
backgroundConnection.onMessage.addListener(function (message) {
  app.ports.receiveLaravelElm.send({...message, ...{
    props: JSON.stringify(message.props),
    state: message.state ? message.state : null,
  }})
})

// Tell background script which tab we want to receive messages from
backgroundConnection.postMessage(
  {
    tabId: chrome.devtools.inspectedWindow.tabId,
  }
)
