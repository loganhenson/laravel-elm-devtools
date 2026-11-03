// Zips the files Chrome needs into dist/laravel-elm-devtools-<version>.zip, ready to "Load unpacked"
// (after unzipping) or to upload to the Chrome Web Store. Run via `npm run package`.
import { crc32, deflateRawSync } from 'node:zlib'
import { existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs'
import { join, sep } from 'node:path'

const FILES = [
  'manifest.json',
  'content-script.js',
  'devtools.html',
  'devtools.js',
  'panel.html',
  'panel.js',
  'js/parser.js',
  'built/elm.js',
  'built/main.css',
  'icons',
]

const manifest = JSON.parse(readFileSync('manifest.json', 'utf8'))
const pkg = JSON.parse(readFileSync('package.json', 'utf8'))
if (manifest.version !== pkg.version) {
  console.error(`manifest.json version (${manifest.version}) does not match package.json (${pkg.version}).`)
  process.exit(1)
}

const expand = (path) => (statSync(path).isDirectory() ? readdirSync(path).flatMap((f) => expand(join(path, f))) : [path])
const paths = FILES.flatMap((f) => {
  if (!existsSync(f)) {
    console.error(`Missing ${f}. Run \`npm run build\` first.`)
    process.exit(1)
  }
  return expand(f)
}).map((p) => p.replaceAll(sep, '/'))

// Minimal zip writer (deflate, no zip64): enough for a few hundred KB of extension files.
const local = []
const central = []
let offset = 0
for (const path of paths) {
  const data = readFileSync(path)
  const compressed = deflateRawSync(data, { level: 9 })
  const name = Buffer.from(path)
  const crc = crc32(data)
  const header = Buffer.alloc(30)
  header.writeUInt32LE(0x04034b50, 0)
  header.writeUInt16LE(20, 4) // version needed
  header.writeUInt16LE(0x0800, 6) // utf-8 names
  header.writeUInt16LE(8, 8) // deflate
  header.writeUInt32LE(0x00210000, 10) // 1980-01-01 00:00 (reproducible)
  header.writeUInt32LE(crc, 14)
  header.writeUInt32LE(compressed.length, 18)
  header.writeUInt32LE(data.length, 22)
  header.writeUInt16LE(name.length, 26)
  local.push(header, name, compressed)

  const entry = Buffer.alloc(46)
  entry.writeUInt32LE(0x02014b50, 0)
  entry.writeUInt16LE(20, 4)
  entry.writeUInt16LE(20, 6)
  entry.writeUInt16LE(0x0800, 8)
  entry.writeUInt16LE(8, 10)
  entry.writeUInt32LE(0x00210000, 12)
  entry.writeUInt32LE(crc, 16)
  entry.writeUInt32LE(compressed.length, 20)
  entry.writeUInt32LE(data.length, 24)
  entry.writeUInt16LE(name.length, 28)
  entry.writeUInt32LE(offset, 42)
  central.push(entry, name)
  offset += header.length + name.length + compressed.length
}
const centralSize = central.reduce((n, b) => n + b.length, 0)
const end = Buffer.alloc(22)
end.writeUInt32LE(0x06054b50, 0)
end.writeUInt16LE(paths.length, 8)
end.writeUInt16LE(paths.length, 10)
end.writeUInt32LE(centralSize, 12)
end.writeUInt32LE(offset, 16)

mkdirSync('dist', { recursive: true })
const out = `dist/laravel-elm-devtools-${pkg.version}.zip`
writeFileSync(out, Buffer.concat([...local, ...central, end]))
console.log(`${out} (${paths.length} files)`)
