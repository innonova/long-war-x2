// The converter's version (ew-map.ts writes it into each converted level's section, "; ew-map.ts <n>"), on its own so the
// setup's map step (ew-maps.ts) can tell a current conversion from an older one without loading the converter. Raised
// with every change to what ew-map.ts writes; its history is in ew-map.ts.
export const CONVERTER_VERSION = 100
