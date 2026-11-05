// An Enemy Within unit's animations under XCOM 2's names (features/lw-ew-units.md): XCOM 2's unit code plays a unit's
// animations by name (NO_IdleGunUpA, MV_RunFwd_StartA, HL_StepOutA …); EW's skeletons have other bone names, so XCOM 2's
// own animations cannot move EW's bodies, and EW's must answer to XCOM 2's names. In the unit's converted package
// (ew-package.ts), each EW animation that stands for an XCOM 2 name gets a copy carrying that name in the same AnimSet.
// Names only: which EW animation stands for which XCOM 2 one (EW names them the same way with an AC_ prefix, and
// otherwise where the games differ).
//
//   node tools/convert/ew-unit-anims.ts <converted unit .upk> <AnimSet path> <out .upk>
import { readFileSync, writeFileSync } from 'node:fs'
import { openPackage, type Export, type NameEntry } from '@innonova/upkit/package'
import { Reader, Writer } from '@innonova/upkit/bytes'
import { readTags, type Tag } from '@innonova/upkit/objects'
import { writePackage } from '@innonova/upkit/writer'
import { Package } from '@innonova/upkit/upk'
import { decodeSequence, encodePerTrack, mirrorSequence, readBones, readSkeleton, sampleSequence, type Skeleton } from './ew-anim-mirror.ts'

import { X2_ANIM_NAMES } from './x2-anim-names.ts'
/** The names XCOM 2's Sectoid answers to (kept for ew-package.ts --anims). */
export const X2_SECTOID = X2_ANIM_NAMES.Sectoid!

/**
 * Names a template's own animation sets lack that are asked for on it (features/lw-aliens.md): the Floater's Launch is
 * played as XCOM 2's teleport (the Codex's), its start and stop; the Seeker's Strangle as XCOM 2's Bind (the Viper's); and
 * the Cyberdisc's closed and open states, EW's own, which the tree it plays under asks for by EW's names (without the
 * closed state its petals stood in their reference pose, spikes all round).
 */
export const ABILITY_ANIMS: Record<string, string[]> = {
  Gatekeeper: ['MV_JetClosedState', 'MV_JetOpenState'],
  Archon: ['HL_TeleportStartA', 'HL_TeleportStopA'],
  Faceless: ['NO_BindStartA', 'NO_BindLoopA', 'NO_BindStopA', 'NO_BindHurtA', 'HL_BindDeathA'],
}

