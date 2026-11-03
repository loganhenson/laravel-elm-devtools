# Laravel Elm DevTools

A Chrome DevTools panel for [Laravel Elm](https://github.com/loganhenson/laravel-elm) apps. Open DevTools on a
Laravel Elm page and the **Laravel Elm** panel shows:

-   **Props**: the JSON your controller passed to `Elm::render`, including Laravel Elm's own (`errors`,
    `loading`, `viewports`, ...).
-   **State**: the page's `state` record, live, as Elm values (`Just 1`, `Editing 2 "draft"`,
    `Dict.fromList [...]`, ...). It updates after every `Msg`.
-   **Ports**: the page's ports that JavaScript is subscribed to.
-   The current page (`Admin.Users` → `resources/elm/pages/Admin/Users.elm`) and URL. The panel follows Laravel
    Elm navigations and full page loads.

Nodes collapse and expand on click, and stay collapsed as the state changes. The panel follows the DevTools
light/dark theme.

## Requirements

-   Chrome, Edge, Brave or another Chromium browser (version 116+).
-   A Laravel Elm app (`loganhenson/laravel-elm` 6.x with the `laravel-elm` 4.x Vite plugin; earlier versions use
    the same protocol) running in debug mode: `APP_DEBUG=true`, or `ELM_DEBUG=true` to enable it separately.
-   For **State**: the Vite dev server (`npm run dev` or `composer run dev`). Production builds (`npm run build`)
    compile the state messages out, because they rely on `Debug.toString`, which `elm make --optimize` does not
    allow. Props and ports still show.

## Installation

The extension is installed unpacked (it isn't in the Chrome Web Store).

### From a release

1. Download `laravel-elm-devtools-<version>.zip` from the
   [latest release](https://github.com/loganhenson/laravel-elm-devtools/releases/latest) and unzip it.
2. Open `chrome://extensions`, turn on **Developer mode** (top right).
3. Click **Load unpacked** and select the unzipped folder.

### From source

```bash
git clone https://github.com/loganhenson/laravel-elm-devtools.git
cd laravel-elm-devtools
npm install
npm run build
```

Then **Load unpacked** (as above) and select the `laravel-elm-devtools` folder.

To update later: `git pull && npm install && npm run build`, then click the reload icon on the extension in
`chrome://extensions`.

## Usage

1. Start your app in development: `composer run dev` (or `php artisan serve` and `npm run dev`).
2. Open a page rendered with `Elm::render`, open DevTools (F12 / ⌥⌘I), and select the **Laravel Elm** panel (it
   may be under `»`).
3. Interact with the page: **State** updates after every `Msg`, and the panel switches pages as you navigate.

The ⟳ button asks the page to send its props and state again.

### Troubleshooting

| Symptom                                    | Fix                                                                                                                                                                                                                                                              |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| "Waiting for a Laravel Elm page…"          | The page isn't rendered with `Elm::render`, or debug mode is off (`APP_DEBUG` / `ELM_DEBUG`). Pages opened before the extension was installed or reloaded need a refresh.                                                                                                       |
| No **Laravel Elm** panel in DevTools       | Close and reopen DevTools after installing the extension.                                                                                                                                                                                                        |
| "No state received yet"                    | You're running a production build: start `npm run dev`. If it is running, make sure the Vite plugin isn't configured with `laravelElm({ debug: false })`; with debug on, the dev server switches on the `sendStateToDevtools` line between `DEBUG_TOGGLE` comments in `resources/elm/laravel-elm-stuff/LaravelElm.elm`. |
| "Could not parse the state"                | Please [open an issue](https://github.com/loganhenson/laravel-elm-devtools/issues) with the raw state shown below the message.                                                                                                                                   |

## How it works

In debug mode Laravel Elm posts `{ type: 'laravel-elm-devtools', data: { page, url, props, state, ports } }` to
the window when a page loads, when props change and (in development builds) after every `Msg`. `state` is
`Debug.toString` of the page's state.

-   `content-script.js` relays those messages to the extension. It runs on every http(s) page, which is why
    Chrome says the extension can "read and change your data on all websites". It only reads messages Laravel
    Elm posts to the window, and only sends them to the extension's own DevTools panel.
-   `panel.js` (the DevTools panel) keeps the messages for the inspected tab, parses `state` with `js/parser.js`
    and hands both to the Elm app in `src/`.
-   When the panel opens, or when you click ⟳, it dispatches `laravel-elm-devtools-connect` in the page, and
    Laravel Elm answers with the current page.

Nothing leaves your browser.

## Development

```bash
npm install
npm run watch   # rebuilds built/elm.js and built/main.css on change
```

After a change, reload the extension in `chrome://extensions` and reopen DevTools. To debug the panel itself,
right-click inside it and choose **Inspect**.

| Path                                       | What                                                                     |
| ------------------------------------------ | ------------------------------------------------------------------------ |
| `src/Main.elm`                             | The panel UI.                                                            |
| `src/Inspector.elm`                        | The collapsible tree for props (JSON) and state (Elm values).            |
| `js/debug-string.peggy` → `js/parser.js`   | Parses `Debug.toString` output. Run `npm run build:parser` after editing the grammar. |
| `css/main.css`                             | Tailwind 4 entry point.                                                  |
| `panel.js`, `content-script.js`, `devtools.js`, `manifest.json` | Extension plumbing.                               |

### Releasing

1. Bump `version` in both `package.json` and `manifest.json`.
2. Commit, then tag and push: `git tag v3.0.1 && git push origin main v3.0.1`.

The **Release** workflow builds `dist/laravel-elm-devtools-<version>.zip` (`npm run package`) and attaches it to a
GitHub release for the tag. The same zip can be uploaded to the Chrome Web Store.

## License

MIT, see [LICENSE](LICENSE).
