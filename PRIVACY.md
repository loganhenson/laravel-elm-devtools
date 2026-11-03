# Privacy Policy

_Laravel Elm DevTools_ (the Chrome extension in this repository) does not collect, store, sell or transmit any
personal or user data.

-   It requests no permissions (no host permissions, no content scripts) and only runs while you have Chrome
    DevTools open on a tab and have opened its **Laravel Elm** panel.
-   The panel reads the debug messages a Laravel Elm app posts to its own page (`window.postMessage` with type
    `laravel-elm-devtools`, sent only when the app runs in debug mode): the page name, URL, props, state and port
    names. It displays them in DevTools and keeps them in memory only while DevTools is open. They never leave
    your browser.
-   The extension makes no network requests, uses no analytics, and stores nothing.

Questions: [open an issue](https://github.com/loganhenson/laravel-elm-devtools/issues).

_Last updated: 2026-11-03_
