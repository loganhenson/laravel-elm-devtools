// Rebuilds the panel while you work on it: Tailwind in watch mode + `elm make` on every
// change in src/. Reload the extension (chrome://extensions) and reopen DevTools to see changes.
import { spawn } from 'node:child_process'
import { watch } from 'node:fs'

const run = (command, args) => spawn(command, args, { stdio: 'inherit', shell: process.platform === 'win32' })

run('npx', ['tailwindcss', '-i', 'css/main.css', '-o', 'built/main.css', '--watch'])

let running = null
let queued = false
const make = () => {
  if (running) {
    queued = true
    return
  }
  running = run('npx', ['elm', 'make', 'src/Main.elm', '--output', 'built/elm.js'])
  running.on('exit', () => {
    running = null
    if (queued) {
      queued = false
      make()
    }
  })
}

make()

let timer
watch('src', { recursive: true }, (event, file) => {
  if (file && file.endsWith('.elm')) {
    clearTimeout(timer)
    timer = setTimeout(make, 100)
  }
})
