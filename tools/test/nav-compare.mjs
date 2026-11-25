#!/usr/bin/env node
// EW's base navigation against the port's, as tools/test/nav-walk.sh read them (features/nav-map.md): for each room, the
// menu entries each game has, and for each screen both have, the labels read on it in one game and not the other. A
// label is an OCR line with letters, its numbers, money and punctuation dropped (they change with the campaign), in
// capitals; two labels are the same when most of their words are (OCR misreads a letter or two). Lines that change with
// the campaign (soldiers' names, dates) show up as differences too: the table is read, not counted.
//   node tools/test/nav-compare.mjs [logs/nav/ew] [logs/nav/port] > logs/nav/compare.md
import { readFileSync, existsSync, readdirSync } from 'node:fs'
import { join } from 'node:path'

const [ewDir = 'logs/nav/ew', portDir = 'logs/nav/port'] = process.argv.slice(2)

function readIndex(dir) {
  const rows = readFileSync(join(dir, 'index.tsv'), 'utf8').trim().split('\n').slice(1).map((l) => l.split('\t'))
  return rows.map(([room, entry, screen, back, lines]) => ({ room, entry, screen, back, lines: Number(lines) }))
}
const slug = (s) => s.replace(/[ /:]/g, '_').replace(/[^A-Za-z0-9_-]/g, '')
function labels(dir, room, entry) {
  const f = join(dir, slug(room), (entry ? slug(entry) : '_room') + '.txt')
  if (!existsSync(f)) return []
  const out = new Set()
  for (const line of readFileSync(f, 'utf8').split('\n')) {
    const m = /^\d+ \d+ \d+ \d+ (.*)$/.exec(line)
    if (!m) continue
    const t = m[1].toUpperCase().replace(/§?\d[\d,.:%]*/g, ' ').replace(/[^A-Z' -]/g, ' ').replace(/\s+/g, ' ').trim()
    if (t.replace(/[^A-Z]/g, '').length >= 3) out.add(t)
  }
  return [...out]
}
const words = (t) => new Set(t.split(' ').filter((w) => w.length > 1))
function same(a, b) {
  if (a === b) return true
  const A = words(a), B = words(b)
  if (!A.size || !B.size) return false
  let n = 0
  for (const w of A) if (B.has(w)) n++
  return n / Math.max(A.size, B.size) >= 0.6
}
const onlyIn = (xs, ys) => xs.filter((x) => !ys.some((y) => same(x, y)))

const ew = readIndex(ewDir), port = readIndex(portDir)
const rooms = [...new Set([...ew, ...port].map((r) => r.room))]
const out = ['# EW\'s base navigation against the port\'s', '', `From ${ewDir} and ${portDir} (tools/test/nav-walk.sh).`, '']
for (const room of rooms) {
  const e = ew.filter((r) => r.room === room && r.entry), p = port.filter((r) => r.room === room && r.entry)
  out.push(`## ${room}`, '')
  const eEntries = e.map((r) => r.entry), pEntries = p.map((r) => r.entry)
  const missing = onlyIn(eEntries, pEntries), extra = onlyIn(pEntries, eEntries)
  out.push(`- Menu: EW ${eEntries.length} entries, the port ${pEntries.length}.` + (missing.length ? ` **Only in EW:** ${missing.join('; ')}.` : '') + (extra.length ? ` **Only in the port:** ${extra.join('; ')}.` : ''))
  const roomOnlyEW = onlyIn(labels(ewDir, room, ''), labels(portDir, room, '')), roomOnlyPort = onlyIn(labels(portDir, room, ''), labels(ewDir, room, ''))
  if (roomOnlyEW.length || roomOnlyPort.length)
    out.push(`- The room's screen: only in EW: ${roomOnlyEW.join(' · ') || '-'}; only in the port: ${roomOnlyPort.join(' · ') || '-'}`)
  for (const r of e) {
    const q = p.find((x) => same(x.entry, r.entry))
    if (!q) continue
    const a = labels(ewDir, room, r.entry), b = labels(portDir, room, q.entry)
    const oe = onlyIn(a, b), op = onlyIn(b, a)
    const back = [r.back !== 'back' ? `EW's way back: ${r.back}` : '', q.back !== 'back' ? `**the port's way back: ${q.back}**` : ''].filter(Boolean).join('; ')
    out.push(`- **${r.entry}** (the port: ${q.screen || '?'}; ${a.length} labels in EW, ${b.length} in the port${back ? '; ' + back : ''})`)
    if (oe.length) out.push(`  - only in EW: ${oe.join(' · ')}`)
    if (op.length) out.push(`  - only in the port: ${op.join(' · ')}`)
  }
  out.push('')
}
console.log(out.join('\n'))
