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

/** The names XCOM 2's Sectoid answers to (its AnimSet AS_Sectoid). */
export const X2_SECTOID = [
  'FF_FireA', 'HL_CallReinforcementsA', 'HL_DeathA', 'HL_DeathB', 'HL_DeathDefaultA', 'HL_DeathFiringA', 'HL_DeathGrenadeA',
  'HL_DeathLeftA', 'HL_DeathRightA', 'HL_DoorOpenA', 'HL_FireStartA', 'HL_FireStopA', 'HL_FlinchA', 'HL_GetUpA', 'HL_HurtBackA',
  'HL_HurtFrontA', 'HL_HurtLeftA', 'HL_HurtRightA', 'HL_IdleA', 'HL_IdleAlertA', 'HL_MeleeDeathA', 'HL_Panic_LoopA', 'HL_Panic_StartA',
  'HL_Panic_StopA', 'HL_PeekFwd_LoopA', 'HL_PeekFwd_StartA', 'HL_PeekFwd_StopA', 'HL_Peek_LoopA', 'HL_Peek_StartA', 'HL_Peek_StopA',
  'HL_Psi_ExplosionLoopA', 'HL_Psi_ExplosionStartA', 'HL_Psi_ExplosionStopA', 'HL_Psi_MindControlledA', 'HL_Psi_ProjectileMediumA',
  'HL_Psi_ReAnimateA', 'HL_ReloadA', 'HL_Run2CoverA', 'HL_SignalLookAtBackLeft', 'HL_SignalLookAtBackRight', 'HL_SignalLookAtFwdLeft',
  'HL_SignalLookAtFwdRight', 'HL_SignalNegativeA', 'HL_SignalPointA', 'HL_SignalPointAttackA', 'HL_SignalPointFlankedA',
  'HL_SignalPositiveA', 'HL_Stand2CrouchA', 'HL_StepInA', 'HL_StepOutA', 'HL_StunnedIdleA', 'HL_StunnedStartA', 'HL_StunnedStopA',
  'HL_TurnLeft180', 'HL_TurnLeft45', 'HL_TurnLeft90', 'HL_TurnRight180', 'HL_TurnRight45', 'HL_TurnRight90', 'HL_WindowBreakA',
  'HR_DoorOpenA', 'HR_FlinchA', 'HR_Peek_LoopA', 'HR_Peek_StartA', 'HR_Peek_StopA', 'HR_Run2CoverA', 'HR_StepInA', 'HR_StepOutA',
  'HR_WindowBreakA', 'LL_Crouch2StandA', 'LL_FireStartA', 'LL_FireStopA', 'LL_IdleA', 'LL_IdleAlertA', 'LL_Peek_LoopA', 'LL_Peek_StartA',
  'LL_Peek_StopA', 'LL_Run2CoverA', 'LL_Rush2CoverA', 'LL_SignalLookAtBackLeft', 'LL_SignalLookAtBackRight', 'LL_SignalLookAtFwdLeft',
  'LL_SignalLookAtFwdRight', 'LL_TurnLeft180', 'LL_TurnLeft45', 'LL_TurnLeft90', 'LL_TurnRight180', 'LL_TurnRight45', 'LL_TurnRight90',
  'LL_WindowBreakA', 'LR_Peek_LoopA', 'LR_Peek_StartA', 'LR_Peek_StopA', 'LR_Run2CoverA', 'LR_WindowBreakA', 'MV_ClimbDrainDwn_LoopA',
  'MV_ClimbDrainDwn_StartA', 'MV_ClimbDrainDwn_StopA', 'MV_ClimbDrainUp_LoopA', 'MV_ClimbDrainUp_StartA', 'MV_ClimbDrainUp_StopA',
  'MV_ClimbDropHigh_StartA', 'MV_ClimbDropHigh_StartWallA', 'MV_ClimbDropHigh_StopA', 'MV_ClimbDropLow_StartA',
  'MV_ClimbDropLow_StartWallA', 'MV_ClimbDropLow_StopA', 'MV_ClimbDrop_FurtherA', 'MV_ClimbDrop_StartA', 'MV_ClimbDrop_StartB',
  'MV_ClimbDrop_StopA', 'MV_ClimbLadderDwn_LoopA', 'MV_ClimbLadderDwn_StartA', 'MV_ClimbLadderDwn_StopA', 'MV_ClimbLadderUp_LoopA',
  'MV_ClimbLadderUp_StartA', 'MV_ClimbLadderUp_StopA', 'MV_ClimbLowObject_DwnA', 'MV_ClimbLowObject_Over1TileA',
  'MV_ClimbLowObject_Over2TilesA', 'MV_ClimbLowObject_UpA', 'MV_DoorOpenBreakA', 'MV_LowTurnLeft180', 'MV_LowTurnLeft45',
  'MV_LowTurnLeft90', 'MV_LowTurnRight180', 'MV_LowTurnRight45', 'MV_LowTurnRight90', 'MV_RunBackLeft_StartA', 'MV_RunBackRight_StartA',
  'MV_RunFlinchA', 'MV_RunFwdA', 'MV_RunFwd_StartA', 'MV_RunFwd_StopCrouchA', 'MV_RunFwd_StopStandA', 'MV_RunLeft_StartA',
  'MV_RunRight_StartA', 'MV_RunTurn90LeftA', 'MV_RunTurn90RightA', 'MV_TurnLeft180', 'MV_TurnLeft45', 'MV_TurnLeft90',
  'MV_TurnRight180', 'MV_TurnRight45', 'MV_TurnRight90', 'MV_WalkFwdA', 'MV_WindowBreakThroughA', 'NO_DoorOpenA', 'NO_FireStartA',
  'NO_FireStopA', 'NO_IdleAlertGunDwnA', 'NO_IdleAlertGunUpA', 'NO_IdleGunDwnA', 'NO_IdleGunUpA', 'NO_Psi_Explosion', 'NO_TurnLeft180',
  'NO_TurnLeft45', 'NO_TurnLeft90', 'NO_TurnRight180', 'NO_TurnRight45', 'NO_TurnRight90', 'NO_WindowBreakA',
]

