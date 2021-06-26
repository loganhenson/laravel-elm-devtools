(async () => {
  const src = chrome.extension.getURL('./content_main.js');
  const contentScript = await import(src);
  contentScript.main();
})();