/** Where the rules below do not reach: the EW animation for an XCOM 2 name (first that the unit has). */
const TABLE: Record<string, string[]> = {
  HL_TeleportStartA: ['AC_NO_JetUpGround_StartA'], HL_TeleportStopA: ['AC_NO_JetDownGround_StopA'],
  NO_BindStartA: ['AC_NO_Strangle_StartA'], NO_BindLoopA: ['AC_NO_Strangle_LoopA'], NO_BindStopA: ['AC_NO_Strangle_StopA'],
  NO_IdleGunUpA: ['AC_NO_IdleA'], NO_IdleGunDwnA: ['AC_NO_IdleA'],
  NO_IdleAlertGunUpA: ['AC_NO_IdleOnAlertA', 'AC_NO_IdleA'], NO_IdleAlertGunDwnA: ['AC_NO_IdleOnAlertA', 'AC_NO_IdleA'],
  HL_IdleAlertA: ['AC_HL_IdleB', 'AC_HL_IdleA'], LL_IdleAlertA: ['AC_LL_IdleA'],
  NO_FireStartA: ['AC_NO_EquipOnA'], NO_FireStopA: ['AC_NO_EquipOffA'],
  HL_FireStartA: ['AC_HL_Cover2FocusFire90', 'AC_HL_EquipOnA'], HL_FireStopA: ['AC_HL_FocusFire2Cover90', 'AC_HL_EquipOffA'],
  LL_FireStartA: ['AC_LL_Cover2FocusFire90', 'AC_LL_EquipOnA'], LL_FireStopA: ['AC_LL_FocusFire2Cover90', 'AC_LL_EquipOffA'],
  HL_StepOutA: ['AC_HL_Cover2FocusFire90'], HL_StepInA: ['AC_HL_FocusFire2Cover90', 'AC_HL_FocusFire2CoverA', 'AC_HL_StayFocusFire2Cover90'],
  HR_StepOutA: ['AC_HR_Cover2FocusFire90'], HR_StepInA: ['AC_HR_FocusFire2Cover90', 'AC_HR_FocusFire2CoverA'],
  HL_Run2CoverA: ['AC_HL_Run2CoverStopA'], HR_Run2CoverA: ['AC_HR_Run2CoverStopA'],
  LL_Run2CoverA: ['AC_LL_Run2CoverStopA'], LR_Run2CoverA: ['AC_LR_Run2CoverStopA'], LL_Rush2CoverA: ['AC_LL_Run2CoverStopA'], HL_Rush2CoverA: ['AC_HL_Run2CoverStopA'], HR_Rush2CoverA: ['AC_HR_Run2CoverStopA'],
  HL_Peek_StartA: ['AC_HL_SideLookStartA'], HL_Peek_LoopA: ['AC_HL_SideLookA'], HL_Peek_StopA: ['AC_HL_SideLookStartA'],
  HR_Peek_StartA: ['AC_HL_SideLookStartA'], HR_Peek_LoopA: ['AC_HL_SideLookA'], HR_Peek_StopA: ['AC_HL_SideLookStartA'],
  HL_PeekFwd_StartA: ['AC_HL_SideLookStartA'], HL_PeekFwd_LoopA: ['AC_HL_SideLookA'], HL_PeekFwd_StopA: ['AC_HL_SideLookStartA'],
  LL_Peek_StartA: ['AC_LL_OverLookStartA'], LL_Peek_LoopA: ['AC_LL_OverLookA'], LL_Peek_StopA: ['AC_LL_OverLookStartA'],
  LR_Peek_StartA: ['AC_LL_OverLookStartA'], LR_Peek_LoopA: ['AC_LL_OverLookA'], LR_Peek_StopA: ['AC_LL_OverLookStartA'],
  HL_FlinchA: ['AC_HL_FlinchStartA'], HR_FlinchA: ['AC_HL_FlinchStartA'], MV_RunFlinchA: ['AC_NO_HurtFrontA'],
  HL_HurtLeftA: ['AC_HL_HurtFrontA'], HL_HurtRightA: ['AC_HL_HurtFrontA'],
  HL_DeathA: ['AC_NO_DeathA'], HL_DeathB: ['AC_NO_DeathA'], HL_DeathDefaultA: ['AC_NO_DeathA'], HL_DeathFiringA: ['AC_NO_DeathA'],
  HL_DeathGrenadeA: ['AC_NO_DeathA'], HL_DeathLeftA: ['AC_NO_DeathA'], HL_DeathRightA: ['AC_NO_DeathA'], HL_MeleeDeathA: ['AC_NO_kineticstrikedeathA', 'AC_NO_DeathA'],
  HL_GetUpA: ['AC_NO_GetUp_ReAnimateA'], HL_Psi_ReAnimateA: ['AC_NO_GetUp_ReAnimateA'],
  HL_Panic_StartA: ['AC_HL_Panicked_StartA'], HL_Panic_LoopA: ['AC_NO_Panicked_LoopA'], HL_Panic_StopA: ['AC_NO_IdleA'],
  HL_StunnedStartA: ['AC_NO_SuppressFlinchA'], HL_StunnedIdleA: ['AC_NO_SuppressIdleA'], HL_StunnedStopA: ['AC_NO_IdleA'],
  HL_Psi_MindControlledA: ['AC_HL_Possessed_StartA', 'AC_NO_Possessed_StartA'], HL_Psi_ProjectileMediumA: ['AC_NO_Psi_Panic'],
  HL_Psi_ExplosionStartA: ['AC_NO_Psi_MindFray'], HL_Psi_ExplosionLoopA: ['AC_NO_Psi_MindFray'], HL_Psi_ExplosionStopA: ['AC_NO_IdleA'],
  NO_Psi_Explosion: ['AC_NO_Psi_MindFray'],
  HL_CallReinforcementsA: ['AC_NO_CallOthersA'],
  POD_RevealA: ['AC_NO_CallOthersA', 'AC_NO_IdleOnAlertA'], POD_RevealB: ['AC_NO_IdleOnAlertA', 'AC_NO_CallOthersA'], POD_RevealC: ['AC_NO_IdleOnAlertA', 'AC_NO_CallOthersA'],
  HL_SignalPointA: ['AC_NO_CallOthersA'], HL_SignalPointAttackA: ['AC_NO_CallOthersA'], HL_SignalPointFlankedA: ['AC_NO_CallOthersA'],
  HL_SignalPositiveA: ['AC_NO_IdleOnAlertA'], HL_SignalNegativeA: ['AC_NO_IdleOnAlertA'],
  HL_Stand2CrouchA: ['AC_LL_Cover2IdleA', 'AC_LL_IdleA'], LL_Crouch2StandA: ['AC_HL_IdleA'],
  NO_DoorOpenA: ['AC_HL_Door_OpenFarA'], HL_DoorOpenA: ['AC_HL_Door_OpenFarA'], HR_DoorOpenA: ['AC_HL_Door_OpenFarA'],
  MV_DoorOpenBreakA: ['AC_NO_Door_OpenBreakA'], NO_WindowBreakA: ['AC_NO_WindowBreakThroughA'], MV_WindowBreakThroughA: ['AC_NO_WindowBreakThroughA'],
  HR_WindowBreakA: ['AC_HL_WindowBreakA'], LR_WindowBreakA: ['AC_LL_WindowBreakA'],
  MV_RunFwd_StartA: ['MV_RunFwdA'], MV_RunFwd_StopStandA: ['MV_RunFwd_StopA'], MV_RunFwd_StopCrouchA: ['MV_RunFwd_StopA'],
  MV_RunLeft_StartA: ['MV_RunLeftA'], MV_RunRight_StartA: ['MV_RunRightA'],
  MV_RunBackLeft_StartA: ['MV_RunBackA'], MV_RunBackRight_StartA: ['MV_RunBackA'],
  MV_RunTurn90LeftA: ['MV_RunLeftA'], MV_RunTurn90RightA: ['MV_RunRightA'], MV_WalkFwdA: ['MV_RunFwdA'],
  MV_ClimbDropHigh_StartA: ['AC_NO_ClimbHighDrop_StartA'], MV_ClimbDropHigh_StartWallA: ['AC_NO_ClimbHighDrop_StartB', 'AC_NO_ClimbHighDrop_StartA'],
  MV_ClimbDropHigh_StopA: ['AC_NO_ClimbHighDrop_StopA'], MV_ClimbDropLow_StartA: ['AC_NO_ClimbLowDrop_StartA', 'AC_NO_ClimbHighDrop_StartA'],
  MV_ClimbDropLow_StartWallA: ['AC_NO_ClimbLowDrop_StartB', 'AC_NO_ClimbLowDrop_StartA', 'AC_NO_ClimbHighDrop_StartB'], MV_ClimbDropLow_StopA: ['AC_NO_ClimbLowDrop_StopA', 'AC_NO_ClimbHighDrop_StopA'],
  MV_ClimbDrop_StartA: ['AC_NO_ClimbLowDrop_StartA', 'AC_NO_ClimbHighDrop_StartA'], MV_ClimbDrop_StartB: ['AC_NO_ClimbLowDrop_StartB', 'AC_NO_ClimbLowDrop_StartA', 'AC_NO_ClimbHighDrop_StartB'],
  MV_ClimbDrop_StopA: ['AC_NO_ClimbLowDrop_StopA', 'AC_NO_ClimbHighDrop_StopA'], MV_ClimbDrop_FurtherA: ['AC_NO_ClimbHighDrop_StopA'],
  MV_ClimbLowObject_UpA: ['AC_NO_ClimbLowObject_UpA'], MV_ClimbLowObject_DwnA: ['AC_NO_ClimbLowObject_DwnA'],
  MV_ClimbLowObject_Over1TileA: ['AC_NO_ClimbLowObject_OverA'], MV_ClimbLowObject_Over2TilesA: ['AC_NO_ClimbLowObject_OverA'],
  MV_ClimbDrainUp_StartA: ['AC_NO_ClimbLadderUp_StartA'], MV_ClimbDrainUp_StopA: ['AC_NO_ClimbLadderUp_StopA'],
  MV_ClimbDrainDwn_StartA: ['AC_NO_ClimbLadderDwn_StartA'], MV_ClimbDrainDwn_StopA: ['AC_NO_ClimbLadderDwn_StopA'],
  MV_ClimbLadderUp_StartA: ['AC_NO_ClimbLadderUp_StartA'], MV_ClimbLadderUp_StopA: ['AC_NO_ClimbLadderUp_StopA'],
  MV_ClimbLadderDwn_StartA: ['AC_NO_ClimbLadderDwn_StartA'], MV_ClimbLadderDwn_StopA: ['AC_NO_ClimbLadderDwn_StopA'],
}