/** Where the rules below do not reach: the EW animation for an XCOM 2 name (first that the unit has). */
const TABLE: Record<string, string[]> = {
  NO_IdleGunUpA: ['AC_NO_IdleA'], NO_IdleGunDwnA: ['AC_NO_IdleA'],
  NO_IdleAlertGunUpA: ['AC_NO_IdleOnAlertA', 'AC_NO_IdleA'], NO_IdleAlertGunDwnA: ['AC_NO_IdleOnAlertA', 'AC_NO_IdleA'],
  HL_IdleAlertA: ['AC_HL_IdleB', 'AC_HL_IdleA'], LL_IdleAlertA: ['AC_LL_IdleA'],
  NO_FireStartA: ['AC_NO_EquipOnA'], NO_FireStopA: ['AC_NO_EquipOffA'],
  HL_FireStartA: ['AC_HL_Cover2FocusFire90', 'AC_HL_EquipOnA'], HL_FireStopA: ['AC_HL_FocusFire2Cover90', 'AC_HL_EquipOffA'],
  LL_FireStartA: ['AC_LL_Cover2FocusFire90', 'AC_LL_EquipOnA'], LL_FireStopA: ['AC_LL_FocusFire2Cover90', 'AC_LL_EquipOffA'],
  HL_StepOutA: ['AC_HL_Cover2FocusFire90'], HL_StepInA: ['AC_HL_FocusFire2Cover90'],
  HR_StepOutA: ['AC_HR_Cover2FocusFire90'], HR_StepInA: ['AC_HR_FocusFire2Cover90'],
  HL_Run2CoverA: ['AC_HL_Run2CoverStopA'], HR_Run2CoverA: ['AC_HR_Run2CoverStopA'],
  LL_Run2CoverA: ['AC_LL_Run2CoverStopA'], LR_Run2CoverA: ['AC_LR_Run2CoverStopA'], LL_Rush2CoverA: ['AC_LL_Run2CoverStopA'],
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
  MV_ClimbDropHigh_StopA: ['AC_NO_ClimbHighDrop_StopA'], MV_ClimbDropLow_StartA: ['AC_NO_ClimbLowDrop_StartA'],
  MV_ClimbDropLow_StartWallA: ['AC_NO_ClimbLowDrop_StartB', 'AC_NO_ClimbLowDrop_StartA'], MV_ClimbDropLow_StopA: ['AC_NO_ClimbLowDrop_StopA'],
  MV_ClimbDrop_StartA: ['AC_NO_ClimbLowDrop_StartA'], MV_ClimbDrop_StartB: ['AC_NO_ClimbLowDrop_StartB', 'AC_NO_ClimbLowDrop_StartA'],
  MV_ClimbDrop_StopA: ['AC_NO_ClimbLowDrop_StopA'], MV_ClimbDrop_FurtherA: ['AC_NO_ClimbHighDrop_StopA'],
  MV_ClimbLowObject_UpA: ['AC_NO_ClimbLowObject_UpA'], MV_ClimbLowObject_DwnA: ['AC_NO_ClimbLowObject_DwnA'],
  MV_ClimbLowObject_Over1TileA: ['AC_NO_ClimbLowObject_OverA'], MV_ClimbLowObject_Over2TilesA: ['AC_NO_ClimbLowObject_OverA'],
  MV_ClimbDrainUp_StartA: ['AC_NO_ClimbLadderUp_StartA'], MV_ClimbDrainUp_StopA: ['AC_NO_ClimbLadderUp_StopA'],
  MV_ClimbDrainDwn_StartA: ['AC_NO_ClimbLadderDwn_StartA'], MV_ClimbDrainDwn_StopA: ['AC_NO_ClimbLadderDwn_StopA'],
  MV_ClimbLadderUp_StartA: ['AC_NO_ClimbLadderUp_StartA'], MV_ClimbLadderUp_StopA: ['AC_NO_ClimbLadderUp_StopA'],
  MV_ClimbLadderDwn_StartA: ['AC_NO_ClimbLadderDwn_StartA'], MV_ClimbLadderDwn_StopA: ['AC_NO_ClimbLadderDwn_StopA'],
}

