# Contributing

```bash
npm install
npm run watch
```

Load the folder with **Load unpacked** in `chrome://extensions`, reload the extension after changes and reopen
DevTools. See [Development](readme.md#development) for the layout of the code.

Before opening a PR, run `npm run package` (it builds with `elm make --optimize`, which rejects `Debug` usage).
