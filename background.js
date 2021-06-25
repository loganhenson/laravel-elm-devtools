let connections = {}

chrome.runtime.onConnect.addListener(function (port) {

  let extensionListener = function (message) {
    // The original connection event doesn't include the tab ID of the
    // DevTools page, so we need to send it explicitly.
    if (message.tabId) {
      connections[message.tabId] = port
    }
  }

  // Listen to messages sent from the DevTools page
  port.onMessage.addListener(extensionListener)

  port.onDisconnect.addListener(function (port) {
    port.onMessage.removeListener(extensionListener)

    let tabs = Object.keys(connections)
    for (let i = 0, len = tabs.length; i < len; i++) {
      if (connections[tabs[i]] === port) {
        delete connections[tabs[i]]
        break
      }
    }
  })
})

// Receive message from content script and relay to the devTools page for the current tab
chrome.runtime.onMessage.addListener(function (request, sender) {
  // Messages from content scripts should have sender.tab set
  if (sender.tab) {
    let tabId = sender.tab.id
    if (tabId in connections) {
      connections[tabId].postMessage(request)
    }
  }

  return true
})
