import { parse } from './js/parser.js'

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
    props: {props: message.props},
    state: message.state ? ({state: parse(`_:${message.state}`).value.value}) : {state: {}},
  }})
})

// Tell background script which tab we want to receive messages from
backgroundConnection.postMessage(
  {
    tabId: chrome.devtools.inspectedWindow.tabId,
  }
)
