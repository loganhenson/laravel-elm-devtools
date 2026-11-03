# Chrome Web Store listing

Copy/paste source for the [Developer Dashboard](https://chrome.google.com/webstore/devconsole). Images are in this
folder; the package is `dist/laravel-elm-devtools-<version>.zip` (`npm run package`) or the GitHub release asset.

## Package

Upload `laravel-elm-devtools-<version>.zip`.

## Store listing

**Description**

```
A Chrome DevTools panel for Laravel Elm (https://github.com/loganhenson/laravel-elm) apps.

Open DevTools on a Laravel Elm page and select the "Laravel Elm" panel to see:

• Props: the JSON your controller passed to Elm::render, including Laravel Elm's own (errors, loading, viewports).
• State: the page's state record, live, shown as Elm values (Just 1, Editing 2 "draft", Dict.fromList [...]). It updates after every Msg.
• Ports: the page's ports that JavaScript is subscribed to.
• The current page and URL. The panel follows Laravel Elm navigations and full page loads.

Nodes collapse and expand on click and stay collapsed as the state changes. The panel follows the DevTools light/dark theme.

Requirements: a Laravel Elm app in debug mode (APP_DEBUG=true or ELM_DEBUG=true). State is sent while the Vite dev server (npm run dev) is running; production builds compile it out.

Nothing leaves your browser: the extension only reads the messages Laravel Elm posts to the page and shows them in its DevTools panel.

Docs and source: https://github.com/loganhenson/laravel-elm-devtools
```

- **Category:** Developer Tools
- **Language:** English
- **Store icon (128×128):** `../icons/icon128.png`
- **Screenshots (1280×800):** `screenshot-1-model.png`, `screenshot-2-ports.png`
- **Small promo tile (440×280):** `promo-440x280.png`
- **Homepage URL:** https://github.com/loganhenson/laravel-elm-devtools
- **Support URL:** https://github.com/loganhenson/laravel-elm-devtools/issues

## Privacy

**Single purpose**

```
Debugging Laravel Elm web applications: it adds a DevTools panel that shows the props, state and ports of the Laravel Elm page being inspected.
```

**Host permission justification** (the content script runs on http/https pages)

```
Laravel Elm apps can run on any domain (localhost, *.test, staging and production hosts), so the content script runs on http(s) pages. It only listens for messages that Laravel Elm itself posts to the page (window.postMessage with type "laravel-elm-devtools", sent only when the app is in debug mode) and forwards them to the extension's own DevTools panel for the same tab. It does not read or modify page content, and sends nothing over the network.
```

**Remote code:** No, I am not using remote code. (All JavaScript is in the package.)

**Data usage:** check nothing. The extension does not collect or transmit any user data. Certify the three
statements (not sold to third parties; not used for unrelated purposes; not used for creditworthiness/lending).

**Privacy policy URL:** https://github.com/loganhenson/laravel-elm-devtools/blob/main/PRIVACY.md

## Distribution

- **Visibility:** Public
- **Regions:** All regions
