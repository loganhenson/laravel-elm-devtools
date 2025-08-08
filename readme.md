# Laravel Elm DevTools

Browser extension for debugging Laravel Elm applications.

## Features

- **Props Inspector**: View all props passed to your Elm pages
- **State Inspector**: Debug Elm application state in real-time
- **Page Information**: See current page, URL, and navigation history
- **Port Monitoring**: Track active Elm ports and subscriptions

## Requirements

- Chrome/Chromium browser
- Laravel Elm v5.0+ with debug mode enabled
- Laravel 12+ application

## Installation

### Development

1. Clone this repository
2. Install dependencies:
   ```bash
   npm install
   ```
3. Build the extension:
   ```bash
   npm run build
   ```
4. Load the extension in Chrome:
   - Open Chrome and go to `chrome://extensions/`
   - Enable "Developer mode"
   - Click "Load unpacked"
   - Select the `laravel-elm-devtools` folder

### From Release

1. Download the latest release
2. Load the extension in Chrome as described above

## Usage

1. Open your Laravel Elm application in Chrome
2. Open Chrome DevTools (F12)
3. Look for the "Laravel Elm" tab in DevTools
4. Navigate through your Elm application to see props and state changes in real-time

## Debugging

The devtools automatically detect Laravel Elm applications with debug mode enabled. Make sure:

1. Your Laravel application has `APP_DEBUG=true` in `.env`
2. Your Vite config includes the `laravelElm` plugin with `debug: true`
3. Your Elm pages are properly initialized with the Laravel Elm framework

## Development

Watch for changes during development:
```bash
npm run watch
```

## Compatibility

- **Manifest Version**: v3 (Chrome Extensions API v3)
- **Laravel Elm**: v5.0+
- **Laravel**: 12.x+
- **PHP**: 8.4+

## License

MIT License - see [LICENSE](LICENSE) file for details.