/** The EW animation for an XCOM 2 name: the same name, its AC_ form, the table, then the turns (EW turns only moving). */
export function ewFor(x2: string, ew: Set<string>): string | undefined {
  if (ew.has(x2)) return x2
  if (ew.has('AC_' + x2)) return 'AC_' + x2
  for (const c of TABLE[x2] ?? []) if (ew.has(c)) return c
  const turn = /^(?:HL|LL|NO|MV|MV_Low)_?Turn(Left|Right)(\d+)$/.exec(x2.replace('MV_LowTurn', 'MV_Turn'))
  if (turn && ew.has(`MV_Turn${turn[1]}${turn[2]}`)) return `MV_Turn${turn[1]}${turn[2]}`
  const signal = /^(HL|LL)_SignalLookAt/.exec(x2)
  if (signal && ew.has('AC_NO_IdleOnAlertA')) return 'AC_NO_IdleOnAlertA'
  return undefined
}

/** The converted unit package with the AnimSet's sequences also under XCOM 2's names; returns its bytes and a report. */
export function renameAnims(source: Uint8Array, animSetPath: string, x2Names: string[]): { bytes: Uint8Array; report: string } {
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
  const byName = new Map<string, number>()
  const nameAt = new Map<number, { start: number; at: number }>()
  for (const s of seqs) {
    const d: Uint8Array = pkg.data(s)
    const r = new Reader(d.subarray(4))
    for (const t of readTags(r, pkg) as Tag[]) if (t.name === 'SequenceName') byName.set(nameOf(i32(t.value)), s)
  }

  // A copy of each EW sequence an XCOM 2 name needs, its SequenceName that name (the tag's value found by its bytes).
  const copies: number[] = []
  const unmatched: string[] = []
  const ewNames = new Set(byName.keys())
  for (const x2 of x2Names) {
    if (byName.has(x2)) continue
    const ew = ewFor(x2, ewNames)
    if (!ew) { unmatched.push(x2); continue }
    const src = byName.get(ew)!
    const d = Uint8Array.from(pkg.data(src) as Uint8Array)
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
    const e = pkg.exports[src - 1]
    const r = nameIndex(`${nameOf(e.objectName)}_X2_${x2}`)
    added.push({ entry: { ...e, objectName: { index: r, number: 0 }, serialSize: 0, serialOffset: 0, netObjects: [] }, data: d })
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
  return { bytes, report: `${animSetPath}: ${seqs.length} sequences, ${copies.length} copies under XCOM 2's names, ${unmatched.length} XCOM 2 names without an EW animation${unmatched.length ? ` (${unmatched.join(' ')})` : ''}` }
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