/**
 * Last, by what the XCOM 2 animation does (for the species whose EW names differ most: the flyers, the crawlers, the
 * machines): the first EW animation of the candidates the unit has. Abilities of XCOM 2's own (Bind, Anima Gate …) that
 * Long War's aliens do not use stay unanswered.
 */
const KEYWORDS: [RegExp, string[]][] = [
  [/Fly(Up)?(Start|A$)|FlyUpA$/, ['AC_NO_JetUpAir_StartA', 'AC_NO_JetUpGround_StartA']],
  [/FlyUp(Loop|StartLoop)/, ['MV_JetUpAir_LoopA']],
  [/FlyUpStop/, ['AC_NO_JetUpAir_StopA']],
  [/FlyDwn(Start|A$)/, ['AC_NO_JetDownAir_StartA']],
  [/FlyDwnLoop/, ['MV_JetDownAir_LoopA']],
  [/FlyDwnStop/, ['AC_NO_JetDownGround_StopA', 'AC_NO_JetDownAir_StopA']],
  [/^NO_OpenA$/, ['AC_NO_Open']],
  [/^NO_CloseA$/, ['AC_NO_Close']],
  [/FireSuppressIdle/, ['AC_NO_SuppressIdleA']],
  [/FireSuppress/, ['AC_NO_SuppressAttackFireA', 'FF_FireA']],
  [/^NO_FireStart/, ['AC_NO_SuppressAttackStartA', 'AC_NO_IdleOnAlertA']],
  [/^NO_FireStop/, ['AC_NO_IdleA']],
  [/Melee(Miss)?A$|MeleeStab|ClawsSlash|BiteStart|Counterattack/, ['AC_NO_MeleeAttackA', 'AC_NO_MeleeA', 'AC_NO_BullRushA', 'AC_NO_SwordAttackA']],
  [/Death/, ['AC_NO_DeathA', 'AC_NO_kineticstrikedeathA']],
  [/Hurt|Flinch/, ['AC_NO_HurtFrontA', 'AC_HL_HurtFrontA', 'AC_HL_FlinchA', 'AC_NO_SuppressFlinchA']],
  [/GetUp|Resurrect/, ['AC_NO_GetUp_ReAnimateA', 'AC_NO_IdleA']],
  [/Stunned|Hacked|ShutDown|Shutdown/, ['AC_NO_SuppressIdleA', 'AC_NO_IdleA']],
  [/Panic/, ['AC_NO_Panicked_LoopA', 'AC_HL_Panicked_StartA', 'AC_NO_Panicked_StartA']],
  [/MindControlled/, ['AC_NO_Possessed_StartA', 'AC_HL_Possessed_StartA']],
  [/Reload/, ['AC_NO_ReloadA', 'AC_HL_ReloadA']],
  [/Grenade|MicroMissiles|AcidBlob|ShellLauncher|PoisonSpit/, ['AC_NO_ThrowGrenadeA', 'FF_FireA']],
  [/^FF_Fire/, ['FF_FireA']],
  [/Rage|Psychosis/, ['AC_NO_BloodCallA', 'AC_NO_CallOthersA']],
  [/Signal|Reveal/, ['AC_NO_CallOthersA', 'AC_NO_CallOthers', 'AC_NO_SignalVictoryA', 'AC_NO_IdleOnAlertA']],
  [/ClimbHighJump_Start/, ['AC_NO_ClimbHighJump_StartA']],
  [/ClimbHighJump_Stop/, ['AC_NO_ClimbHighJump_StopA', 'AC_NO_ClimbHighJump_StopB']],
  [/Hatch/, ['AC_NO_HatchA']],
]

