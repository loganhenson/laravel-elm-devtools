# Privacy Policy

_Laravel Elm DevTools_ (the Chrome extension in this repository) does not collect, store, sell or transmit any
personal or user data.

-   Its content script runs on http(s) pages only to receive the debug messages a Laravel Elm app posts to its own
    page (`window.postMessage` with type `laravel-elm-devtools`, sent only when the app runs in debug mode). It does
    not read or change page content.
-   Those messages (the page name, URL, props, state and port names of the Laravel Elm page) are passed to the
    extension's DevTools panel for the same tab and displayed there. They are kept in memory only while DevTools is
    open, and never leave your browser.
-   The extension makes no network requests, uses no analytics, and stores nothing.

Questions: [open an issue](https://github.com/loganhenson/laravel-elm-devtools/issues).

_Last updated: 2026-11-03_
