// EW's own materials made inert in a converted package (features/lw-missions.md, 2026-11-04): XCOM 2 cannot draw them (their
// shaders are not in its caches and the cooked materials carry no expressions to compile), yet every one it loads it tries
// to compile, about two seconds each: 53 in the person's log, half a minute and more of the game's start and of each
// mission's loading, for nothing drawn (the mod's stand-ins draw EW's things). Each Material (a parent; its instances stay)
// becomes an empty material instance (the package's MaterialInstanceConstant class, no properties: no parent): still a
// material wherever one is expected, nothing to compile, XCOM 2's default material if anything draws it. (As a plain
// object of another class, the game crashed loading the Sectoid's package.)
import { Package } from '@innonova/upkit/upk'
import { readProps } from './ew-anim-mirror.ts'

/** The package's Material exports turned into empty objects; returns the bytes with the stub they share appended. */
export function stubMaterials(bytes: Uint8Array): { bytes: Uint8Array; count: number } {
  const meta: any = new Package(bytes)
  const v = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)
  const donor = meta.exports.find((e: any) => e.type === 'MaterialInstanceConstant')
  // The materials and their instances: an instance with static permutations (the Sectoid's own) builds them from its parent
  // as it loads, and with its parent an empty instance the game crashed. Decal materials are left (their own class).
  const materials = meta.exports.filter((e: any) => e.type === 'Material' || e.type === 'MaterialInstanceConstant' || e.type === 'MaterialInstanceTimeVarying')
  if (!donor || materials.length === 0) return { bytes, count: 0 }
  const donorClass = v.getInt32(donor.entryOffset, true)
  const flagsLo = v.getUint32(donor.entryOffset + 24, true)
  const flagsHi = v.getUint32(donor.entryOffset + 28, true)
  const out = new Uint8Array(bytes.length + 12)
  out.set(bytes)
  const stubAt = bytes.length
  const o = new DataView(out.buffer)
  o.setInt32(stubAt, -1, true) // net index
  o.setInt32(stubAt + 4, meta.names.indexOf('None'), true) // no properties
  o.setInt32(stubAt + 8, 0, true)
  for (const e of materials) {
    const at = e.entryOffset
    o.setInt32(at + 0, donorClass, true) // class
    o.setInt32(at + 4, 0, true) // super
    o.setInt32(at + 20, 0, true) // archetype
    o.setUint32(at + 24, flagsLo, true)
    o.setUint32(at + 28, flagsHi, true)
    o.setInt32(at + 32, 12, true) // serial size
    o.setInt32(at + 36, stubAt, true) // serial offset
  }
  return { bytes: out, count: materials.filter((e: any) => e.type === 'Material').length }
}

/**
 * EW's particle effects that its animations start (AnimNotify_PlayParticleEffect: a Drone's muzzle flash on its own body,
 * the Floater's jets) left without a template, so they start nothing: their materials are made inert above, and the game
 * crashed as a Drone fired (the person's log and the test machine, 2026-11-04). XCOM 2's own shot effects still play.
 * Changes the bytes in place; returns how many.
 */
export function quietParticleNotifies(bytes: Uint8Array): number {
  const meta: any = new Package(bytes)
  const v = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)
  let n = 0
  for (const e of meta.exports) {
    if (e.type !== 'AnimNotify_PlayParticleEffect' || e.size <= 4) continue
    const { props } = readProps(meta, bytes.subarray(e.offset, e.offset + e.size))
    const ps = props.find((p) => p.name === 'PSTemplate' && p.size === 4)
    if (!ps) continue
    v.setInt32(e.offset + ps.at, 0, true)
    n++
  }
  return n
}