/** The EW animation for an XCOM 2 name: the same name, its AC_ form, the table, the turns (EW turns only moving), then by
 *  what it does (KEYWORDS). */
export function ewFor(x2: string, ew: Set<string>): string | undefined {
  if (ew.has(x2)) return x2
  if (ew.has('AC_' + x2)) return 'AC_' + x2
  for (const c of TABLE[x2] ?? []) if (ew.has(c)) return c
  const turn = /^(?:HL|LL|NO|MV|MV_Low)_?Turn(Left|Right)(\d+)$/.exec(x2.replace('MV_LowTurn', 'MV_Turn'))
  if (turn && ew.has(`MV_Turn${turn[1]}${turn[2]}`)) return `MV_Turn${turn[1]}${turn[2]}`
  const signal = /^(HL|LL)_SignalLookAt/.exec(x2)
  if (signal && ew.has('AC_NO_IdleOnAlertA')) return 'AC_NO_IdleOnAlertA'
  // Cover: EW plays the right side by mirroring the left (its own right-side sequences are empty), and its small units (the
  // Sectoid) take low cover as high: their low-cover sequences are empty. So the right side falls back to the left, low
  // cover to high.
  const cover = /^(L|H)(L|R)_(.+)$/.exec(x2)
  if (cover) {
    const left = cover[2] === 'R' ? ewFor(`${cover[1]}L_${cover[3]}`, ew) : undefined
    if (left) return left
    const high = cover[1] === 'L' ? ewFor(`H${cover[2]}_${cover[3]}`, ew) : undefined
    if (high) return high
  }
  for (const [re, candidates] of KEYWORDS) if (re.test(x2)) for (const c of candidates) if (ew.has(c)) return c
  // Last, the unit's idle: an action EW's unit has no animation for (a Thin Man's ladder, a window broken through, a Seeker's
  // panic) played as nothing holds it in its reference pose, arms out; standing idle is the lesser fault. Not the additive
  // layers (an idle added on top of a pose distorts it).
  if (!/^ADD_|Zero/.test(x2)) for (const c of ['AC_NO_IdleA', 'AC_HL_IdleA', 'AC_NO_IdleOnAlertA']) if (ew.has(c)) return c
  return undefined
}

/** Whether a sequence has its compressed animation: the byte array that ends the object, not empty. */
function hasAnimationData(d: Uint8Array, propsEnd: number): boolean {
  const v = new DataView(d.buffer, d.byteOffset, d.byteLength)
  for (let o = propsEnd; o + 4 <= d.length; o++) {
    const n = v.getInt32(o, true)
    if (n > 0 && o + 4 + n === d.length) return true
  }
  return false
}

/** The converted unit package with the AnimSet's sequences also under XCOM 2's names; returns its bytes and a report. */
export function renameAnims(source: Uint8Array, animSetPaths: string | string[], x2Names: string[], reencode = false): { bytes: Uint8Array; report: string } {
  // The copies go into the first set; the EW animations they copy may be in any of them.
  const paths = typeof animSetPaths === 'string' ? [animSetPaths] : animSetPaths
  const animSetPath = paths[0]!
  const pkg: any = openPackage(source)
  const names: NameEntry[] = []
  const added: { entry: Export; data: Uint8Array }[] = []
  const data = new Map<number, Uint8Array>()
  const nameFlags: bigint = pkg.names[pkg.names.findIndex((n: NameEntry) => n.name === 'None')].flags
  const namesByText = new Map<string, number>()
  pkg.names.forEach((n: NameEntry, k: number) => { if (!namesByText.has(n.name)) namesByText.set(n.name, k) })
  const nameIndex = (s: string): number => {
    const i = namesByText.get(s)
    if (i !== undefined) return i
    names.push({ name: s, flags: nameFlags } as NameEntry)
    namesByText.set(s, pkg.names.length + names.length - 1)
    return pkg.names.length + names.length - 1
  }
  const nameOf = (r: any) => String(pkg.names[r.index ?? r]?.name)
  const pathOf = (ref: number): string => {
    if (ref <= 0) return ''
    const e = pkg.exports[ref - 1]
    const o = pathOf(e.outer ?? e.outerIndex)
    const n = nameOf(e.objectName) + ((e.objectName.number ?? 0) ? `_${e.objectName.number - 1}` : '')
    return (o ? o + '.' : '') + n
  }
  const setRef = pkg.exports.findIndex((_e: any, k: number) => pathOf(k + 1) === animSetPath) + 1
  if (setRef <= 0) throw new Error(`no AnimSet ${animSetPath}`)
  const i32 = (b: Uint8Array, o = 0) => new DataView(b.buffer, b.byteOffset).getInt32(o, true)

  // The AnimSet's sequences and their names.
  const setData: Uint8Array = pkg.data(setRef)
  const setReader = new Reader(setData.subarray(4))
  const setTags: Tag[] = readTags(setReader, pkg)
  const seqTag = setTags.find((t) => t.name === 'Sequences')
  if (!seqTag) throw new Error('the AnimSet lists no sequences')
  const seqs = Array.from({ length: i32(seqTag.value) }, (_, k) => i32(seqTag.value, 4 + 4 * k))
  const sources = [...seqs]
  for (const other of paths.slice(1)) {
    const ref = pkg.exports.findIndex((_e: any, k: number) => pathOf(k + 1) === other) + 1
    if (ref <= 0) continue
    const t = (readTags(new Reader((pkg.data(ref) as Uint8Array).subarray(4)), pkg) as Tag[]).find((x) => x.name === 'Sequences')
    if (t) for (let k = 0; k < i32(t.value); k++) sources.push(i32(t.value, 4 + 4 * k))
  }
  // The sequences by name, those without animation data left out: EW's cooker left the ones EW never plays empty (57 of the
  // Sectoid's 178: its low cover, its right side …), and played they hold the unit in its reference pose (the person's
  // posing Sectoids).
  // A sequence whose animation is another's (EW's cooker kept one copy of identical data: CompressedStreamRefIndex, an
  // index into the set's sequences, the Sectoid's EquipOff90A playing Cover2FocusFire90's) counts as having it; its copies
  // are made from that one's data (dataOf), so they need no reference.
  const byName = new Map<string, number>()
  const dataOf = new Map<number, number>()
  let empty = 0
  let shared = 0
  for (const s of sources) {
    const d: Uint8Array = pkg.data(s)
    const r = new Reader(d.subarray(4))
    let seqName = ''
    let refIndex = -1
    for (const t of readTags(r, pkg) as Tag[]) {
      if (t.name === 'SequenceName') seqName = nameOf(i32(t.value))
      else if (t.name === 'CompressedStreamRefIndex') refIndex = i32(t.value)
    }
    if (!seqName) continue
    if (!hasAnimationData(d, 4 + (r as any).o)) {
      const owner = refIndex >= 0 && refIndex < seqs.length ? seqs[refIndex]! : 0
      const od: Uint8Array | undefined = owner ? pkg.data(owner) : undefined
      if (!od || !hasAnimationData(od, 4 + (() => { const rr = new Reader(od.subarray(4)); readTags(rr, pkg); return (rr as any).o })())) {
        empty++
        continue
      }
      dataOf.set(s, owner)
      shared++
    }
    byName.set(seqName, s)
  }

  // A copy of each EW sequence an XCOM 2 name needs, its SequenceName that name (the tag's value found by its bytes).
  // The mirroring (ew-anim-mirror.ts): the unit's skeleton and mirror table, its tracks' bones, read once when needed.
  const upk = new Package(source)
  let mirrorCount = 0
  let rewriteCount = 0
  let skel: { skeleton: Skeleton; trackBones: number[] } | null | undefined
  const skeleton = () => {
    if (skel !== undefined) return skel
    skel = null
    const tb = setTags.find((t) => t.name === 'TrackBoneNames')
    if (!tb) return skel
    const tracks = Array.from({ length: i32(tb.value) }, (_, k) => nameOf(i32(tb.value, 4 + 8 * k)))
    // The unit's mesh: the skeletal mesh whose bones the tracks name.
    for (let k = 0; k < upk.exports.length && !skel; k++) {
      if (upk.exports[k]!.type !== 'SkeletalMesh') continue
      const sk = readSkeleton(upk, k, readBones)
      const trackBones = tracks.map((t) => sk.bones.findIndex((b) => b.name === t))
      if (trackBones.filter((b) => b >= 0).length >= tracks.length * 0.9) skel = { skeleton: sk, trackBones }
    }
    return skel
  }
  const canMirror = () => !!skeleton() && skel!.skeleton.mirror.length === skel!.skeleton.bones.length
  /** A copy's data with the sequence's animation written again per track (mirrored, or as it is): per-track keys, its
   *  offsets and compressed bytes replaced. */
  const mirroredData = (d: Uint8Array, src: number, mirror = true): Uint8Array | undefined => {
    const s = skel!
    const seq = decodeSequence(upk, src - 1, s.trackBones.length)
    const { rotations, positions } = mirror ? mirrorSequence(seq, s.skeleton, s.trackBones) : sampleSequence(seq, s.skeleton, s.trackBones)
    const { stream, offsets } = encodePerTrack(rotations, positions)
    const r = new Reader(d.subarray(4))
    const tags: Tag[] = readTags(r, pkg)
    const propsEnd = 4 + (r as any).o
    // The compressed bytes: the array that ends the object; what is between the properties and it, kept.
    const v = new DataView(d.buffer, d.byteOffset, d.byteLength)
    let streamAt = -1
    for (let o = propsEnd; o + 4 <= d.length; o++) {
      const n = v.getInt32(o, true)
      if (n > 0 && o + 4 + n === d.length) { streamAt = o; break }
    }
    if (streamAt < 0) return undefined
    const w = new Writer()
    w.bytes(d.subarray(0, 4))
    const nr = (x: string) => { w.i32(nameIndex(x)).i32(0) }
    const tag = (name: string, type: string, value: Uint8Array, arrayIndex = 0, sub?: string, bool?: number) => {
      nr(name)
      nr(type)
      w.i32(value.length).i32(arrayIndex)
      if (type === 'StructProperty' || type === 'ByteProperty') nr(sub ?? 'None')
      else if (type === 'BoolProperty') w.u8(bool ?? 0)
      w.bytes(value)
    }
    const nameValue = (x: string) => { const b = new Writer(); b.i32(nameIndex(x)).i32(0); return b.done() }
    const offsetsValue = (() => { const b = new Writer(); b.i32(offsets.length); offsets.forEach((o) => b.i32(o)); return b.done() })()
    let keyFormatWritten = false
    for (const t of tags) {
      if (t.name === 'KeyEncodingFormat') { tag(t.name, 'ByteProperty', nameValue('AKF_PerTrackCompression'), 0, t.enumName ?? 'AnimationKeyFormat'); keyFormatWritten = true }
      else if (t.name === 'CompressedTrackOffsets') tag(t.name, 'ArrayProperty', offsetsValue)
      else tag(t.name, t.type, t.value, t.arrayIndex, t.type === 'StructProperty' ? t.structName : t.enumName, t.boolValue)
    }
    if (!keyFormatWritten) tag('KeyEncodingFormat', 'ByteProperty', nameValue('AKF_PerTrackCompression'), 0, 'AnimationKeyFormat')
    nr('None')
    w.bytes(d.subarray(propsEnd, streamAt))
    w.i32(stream.length)
    w.bytes(stream)
    return w.done()
  }

  const copies: number[] = []
  const unmatched: string[] = []
  const ewNames = new Set(byName.keys())
  for (const x2 of x2Names) {
    if (byName.has(x2)) continue
    const ew = ewFor(x2, ewNames)
    if (!ew) { unmatched.push(x2); continue }
    const src = dataOf.get(byName.get(ew)!) ?? byName.get(ew)!
    const d = Uint8Array.from(pkg.data(src) as Uint8Array)
    // No network index of its own (the source's, copied, made the game log a duplicate for each copy).
    new DataView(d.buffer).setInt32(0, -1, true)
    // Find the SequenceName tag: name "SequenceName", type "NameProperty", size 8, index 0, then the value.
    const want = namesByText.get('SequenceName')!, nameProp = namesByText.get('NameProperty')!
    let patched = false
    for (let o = 4; o + 32 <= d.length; o += 4) {
      const dv = new DataView(d.buffer, d.byteOffset)
      if (dv.getInt32(o, true) === want && dv.getInt32(o + 8, true) === nameProp && dv.getInt32(o + 16, true) === 8) {
        dv.setInt32(o + 24, nameIndex(x2), true)
        dv.setInt32(o + 28, 0, true)
        patched = true
        break
      }
    }
    if (!patched) { unmatched.push(x2); continue }
    // XCOM 2's right side of cover, played by EW from its left side mirrored: the copy carries the mirrored animation.
    const mirrored = /^(L|H)R_/.test(x2) && /^AC_(L|H)L_/.test(ew) && canMirror() ? mirroredData(d, src) : undefined
    if (mirrored) mirrorCount++
    // Written again per track where asked (the Cyberdisc: XCOM 2 played its EW-compressed keys' rotations but not their
    // translations, its blades left in their reference pose).
    const rewritten = !mirrored && reencode && skeleton() ? mirroredData(d, src, false) : undefined
    if (rewritten) rewriteCount++
    const e = pkg.exports[src - 1]
    const r = nameIndex(`${nameOf(e.objectName)}_X2_${x2}`)
    added.push({ entry: { ...e, objectName: { index: r, number: 0 }, serialSize: 0, serialOffset: 0, netObjects: [] }, data: mirrored ?? rewritten ?? d })
    copies.push(pkg.exports.length + added.length)
  }

  // The AnimSet with the copies in its list.
  const all = [...seqs, ...copies]
  const w = new Writer()
  w.bytes(setData.subarray(0, 4))
  const nr = (s: string) => { w.i32(nameIndex(s)).i32(0) }
  for (const t of setTags) {
    const value = t.name === 'Sequences' ? (() => { const x = new Writer(); x.i32(all.length); all.forEach((s) => x.i32(s)); return x.done() })() : t.value
    nr(t.name)
    nr(t.type)
    w.i32(value.length).i32(t.arrayIndex)
    if (t.type === 'StructProperty') nr(t.structName!)
    else if (t.type === 'ByteProperty') nr(t.enumName ?? 'None')
    else if (t.type === 'BoolProperty') w.u8(t.boolValue ?? 0)
    w.bytes(value)
  }
  nr('None')
  w.bytes(setData.subarray(4 + (setReader as any).o))
  data.set(setRef, w.done())

  const bytes = writePackage(pkg, { data, names, imports: [], exports: added })
  return { bytes, report: `${animSetPath}: ${seqs.length} sequences (${empty} without animation data, ${shared} sharing another's), ${copies.length} copies under XCOM 2's names (${mirrorCount} mirrored${rewriteCount ? `, ${rewriteCount} written again per track` : ""}), ${unmatched.length} XCOM 2 names without an EW animation${unmatched.length ? ` (${unmatched.join(' ')})` : ''}` }
}

if (/ew-unit-anims\.ts$/.test(process.argv[1] ?? '')) {
  const [src, set, out] = process.argv.slice(2).filter((a) => a !== '--')
  if (!out) {
    console.error('usage: ew-unit-anims.ts <converted unit .upk> <AnimSet path> <out .upk>')
    process.exit(2)
  }
  const { bytes, report } = renameAnims(new Uint8Array(readFileSync(src!)), set!, X2_SECTOID)
  writeFileSync(out!, bytes)
  console.log(report)
}
